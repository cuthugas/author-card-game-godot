# Blackbriar playtest checklist

## Automated rules regression

Run `godot --headless --path . --script res://test_runner.gd` from the project folder. The suite exits nonzero on failed assertions and prints match pacing statistics. It uses fixed seeds so a failure can be reproduced.

Coverage: all author pairings, repeated deterministic matches, invalid input without mutation, resource bounds, fixed board size, AI progress, passing without softlock, exactly one match result, and immutable terminal state.

## Automated scene lifecycle

Run `XDG_DATA_HOME=/tmp/blackbriar-ui-qa godot --headless --path . --script res://tests/ui_runner.gd`. This isolates test saves from your player profile. It visits every screen, starts each author, resolves chapters, checks results and one-time rewards, restarts scenes, and verifies save/reload.

## Interactive acceptance

- Start the game from `project.godot`; title, author chooser, and primary action fit at 1280×720.
- Select each author and verify matching passive, card collection, and deck.
- Start a new match and read the tutorial before taking the first action.
- Select an affordable character, place it into each legal lane, and verify cost/hand/board updates once.
- Try an occupied lane and an unaffordable card; verify clear feedback and no lost card or ink.
- Play a targeted concept, inspect its lesson, and verify its described effect.
- End a chapter; verify lane attacks are understandable and the player regains control.
- Use the author power once, then attempt a second use that chapter.
- Finish a win and a loss; verify reward/progression applies only once.
- Leave the result screen and start another match; verify no old overlays, cards, signals, or effects remain.
- Save, close, and reopen; verify deck choices and campaign progress persist.
- Open the collection and return without starting a match.
- Toggle audio and verify the preference persists.
- Resize the window; verify all essential controls remain reachable.

A passed automated suite validates rules execution; interactive checks additionally validate visual clarity, input, sound, and scene lifecycle.

## Mouse-event end-to-end regression

`XDG_DATA_HOME=/tmp/blackbriar-input-qa godot --headless --path . --script tests/input_runner.gd`

Routes InputEventMouseButton/Motion through the viewport, selecting title/duel buttons, hand cards, lane targets, End chapter and result navigation. Uses engine legality only to select moves; does not invoke game actions or button signals directly. September13 result:35 clicks,6 chapters,0 failures. Complements rendered visual smoke and handler-level lifecycle tests; it is not an independent human usability study.
