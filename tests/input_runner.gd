extends SceneTree
## Exercises real viewport mouse routing, not button signals or gameplay handlers.
var scene
var failures := 0
var actions := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("INPUT FAIL: " + message)

func click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
	actions += 1
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
	root.size = Vector2i(1440,900)
	root.content_scale_size = Vector2i(1440,900)
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	# In-memory profile avoids modifying a player's progression.
	scene.profile.data.tutorial_seen = true
	await click_at(Vector2(280,600))
	check(scene.screen == "authors", "title button opens author selection")
	await click_at(Vector2(500,820))
	check(scene.screen == "match", "quick duel button opens match")
	if scene.screen != "match": quit(1); return
	var rounds := 0
	while scene.game.winner == -1 and rounds < 25:
		var moves := 0
		while moves < 12 and scene.game.winner == -1:
			var chosen := -1
			var target := -1
			for index in scene.game.players[0].hand.size():
				for lane in 3:
					if scene.game.can_play_card(0,index,lane):
						chosen = index
						target = lane
						break
				if chosen >= 0: break
			if chosen < 0: break
			var count: int = scene.game.players[0].hand.size()
			var width := minf(160,(1050.0-maxi(0,count-1)*10)/maxi(1,count))
			await click_at(Vector2(60+chosen*(width+10)+width/2,760))
			check(scene.selected_card == chosen, "hand click selects expected card")
			var target_y := 250 if scene._targets_enemy(scene.game.players[0].hand[chosen]) else 478
			await click_at(Vector2(60+target*358+167,target_y))
			check(scene.selected_card == -1, "lane click plays selected card")
			moves += 1
		if scene.game.winner != -1: break
		await click_at(Vector2(1275,756))
		if not await wait_for_playback(): quit(1); return
		check(not scene.busy, "chapter releases input")
		rounds += 1
	check(scene.game.winner != -1, "mouse-driven match reaches result")
	check(is_instance_valid(scene.overlay), "result modal visible")
	await click_at(Vector2(720,690))
	check(scene.screen == "title", "result returns to title")
	print("BLACKBRIAR_INPUT actions=%d rounds=%d failures=%d" % [actions,rounds,failures])
	scene._exit_tree()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
