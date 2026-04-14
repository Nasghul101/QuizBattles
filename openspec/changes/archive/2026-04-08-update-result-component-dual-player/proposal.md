# Proposal: update-result-component-dual-player

## Summary
Update `result_component.gd` to match the new dual-player UI layout introduced in `result_component.tscn`. The scene now has separate `ResultButtonContainerP1` and `ResultButtonContainerP2` containers, a `RoundLabel` for displaying the round number, and a `CategoryLabel` for displaying the category name as text (replacing the old `CategorySymbol` TextureRect).

## Motivation
The UI layout of `result_component.tscn` has been redesigned to show both players' answer outcomes side-by-side within a single component, along with a textual round identifier and category name. The script must reflect these structural changes.

## Scope
**Only `result_component.gd`** is in scope for this change. Callers (e.g. `gameplay_screen.gd`) will need to be updated separately in a follow-up change.

## Changes

### 1. Dual-container button population
`initialize_empty(num_answer_buttons)` must populate **both** `ResultButtonContainerP1` and `ResultButtonContainerP2` with the same number of `ResultButtonComponent` instances. Both containers always hold an equal amount of buttons.

Two internal arrays are maintained: `answer_buttons_p1` and `answer_buttons_p2`.

### 2. Round label via set_round()
A new method `set_round(round_number: int)` sets `RoundLabel.text` to `"Round %d" % round_number`. This is called externally by the gameplay screen after the component is instantiated, rather than auto-detecting position.

### 3. Updated load_result_data signature
Old: `load_result_data(category_texture: Texture2D, results: Array) -> void`  
New: `load_result_data(category_name: String, p1_results: Array, p2_results: Array) -> void`

- `CategoryLabel.text` is set to `category_name`.
- P1 results are applied to P1 buttons; P2 results are applied to P2 buttons.
- Both arrays must have the same size and must not exceed the number of initialized buttons.

### 4. hide_results() hides only P2 buttons
`hide_results()` previously hid all buttons. It now hides only the P2 buttons (opponent), since the P1 (local player) results are always shown.

### 5. Remove category_symbol references
All references to `category_symbol` TextureRect are removed. The old `stored_results` single array is replaced with `stored_results_p1` and `stored_results_p2`.

## Out of Scope
- Changes to `gameplay_screen.gd` (to be addressed in a follow-up).
- Changes to `result_component.tscn` (already done by the user).
- Changes to `result_button_component` or `answer_review_screen`.
