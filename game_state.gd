class_name GameState
extends Node

signal action_recorded(event: Dictionary)
signal state_changed
signal message_changed(message: String)
signal match_finished(winner: int)

var players: Array[Dictionary] = []
var current_player := 0
var turn := 0
var winner := -1
var database: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var quiz_used := false
var _resolving := false

func start_match(hero: String, rival: String, custom_deck: Array = [], seed_value: int = 0) -> void:
	database = CardData.all_cards()
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	winner = -1
	turn = 1
	current_player = 0
	quiz_used = false
	_resolving = false
	players = [_new_player(hero.to_lower()), _new_player(rival.to_lower())]
	for side in 2:
		players[side].deck = _build_deck(players[side].author)
		if side == 0 and not custom_deck.is_empty():
			players[side].deck.clear()
			for entry in custom_deck:
				if entry is Dictionary: players[side].deck.append(entry.duplicate(true))
				else:
					for card in database:
						if card.id == entry: players[side].deck.append(card.duplicate(true)); break
		_shuffle(players[side].deck)
		for i in 4: draw_card(side)
	message_changed.emit("Chapter 1 · Choose a card, then a lane. End chapter to clash.")
	state_changed.emit()

func _new_player(author: String) -> Dictionary:
	return {"author":author,"reputation":16,"knowledge":0,"inspiration":2,"max_inspiration":2,"deck":[],"hand":[],"board":[null,null,null],"discard":[],"power_used":false,"next_ink":0,"fatigue":0,"last_spell_effects":[]}

func _shuffle(cards: Array) -> void:
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var item = cards[i]
		cards[i] = cards[j]
		cards[j] = item

func _build_deck(author: String) -> Array:
	return CardData.deck_for(author)

func draw_card(side: int) -> void:
	if not _valid_side(side) or winner != -1: return
	var p: Dictionary = players[side]
	if p.deck.is_empty():
		p.fatigue += 1
		p.reputation -= p.fatigue
		_check_winner()
		return
	var card: Dictionary = p.deck.pop_back()
	if p.hand.size() >= 7: p.discard.append(card)
	else: p.hand.append(card)

func _valid_side(side: int) -> bool:
	return players.size() == 2 and side >= 0 and side <= 1

func can_play_card(side: int, hand_index: int, lane: int = 0) -> bool:
	if winner != -1 or not _valid_side(side) or side != current_player or lane < 0 or lane > 2: return false
	if hand_index < 0 or hand_index >= players[side].hand.size(): return false
	var card: Dictionary = players[side].hand[hand_index]
	if int(card.cost) > int(players[side].inspiration): return false
	if card.type == "unit": return players[side].board[lane] == null
	return _effects_targetable(side, _effects_for(card, "on_play"), lane)

## Some effect primitives only make sense with a friendly or enemy unit
## already occupying the target lane; this checks every effect a card (or,
## for repeat_last_spell, the spell it repeats) would try to resolve.
func _effects_targetable(side: int, effects: Array, lane: int) -> bool:
	if effects.is_empty(): return false
	for effect in effects:
		match str(effect.get("type","")):
			"buff_ally_lane", "grant_reprieve":
				if players[side].board[lane] == null: return false
			"weaken_enemy_lane":
				if players[1-side].board[lane] == null: return false
			"repeat_last_spell":
				var previous: Array = players[side].last_spell_effects
				if previous.is_empty() or not _effects_targetable(side, previous, lane): return false
	return true

## Flattens every effect a card's triggers would fire for the given event
## ("on_arrival" for units, "on_play" for spells) into a single list.
static func _effects_for(card: Dictionary, event: String) -> Array:
	var effects: Array = []
	for trigger in card.get("triggers", []):
		if str(trigger.get("event","")) == event:
			effects.append_array(trigger.get("effects", []))
	return effects

