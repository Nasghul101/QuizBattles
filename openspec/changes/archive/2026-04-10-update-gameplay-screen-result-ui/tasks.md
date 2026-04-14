# Tasks: update-gameplay-screen-result-ui

## Implementation Checklist

- [x] **1. Update `@onready` node references in `gameplay_screen.gd`**
  - Remove `result_container_l` and `result_container_r` declarations.
  - Add `@onready var result_container: VBoxContainer = %ResultContainer` (already present as the play-button-area container but verify the unique name).
  - Add `@onready var name_p1_label: Label = %NameP1`.
  - Add `@onready var name_p2_label: Label = %NameP2`.

- [x] **2. Populate name labels in `_ready()`**
  - Set `name_p1_label.text` to `UserDatabase.current_user.username`.
  - In multiplayer mode, set `name_p2_label.text` to `opponent_username` (available after `initialize()` sets it).
  - In single-player mode, set `name_p2_label.text = ""`.
  - Name label population must happen after `initialize()` has run (use the existing guard pattern: check `is_multiplayer`).

- [x] **3. Update `_initialize_result_components()` to use single container**
  - Remove the dual-loop that populated both `result_container_l` and `result_container_r`.
  - Create `num_rounds` result components in `result_container` only.
  - After `add_child`, call `component.initialize_empty(num_questions)`.
  - After `add_child`, call `component.set_round(i + 1)`.

- [x] **4. Update `_complete_round()` for single-player**
  - Replace `result_container_l.get_child(current_round - 1)` with `result_container.get_child(current_round - 1)`.
  - Change `result_l.load_result_data(icon_placeholder, current_round_results)` to
    `result_component.load_result_data(selected_category, current_round_results, [])`.
  - After `load_result_data`, call `result_component.hide_results()` to hide the empty P2 buttons.
  - Remove the `icon_placeholder` preload if it is no longer referenced elsewhere.

- [x] **5. Update `_display_round_results()` for multiplayer**
  - Remove the `side` parameter; a single component now holds both players' data.
  - Change signature to `_display_round_results(round_idx: int)`.
  - Fetch `p1_results` from `match_data.rounds_data[round_idx].player_answers[my_username].results`.
  - Fetch `p2_results` from `match_data.rounds_data[round_idx].player_answers[opponent_username].results`.
  - Call `result_container.get_child(round_idx).load_result_data(category_name, p1_results, p2_results)`.
  - Update all call sites in `_handle_round_completion()` and `_load_existing_match_state()`.

- [x] **6. Update `hide_results()` call sites in `_load_existing_match_state()`**
  - Change `opponent_container.get_child(round_idx).hide_results()` to
    `result_container.get_child(round_idx).hide_results()`.
  - Remove the `opponent_container` variable; it is no longer needed.

- [x] **7. Update `_calculate_score_from_results()` for unified container**
  - Change signature from `_calculate_score_from_results(container: VBoxContainer) -> int`
    to `_calculate_score_from_results(side: String) -> int` where `side` is `"p1"` or `"p2"`.
  - Iterate `result_container.get_children()`.
  - For `side == "p1"`, count correct answers in `result_component.stored_results_p1`.
  - For `side == "p2"`, count correct answers in `result_component.stored_results_p2`.

- [x] **8. Update `_update_score_labels()` and `_show_finish_popup()`**
  - Replace `_calculate_score_from_results(result_container_l)` with `_calculate_score_from_results("p1")`.
  - Replace `_calculate_score_from_results(result_container_r)` with `_calculate_score_from_results("p2")`.

- [x] **9. Update class-level doc comment and any inline comments** that reference the old dual-container design.

- [x] **10. Validate in Godot**
  - Open the scene and verify no `@onready` errors.
  - Run a single-player game to confirm result components display and P2 buttons are hidden.
  - Run a multiplayer match to confirm both players' results are visible in each component.
  - Verify score labels update correctly after each round.

## Dependencies
- Tasks 1–3 must complete before 4–6.
- Tasks 4–8 are independent of each other and can be done in any order after 1–3.
- Task 9 can be done alongside any other task.
- Task 10 must be last.

## Notes
- `icon_placeholder` was only used as the `Texture2D` argument to the old `load_result_data`. Once task 4 removes that call, check if it is used anywhere else before removing the preload.
- The `result_component` changes (new API) are already implemented in the attached script; only `gameplay_screen.gd` needs to change.
