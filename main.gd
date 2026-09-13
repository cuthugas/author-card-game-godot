extends Node3D

const Rules = preload("res://game_state.gd")
const Profile = preload("res://profile.gd")
const Stage = preload("res://atmosphere.gd")
const GOLD := Color("c9a86a")
const IVORY := Color("eee5cc")
const MUTED := Color("a7b3a1")
const BG := Color("101d17")
const AUTHORS := ["poe", "shelley", "shakespeare", "austen", "carroll"]
const NAMES := {"poe":"Edgar Allan Poe", "shelley":"Mary Shelley", "shakespeare":"William Shakespeare", "austen":"Jane Austen", "carroll":"Lewis Carroll"}
const TAGS := {"poe":"DREAD & RECURSION", "shelley":"CREATION & SACRIFICE", "shakespeare":"AMBITION & TRAGEDY", "austen":"WIT & RESILIENCE", "carroll":"WONDER & POSSIBILITY"}
const ICONS := {"poe":"R", "shelley":"S", "shakespeare":"W", "austen":"A", "carroll":"C", "neutral":"✦"}
var profile = Profile.new()
var game
var ui: Control
var overlay: Control
var screen := "title"
var selected_author := "poe"
var selected_card := -1
var selected_lane := 0
var campaign_mode := false
var recorded := false
var busy := false
var log_lines: Array[String] = []
var message := ""
var deck_draft: Array = []
var codex_filter := "all"
var serif: Font = preload("res://assets/Display.ttf")
var sans: Font = preload("res://assets/Body.ttf")
var art: Texture2D
var backdrop: Texture2D
var sound: AudioStreamPlayer
var ambient: AudioStreamPlayer
var question_index := 0
var action_queue: Array[Dictionary] = []
var playback_event: Dictionary = {}
var skip_replay := false
var replay_paused := false
var replay_step := 0

func _ready() -> void:
	get_tree().auto_accept_quit = false
	profile.load_profile()
	selected_author = profile.data.author if profile.data.author in AUTHORS else "poe"
	if ResourceLoader.exists("res://assets/author_atlas.png"): art = load("res://assets/author_atlas.png")
	if ResourceLoader.exists("res://assets/library.png"): backdrop = load("res://assets/library.png")
	add_child(Stage.new())
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var theme := Theme.new()
	theme.default_font = sans
	theme.default_font_size = 18
	ui.theme = theme
	sound = AudioStreamPlayer.new()
	add_child(sound)
	ambient = AudioStreamPlayer.new()
	add_child(ambient)
	ambient.volume_db = -29
	if ResourceLoader.exists("res://assets/ambience.wav"):
		ambient.stream = load("res://assets/ambience.wav")
		ambient.finished.connect(func(): ambient.play())
		if not profile.data.muted: ambient.play()
	_show_title()
	if "--visual-smoke" in OS.get_cmdline_user_args(): _visual_smoke()

func _clear() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	overlay = null

