class_name PlayerProfile
extends RefCounted

const PATH := "user://blackbriar_profile.json"
var data := {"version": 1, "author": "poe", "wins": 0, "matches": 0, "knowledge": 0, "campaign": {}, "decks": {}, "tutorial_seen": false, "muted": false}

func load_profile() -> void:
	if not FileAccess.file_exists(PATH): return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary: return
	if parsed.get("author") is String and CardData.AUTHORS.has(parsed.author): data.author = parsed.author
	for key in ["wins", "matches", "knowledge"]:
		var value = parsed.get(key, 0)
		if value is int or value is float: data[key] = clampi(int(value), 0, 1000000000)
	for key in ["tutorial_seen", "muted"]:
		if parsed.get(key) is bool: data[key] = parsed[key]
	data.campaign = {}
	if parsed.get("campaign") is Dictionary:
		for author in CardData.AUTHORS:
			var value = parsed.campaign.get(author, 0)
			if value is int or value is float: data.campaign[author] = clampi(int(value), 0, 5)
	data.decks = {}
	if parsed.get("decks") is Dictionary:
		for author in CardData.AUTHORS:
			var deck = parsed.decks.get(author)
			if _valid_deck(author, deck): data.decks[author] = deck.duplicate()

func _valid_deck(author: String, deck: Variant) -> bool:
	if not deck is Array or deck.size() != 18: return false
	var counts := {}
	for id in deck:
		if not id is String: return false
		var card := CardData.get_card(id)
		if card.is_empty() or (card.author != author and card.author != "neutral"): return false
		counts[id] = counts.get(id, 0) + 1
		if counts[id] > 2: return false
	return true

func save_profile() -> void:
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	DirAccess.rename_absolute(PATH + ".tmp", PATH)

func progress(author: String) -> int:
	return clampi(int(data.campaign.get(author, 0)), 0, 5)

func record_match(author: String, won: bool, campaign: bool) -> void:
	data.matches += 1
	if won:
		data.wins += 1
		if campaign: data.campaign[author] = mini(5, progress(author) + 1)
	save_profile()