func play_card(side: int, hand_index: int, lane: int = 0) -> bool:
	if not can_play_card(side, hand_index, lane): return false
	var p: Dictionary = players[side]
	var card: Dictionary = p.hand[hand_index]
	p.inspiration -= int(card.cost)
	p.hand.remove_at(hand_index)
	if card.type == "unit":
		var unit: Dictionary = card.duplicate(true)
		unit.max_health = int(unit.health)
		unit.shield = unit.keywords.has("shield")
		p.board[lane] = unit
		_resolve_triggers(side, unit.get("triggers", []), "on_arrival", lane)
		_apply_author_passive(side, unit)
	else:
		var effects := _effects_for(card, "on_play")
		for effect in effects: _apply_effect(side, effect, lane)
		if not _has_effect_type(effects, "repeat_last_spell"): p.last_spell_effects = effects
		p.discard.append(card)
	_check_winner()
	_record_action("card",side,lane,"%s plays %s in lane %d (−%d ink). %s" % [_who(side),card.name,lane+1,card.cost,card.text])
	state_changed.emit()
	return true

static func _has_effect_type(effects: Array, type_name: String) -> bool:
	for effect in effects:
		if str(effect.get("type","")) == type_name: return true
	return false

## Gives a unit its author's small on-arrival bonus when its tags match the
## author's bonus_tag (e.g. Poe's "dread" characters gain +1 attack). This is
## separate from the once-per-match author power in power().
func _apply_author_passive(side: int, unit: Dictionary) -> void:
	var profile: Dictionary = CardData.AUTHORS.get(players[side].author, {})
	var bonus_tag: String = str(profile.get("bonus_tag",""))
	if bonus_tag == "" or not unit.get("tags", []).has(bonus_tag): return
	match str(profile.get("bonus_stat","")):
		"attack": unit.attack += 1
		"health": unit.health += 1; unit.max_health += 1

func _resolve_triggers(side: int, triggers: Array, event: String, lane: int) -> void:
	for trigger in triggers:
		if str(trigger.get("event","")) == event:
			for effect in trigger.get("effects", []): _apply_effect(side, effect, lane)

## Applies one typed effect primitive. Cards compose these into lists via
## their "triggers" (see CardData._legacy_spell_triggers for examples), so a
## single card can chain several small effects instead of one fixed keyword.
func _apply_effect(side: int, effect: Dictionary, lane: int) -> void:
	var p: Dictionary = players[side]
	match str(effect.get("type","")):
		"draw":
			for i in int(effect.get("amount",1)): draw_card(side)
		"gain_inspiration": p.inspiration += int(effect.get("amount",1))
		"gain_next_inspiration": p.next_ink += int(effect.get("amount",1))
		"heal_reputation": p.reputation = mini(16, p.reputation + int(effect.get("amount",1)))
		"heal_ally_lane":
			if p.board[lane] != null: p.board[lane].health = mini(p.board[lane].max_health, p.board[lane].health + int(effect.get("amount",1)))
		"buff_ally_lane":
			if p.board[lane] != null:
				p.board[lane].attack += int(effect.get("attack",0))
				p.board[lane].health += int(effect.get("health",0))
				p.board[lane].max_health += int(effect.get("health",0))
		"damage_enemy_lane":
			if players[1-side].board[lane] != null: _hit_unit(1-side, lane, int(effect.get("amount",1)))
			else: players[1-side].reputation -= int(effect.get("amount",1))
		"weaken_enemy_lane":
			if players[1-side].board[lane] != null:
				players[1-side].board[lane].attack = maxi(0, players[1-side].board[lane].attack - int(effect.get("attack",1)))
		"expose_lane":
			var foe = players[1-side].board[lane]
			# The Dictionary only attacks a defended falsehood.  A character
			# without a shield is merely exposed; the sting goes to its author.
			if foe != null and foe.get("shield", false):
				foe.shield = false
				_hit_unit(1-side, lane, int(effect.get("shield_break_damage",1)))
			else: players[1-side].reputation -= int(effect.get("author_damage",1))
		"grant_reprieve":
			if p.board[lane] != null: p.board[lane].reprieve = true
		"repeat_last_spell":
			for sub_effect in p.last_spell_effects: _apply_effect(side, sub_effect, lane)

func _hit_unit(side: int, lane: int, amount: int, defer_death: bool = false) -> void:
	var unit = players[side].board[lane]
	if unit == null or amount <= 0: return
	if unit.get("shield", false): unit.shield = false; return
	unit.health -= amount
	if unit.health > 0 and unit.keywords.has("rage"): unit.attack += 1
	if not defer_death and unit.health <= 0: _defeat_unit(side, lane)

