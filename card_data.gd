class_name CardData
extends RefCounted

const AUTHORS := {
	"poe": {"name":"Edgar Allan Poe", "title":"The House of Nevermore", "description":"Turn grief into pressure. Death draws fresh pages; the Raven drinks from a fading reputation.", "power":"Nevermore", "power_text":"Deal 2 damage to the opposing author.", "color":"9675bc"},
	"shelley": {"name":"Mary Shelley", "title":"The Galvanic Archive", "description":"Build enduring creations. Wounded characters grow furious, while careful restoration keeps them alive.", "power":"Galvanize", "power_text":"Your strongest character gains +1 attack and +2 health. If none, heal 3 reputation.", "color":"78a992"},
	"shakespeare": {"name":"William Shakespeare", "title":"The Thorned Stage", "description":"Fill the stage, then raise every voice. Tragedy rewards daring attacks and an ensemble cast.", "power":"Raise the Curtain", "power_text":"All your characters gain +1 attack.", "color":"bc746b"},
	"austen": {"name":"Jane Austen", "title":"The Velvet Drawing Room", "description":"Win through observation and endurance. Restore reputation, gather options, and outlast a reckless rival.", "power":"Social Insight", "power_text":"Heal 3 reputation and draw 1 card.", "color":"c3a66e"},
	"carroll": {"name":"Lewis Carroll", "title":"The Crooked Looking Glass", "description":"Follow curiosity into unexpected combinations. Extra cards and inspiration make each turn a new puzzle.", "power":"Down the Rabbit Hole", "power_text":"Draw 2 cards.", "color":"75acbe"}
}

static func _card(id: String, title: String, author: String, cost: int, attack: int, health: int, effect: String, rules: String, lesson: String, source: String) -> Dictionary:
	var is_unit := author != "neutral"
	return {"id":id,"name":title,"author":author,"author_id":author,"cost":cost,"attack":attack,"health":health,"effect":effect,"value":1,"type":"unit" if is_unit else "spell","kind":"Character" if is_unit else "Concept","text":rules,"description":rules,"lesson":lesson,"source":source}

