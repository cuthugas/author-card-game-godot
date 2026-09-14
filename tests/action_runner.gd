extends SceneTree
## Verifies readable action playback can show intermediate states without changing rules.
var checks := 0
var failures := 0
var events: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("ACTION FAIL: " + label)

func new_game() -> GameState:
	var game := GameState.new()
	root.add_child(game)
	game.start_match("poe", "shelley", [], 301)
	game.action_recorded.connect(func(event: Dictionary): events.append(event))
	events.clear()
	return game

func put(game: GameState, side: int, lane: int, attack: int, health: int) -> void:
	var unit := CardData.get_card("poe_usher")
	unit.attack = attack
	unit.health = health
	unit.max_health = health
	unit.keywords = []
	unit.shield = false
	game.players[side].board[lane] = unit

func _run() -> void:
	_test_clash_snapshots()
	_test_rival_playback()
	_test_terminal_snapshot()
	print("BLACKBRIAR_ACTION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _test_clash_snapshots() -> void:
	var game := new_game()
	for lane in 3: put(game, 0, lane, lane + 1, 5)
	put(game, 1, 1, 1, 5)
	game._clash(0)
	check(events.size() == 3, "one action snapshot per occupied attacking lane")
	if events.size() == 3:
		for lane in 3:
			check(events[lane].kind == "clash" and events[lane].side == 0 and events[lane].lane == lane, "clash lane %d identified" % lane)
			check(not str(events[lane].text).is_empty(), "clash has explanatory text")
		check(events[0].players[1].reputation == 15, "first lane snapshot excludes subsequent direct strike")
		check(events[0].players[1].board[1].health == 5, "first lane snapshot precedes second lane damage")
		check(events[1].players[1].board[1].health == 3 and events[1].players[0].board[1].health == 4, "opposing characters exchange damage in second snapshot")
		check(events[2].players[1].reputation == 12, "last lane contains final direct strike")
		check(events[2].players == game.players, "last clash matches actual board")
		game.players[0].board[0].health = 99
		check(events[0].players[0].board[0].health == 5, "stored nested unit does not alias mutable engine state")
		events[0].players[1].reputation = 88
		check(game.players[1].reputation == 12 and events[1].players[1].reputation == 15, "each snapshot independent of engine and neighboring snapshots")
	game.free()

func _test_rival_playback() -> void:
	var game := new_game()
	game.players[1].hand = [CardData.get_card("shelley_clerval")]
	game.players[1].deck = [CardData.get_card("shelley_creature")]
	game.end_turn()
	var cards: Array[Dictionary] = []
	for event in events:
		if event.kind == "card" and event.side == 1: cards.append(event)
	check(cards.size() == 1, "rival card play emitted individually")
	if cards.size() == 1:
		var event: Dictionary = cards[0]
		check(event.lane >= 0 and event.lane < 3, "rival card identifies its destination")
		check(event.players[1].board[event.lane].id == "shelley_clerval", "rival card visible in its post-play snapshot")
		check(str(event.text).contains("Henry Clerval"), "rival play names the card")
	check(not events.is_empty(), "end chapter emits playback")
	if not events.is_empty():
		var last: Dictionary = events.back()
		check(last.players == game.players, "final chapter snapshot matches final players")
		check(last.turn == game.turn and last.current_player == 0 and last.winner == -1, "final chapter restores player control and chapter")
		check(last.kind == "refresh", "next chapter is explicit final action")
	var count := events.size()
	check(not game.play_card(1, 0, 0), "invalid rival action rejected")
	check(events.size() == count, "rejected action creates no misleading playback")
	game.free()

func _test_terminal_snapshot() -> void:
	var game := new_game()
	put(game, 0, 0, 16, 5)
	put(game, 0, 1, 2, 5)
	game.end_turn()
	check(game.winner == 0, "lethal first lane ends match")
	check(not events.is_empty(), "terminal action recorded")
	if not events.is_empty():
		var last: Dictionary = events.back()
		check(last.winner == 0 and last.players == game.players, "terminal snapshot contains winning state")
		check(last.kind == "clash" and last.lane == 0, "no later lane or rival action after lethal clash")
	game.free()
