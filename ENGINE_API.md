# Blackbriar engine API

`GameState` extends Node. Add it to tree; call `start_match(hero,rival,custom_deck=[],seed_value=0)`. Author IDs are lowercase `poe`, `shelley`, `shakespeare`, `austen`, `carroll`. Seed zero randomizes; other seeds reproduce draws and AI decisions. Custom decks accept card dictionaries or IDs. Default decks have 18 cards.

Signals: `state_changed()`, `message_changed(message:String)`, `match_finished(winner:int)` (once per match).

State: `players[0]` human, `[1]` rival; each dictionary has `author`, `reputation` (starts 16), `inspiration` (ink), `max_inspiration` (starts 2, grows to 6), `deck`, `hand` (max 7, overdraw discarded), `discard`, `board` (fixed three entries, null or unit dictionary), `power_used`, `next_ink`, `fatigue`, `knowledge` (correct quiz count only), `last_spell`. Unit dictionaries add `max_health` and `shield`. `turn` starts 1 and counts complete rounds. `current_player` is 0 outside synchronous AI processing. `winner` is -1 ongoing, 0 human, 1 rival, 2 draw.

- `can_play_card(side,index,lane=0)->bool`: checks affordability, turn, terminal state, lane, target and hand bounds.
- `play_card(side,index,lane=0)->bool`: makes the validated move, emits state. Units require empty friendly lane; buff/shield require friendly unit; weaken requires opposing unit; damage hits enemy unit in lane or reputation when empty. Other spells can use any lane.
- `can_power(side)->bool`, `power(side)->bool`: cost 2 ink, once per turn.
- `answer_question(correct)->bool`: at most once per human round; correct grants one immediate ink and one knowledge. Incorrect consumes opportunity, no penalty. Knowledge never independently wins.
- `end_turn()`: human units strike, AI refreshes/plays/strikes, new human round refreshes and draws. Guards repeated/terminal calls. Clash retaliation is simultaneous within each occupied lane. Empty opposing lanes take direct reputation damage. Persistent unit damage; no overflow. Units may strike the turn played.
- `draw_card(side)`: draw or increasing fatigue damage (1,2,3...). Discards never recycle. Match always concludes even if neither player acts.

Effects are fixed magnitudes; card `value` is metadata. Unit effects: `none`, `draw` (one on summon), `shield` (first damaging hit absorbed), `rage` (+1 attack when surviving damage), `death_draw`, `inspire` (+1 immediate ink), `heal` (2 reputation), `drain` (heal1 on direct strike). Spells: `damage` 3; `buff` +2 attack/+1 health and max health; `shield`; `heal` reputation3 + targeted ally2 up to max; `draw`2; `foreshadow` draw1 +2 next refresh ink; `metaphor` copies own previous non-metaphor spell; `weaken` targeted enemy -2 attack min0, then damage1.

Powers: Poe deals2 direct; Shelley strongest ally +1 attack/+2 health (or heal3 reputation if empty); Shakespeare all allies +1 attack; Austen heal3 reputation/draw1; Carroll draw2. All are permanent where relevant. Reputation healing caps16.
