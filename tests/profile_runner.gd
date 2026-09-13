extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(label)
func _init() -> void:
	var profile := PlayerProfile.new()
	var fixture := {"author":"invalid", "wins":"bad", "matches":-4, "knowledge":5, "campaign":{"poe":99,"shelley":"bad"},"decks":{"poe":["invalid"]},"muted":"bad"}
	var file := FileAccess.open(PlayerProfile.PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture))
	file.close()
	profile.load_profile()
	check(profile.data.author == "poe", "invalid author rejected")
	check(profile.data.wins == 0 and profile.data.matches == 0, "invalid counters sanitized")
	check(profile.data.knowledge == 5,"valid insight retained")
	check(profile.progress("poe") == 5 and profile.progress("shelley") == 0,"campaign validation")
	check(profile.data.decks.is_empty(),"invalid deck rejected")
	check(profile.data.muted == false,"invalid setting rejected")
	profile.data.campaign.clear()
	profile.record_match("poe",false,true)
	check(profile.progress("poe") == 0,"loss does not unlock")
	for i in 7: profile.record_match("poe",true,true)
	check(profile.progress("poe") == 5,"campaign caps at five seals")
	profile.record_match("shelley",true,false)
	check(profile.progress("shelley") == 0,"quick duel does not unlock campaign")
	var deck: Array = []
	for card in CardData.deck_for("poe"): deck.append(card.id)
	profile.data.decks.poe = deck
	profile.save_profile()
	var reloaded := PlayerProfile.new()
	reloaded.load_profile()
	check(reloaded.data.decks.poe == deck,"custom deck survives reload")
	check(reloaded.progress("poe") == 5,"campaign survives reload")
	check(reloaded.data.matches == 9 and reloaded.data.wins == 8,"match counters survive reload")
	print("BLACKBRIAR_PROFILE checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