static func all_cards() -> Array[Dictionary]:
	return [
		_card("poe_raven","The Raven","poe",3,3,3,"drain","Direct strikes restore 1 reputation.","The repeated word 'Nevermore' changes meaning as the speaker's questions become more desperate.","The Raven (1845)"),
		_card("poe_usher","Roderick Usher","poe",2,2,2,"death_draw","On defeat: draw 1 card.","The decaying house parallels the decline of the Usher family, linking setting and character.","The Fall of the House of Usher (1839)"),
		_card("poe_montresor","Montresor","poe",3,4,2,"shield","Prevent the first damage this character takes.","Montresor's courteous language conceals revenge; his account invites doubts about his judgment.","The Cask of Amontillado (1846)"),
		_card("poe_dupin","C. Auguste Dupin","poe",2,1,3,"draw","On arrival: draw 1 card.","Dupin solves mysteries through analysis, helping establish the literary detective tradition.","The Murders in the Rue Morgue (1841)"),
		_card("poe_narrator","The Tell-Tale Narrator","poe",1,2,1,"rage","After surviving damage: gain +1 attack.","The narrator insists on sanity while describing obsessive behavior: an example of unreliable narration.","The Tell-Tale Heart (1843)"),
		_card("shelley_creature","The Creature","shelley",4,4,5,"rage","After surviving damage: gain +1 attack.","The Creature's account asks readers to examine how rejection and neglect shape a person.","Frankenstein (1818)"),
		_card("shelley_victor","Victor Frankenstein","shelley",2,2,3,"inspire","On arrival: gain 1 inspiration.","Victor's pursuit of knowledge becomes dangerous when he abandons responsibility for his creation.","Frankenstein (1818)"),
		_card("shelley_walton","Robert Walton","shelley",2,1,4,"draw","On arrival: draw 1 card.","Walton's letters frame Victor's story and offer another perspective on ambition.","Frankenstein (1818)"),
		_card("shelley_elizabeth","Elizabeth Lavenza","shelley",2,2,3,"heal","On arrival: restore 2 reputation.","Elizabeth's letters contrast domestic affection with Victor's isolating ambition.","Frankenstein (1818)"),
		_card("shelley_clerval","Henry Clerval","shelley",1,1,3,"shield","Prevent the first damage this character takes.","Clerval's love of languages and human relationships contrasts with Victor's consuming scientific ambition.","Frankenstein (1818)"),
		_card("shakespeare_hamlet","Hamlet","shakespeare",3,3,3,"death_draw","On defeat: draw 1 card.","Hamlet's soliloquies reveal competing impulses that public dialogue can conceal.","Hamlet (c. 1600–1601)"),
		_card("shakespeare_macbeth","Lady Macbeth","shakespeare",2,3,2,"inspire","On arrival: gain 1 inspiration.","Lady Macbeth's early commands contrast with her later fragmented speech, revealing the effects of guilt.","Macbeth (c. 1606)"),
		_card("shakespeare_puck","Puck","shakespeare",1,2,1,"draw","On arrival: draw 1 card.","Puck's mistakes create comic confusion and connect the play's human and fairy worlds.","A Midsummer Night's Dream (c. 1595–1596)"),
		_card("shakespeare_portia","Portia","shakespeare",3,2,5,"shield","Prevent the first damage this character takes.","Portia's courtroom disguise explores the relationship between authority, performance, and persuasion.","The Merchant of Venice (c. 1596–1597)"),
		_card("shakespeare_prospero","Prospero","shakespeare",4,4,4,"heal","On arrival: restore 2 reputation.","Prospero directs events like a dramatist, then chooses to give up his magic.","The Tempest (c. 1610–1611)"),
		_card("austen_elizabeth","Elizabeth Bennet","austen",2,2,3,"draw","On arrival: draw 1 card.","Elizabeth's changing judgment shows why first impressions need revision.","Pride and Prejudice (1813)"),
		_card("austen_darcy","Fitzwilliam Darcy","austen",4,3,6,"shield","Prevent the first damage this character takes.","Darcy's actions complicate the judgments formed from his reserved social manner.","Pride and Prejudice (1813)"),
		_card("austen_emma","Emma Woodhouse","austen",2,3,2,"inspire","On arrival: gain 1 inspiration.","Emma's confident matchmaking exposes the gap between her interpretations and other people's feelings.","Emma (1815)"),
		_card("austen_anne","Anne Elliot","austen",2,1,4,"heal","On arrival: restore 2 reputation.","Anne's renewed relationship with Wentworth explores persuasion, constancy, and second chances.","Persuasion (1817)"),
		_card("austen_elinor","Elinor Dashwood","austen",1,1,3,"heal","On arrival: restore 2 reputation.","Elinor's restraint does not mean she lacks deep feeling; the novel tests outward appearances.","Sense and Sensibility (1811)"),
		_card("carroll_alice","Alice","carroll",2,2,3,"draw","On arrival: draw 1 card.","Alice questions strange rules, exposing the instability of language and authority in Wonderland.","Alice's Adventures in Wonderland (1865)"),
		_card("carroll_cat","Cheshire Cat","carroll",3,3,3,"shield","Prevent the first damage this character takes.","The Cat's disappearing body turns a familiar grin into a playful challenge to ordinary logic.","Alice's Adventures in Wonderland (1865)"),
		_card("carroll_rabbit","White Rabbit","carroll",1,1,2,"inspire","On arrival: gain 1 inspiration.","The Rabbit's anxiety about time draws Alice from the familiar world into the unexpected.","Alice's Adventures in Wonderland (1865)"),
		_card("carroll_hatter","The Hatter","carroll",2,2,2,"draw","On arrival: draw 1 card.","The tea party treats Time as a person, turning a figure of speech into a comic situation.","Alice's Adventures in Wonderland (1865)"),
		_card("carroll_queen","Queen of Hearts","carroll",4,5,3,"rage","After surviving damage: gain +1 attack.","The Queen's repeated threats satirize arbitrary power and the misuse of authority.","Alice's Adventures in Wonderland (1865)"),
		_card("foreshadowing","Foreshadowing","neutral",1,0,0,"foreshadow","Draw 1. Gain 2 extra inspiration next turn.","Foreshadowing plants a detail that prepares readers for a later event.","Literary craft • anticipation"),
		_card("imagery","Imagery","neutral",1,0,0,"buff","An allied character gains +2 attack and +1 health.","Imagery evokes sensory experience, including sound, smell, touch, taste, and sight.","Literary craft • sensory language"),
		_card("metaphor","Metaphor","neutral",2,0,0,"metaphor","Repeat your last Concept, using this lane as its target.","A metaphor describes one thing as another to suggest a meaningful resemblance.","Literary craft • figurative language"),
		_card("revision","Revision","neutral",1,0,0,"heal","Restore 3 reputation and heal your character in this lane for 2.","Revision rethinks meaning, structure, and expression; it is more than correcting spelling.","Writing craft • rethinking a draft"),
		_card("close_reading","Close Reading","neutral",2,0,0,"draw","Draw 2 cards.","Close reading supports an interpretation through careful attention to particular words and patterns.","Reading practice • textual evidence"),
		_card("dramatic_irony","Dramatic Irony","neutral",2,0,0,"weaken","An enemy character loses 2 attack and takes 1 damage.","Dramatic irony occurs when the audience knows something a character does not.","Literary craft • unequal knowledge"),
		_card("alliteration","Alliteration","neutral",1,0,0,"buff","An allied character gains +2 attack and +1 health.","Alliteration repeats initial consonant sounds in nearby words, emphasizing sound rather than spelling.","Literary craft • patterned sound"),
		_card("conflict","Conflict","neutral",2,0,0,"damage","Deal 3 damage to the opposing character in this lane, or its author if empty.","Conflict places opposing desires or forces in tension and can occur within a character.","Literary craft • opposing forces"),
		_card("unreliable_narrator","Unreliable Narrator","neutral",2,0,0,"weaken","An enemy character loses 2 attack and takes 1 damage.","An unreliable narrator gives readers reasons to question the account being told.","Literary craft • narrative perspective"),
		_card("catharsis","Catharsis","neutral",2,0,0,"heal","Restore 3 reputation and heal your character in this lane for 2.","Catharsis describes an emotional release or clarification associated with experiencing tragedy.","Literary criticism • tragedy"),
		_card("symbolism","Symbolism","neutral",2,0,0,"draw","Draw 2 cards.","A symbol carries meaning beyond its literal role; its significance depends on context.","Literary craft • layered meaning"),
		_card("climax","Climax","neutral",2,0,0,"damage","Deal 3 damage to the opposing character in this lane, or its author if empty.","A climax is a point of heightened tension or decisive action in a narrative.","Literary craft • narrative structure")
	]

static func get_card(id: String) -> Dictionary:
	for card in all_cards():
		if card.id == id:
			return card.duplicate(true)
	return {}

static func deck_for(author: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card in all_cards():
		if card.author == author.to_lower():
			result.append(card.duplicate(true))
			result.append(card.duplicate(true))
	for id in ["foreshadowing","imagery","metaphor","revision","close_reading","dramatic_irony","conflict","climax"]:
		result.append(get_card(id))
	return result

static func author_color(author: String) -> Color:
	return Color(AUTHORS.get(author.to_lower(), {"color":"9b9b8f"}).color)
