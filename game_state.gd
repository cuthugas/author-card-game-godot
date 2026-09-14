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
	return {"author":author,"reputation":16,"knowledge":0,"inspiration":2,"max_inspiration":2,"deck":[],"hand":[],"board":[null,null,null],"discard":[],"power_used":false,"next_ink":0,"fatigue":0,"last_spell":""}

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
	return _effect_valid(side, str(card.effect), lane)

func _effect_valid(side: int, effect: String, lane: int) -> bool:
	if effect in ["buff", "reprieve"]: return players[side].board[lane] != null
	if effect == "weaken": return players[1-side].board[lane] != null
	if effect == "metaphor":
		var previous: String = players[side].last_spell
		return previous != "" and previous != "metaphor" and _effect_valid(side, previous, lane)
	return true

func play_card(side: int, hand_index: int, lane: int = 0) -> bool:
	if not can_play_card(side, hand_index, lane): return false
	var p: Dictionary = players[side]
	var card: Dictionary = p.hand[hand_index]
	p.inspiration -= int(card.cost)
	p.hand.remove_at(hand_index)
	if card.type == "unit":
		var unit: Dictionary = card.duplicate(true)
		unit.max_health = int(unit.health)
		unit.shield = unit.effect == "shield"
		p.board[lane] = unit
		match str(unit.effect):
			"draw": draw_card(side)
			"inspire": p.inspiration += 1
			"heal": p.reputation = mini(16, p.reputation + 2)
	else:
		_resolve_effect(side, str(card.effect), lane)
		if card.effect != "metaphor": p.last_spell = card.effect
		p.discard.append(card)
	_check_winner()
	_record_action("card",side,lane,"%s plays %s in lane %d (−%d ink). %s" % [_who(side),card.name,lane+1,card.cost,card.text])
	state_changed.emit()
	return true

func _resolve_effect(side: int, effect: String, lane: int) -> void:
	var p: Dictionary = players[side]
	match effect:
		"damage":
			if players[1-side].board[lane] != null: _hit_unit(1-side, lane, 3)
			else: players[1-side].reputation -= 3
		"buff":
			p.board[lane].attack += 2
			p.board[lane].health += 1
			p.board[lane].max_health += 1
		"heal":
			p.reputation = mini(16, p.reputation + 3)
			if p.board[lane] != null: p.board[lane].health = mini(p.board[lane].max_health, p.board[lane].health + 2)
		"draw":
			draw_card(side)
			draw_card(side)
		"foreshadow":
			p.next_ink += 2
			draw_card(side)
		"metaphor": _resolve_effect(side, p.last_spell, lane)
		"weaken":
			players[1-side].board[lane].attack = maxi(0, players[1-side].board[lane].attack - 2)
			_hit_unit(1-side, lane, 1)
		"expose":
			var foe = players[1-side].board[lane]
			# The Dictionary only attacks a defended falsehood.  A character
			# without a shield is merely exposed; the sting goes to its author.
			if foe != null and foe.get("shield", false):
				foe.shield = false
				foe.health -= 1
				if foe.health > 0 and foe.effect == "rage": foe.attack += 1
				if foe.health <= 0: _defeat_unit(1-side, lane)
			else: players[1-side].reputation -= 1
		"reprieve": p.board[lane].reprieve = true

func _hit_unit(side: int, lane: int, amount: int, defer_death: bool = false) -> void:
	var unit = players[side].board[lane]
	if unit == null or amount <= 0: return
	if unit.get("shield", false): unit.shield = false; return
	unit.health -= amount
	if unit.health > 0 and unit.effect == "rage": unit.attack += 1
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
	if unit.effect == "death_draw": draw_card(side)

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
			if attacker.effect == "drain" and attacker.attack > 0: players[side].reputation = mini(16, players[side].reputation + 1)
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
		match str(card.effect):
			"damage":
				score = 4.0
				if enemy != null: score += 5.0 if enemy.health <= 3 else 1.0
				elif players[0].reputation <= 3: score += 100.0
			"buff": score = 4.0 + (2.0 if ally != null and ally.health < ally.get("max_health", ally.health) else 0.0)
			"heal": score = float(mini(3, 16 - players[1].reputation)) + (2.0 if ally != null and ally.health < ally.get("max_health", ally.health) else 0.0)
			"draw": score = 3.0 if players[1].hand.size() < 5 and players[1].deck.size() >= 2 else -2.0
			"foreshadow": score = 3.5 if not players[1].deck.is_empty() else -2.0
			"metaphor": score = 3.0
			"weaken": score = 4.0 + enemy.attack * 0.5
			"expose": score = 4.0 + (4.0 if enemy != null and enemy.get("shield", false) else (1.0 if enemy != null else 0.5))
			"reprieve": score = 3.0 + (3.0 if ally != null and ally.health <= 2 else -1.0)
	return score + rng.randf() * 0.1

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