func _rect(parent: Node, box: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = box.position
	node.size = box.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _label(parent: Node, text: String, box: Rect2, size := 18, color := IVORY, display := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = box.position
	node.add_theme_font_override("font", serif if display else sans)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = box.size
	return node

func _style(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _panel(parent: Node, box: Rect2, fill := Color("14231ceF"), border := Color("485242")) -> Panel:
	var node := Panel.new()
	node.position = box.position
	node.size = box.size
	node.add_theme_stylebox_override("panel", _style(fill,border))
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, box: Rect2, callback: Callable, primary := false, disabled := false) -> Button:
	var node := Button.new()
	node.position = box.position
	node.size = box.size
	node.text = text
	node.disabled = disabled
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_color_override("font_color", BG if primary else IVORY)
	node.add_theme_color_override("font_hover_color", Color("ffffff"))
	node.add_theme_color_override("font_disabled_color",Color("708073"))
	node.add_theme_stylebox_override("normal",_style(GOLD if primary else Color("182820ef"),GOLD if primary else Color("526047")))
	node.add_theme_stylebox_override("hover",_style(Color("364938"),GOLD,2))
	node.add_theme_stylebox_override("pressed",_style(Color("4b5639"),IVORY,2))
	node.add_theme_stylebox_override("focus",_style(Color("00000000"),IVORY,2))
	node.add_theme_stylebox_override("disabled",_style(Color("142019cc"),Color("344437")))
	node.pressed.connect(func(): _tone(); callback.call())
	parent.add_child(node)
	return node

func _picture(parent: Node, texture: Texture2D, box: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.position = box.position
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = box.size
	return node

func _author_art(author: String) -> Texture2D:
	if art == null: return null
	var atlas := AtlasTexture.new()
	atlas.atlas = art
	var index: int = AUTHORS.find(author)
	if index < 0: index = 0
	atlas.region = Rect2(index*art.get_width()/5.0,0,art.get_width()/5.0,art.get_height())
	return atlas

func _background() -> void:
	if backdrop: _picture(ui,backdrop,Rect2(0,0,1440,900))
	_rect(ui,Rect2(0,0,1440,900),Color(0.025,0.045,0.033,0.45))
	_rect(ui,Rect2(0,0,650,900),Color(0.025,0.045,0.033,0.8))

func _header(title: String, subtitle: String, back: Callable) -> void:
	_rect(ui,Rect2(0,0,1440,900),Color("0b1611e8"))
	_label(ui,"B / B",Rect2(50,30,100,40),28,GOLD,true)
	_label(ui,title,Rect2(175,24,960,48),34,IVORY,true)
	_label(ui,subtitle,Rect2(177,74,1080,32),16,MUTED)
	_button(ui,"←  Back",Rect2(1240,32,150,46),back)
	_rect(ui,Rect2(50,120,1340,1),Color("526047"))

func _show_title() -> void:
	screen = "title"
	busy = false
	_clear()
	_background()
	_label(ui,"BLACKBRIAR LITERARY SOCIETY",Rect2(78,75,600,35),17,GOLD)
	_rect(ui,Rect2(80,128,68,2),GOLD)
	_label(ui,"Blackbriar",Rect2(73,170,800,110),92,IVORY,true)
	_label(ui,"The Midnight Colloquium",Rect2(80,290,650,58),32,GOLD,true)
	_label(ui,"The mountains keep their secrets.\nThe dead still have something to say.",Rect2(83,375,490,80),23,IVORY,true)
	_label(ui,"Summon literary legends. Shape the story.\nWin a battle of wits before the candles burn out.",Rect2(83,470,500,65),18,MUTED)
	_button(ui,"Enter the Colloquium    →",Rect2(83,570,410,62),_show_authors,true)
	_button(ui,"The card catalogue",Rect2(83,650,198,50),func(): _show_codex())
	_button(ui,"How to play",Rect2(295,650,198,50),_show_tutorial)
	_button(ui,"Settings",Rect2(83,716,198,46),_show_settings)
	_button(ui,"Quit",Rect2(295,716,198,46),_quit_game)
	_label(ui,"FIVE AUTHORS  /  THREE LANES  /  ONE LAST WORD",Rect2(83,829,700,25),14,GOLD)
	var stats := _panel(ui,Rect2(1030,709,325,121),Color("111d17dd"),Color("756544"))
	_label(stats,"YOUR ANNOTATIONS",Rect2(22,14,280,24),14,GOLD)
	_label(stats,"%d victories   ·   %d insights" % [profile.data.wins,profile.data.knowledge],Rect2(22,50,280,32),22,IVORY,true)
	_label(stats,"Progress is saved automatically",Rect2(22,89,280,20),13,MUTED)

func _show_authors() -> void:
	screen = "authors"
	_clear()
	_header("Choose your voice", "Every author changes how the argument unfolds. All cards are available from the beginning.", _show_title)
	for i in AUTHORS.size():
		var id: String = AUTHORS[i]
		var color := CardData.author_color(id)
		var card := _panel(ui,Rect2(50+i*272,157,252,514),Color("14221b"),GOLD if selected_author == id else color)
		if art: _picture(card,_author_art(id),Rect2(8,8,236,260))
		_label(card,TAGS[id],Rect2(16,283,220,34),12,color.lightened(0.3))
		_label(card,NAMES[id],Rect2(16,326,224,70),29,IVORY,true)
		_label(card,"%d / 5 seals collected" % profile.progress(id),Rect2(16,408,220,25),15,MUTED)
		_button(card,"Selected" if selected_author == id else "Choose author",Rect2(16,451,220,46),func(): selected_author = id; profile.data.author = id; profile.save_profile(); _show_authors(),selected_author == id)
	_label(ui,"%s  ·  %s" % [NAMES[selected_author],_power_description(selected_author)],Rect2(60,699,1320,60),20,IVORY,true)
	_button(ui,"Campaign   →",Rect2(60,792,300,57),_show_campaign,true)
	_button(ui,"Quick duel",Rect2(380,792,270,57),func(): campaign_mode = false; _start_match(AUTHORS[(AUTHORS.find(selected_author)+1+int(profile.data.matches)%4)%5]))
	_button(ui,"Build your deck",Rect2(670,792,270,57),_show_deck)
	_button(ui,"Rules & tutorial",Rect2(960,792,270,57),_show_tutorial)

func _power_description(author: String) -> String:
	return CardData.AUTHORS[author].power + ": " + CardData.AUTHORS[author].power_text

func _show_campaign() -> void:
	screen = "campaign"
	_clear()
	_header("The midnight road", "Five encounters through the Blackbriar estate. Each victory earns a permanent author seal.",_show_authors)
	var progress: int = profile.progress(selected_author)
	var places := ["The Iron Gate","The Glasshouse","The Portrait Hall","The Hollow Library","The Midnight Table"]
	var stories := ["A raven waits where the road ends.","Something stirs beneath the broken glass.","Every portrait remembers its ambition.","Polite words conceal a sharper edge.","At midnight, the rules begin to smile."]
	for i in 5:
		var card := _panel(ui,Rect2(50+i*272,175,252,472),Color("14231bef"),GOLD if i == progress else Color("46513e"))
		if art: _picture(card,_author_art(AUTHORS[i]),Rect2(8,8,236,200))
		_label(card,"SEAL %s  ·  %s" % [str(i+1),"EARNED" if i < progress else ("NEXT" if i == progress else "LOCKED")],Rect2(16,225,220,26),14,GOLD)
		_label(card,places[i],Rect2(16,270,220,67),27,IVORY,true)
		_label(card,stories[i],Rect2(16,346,220,60),17,MUTED)
		_label(card,NAMES[AUTHORS[i]],Rect2(16,424,220,25),16,IVORY)
	_label(ui,"Your voice: %s     •     %d of 5 seals" % [NAMES[selected_author],progress],Rect2(60,687,1260,36),24,IVORY,true)
	if progress < 5:
		_button(ui,"Enter %s   →" % places[progress],Rect2(60,759,520,65),func(): campaign_mode = true; _start_match(AUTHORS[progress]),true)
	else:
		_label(ui,"The society knows your name. Master another author, or return for a free duel.",Rect2(60,747,1250,35),22,GOLD,true)
		_button(ui,"Return to the authors",Rect2(60,808,360,50),_show_authors,true)
	_button(ui,"Refine your deck",Rect2(610,759,300,65),_show_deck)

func _start_match(rival: String) -> void:
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = Rules.new()
	add_child(game)
	game.action_recorded.connect(_on_action)
	action_queue.clear()
	playback_event.clear()
	game.message_changed.connect(_on_message)
	game.match_finished.connect(_on_finished)
	selected_card = -1
	selected_lane = 0
	recorded = false
	busy = false
	log_lines.clear()
	message = "Select a card, then choose a lane. End the chapter to clash."
	var saved_deck = profile.data.decks.get(selected_author,[])
	var deck: Array = saved_deck if saved_deck is Array and CardData.is_valid_deck(selected_author,saved_deck) else []
	game.start_match(selected_author,rival,deck)
	screen = "match"
	_show_match()
	if not profile.data.tutorial_seen: _show_tutorial()

func _show_match() -> void:
	if not is_instance_valid(game) or game.players.size() < 2: return
	screen = "match"
	_clear()
	var visible_players: Array = playback_event.get("players",game.players)
	var hero: Dictionary = visible_players[0]
	var enemy: Dictionary = visible_players[1]
	_rect(ui,Rect2(0,0,1440,96),Color("0c1711ed"))
	_label(ui,"BLACKBRIAR",Rect2(35,17,290,40),30,IVORY,true)
	_label(ui,"CHAPTER %02d" % int(playback_event.get("turn",game.turn)),Rect2(35,58,220,25),14,GOLD)
	_label(ui,"%s  /  %s" % [NAMES[hero.author],NAMES[enemy.author]],Rect2(320,26,700,35),23,IVORY,true)
	_label(ui,_phase_text(),Rect2(320,61,870,28),15,GOLD)
	if busy:
		_button(ui,"Resume" if replay_paused else "Pause replay",Rect2(861,22,155,40),func(): replay_paused = not replay_paused; _show_match())
		_button(ui,"Skip replay",Rect2(1030,22,165,40),func(): skip_replay = true; replay_paused = false)
	_button(ui,"?",Rect2(1210,24,50,46),_show_tutorial,false,busy)
	_button(ui,"Menu",Rect2(1275,24,125,46),_pause_menu)
	# The three argument lanes sit over a real candlelit 3D table.
	_label(ui,"RIVAL’S CHARACTERS  ·  " + NAMES[enemy.author],Rect2(60,110,710,28),18,CardData.author_color(enemy.author).lightened(0.35))
	_label(ui,"%d REPUTATION" % enemy.reputation,Rect2(839,107,280,36),25,IVORY,true)
	_health_bar(Rect2(60,146,1050,5),enemy.reputation,Color("b87871"))
	for lane in 3:
		var x := 60+lane*358
		_panel(ui,Rect2(x-5,161,344,406),Color("132019"),Color("62705b"))
		_board_slot(Rect2(x,170,334,160),enemy.board[lane],lane,true)
		_label(ui,"LANE %d  ·  ATTACKS STRAIGHT ACROSS" % (lane+1),Rect2(x+8,351,325,28),14,GOLD)
		_board_slot(Rect2(x,398,334,160),hero.board[lane],lane,false)
	_label(ui,"YOUR CHARACTERS  ·  " + NAMES[hero.author],Rect2(60,579,730,30),18,CardData.author_color(hero.author).lightened(0.35))
	_label(ui,"%d REPUTATION" % hero.reputation,Rect2(839,576,280,36),25,IVORY,true)
	_health_bar(Rect2(60,618,1050,5),hero.reputation,Color("a5b88d"))
	_label(ui,"YOUR HAND  /  SELECT A CARD, THEN A LANE",Rect2(60,641,1050,26),13,GOLD)
	var count: int = hero.hand.size()
	var width := minf(160, (1050.0-maxi(0,count-1)*10)/maxi(1,count))
	for index in count:
		_hand_card(hero.hand[index],index,Rect2(60+index*(width+10),679,width,181))
	_build_sidebar(hero,enemy)
	if game.winner != -1 and not busy: _show_result()

func _health_bar(box: Rect2, health: int, color: Color) -> void:
	_rect(ui,box,Color("29362a"))
	_rect(ui,Rect2(box.position,Vector2(box.size.x*clampf(health/16.0,0,1),box.size.y)),color)

func _board_slot(box: Rect2, unit, lane: int, enemy: bool) -> void:
	var chosen: bool = selected_card >= 0 and game.can_play_card(0,selected_card,lane) and enemy == _targets_enemy(game.players[0].hand[selected_card])
	var highlighted: bool = playback_event.get("lane",-1) == lane
	var border := GOLD if chosen or highlighted else (Color("866159") if enemy else Color("759a78"))
	var panel := _panel(ui,box,Color("102018d9"),border)
	if unit == null:
		_label(panel,"—",Rect2(140,20,80,48),40,Color("788169"),true)
		_label(panel,"RIVAL: UNDEFENDED" if enemy else "YOUR EMPTY SLOT",Rect2(38,81,265,28),15,MUTED)
		_label(panel,"Your attack hits rival Reputation" if enemy else "Play a character here to defend",Rect2(38,117,280,24),14,Color("85927d"))
	else:
		if art: _picture(panel,_author_art(unit.author),Rect2(7,7,88,145))
		_label(panel,unit.name,Rect2(110,12,211,48),23,IVORY,true)
		_label(panel,"%d ATK   /   %d HP" % [unit.attack,unit.health],Rect2(110,66,211,28),19,GOLD)
		var ability: String = unit.text
		if unit.get("shield",false): ability = "SHIELDED · First hit is blocked."
		elif unit.effect == "shield": ability = "Shield spent. Next hit deals damage."
		_label(panel,ability,Rect2(110,104,210,48),13,MUTED)
	if chosen: _label(panel,"TARGET",Rect2(8,132,96,22),13,GOLD)
	var hit := _button(panel,"",Rect2(0,0,box.size.x,box.size.y),func(): _lane_clicked(lane,enemy))
	hit.add_theme_stylebox_override("normal",_style(Color("00000000"),Color("00000000"),0))
	hit.add_theme_stylebox_override("hover",_style(Color("c9a86a12"),GOLD,2))
	hit.tooltip_text = "Select this lane" if unit == null else unit.name+"\n"+unit.text+"\n"+unit.lesson

func _hand_card(card: Dictionary, index: int, box: Rect2) -> void:
	var selected := selected_card == index
	var affordable: bool = card.cost <= game.players[0].inspiration
	var panel := _panel(ui,box,Color("1c2c22"),GOLD if selected else CardData.author_color(card.author))
	if art:
		var pic := _picture(panel,_author_art(card.author),Rect2(4,4,box.size.x-8,58))
		pic.modulate = Color(0.8,0.85,0.75) if affordable else Color(0.35,0.4,0.35)
	_rect(panel,Rect2(8,8,30,30),GOLD if affordable else Color("53604c"))
	_label(panel,str(card.cost),Rect2(16,8,28,30),21,BG,true)
	_label(panel,card.name,Rect2(10,68,box.size.x-20,49),18,IVORY if affordable else MUTED,true)
	_label(panel,("%d ATK / %d HP" % [card.attack,card.health]) if card.kind == "Character" else "LITERARY CONCEPT",Rect2(10,120,box.size.x-20,25),12,GOLD)
	_label(panel,"SELECTED" if selected else "Click to inspect",Rect2(10,152,box.size.x-20,21),12,IVORY if selected else MUTED)
	var button := _button(panel,"",Rect2(0,0,box.size.x,box.size.y),func(): selected_card = index if selected_card != index else -1; _show_match(),false,busy)
	button.add_theme_stylebox_override("normal",_style(Color("00000000"),Color("00000000"),0))
	button.add_theme_stylebox_override("hover",_style(Color("c9a86a0b"),IVORY,2))
	button.tooltip_text = "%s\n%s\n%s" % [card.name,card.text,card.lesson]

func _build_sidebar(hero: Dictionary, enemy: Dictionary) -> void:
	var panel := _panel(ui,Rect2(1150,110,250,753),Color("102018f5"),Color("65704e"))
	_label(panel,"INSPIRATION",Rect2(18,15,215,28),14,GOLD)
	_label(panel,"%d / %d" % [hero.inspiration,hero.max_inspiration],Rect2(18,42,215,56),43,IVORY,true)
	_label(panel,"Refills each chapter  ·  cap 6",Rect2(18,104,219,24),13,MUTED)
	_rect(panel,Rect2(18,141,214,1),Color("46523b"))
	if selected_card >= 0 and selected_card < hero.hand.size():
		var card: Dictionary = hero.hand[selected_card]
		_label(panel,card.name,Rect2(18,158,215,58),26,IVORY,true)
		_label(panel,card.text,Rect2(18,222,215,78),17,GOLD)
		_label(panel,card.lesson,Rect2(18,305,215,85),16,MUTED)
		_label(panel,card.get("source",""),Rect2(18,397,215,43),13,MUTED)
		_label(panel,_target_instruction(card),Rect2(18,451,215,38),16,IVORY)
	else:
		_label(panel,"Action by action",Rect2(18,157,215,42),25,IVORY,true)
		_label(panel,message,Rect2(18,213,215,149),17,MUTED)
		_label(panel,"Turn order:\n1. Your characters attack.\n2. Rival plays cards.\n3. Rival characters attack.\n4. Your ink refills.",Rect2(18,370,215,108),15,IVORY)
	var power_button := _button(panel,"Author power  ·  2 ink",Rect2(15,500,220,47),_use_power,false,busy or not game.can_power(0))
	power_button.tooltip_text = _power_description(hero.author)
	_button(panel,"Close reading  +1 ink",Rect2(15,557,220,46),_show_question,false,busy or game.quiz_used)
	_button(panel,"Attack / end turn →",Rect2(15,617,220,58),_end_chapter,true,busy)
	_label(panel,"Deck %d  ·  Discard %d\nRival hand %d  ·  Deck %d" % [hero.deck.size(),hero.discard.size(),enemy.hand.size(),enemy.deck.size()],Rect2(18,696,220,42),13,MUTED)

func _lane_clicked(lane: int, enemy: bool) -> void:
	if busy or game.winner != -1: return
	selected_lane = lane
	if selected_card < 0:
		var unit = game.players[1 if enemy else 0].board[lane]
		if unit != null: _inspect_card(unit)
		return
	if enemy != _targets_enemy(game.players[0].hand[selected_card]):
		message = _target_instruction(game.players[0].hand[selected_card])
		_show_match()
		return
	if game.play_card(0,selected_card,lane):
		_tone("play")
		selected_card = -1
	else:
		message = "That card cannot be played there. Check your ink and choose a valid lane."
	_show_match()

func _use_power() -> void:
	if busy: return
	if game.power(0):
		selected_card = -1
		_tone("play")
	else: message = "Your author power needs 2 ink and a valid target. It can be used once per chapter."
	_show_match()

func _end_chapter() -> void:
	if busy or game.winner != -1: return
	busy = true
	skip_replay = false
	replay_paused = false
	replay_step = 0
	selected_card = -1
	action_queue.clear()
	var active_game = game
	game.end_turn()
	for event in action_queue:
		if game != active_game or screen != "match": break
		replay_step += 1
		playback_event = event
		message = event.text
		_show_match()
		if event.kind == "clash": _tone("clash")
		elif event.kind == "card": _tone("play")
		var elapsed := 0.0
		while elapsed < (1.2 if event.kind == "clash" else 0.95):
			await get_tree().create_timer(0.05).timeout
			if game != active_game or screen != "match" or skip_replay: break
			if not replay_paused: elapsed += 0.05
	if game != active_game: return
	playback_event = {}
	action_queue = []
	busy = false
	if screen == "match":
		message = "Your turn: play cards or use your power, then attack. The battle log keeps every action."
		_show_match()

func _on_action(event: Dictionary) -> void:
	if busy: action_queue.append(event)

func _targets_enemy(card: Dictionary) -> bool:
	var effect: String = card.effect
	if effect == "metaphor": effect = game.players[0].last_spell
	return card.kind != "Character" and effect in ["damage","weaken"]

func _target_instruction(card: Dictionary) -> String:
	if card.cost > game.players[0].inspiration: return "Needs %d ink; you have %d. Choose a cheaper card or end your turn." % [card.cost,game.players[0].inspiration]
	var legal := false
	for lane in 3:
		if game.can_play_card(0,selected_card,lane): legal = true
	if not legal: return "No valid target right now. Choose another card."
	if card.kind == "Character": return "Click a gold EMPTY SLOT on YOUR bottom row."
	if _targets_enemy(card): return "Click a gold target on the RIVAL’S top row."
	return "Click a gold target on YOUR bottom row."

func _phase_text() -> String:
	if playback_event.is_empty(): return "YOUR TURN  ·  Play cards → attack → rival responds"
	var owner := ("%d/%d  ·  " % [replay_step,action_queue.size()]) + ("YOUR" if playback_event.side == 0 else "RIVAL’S")
	match str(playback_event.kind):
		"clash": return owner + " ATTACK  ·  Lane " + str(playback_event.lane+1)
		"card": return owner + " CARD  ·  " + str(playback_event.text).split(".")[0]
		"power": return owner + " AUTHOR POWER"
		_: return owner + " TURN BEGINS"

func _on_message(value: String) -> void:
	message = value
	log_lines.append(value)
	if log_lines.size() > 40: log_lines.pop_front()

func _on_finished(winner: int) -> void:
	if recorded: return
	recorded = true
	if "--visual-smoke" not in OS.get_cmdline_user_args():
		profile.record_match(selected_author,winner == 0,campaign_mode)

func _modal(title: String, width := 760, height := 600) -> Panel:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	var shade := _rect(overlay,Rect2(0,0,1440,900),Color("050b08dd"))
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := _panel(overlay,Rect2((1440-width)/2.0,(900-height)/2.0,width,height),Color("17271fff"),GOLD)
	_label(panel,title,Rect2(34,23,width-68,65),36,IVORY,true)
	_rect(panel,Rect2(34,99,width-68,1),GOLD.darkened(0.5))
	return panel

func _close_modal() -> void:
	if is_instance_valid(overlay):
		ui.remove_child(overlay)
		overlay.queue_free()
	overlay = null

func _show_tutorial() -> void:
	var panel := _modal("The rules of the Colloquium",850,685)
	var rules := [
		["01  ·  Write your opening","Spend Inspiration to play cards. Select a card in your hand, then click a lane. Each lane holds one character per side."],
		["02  ·  Make the argument","Attack / end turn resolves your attacks first. The rival then plays and attacks. Characters fight only across their numbered lane; an empty opposing slot takes Reputation damage."],
		["03  ·  Change the meaning","Concepts bend the rules. Select one and read the margin note, then click its target lane. Use your author's unique power for 2 ink."],
		["04  ·  Have the last word","Reduce your rival's 16 Reputation to zero. Ink refills and grows each chapter. Late chapters become more dangerous, so keep the pressure on."],
		["05  ·  Read between the lines","Once per chapter, an optional Close Reading question rewards a correct answer with 1 ink and a permanent insight. Mistakes teach, without a penalty."]
	]
	for i in rules.size():
		_label(panel,rules[i][0],Rect2(35,122+i*94,780,30),21,GOLD,true)
		_label(panel,rules[i][1],Rect2(35,156+i*94,780,53),17,IVORY)
	_button(panel,"Take my seat   →",Rect2(35,609,370,48),func(): profile.data.tutorial_seen = true; profile.save_profile(); _close_modal(),true)
	_label(panel,"Mouse to play  ·  Esc for menu  ·  F11 fullscreen",Rect2(426,616,380,35),14,MUTED)

func _pause_menu() -> void:
	if busy or game.winner != -1: return
	var panel := _modal("Between chapters",600,425)
	_button(panel,"Resume the duel",Rect2(35,130,530,54),_close_modal,true)
	_button(panel,"Read the battle log",Rect2(35,199,530,54),_show_log)
	_button(panel,"Concede & return to the lodge",Rect2(35,268,530,54),_concede)
	_label(panel,"Completed matches and learning are saved.\nAn unfinished duel is not resumed after quitting.",Rect2(35,343,530,58),16,MUTED)

func _show_log() -> void:
	var panel := _modal("The written record",900,720)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(35,120)
	scroll.size = Vector2(830,510)
	panel.add_child(scroll)
	var text := Label.new()
	text.custom_minimum_size.x = 790
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.text = "\n\n".join(log_lines)
	text.add_theme_color_override("font_color",IVORY)
	scroll.add_child(text)
	_button(panel,"Return to the table",Rect2(35,653,830,46),_close_modal,true)

func _show_result() -> void:
	var won: bool = game.winner == 0
	var panel := _modal("The last word is yours." if won else ("A shared silence." if game.winner == 2 else "The rival has the last word."),800,555)
	_label(panel,"VICTORY" if won else ("DRAW" if game.winner == 2 else "CHAPTER CLOSED"),Rect2(35,126,730,34),18,GOLD)
	_label(panel,"%s • %d chapters" % [NAMES[selected_author],game.turn],Rect2(35,183,730,40),28,IVORY,true)
	_label(panel,"An argument worth remembering. Your seal has been added to the midnight road." if won and campaign_mode else ("Your argument held. Try a different voice, refine your deck, or meet your next rival." if won else "Every revision begins with a question. Try protecting an open lane, or save ink for a decisive concept."),Rect2(35,248,730,88),21,MUTED,true)
	_label(panel,"%d victories recorded   ·   %d literary insights" % [profile.data.wins,profile.data.knowledge],Rect2(35,353,730,35),17,GOLD)
	_button(panel,"Continue the midnight road" if campaign_mode else "Another duel",Rect2(35,419,730,52),_show_campaign if campaign_mode else func(): _start_match(AUTHORS[(AUTHORS.find(game.players[1].author)+1)%5]),true)
	_button(panel,"Return to the lodge",Rect2(35,486,730,44),_show_title)

func _show_settings() -> void:
	var panel := _modal("The room, to your liking",650,405)
	_button(panel,"Sound: " + ("off" if profile.data.muted else "on"),Rect2(35,130,580,52),_toggle_sound)
	_button(panel,"Toggle fullscreen  ·  F11",Rect2(35,198,580,52),_fullscreen)
	_label(panel,"No accounts, purchases, or network connection required.\nProgress stays on this computer.",Rect2(35,267,580,55),17,MUTED)
	_button(panel,"Done",Rect2(35,339,580,44),_close_modal,true)

func _fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11: _fullscreen()
		if event.keycode == KEY_ESCAPE:
			if is_instance_valid(overlay) and (not is_instance_valid(game) or game.winner == -1 or screen != "match"): _close_modal()
			elif screen == "match": _pause_menu()

func _tone(kind := "click") -> void:
	if profile.data.muted: return
	var path := "res://assets/"+kind+".wav"
	if ResourceLoader.exists(path):
		sound.stream = load(path)
		sound.volume_db = -14
		sound.play()

func _show_question() -> void:
	if busy or game.winner != -1 or game.quiz_used: return
	var bank: Array[Dictionary] = LiteraryContent.questions()
	# Rotate the full bank across saved insights and matches; randomize answer positions.
	question_index = (int(profile.data.knowledge)+int(profile.data.matches)*7+game.turn-1) % bank.size()
	var question: Dictionary = bank[question_index]
	var order: Array = [0,1,2]
	order.shuffle()
	var panel := _modal("Close reading",810,590)
	_label(panel,"ONE QUESTION  ·  +1 INSPIRATION FOR AN INSIGHT",Rect2(35,123,740,26),14,GOLD)
	_label(panel,question.question,Rect2(35,169,740,90),28,IVORY,true)
	for i in 3:
		var answer: int = order[i]
		_button(panel,question.choices[answer],Rect2(35,287+i*66,740,54),func(): _answer_question(answer == question.correct,question))
	_button(panel,"Return without answering",Rect2(35,512,740,45),_close_modal)

func _answer_question(correct: bool, question: Dictionary) -> void:
	if not game.answer_question(correct): _close_modal(); return
	if correct:
		profile.data.knowledge += 1
		profile.save_profile()
	_show_match()
	var panel := _modal("A keen observation." if correct else "A useful revision.",770,450)
	_label(panel,"+1 INSPIRATION  ·  INSIGHT RECORDED" if correct else "NO PENALTY  ·  ANOTHER QUESTION NEXT CHAPTER",Rect2(35,123,700,35),15,GOLD)
	_label(panel,question.explanation,Rect2(35,185,700,136),25,IVORY,true)
	_button(panel,"Return to the argument",Rect2(35,361,700,54),_close_modal,true)

func _inspect_card(card: Dictionary) -> void:
	var panel := _modal(card.name,900,590)
	if art: _picture(panel,_author_art(card.author),Rect2(35,125,210,390))
	_label(panel,(NAMES.get(card.author,"The Literary Arts") as String).to_upper(),Rect2(277,125,578,30),15,GOLD)
	_label(panel,"%d INSPIRATION  ·  %s" % [card.cost,card.kind],Rect2(277,178,570,35),19,IVORY)
	_label(panel,card.text,Rect2(277,232,570,93),24,IVORY,true)
	_label(panel,card.lesson,Rect2(277,340,570,117),20,MUTED,true)
	_label(panel,card.source,Rect2(277,465,570,42),15,GOLD)
	_button(panel,"Close the annotation",Rect2(35,530,830,42),_close_modal,true)

func _show_codex() -> void:
	screen = "codex"
	_clear()
	_header("The card catalogue", "37 cards. Five literary voices. Inspect any card to discover the source and the craft behind its effect.",_show_title)
	var filters := ["all","poe","shelley","shakespeare","austen","carroll","neutral"]
	for i in filters.size():
		var filter: String = filters[i]
		_button(ui,filter.capitalize(),Rect2(50+i*193,144,181,43),func(): codex_filter = filter; _show_codex(),filter == codex_filter)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(50,214)
	scroll.size = Vector2(1340,638)
	ui.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",15)
	grid.add_theme_constant_override("v_separation",18)
	scroll.add_child(grid)
	for card in CardData.all_cards():
		if codex_filter != "all" and card.author != codex_filter: continue
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(250,282)
		grid.add_child(holder)
		var tile := _panel(holder,Rect2(0,0,250,282),Color("1a2a20"),CardData.author_color(card.author))
		if art: _picture(tile,_author_art(card.author),Rect2(7,7,236,102))
		_label(tile,card.name,Rect2(16,124,222,56),25,IVORY,true)
		_label(tile,"%d INK  ·  %s" % [card.cost,card.kind.to_upper()],Rect2(16,188,220,25),13,GOLD)
		_button(tile,"Read annotation",Rect2(15,230,220,38),func(): _inspect_card(card))

func _starter_ids() -> Array:
	var result: Array = []
	for card in CardData.deck_for(selected_author): result.append(card.id)
	return result

func _show_deck() -> void:
	var saved = profile.data.decks.get(selected_author,[])
	deck_draft = saved.duplicate() if saved is Array and CardData.is_valid_deck(selected_author,saved) else _starter_ids()
	_render_deck()

func _render_deck() -> void:
	screen = "deck"
	_clear()
	_header("The writing desk", "Build an 18-card deck from your author's characters and neutral concepts. Up to two copies of each card.",_show_authors)
	var panel := _panel(ui,Rect2(1050,155,340,685),Color("15251df5"),GOLD)
	_label(panel,NAMES[selected_author],Rect2(25,24,290,70),31,IVORY,true)
	_label(panel,"%d / 18 cards" % deck_draft.size(),Rect2(25,112,290,45),30,GOLD,true)
	var units := 0
	var total_cost := 0
	for id in deck_draft:
		var card: Dictionary = CardData.get_card(id)
		if card.kind == "Character": units += 1
		total_cost += card.cost
	_label(panel,"%d characters\n%d concepts\n%.1f average inspiration" % [units,deck_draft.size()-units,float(total_cost)/maxi(1,deck_draft.size())],Rect2(25,184,290,110),20,IVORY)
	_label(panel,"A strong opening matters. Include inexpensive characters, a few ways to draw, and concepts that support your author's power.",Rect2(25,323,290,153),21,MUTED,true)
	_button(panel,"Save this deck",Rect2(25,511,290,53),func(): profile.data.decks[selected_author] = deck_draft.duplicate(); profile.save_profile(); _show_authors(),true,not CardData.is_valid_deck(selected_author,deck_draft))
	_button(panel,"Restore starter deck",Rect2(25,580,290,48),func(): deck_draft = _starter_ids(); _render_deck())
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(50,155)
	scroll.size = Vector2(970,685)
	ui.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",9)
	scroll.add_child(rows)
	for card in CardData.all_cards():
		if card.author not in [selected_author,"neutral"]: continue
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(942,95)
		rows.add_child(holder)
		var row := _panel(holder,Rect2(0,0,942,95),Color("192a20"),Color("42533d"))
		_label(row,str(card.cost),Rect2(18,20,48,40),28,GOLD,true)
		_label(row,card.name,Rect2(68,12,295,35),23,IVORY,true)
		_label(row,card.text,Rect2(68,50,636,38),15,MUTED)
		_button(row,"?",Rect2(691,22,42,45),func(): _inspect_card(card))
		var count: int = deck_draft.count(card.id)
		_button(row,"−",Rect2(748,22,47,45),func(): deck_draft.erase(card.id); _render_deck(),false,count == 0)
		_label(row,str(count),Rect2(813,26,40,35),23,GOLD,true)
		_button(row,"+",Rect2(862,22,47,45),func(): deck_draft.append(card.id); _render_deck(),false,count >= 2 or deck_draft.size() >= 18)

func _concede() -> void:
	if not recorded:
		profile.record_match(selected_author,false,false)
		recorded = true
	_show_title()

func _visual_smoke() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/title.png")
	profile.data.tutorial_seen = true
	_start_match("shelley")
	for index in game.players[0].hand.size():
		if game.players[0].hand[index].kind == "Character" and game.play_card(0,index,0): break
	_show_match()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/battle.png")
	_show_authors()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/authors.png")
	for mode in ["campaign", "deck", "codex", "tutorial", "question", "result"]:
		match mode:
			"campaign": _show_campaign()
			"deck": _show_deck()
			"codex": _show_codex()
			"tutorial": _show_tutorial()
			"question": _start_match("austen"); _show_question()
			"result": game.players[1].reputation = 0; game._check_winner(); _show_match()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/"+mode+".png")
	print("VISUAL_SMOKE_COMPLETE")
	_quit_game()

func _toggle_sound() -> void:
	profile.data.muted = not profile.data.muted
	profile.save_profile()
	ambient.stream_paused = profile.data.muted
	if not profile.data.muted and not ambient.playing: ambient.play()
	_show_settings()

func _exit_tree() -> void:
	if is_instance_valid(ambient):
		ambient.stop()
		ambient.stream = null
	if is_instance_valid(sound):
		sound.stop()
		sound.stream = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit_game()

func _quit_game() -> void:
	_exit_tree()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

func _animate_clash() -> void:
	for lane in 3:
		var unit = game.players[0].board[lane]
		if unit == null: continue
		var stroke := Line2D.new()
		stroke.z_index = 20
		stroke.width = 3
		stroke.default_color = GOLD
		var x := 227.0+lane*358
		stroke.points = PackedVector2Array([Vector2(x,397),Vector2(x,397)])
		ui.add_child(stroke)
		var tween := create_tween()
		tween.tween_method(func(progress: float):
			if is_instance_valid(stroke): stroke.set_point_position(1,Vector2(x,lerpf(397,247,progress))),0.0,1.0,0.22)
		tween.tween_property(stroke,"modulate:a",0.0,0.1)
		tween.tween_callback(stroke.queue_free)

func _float_feedback(text: String, point: Vector2, color: Color) -> void:
	var note := _label(ui,text,Rect2(point,Vector2(100,50)),32,color,true)
	note.z_index = 30
	var tween := create_tween().set_parallel(true)
	tween.tween_property(note,"position:y",point.y-32,0.65)
	tween.tween_property(note,"modulate:a",0.0,0.65)
	tween.chain().tween_callback(note.queue_free)
