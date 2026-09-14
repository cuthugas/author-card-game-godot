extends SceneTree
## Scene-level regression. Run with isolated XDG_DATA_HOME to avoid touching player progress.
var failures: Array[String] = []
var checks := 0
var scene

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("UI FAIL: " + message)

func _frame() -> void:
	await process_frame
	await process_frame

func wait_for_playback() -> bool:
	var deadline := Time.get_ticks_msec() + 30000
	while scene.busy and Time.get_ticks_msec() < deadline:
		if is_instance_valid(scene.overlay):
			check(false, "result must not open during action playback")
			return false
		await create_timer(0.05).timeout
	check(not scene.busy, "action playback completes within 30 seconds")
	return not scene.busy

func _run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await _frame()
	check(scene.screen == "title", "title opens")
	var title_count: int = scene.ui.get_child_count()
	for i in 4:
		scene._show_authors()
		await _frame()
		check(scene.screen == "authors", "author screen opens")
		scene._show_campaign()
		await _frame()
		check(scene.screen == "campaign", "campaign opens")
		scene._show_deck()
		await _frame()
		scene._show_codex()
		await _frame()
		scene._show_title()
		await _frame()
		check(scene.ui.get_child_count() == title_count, "navigation does not accumulate UI")
	scene._show_tutorial()
	await _frame()
	check(is_instance_valid(scene.overlay), "tutorial opens")
	scene._close_modal()
	await _frame()
	check(scene.overlay == null, "tutorial closes")
	scene.profile.data.tutorial_seen = true
	for author in scene.AUTHORS:
		scene.selected_author = author
		scene.campaign_mode = false
		scene._start_match("poe")
		await _frame()
		check(scene.screen == "match", "match opens for " + author)
		var states := 0
		for node in scene.get_children():
			if node is GameState: states += 1
		check(states == 1, "exactly one rules instance after restart")
		check(scene.game.players[0].author == author, "selected author reaches engine")
		scene._show_question()
		await _frame()
		check(is_instance_valid(scene.overlay), "question opens")
		scene._close_modal()
		var before: int = scene.game.turn
		scene._end_chapter()
		await create_timer(0.1).timeout
		scene.skip_replay = true
		if not await wait_for_playback(): quit(1); return
		check(scene.game.turn == before + 1 or scene.game.winner != -1, "end chapter resolves and returns")
		check(not scene.busy, "input unlocks after chapter")
		scene.game.players[1].reputation = 0
		scene.game._check_winner()
		scene._show_match()
		await _frame()
		check(is_instance_valid(scene.overlay), "terminal result opens")
		var matches: int = scene.profile.data.matches
		scene._on_finished(0)
		check(scene.profile.data.matches == matches, "result rewards once")
	# A paused replay must keep the exact action on screen until the player resumes.
	scene._start_match("poe")
	scene._end_chapter()
	await create_timer(0.15).timeout
	scene.replay_paused = true
	var paused_step: int = scene.replay_step
	await create_timer(0.3).timeout
	check(scene.busy and scene.replay_step == paused_step, "pause freezes the visible replay action")
	scene.replay_paused = false
	scene.skip_replay = true
	if not await wait_for_playback(): quit(1); return
	check(scene.playback_event.is_empty(), "skip clears replay state before returning control")
	scene._start_match("shelley")
	var lethal := CardData.get_card("poe_raven")
	lethal.attack = 16
	lethal.max_health = lethal.health
	lethal.shield = false
	scene.game.players[0].board[0] = lethal
	scene._end_chapter()
	await create_timer(0.1).timeout
	check(scene.game.winner == 0 and scene.busy, "winning engine state waits for readable playback")
	check(not is_instance_valid(scene.overlay), "winning result hidden before lethal action finishes")
	scene.skip_replay = true
	if not await wait_for_playback(): quit(1); return
	check(is_instance_valid(scene.overlay), "winning result opens after action playback")
	scene._start_match("poe")
	scene._end_chapter()
	scene._show_title()
	scene._start_match("shelley")
	await create_timer(1.0).timeout
	check(scene.game.turn == 1, "old chapter timer cannot advance new match")
	check(not scene.busy, "rapid restart preserves unlocked input")
	scene.profile.save_profile()
	var reloaded := PlayerProfile.new()
	reloaded.load_profile()
	check(reloaded.data.matches == scene.profile.data.matches, "profile saves and reloads matches")
	check(reloaded.data.wins == scene.profile.data.wins, "profile saves and reloads wins")
	scene._show_title()
	await _frame()
	check(scene.ui.get_child_count() == title_count, "postmatch title no UI leak")
	scene._exit_tree()
	await create_timer(0.2).timeout
	scene.queue_free()
	await _frame()
	print("BLACKBRIAR_UI_QA checks=%d failures=%d" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
