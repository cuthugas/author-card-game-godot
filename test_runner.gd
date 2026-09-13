extends SceneTree
## Deterministic rules regression and full-match stress suite.
## Run: godot --headless --path . --script res://test_runner.gd
var checks := 0
var failures: Array[String] = []
var finish_count := 0
const AUTHORS := ["poe", "shelley", "austen", "shakespeare", "carroll"]

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func new_game(hero := "poe", rival := "shelley", seed_value := 101) -> GameState:
	var game := GameState.new()
	root.add_child(game)
	game.start_match(hero, rival, [], seed_value)
	return game

func snapshot(game: GameState) -> String:
	return var_to_str([game.players, game.turn, game.winner])

func _run() -> void:
	_test_invalid_actions()
	_test_powers()
	_test_effects()
	_test_determinism()
	_test_passive_play()
	_simulate_matchups()
	print("BLACKBRIAR_QA checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)

func _test_invalid_actions() -> void:
	var game := new_game()
	check(game.players.size() == 2, "two players initialized")
	check(game.players[0].board.size() == 3, "three lanes initialized")
	check(game.players[0].hand.size() > 0, "opening hand drawn")
	for side in [-1, 2, 1]:
		var before := snapshot(game)
		check(not game.play_card(side, 0, 0), "reject side %d" % side)
		check(before == snapshot(game), "invalid side leaves state unchanged")
	for index in [-1, 999]:
		var before := snapshot(game)
		check(not game.play_card(0, index, 0), "reject hand index %d" % index)
		check(before == snapshot(game), "invalid card leaves state unchanged")
	for lane in [-1, 3, 99]:
		var before := snapshot(game)
		check(not game.play_card(0, 0, lane), "reject lane %d" % lane)
		check(before == snapshot(game), "invalid lane leaves state unchanged")
	game.players[0].inspiration = 0
	var before := snapshot(game)
	check(not game.power(0), "unaffordable power rejected")
	check(before == snapshot(game), "failed power leaves state unchanged")
	game.free()

func _test_determinism() -> void:
	var a := new_game("poe", "austen", 917)
	var b := new_game("poe", "austen", 917)
	check(snapshot(a) == snapshot(b), "same seed gives same opening")
	for round_index in 4:
		if a.winner == -1: _pilot(a); a.end_turn()
		if b.winner == -1: _pilot(b); b.end_turn()
		check(snapshot(a) == snapshot(b), "same decisions remain deterministic round %d" % round_index)
	a.free()
	b.free()

func _test_passive_play() -> void:
	var game := new_game()
	for i in 50:
		if game.winner != -1: break
		game.end_turn()
	check(game.winner != -1, "passing every turn still terminates")
	game.free()

func _pilot(game: GameState) -> void:
	for action in 32:
		if game.winner != -1: return
		var best_index := -1
		var best_lane := -1
		var best_score := -999.0
		for index in game.players[0].hand.size():
			var card: Dictionary = game.players[0].hand[index]
			for lane in 3:
				if not game.can_play_card(0, index, lane): continue
				var score: float = float(card.get("cost", 0))
				if str(card.get("kind", "")).to_lower() == "character":
					score += 5.0
					if game.players[1].board[lane] == null: score += 2.0
				if score > best_score:
					best_score = score
					best_index = index
					best_lane = lane
		if best_index == -1: break
		check(game.play_card(0, best_index, best_lane), "legal action succeeds")
	game.power(0)

func _simulate_matchups() -> void:
	var rounds: Array[int] = []
	var wins := {}
	for hero in AUTHORS:
		wins[hero] = 0
		for rival in AUTHORS:
			for seed_value in 8:
				var game := new_game(hero, rival, seed_value + 1000)
				finish_count = 0
				game.match_finished.connect(func(_winner: int): finish_count += 1)
				var elapsed := 0
				while game.winner == -1 and elapsed < 50:
					_pilot(game)
					game.end_turn()
					elapsed += 1
					for side in 2:
						check(game.players[side].board.size() == 3, "lanes remain fixed")
						check(game.players[side].inspiration >= 0, "ink never negative")
				check(game.winner != -1, "match terminates %s/%s seed%d" % [hero,rival,seed_value])
				check(finish_count == 1, "finish signal exactly once")
				if game.winner == 0: wins[hero] += 1
				rounds.append(elapsed)
				var before := snapshot(game)
				check(not game.play_card(0, 0, 0), "terminal play rejected")
				check(not game.power(0), "terminal power rejected")
				game.end_turn()
				check(before == snapshot(game), "terminal state locked")
				check(finish_count == 1, "terminal signal not repeated")
				game.free()
	rounds.sort()
	var total := 0
	for count in rounds: total += count
	print("PACING matches=%d rounds_min=%d median=%d max=%d mean=%.2f player_wins=%s" % [rounds.size(),rounds[0],rounds[rounds.size()/2],rounds[-1],float(total)/rounds.size(),str(wins)])

func _put(game: GameState, side: int, id: String, lane: int) -> void:
	var unit := CardData.get_card(id)
	unit.max_health = unit.health
	unit.shield = unit.effect == "shield"
	game.players[side].board[lane] = unit

func _cast(game: GameState, id: String, lane := 0) -> bool:
	game.players[0].hand = [CardData.get_card(id)]
	game.players[0].inspiration = 20
	return game.play_card(0, 0, lane)

func _test_effects() -> void:
	var game := new_game()
	check(not _cast(game, "imagery"), "buff needs allied target")
	check(not _cast(game, "dramatic_irony"), "weaken needs enemy target")
	check(not _cast(game, "metaphor"), "metaphor needs previous concept")
	_put(game, 0, "poe_raven", 0)
	check(_cast(game, "imagery"), "imagery resolves")
	check(game.players[0].board[0].attack == 5 and game.players[0].board[0].health == 4, "imagery adds 2 attack and 1 health")
	check(_cast(game, "metaphor"), "metaphor copies imagery")
	check(game.players[0].board[0].attack == 7, "copied buff applies")
	check(_cast(game, "metaphor"), "consecutive metaphor remains safe")
	check(game.players[0].board[0].attack == 9, "metaphor does not recurse into itself")
	game.players[0].reputation = 10
	game.players[0].board[0].health = 1
	check(_cast(game, "revision"), "revision resolves")
	check(game.players[0].reputation == 13 and game.players[0].board[0].health == 3, "revision heals writer and lane")
	check(_cast(game, "conflict", 1), "direct conflict resolves")
	check(game.players[1].reputation == 13, "empty lane conflict hits author for3")
	_put(game, 1, "shelley_creature", 1)
	check(_cast(game, "conflict", 1), "conflict damages unit")
	check(game.players[1].board[1].health == 2 and game.players[1].board[1].attack == 5, "surviving creature gains rage")
	_put(game, 1, "poe_montresor", 2)
	check(_cast(game, "conflict", 2), "shield absorbs conflict")
	check(game.players[1].board[2].health == 2 and not game.players[1].board[2].shield, "shield consumed without damage")
	check(_cast(game, "conflict", 2), "second conflict defeats shieldless unit")
	check(game.players[1].board[2] == null, "defeated unit removed")
	check(_cast(game, "dramatic_irony", 1), "irony resolves")
	check(game.players[1].board[1].attack == 4 and game.players[1].board[1].health == 1, "weaken plus surviving rage stacks correctly")
	var next_ink: int = game.players[0].next_ink
	check(_cast(game, "foreshadowing"), "foreshadowing resolves")
	check(game.players[0].next_ink == next_ink + 2 and game.players[0].hand.size() == 1, "foreshadow draws and delays ink")
	var ink: int = game.players[0].inspiration
	check(game.answer_question(true), "first correct quiz accepted")
	check(game.players[0].inspiration == ink + 1 and game.players[0].knowledge == 1, "quiz reward correct")
	check(not game.answer_question(true), "quiz cannot be farmed same chapter")
	game.free()
	game = new_game()
	check(game.answer_question(false), "wrong answer consumes attempt")
	check(game.players[0].knowledge == 0 and not game.answer_question(true), "wrong answer cannot be retried for ink")
	game.players[0].deck.clear()
	game.draw_card(0)
	check(game.players[0].reputation == 15, "first fatigue costs1")
	game.draw_card(0)
	check(game.players[0].reputation == 13, "second fatigue costs2")
	game.free()

func _test_powers() -> void:
	for author in AUTHORS:
		var game := new_game(author, "poe")
		game.players[0].reputation = 10
		_put(game, 0, "poe_raven", 0)
		var hand_size: int = game.players[0].hand.size()
		check(game.power(0), "signature usable: " + author)
		check(game.players[0].inspiration == 0, "signature costs2: " + author)
		check(not game.power(0), "signature cannot repeat: " + author)
		match author:
			"poe": check(game.players[1].reputation == 14, "Nevermore deals2")
			"shelley": check(game.players[0].board[0].attack == 4 and game.players[0].board[0].health == 5, "Galvanize grows strongest")
			"austen": check(game.players[0].reputation == 13 and game.players[0].hand.size() == hand_size + 1, "Social Insight heals and draws")
			"shakespeare": check(game.players[0].board[0].attack == 4, "Curtain buffs cast")
			"carroll": check(game.players[0].hand.size() == hand_size + 2, "Rabbit Hole draws2")
		game.free()
	var game := new_game()
	_put(game, 0, "poe_raven", 0)
	_put(game, 1, "poe_raven", 0)
	game._clash(0)
	check(game.players[0].board[0] == null and game.players[1].board[0] == null, "equal lethal clash defeats both simultaneously")
	_put(game, 0, "poe_raven", 1)
	game.players[0].reputation = 10
	game._clash(0)
	check(game.players[0].reputation == 11 and game.players[1].reputation == 13, "Raven drain on direct strike")
	game.free()
