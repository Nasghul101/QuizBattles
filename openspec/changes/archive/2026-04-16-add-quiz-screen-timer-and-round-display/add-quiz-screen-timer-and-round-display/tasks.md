# Tasks: add-quiz-screen-timer-and-round-display

## Implementation Checklist

- [x] **1. Add `set_round_number()` method to `quiz_screen.gd`**
  - Add `func set_round_number(round: int) -> void` that sets `round_number.text = "Round %d" % round` (or bare integer – confirm with spec)
  - Validation: Round 1 shows "Round 1", round 6 shows "Round 6"

- [x] **2. Export `time_limit` variable in `quiz_screen.gd`**
  - `@export var time_limit: float = 30.0` (seconds, Inspector-editable, supports sub-second via float)
  - Validation: Value appears in Godot Inspector for the scene

- [x] **3. Add internal countdown state to `quiz_screen.gd`**
  - `var _time_remaining: float`
  - `var _timer_running: bool = false`

- [x] **4. Connect `TimeLimitBar` initial state in `_ready()`**
  - Set `time_limit_bar.max_value = 1.0`, `time_limit_bar.value = 1.0` (normalized, matches shader expectations)
  - Shader already accepts normalized progress via `shader_parameter/progress`

- [x] **5. Start timer inside `load_question()`**
  - After question setup: `_time_remaining = time_limit`, `_timer_running = true`
  - Reset bar to full: `time_limit_bar.value = 1.0`

- [x] **6. Drive bar in `_process(delta)`**
  - If `_timer_running`: subtract delta from `_time_remaining`, clamp to 0
  - Set `time_limit_bar.value = _time_remaining / time_limit`
  - If `_time_remaining <= 0.0`: call `_on_timer_expired()`

- [x] **7. Stop timer on answer selection**
  - In `_on_answer_selected()`, set `_timer_running = false` before all other logic (already guarded by `has_answered`)

- [x] **8. Implement `_on_timer_expired()`**
  - Collect wrong answer buttons (those whose `answer_text != correct_answer_text`)
  - Pick one at random
  - Call `_on_answer_selected(button.button_index)` (or equivalent path that reuses existing signal logic)

- [x] **9. Call `set_round_number()` from `gameplay_screen.gd`**
  - When showing the quiz screen for any question in a round, call `quiz_screen.set_round_number(current_round)`
  - Ensure it is called before `load_question()` so the label is correct from the start

- [x] **10. Update spec delta**
  - `changes/add-quiz-screen-timer-and-round-display/specs/quiz-screen-component/spec.md`
  - Mark MODIFIED round-display requirement, ADDED timer requirements

## Dependencies
- Task 3 depends on Task 2 (needs `time_limit` to initialize `_time_remaining`)
- Task 5 depends on Tasks 3 & 4
- Task 6 depends on Tasks 3 & 5
- Task 8 depends on Task 6
- Task 9 depends on Task 1

## Parallelizable
- Tasks 1 & 2 can be done simultaneously
- Tasks 3 & 4 can be done simultaneously after Task 2
