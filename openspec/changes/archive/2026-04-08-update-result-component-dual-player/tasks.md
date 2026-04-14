# Tasks: update-result-component-dual-player

## Implementation Checklist

- [x] **T1** — Remove `answer_button_container` @onready (no longer exists in scene) and `category_symbol` references from `result_component.gd`
- [x] **T2** — Replace `answer_buttons: Array` with `answer_buttons_p1: Array` and `answer_buttons_p2: Array`; replace `stored_results: Array` with `stored_results_p1: Array` and `stored_results_p2: Array`
- [x] **T3** — Update `initialize_empty(num_answer_buttons: int)` to populate both `result_button_container_p1` and `result_button_container_p2` with equal counts of `ResultButtonComponent` instances
- [x] **T4** — Add `set_round(round_number: int) -> void` method that sets `round_label.text = "Round %d" % round_number`
- [x] **T5** — Update `load_result_data` signature to `load_result_data(category_name: String, p1_results: Array, p2_results: Array) -> void`; set `category_label.text = category_name`; apply results to respective button arrays
- [x] **T6** — Update `_update_button_states()` to iterate over both `stored_results_p1` / `answer_buttons_p1` and `stored_results_p2` / `answer_buttons_p2`
- [x] **T7** — Update `hide_results()` to hide only P2 buttons (`answer_buttons_p2`)
- [x] **T8** — Update `is_empty` logic: the component is not empty when either P1 or P2 results are loaded
- [x] **T9** — Update doc comments and class-level usage documentation to reflect new API
- [x] **T10** — Manual verification: confirm the component correctly initialises, receives round/category data, and displays P1/P2 buttons when tested in-editor

## Dependencies
- T1 must come before T3–T7
- T3 must come before T5–T8 (buttons must exist before data is loaded)
- T4 is independent of T3–T8
