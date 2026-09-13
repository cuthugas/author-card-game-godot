# Blackbriar single-player release audit

September 13, 2026. Scope follows the user's agreement to begin with AI single-player; online classroom multiplayer is a future phase.

| Requirement | Current evidence |
|---|---|
| Godot 2 D/3 D literary game | project.godot/main.tscn, real Node 3 D candlelit stage in atmosphere.gd; illustrated card interface in main.gd; graphical smoke rendered successfully |
| Original Author Card Game inspiration | Original /home/cuthugas/code/author-card-game and archived context reviewed; author factions, Inspiration, Reputation, literary concepts and quiz-only knowledge retained and redesigned with creative freedom |
| Multiple public-domain authors | card_data.gd defines Poe, Shelley, Shakespeare, Austen and Carroll, five units each, unique author powers |
| Neutral literary cards and learning |12 neutral concepts including imagery, metaphor, foreshadowing;37 cards with lessons/source references;32 questions in literary_content.gd; correct answers reward ink/insights |
| Swift tactical mechanics and AI | Three lanes, persistent damage, simultaneous retaliation, author powers, concepts, fatigue;200 seeded matches finish 3–10 chapters, median 5;7306 rules assertions pass |
| Complete single-player loop | Title, selection, campaign, quick duel, deck editor, catalogue, tutorial, quiz, pause/log, result and repeat navigation implemented;60 UI lifecycle checks pass |
| Progression and persistence | Five seals per author, saved wins/insights and 18-card custom decks;12 profile checks pass including malformed saves, loss/quick-duel progression, seal cap, reload |
| Dark gothic Appalachian presentation | Original library/mountain and faction illustrations, candlelit walnut table, antique palette and fonts, original ambience/effects; all nine screen captures visually inspected without overlap/clipping |
| Responsive combat feedback | Legal targets highlighted, shield state shown, exact power tooltip, clash lines, Reputation deltas; full mouse-event regression passes after these changes |
| Playtesting and error checks | Rules 7306/0, UI 60/0, profile 12/0; source mouse test and independent packaged mouse test pass; packaged test 28 clicks/five chapters/zero failures, clean exit |
| Deliverable | builds/blackbriar-linux/play.sh + godot-runtime + blackbriar.pck; final package tested from /tmp independently of source using bundled runtime. README.md/BUILD.md and licenses included |
| Independent monitoring | Rules/content/QA agents implemented and independently reviewed engine/content/UI before account usage limit; findings fixed, tests retained |

## Practical limits

This is the agreed local single-player release. No online multiplayer, classroom accounts, Windows/macOS export, licensed modern authors, or paid content. The bundled Arch Linux runtime requires compatible system libraries. Faction artwork is shared by cards of the same author. Automated checks establish reproducible correctness and short-match pacing, not subjective enjoyment or classroom learning outcomes. Future classroom feedback can inform balance and teaching design.

Normal menu/window shutdown releases audio cleanly. Forcing Godot to terminate with --quit-after can emit its AudioStreamWAV cleanup warning; this does not occur in the completed packaged-input test or normal graceful quit. Use normal Quit/window-close during play.
