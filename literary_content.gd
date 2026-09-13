class_name LiteraryContent
extends RefCounted

static func _q(prompt: String, choices: Array, correct: int, explanation: String, author: String = "neutral") -> Dictionary:
	return {"question":prompt,"prompt":prompt,"choices":choices,"options":choices,"correct":correct,"answer":correct,"explanation":explanation,"author":author}

static func questions() -> Array[Dictionary]:
	return [
		_q("What does foreshadowing do?",["Prepares readers for a later event","Summarizes every earlier event","Explains a word's origin"],0,"An early clue can prepare a later development without revealing it outright."),
		_q("Which phrase is a metaphor?",["The room was cold","Her voice was a lantern","He ran like a fox"],1,"Calling a voice a lantern suggests guidance or warmth through a direct figurative comparison."),
		_q("Which detail is auditory imagery?",["A violet sky","The rough bark","A bell shivered through the fog"],2,"Auditory imagery evokes sound. Imagery can appeal to any sense."),
		_q("Dramatic irony occurs when…",["The audience knows more than a character","A poem has no rhyme","A character speaks loudly"],0,"Unequal knowledge can create suspense or comedy as the audience anticipates consequences."),
		_q("Which phrase uses alliteration?",["The pale moon","Briar branches bend","A candle in a window"],1,"The repeated initial /b/ sound connects the nearby words."),
		_q("What makes a narrator unreliable?",["Speaking in the first person","Being the main character","Giving reasons to doubt the account"],2,"Contradictions, bias, or limited understanding may lead readers to question a narrator."),
		_q("A symbol's meaning is best supported by…",["Its context and repeated uses","A universal dictionary of symbols","Its number of letters"],0,"Symbols acquire meaning through how a particular work uses them."),
		_q("Which action is close reading?",["Counting a book's pages","Examining how repeated words shape meaning","Guessing the ending from the cover"],1,"Close reading builds interpretations from specific textual details."),
		_q("Which conflict is internal?",["A sailor faces a storm","Two rivals compete","A character struggles with guilt"],2,"An internal conflict occurs within a character's thoughts, desires, or feelings."),
		_q("What is revision?",["Rethinking a draft's meaning and structure","Only fixing punctuation","Copying a final draft unchanged"],0,"Revision may change ideas, organization, evidence, and wording, as well as surface details."),
		_q("A narrative climax typically involves…",["A list of characters","Heightened tension or decisive action","The publisher's address"],1,"A climax concentrates a story's tension in a crucial moment or development."),
		_q("Catharsis is associated with…",["An alphabetical glossary","A change of narrator","Emotional release or clarification"],2,"In discussions of tragedy, catharsis concerns the audience's emotional experience."),
		_q("Which device repeats 'Nevermore' in The Raven?",["A refrain","A stage direction","A footnote"],0,"The recurring refrain takes on different implications as the speaker asks new questions.","poe"),
		_q("Why question the Tell-Tale Heart narrator?",["The story has no title","Claims of sanity clash with obsessive actions","The narrator is a detective"],1,"The contrast between the narrator's claims and described behavior supports an unreliable reading.","poe"),
		_q("Dupin is especially associated with…",["Pastoral farming","Courtly romance","Analytical detective work"],2,"Poe's Dupin stories helped establish conventions of detective fiction.","poe"),
		_q("The house in The Fall of the House of Usher parallels…",["The declining Usher family","A prosperous school","A political election"],0,"Physical decay links the setting to the family's deterioration.","poe"),
		_q("Who creates the Creature in Frankenstein?",["Robert Walton","Victor Frankenstein","Henry Clerval"],1,"Frankenstein is Victor's surname; the Creature is not given a personal name in the novel.","shelley"),
		_q("What frames much of Frankenstein's narrative?",["Newspaper advertisements","A courtroom verdict","Walton's letters"],2,"Walton's letters enclose Victor's narrative, which also includes the Creature's account.","shelley"),
		_q("A central question of Frankenstein concerns…",["Responsibility toward one's creation","How to win a royal election","The rules of cricket"],0,"Victor's abandonment of the Creature connects scientific ambition to ethical responsibility.","shelley"),
		_q("Henry Clerval often contrasts with Victor through…",["His ambition to become king","His interest in language and human connection","His rejection of all friendship"],1,"Clerval's interests and care offer an alternative to Victor's isolating obsession.","shelley"),
		_q("What can a soliloquy reveal?",["A book's print run","An editor's address","A character's private thinking"],2,"Soliloquies let audiences hear thoughts that other characters may not know.","shakespeare"),
		_q("Who causes confusion in A Midsummer Night's Dream?",["Puck","Darcy","Dupin"],0,"Puck's magical mistakes entangle the lovers and help drive the comedy.","shakespeare"),
		_q("Lady Macbeth's later speech especially reveals…",["A new interest in sailing","The effects of guilt","Perfect contentment"],1,"Her fragmented sleepwalking speech revisits images connected to the murders.","shakespeare"),
		_q("Prospero's control of events resembles…",["An accountant balancing figures","A farmer harvesting grain","A dramatist arranging a performance"],2,"The Tempest invites connections between Prospero's staging and theatrical creation.","shakespeare"),
		_q("Elizabeth Bennet learns to reconsider…",["Her first judgments of others","The spelling of her surname","Her ability to read"],0,"New evidence changes Elizabeth's understanding of Darcy and Wickham.","austen"),
		_q("Emma's matchmaking often shows…",["That she knows everyone's feelings perfectly","A gap between confidence and understanding","That the story has no conflict"],1,"Emma misreads others, making her growth depend partly on recognizing her own errors.","austen"),
		_q("Anne Elliot is the heroine of…",["The Tempest","Frankenstein","Persuasion"],2,"Persuasion follows Anne and Wentworth as they encounter a chance to renew their relationship.","austen"),
		_q("Elinor Dashwood's restraint suggests…",["Deep feeling may exist beneath a calm manner","She has no emotions","She never faces difficulty"],0,"Sense and Sensibility explores different ways of expressing and managing feeling.","austen"),
		_q("Who draws Alice toward Wonderland?",["The Raven","The White Rabbit","Prospero"],1,"Alice follows the White Rabbit and falls down the rabbit hole.","carroll"),
		_q("Treating Time as a person at the tea party is…",["A bibliography","A historical date","Personification"],2,"Personification gives human qualities to something nonhuman or abstract.","carroll"),
		_q("The Queen of Hearts' repeated threats satirize…",["Arbitrary authority","Patient scientific inquiry","Quiet friendship"],0,"Her extreme commands turn the exercise of power into absurdity.","carroll"),
		_q("The Cheshire Cat's vanishing grin challenges…",["The order of the alphabet","Ordinary physical logic","The existence of gardens"],1,"The grin without a cat makes a familiar expression into a literal impossibility.","carroll")
	]

static func all_questions() -> Array[Dictionary]:
	return questions()

static func author_description(author: String) -> String:
	return str(CardData.AUTHORS.get(author.to_lower(), {}).get("description", "Literature rewards curiosity and careful attention."))
