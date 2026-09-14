extends SceneTree
var scene
func _init() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tests/"+name+".png")
func unit(id: String) -> Dictionary:
	var card := CardData.get_card(id)
	card.max_health = card.health
	card.shield = card.keywords.has("shield")
	return card
func run() -> void:
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.profile.data.tutorial_seen = true
	scene._start_match("shelley")
	scene.game.players[0].board = [unit("poe_raven"),unit("poe_usher"),null]
	scene.game.players[1].board = [unit("shelley_clerval"),null,unit("shelley_victor")]
	scene.game.players[0].hand = [CardData.get_card("conflict"),CardData.get_card("imagery"),CardData.get_card("poe_dupin")]
	scene.game.players[0].inspiration = 4
	scene.selected_card = 0
	scene._show_match()
	await capture("clarity_targets")
	scene.selected_card = -1
	scene._end_chapter()
	await capture("clarity_replay")
	scene.skip_replay = true
	while scene.busy: await create_timer(0.1).timeout
	await capture("clarity_after")
	print("CLARITY_VISUAL_OK")
	scene._quit_game()
