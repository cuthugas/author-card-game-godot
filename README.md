# Blackbriar: The Midnight Colloquium

A complete local single-player literary card battler for Godot. Five public-domain authors duel on a candlelit 3 D table in a gothic Appalachian literary society.

## Play

Run `./builds/blackbriar-linux/play.sh`, or open `project.godot` in Godot and press F 5. The packaged runtime targets this Linux x 86_64 computer; compatible system libraries are required. See BUILD.md for rebuilding and platform details.

Choose Poe, Shelley, Shakespeare, Austen, or Carroll. Enter a quick duel or earn five campaign seals with each author. Build an 18-card deck from 37 cards. Each card includes a source reference and a literary annotation. All cards are available immediately; campaign seals reward mastery.

Select a card, then a lane. Spend Inspiration on characters, literary concepts, or your author power. End chapter resolves clashes and the AI reply. Reduce the rival's 16 Reputation to zero. Ink grows from 2 to 6; exhaustion creates increasing fatigue. Matches typically last five chapters in automated play. Optional Close Reading questions reward correct answers with 1 ink and a saved insight; wrong answers have no penalty.

Mouse controls all actions. Esc opens/closes the pause menu; F 11 toggles fullscreen. Sound can be muted. Progress saves locally; unfinished duels do not resume after quitting. Online multiplayer and cross-platform classroom deployment are future work, as agreed for this single-player first version.

## Verification

- 7,306 rules checks across 200 seeded matches: zero failures,3–10 chapters, median 5.
- 60 scene lifecycle checks: zero failures.
- Full mouse-event duel:35 clicks,6 chapters, zero failures.
- 12 profile/campaign validation checks: zero failures.
- Rendered review of title, authors, battle, campaign, deck editor, catalogue, tutorial, quiz and result screens.
- Normal GUI shutdown exits cleanly after audio cleanup.

Commands and methodology are in tests/PLAYTEST.md. Automated play does not establish classroom learning outcomes or substitute for human usability feedback.

Art and sound were created for this project; font and runtime licenses accompany the assets/package. See assets/LICENSES.md.