func _defeat_unit(side: int, lane: int) -> void:
	var unit = players[side].board[lane]
	if unit == null: return
	if unit.get("reprieve", false):
		unit.reprieve = false
		unit.health = 1
		return
	players[side].board[lane] = null
	players[side].discard.append(unit)
	if unit.keywords.has("death_draw"): draw_card(side)

func can_power(side: int) -> bool:
	return winner == -1 and _valid_side(side) and current_player == side and not players[side].power_used and players[side].inspiration >= 2

func power(side: int) -> bool:
	if winner != -1 or not _valid_side(side) or current_player != side: return false
	var p: Dictionary = players[side]
	if p.power_used or p.inspiration < 2: return false
	p.power_used = true
	p.inspiration -= 2
	match str(p.author):
		"poe": players[1-side].reputation -= 2
		"shelley":
			var best := -1
			for lane in 3:
				if p.board[lane] != null and (best < 0 or p.board[lane].attack > p.board[best].attack): best = lane
			if best < 0: p.reputation = mini(16, p.reputation + 3)
			else:
				p.board[best].attack += 1
				p.board[best].health += 2
				p.board[best].max_health += 2
		"shakespeare":
			for unit in p.board:
				if unit != null: unit.attack += 1
		"austen":
			p.reputation = mini(16, p.reputation + 3)
			draw_card(side)
		"carroll":
			draw_card(side)
			draw_card(side)
		"doyle":
			players[1-side].reputation -= 1
			draw_card(side)
		"burroughs":
			for unit in p.board:
				if unit != null: unit.max_health += 1; unit.health += 1
	_check_winner()
	_record_action("power",side,-1,"%s uses %s (−2 ink). %s" % [_who(side),CardData.AUTHORS[p.author].power,CardData.AUTHORS[p.author].power_text])
	state_changed.emit()
	return true

func answer_question(correct: bool) -> bool:
	if winner != -1 or players.is_empty() or current_player != 0 or quiz_used: return false
	quiz_used = true
	if correct:
		players[0].inspiration += 1
		players[0].knowledge += 1
	state_changed.emit()
	return true

func end_turn() -> void:
	if winner != -1 or players.is_empty() or current_player != 0 or _resolving: return
	_resolving = true
	_clash(0)
	if winner == -1:
		current_player = 1
		# Rival receives the same resource curve as the human.
		_refresh(1, false)
		_ai_turn()
	if winner == -1:
		_clash(1)
	if winner == -1:
		turn += 1
		current_player = 0
		quiz_used = false
		_refresh(0, true)
		message_changed.emit("Chapter %d · The next page is yours." % turn)
	_resolving = false
	state_changed.emit()

func _refresh(side: int, grow: bool) -> void:
	var p: Dictionary = players[side]
	if grow or (side == 1 and turn > 1): p.max_inspiration = mini(6, p.max_inspiration + 1)
	p.inspiration = p.max_inspiration + p.next_ink
	p.next_ink = 0
	p.power_used = false
	draw_card(side)
	_record_action("refresh",side,-1,"%s begins chapter %d: Inspiration refilled to %d. %s" % [_who(side),turn,p.inspiration,"A card is drawn." if p.fatigue == 0 else "The deck is empty: %d fatigue damage." % p.fatigue])

func _clash(side: int) -> void:
	for lane in 3:
		if winner != -1: return
		var attacker = players[side].board[lane]
		var defender = players[1-side].board[lane]
		if attacker == null: continue
		var detail := ""
		if defender == null:
			detail = "%s’s %s hits %s for %d Reputation: lane %d is undefended." % [_who(side),attacker.name,_who(1-side),attacker.attack,lane+1]
			players[1-side].reputation -= maxi(0, int(attacker.attack))
			if attacker.keywords.has("drain") and attacker.attack > 0: players[side].reputation = mini(16, players[side].reputation + 1)
		else:
			var a: int = attacker.attack
			var d: int = defender.attack
			var dealt := 0 if defender.get("shield",false) else a
			var returned := 0 if attacker.get("shield",false) else d
			detail = "Lane %d: %s → %s, %d damage. Retaliation: %d." % [lane+1,attacker.name,defender.name,dealt,returned]
			if defender.get("shield",false) or attacker.get("shield",false): detail += " A shield blocks its first hit."
			_hit_unit(1-side, lane, a, true)
			_hit_unit(side, lane, d, true)
			for owner in 2:
				if players[owner].board[lane] != null and players[owner].board[lane].health <= 0: _defeat_unit(owner, lane)
		_check_winner()
		if defender != null:
			if attacker.health <= 0: detail += " %s is defeated." % attacker.name
			if defender.health <= 0: detail += " %s is defeated." % defender.name
		_record_action("clash",side,lane,detail)

