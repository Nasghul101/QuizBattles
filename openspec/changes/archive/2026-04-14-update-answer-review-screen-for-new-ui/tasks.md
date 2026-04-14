# Tasks: update-answer-review-screen-for-new-ui

## Implementation

- [x] **1. Add `set_pulsating_enabled(enabled: bool) -> void` to `answer_button.gd`**
  - Accesses `self.material as ShaderMaterial` and sets the `enable_pulsating` shader parameter.
  - Validates that the material cast is non-null before setting.

- [x] **2. Add `set_shader_outline_color(color: Color) -> void` to `answer_button.gd`**
  - Accesses `self.material as ShaderMaterial` and sets the `outline_color` shader parameter.
  - Validates that the material cast is non-null before setting.

- [x] **3. Remove StyleBoxFlat border logic from `answer_review_screen.gd`**
  - Delete the `var style_box = button.get_theme_stylebox("normal")` block and all `style_box.border_*` assignments.

- [x] **4. Replace `button.text = answer_text` with `button.set_answer(answer_text, i)` in `answer_review_screen.gd`**
  - Use the existing `set_answer(text: String, index: int)` API from `answer_button.gd`.

- [x] **5. Disable pulsating on all four answer buttons during load in `answer_review_screen.gd`**
  - After setting text and before calling `reveal_correct()` / `reveal_wrong()`, call `button.set_pulsating_enabled(false)` on each button.

- [x] **6. Set white shader outline for the player's selected answer in `answer_review_screen.gd`**
  - After disabling pulsating, if `answer_text == player_answer`, call `button.set_shader_outline_color(Color.WHITE)`.

- [x] **7. Remove `button.disabled = true` direct assignment; verify disabled state is still correct**
  - `TextureButton.disabled` still works, kept as-is — aligns with component interface.

## Spec / Documentation

- [x] **8. Create `openspec/specs/answer-review-screen/spec.md`**
  - Spec already existed with correct shader-based approach — confirmed up to date.

- [x] **9. Update `openspec/specs/answer-button-component/spec.md`**
  - Applied the `answer-button-component` spec delta — added two new method requirements.

## Validation

- [x] **10. Run `openspec validate update-answer-review-screen-for-new-ui --strict` and fix any issues**

- [x] **11. Manual test**
  - Play through a round, click each result button, verify the review screen appears with correct question/answers.
  - Confirm: correct answers green, wrong answers red, player's selection has white outline, no pulsating animation.
  - Confirm back button dismisses the screen.
