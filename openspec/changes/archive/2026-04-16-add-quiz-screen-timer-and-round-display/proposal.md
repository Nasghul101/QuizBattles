# Change Proposal: add-quiz-screen-timer-and-round-display

## Summary
Add a per-question countdown timer to the quiz screen and wire the RoundNumber label to display the current round number. The timer runs down a visual progress bar from full to empty; when it expires, the game auto-selects a random incorrect answer on the player's behalf.

## Problem
- `RoundNumber` label is never updated – it displays static placeholder text "Round Number".
- `TimeLimitBar` progress bar exists in the scene but has no driving logic; time pressure is not enforced.
- Players can currently take unlimited time to answer, which is inconsistent with the domain spec ("Timer: Per question - timeout = no point").

## Proposed Solution

### Round Number Display
Add a `set_round_number(round: int)` method to `quiz_screen.gd`. Callers (e.g. `gameplay_screen.gd`) call this method after initializing a round. The label displays the round as an integer starting at 1.

### Per-Question Timer
- Export a `time_limit: float` variable (seconds, supports millisecond precision via float) so it is editable in the Godot Inspector.
- On each `load_question()` call, reset and start a `Timer` node (added programmatically in `_ready()`).
- Each `_process(delta)` tick updates `time_limit_bar.value` proportionally based on elapsed time.
- When the player presses an answer button, stop the timer immediately.
- When the timer fires `timeout`, auto-select one of the wrong answer buttons at random, triggering the same answer-selection path as a normal button press.

## Affected Files
- `scenes/ui/quiz_screen.gd` — new exported var, Timer logic, `set_round_number()` method
- `scenes/ui/gameplay_screen.gd` — call `set_round_number()` when showing quiz screen

## Affected Specs
- `specs/quiz-screen-component/spec.md` — MODIFIED (round display requirement) + ADDED (timer requirements)

## Out of Scope
- Scoring bonuses based on remaining time
- Visual color changes on the bar as time decreases
- Pause/resume of the timer for network delays