func _ai_turn() -> void:
	for action in 32:
		if winner != -1: return
		var best_index := -1
		var best_lane := 0
		var best_score := -1000.0
		for index in players[1].hand.size():
			var card: Dictionary = players[1].hand[index]
			for lane in 3:
				if not can_play_card(1, index, lane): continue
				var score := _ai_score(card, lane)
				if score > best_score: best_score = score; best_index = index; best_lane = lane
		if best_index < 0 or best_score <= 0: break
		if not play_card(1, best_index, best_lane): break
	if winner == -1: power(1)

func _ai_score(card: Dictionary, lane: int) -> float:
	var enemy = players[0].board[lane]
	var ally = players[1].board[lane]
	var score := 0.0
	if card.type == "unit":
		score = 5.0 + card.attack + card.health * 0.6
		if enemy != null:
			score += 2.0 if card.health > enemy.attack else -1.0
			if players[1].reputation <= enemy.attack: score += 20.0
		else: score += card.attack * 0.5
	else:
		for effect in _effects_for(card, "on_play"): score += _ai_effect_score(effect, enemy, ally)
	return score + rng.randf() * 0.1

## Scores one effect primitive for the rival AI. Summed across every effect a
## card carries, so a card composed of several small effects (e.g. draw +
## gain_next_inspiration) is scored as the sum of its parts instead of
## needing its own hand-tuned case, unlike the old single-keyword switch.
func _ai_effect_score(effect: Dictionary, enemy, ally) -> float:
	match str(effect.get("type","")):
		"damage_enemy_lane":
			var amount := int(effect.get("amount",1))
			var s := 4.0
			if enemy != null: s += 5.0 if enemy.health <= amount else 1.0
			elif players[0].reputation <= amount: s += 100.0
			return s
		"buff_ally_lane": return 4.0 + (2.0 if ally != null and ally.health < ally.get("max_health", ally.health) else 0.0)
		"heal_reputation": return float(mini(int(effect.get("amount",3)), 16 - players[1].reputation))
		"heal_ally_lane": return 2.0 if ally != null and ally.health < ally.get("max_health", ally.health) else 0.0
		"draw": return 3.0 if players[1].hand.size() < 5 and players[1].deck.size() >= 2 else -2.0
		"gain_inspiration": return 2.0
		"gain_next_inspiration": return 3.5 if not players[1].deck.is_empty() else -2.0
		"weaken_enemy_lane": return 4.0 + (enemy.attack * 0.5 if enemy != null else 0.0)
		"expose_lane": return 4.0 + (4.0 if enemy != null and enemy.get("shield", false) else (1.0 if enemy != null else 0.5))
		"grant_reprieve": return 3.0 + (3.0 if ally != null and ally.health <= 2 else -1.0)
		"repeat_last_spell":
			var total := 0.0
			for sub_effect in players[1].last_spell_effects: total += _ai_effect_score(sub_effect, enemy, ally)
			return total
		_: return 1.0

func _check_winner() -> bool:
	if winner != -1: return true
	if players.size() != 2: return false
	if players[0].reputation <= 0 and players[1].reputation <= 0: winner = 2
	elif players[0].reputation <= 0: winner = 1
	elif players[1].reputation <= 0: winner = 0
	if winner != -1:
		match_finished.emit(winner)
		return true
	return false

func _who(side: int) -> String:
	return "You" if side == 0 else "Rival"

func _record_action(kind: String, side: int, lane: int, text: String) -> void:
	message_changed.emit(text)
	action_recorded.emit({"kind":kind,"side":side,"lane":lane,"text":text,"players":players.duplicate(true),"current_player":current_player,"turn":turn,"winner":winner})
