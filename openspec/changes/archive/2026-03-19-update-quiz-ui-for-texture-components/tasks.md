# Implementation Tasks

## Overview
Update GDScript implementations to work with new texture-based UI components while maintaining all existing functionality.

## Task List

### 1. Update Answer Button Component
- [x] Change `extends Button` to `extends TextureButton` in `answer_button.gd`
- [x] Add internal `_answer_text: String` variable to store answer text
- [x] Add public property getter `var answer_text: String` to expose the stored text
- [x] Update `set_answer()` method to:
  - Store text in `_answer_text` variable
  - Set text on `AnswerLabel` child node via `$AnswerLabel.text = answer_text`
- [x] Remove all `StyleBoxFlat` related code (`_style_box`, `_setup_style()`, `_configure_style_box_border()`)
- [x] Update `_on_button_pressed()` to use new selection indicator approach (if needed)
- [x] Update `reveal_correct()` to animate `self_modulate` to green tint (Color(0.2, 0.8, 0.2, 1.0))
- [x] Update `reveal_wrong()` to animate `self_modulate` to red tint (Color(0.8, 0.2, 0.2, 1.0))
- [x] Update `reset()` to reset `self_modulate` to white (Color(1.0, 1.0, 1.0, 1.0))
- [x] Verify all exported color properties still apply to the tint approach

### 2. Update Quiz Screen Component
- [x] Add `@onready var category_label: Label` reference to the CategoryLabel node
- [x] Update `load_question()` to extract category from question data
- [x] Set `category_label.text` with the category value from `data["category"]`
- [x] Update `_on_answer_selected()` to read answer text from `selected_button.answer_text` instead of `selected_button.text`
- [x] Update `_reveal_all_buttons()` to compare using `button.answer_text` instead of `button.text`

### 3. Testing and Validation
- [ ] Test answer button color transitions (neutral → green/red)
- [ ] Test answer selection and validation logic
- [ ] Test category display shows correct category name
- [ ] Verify all answer buttons receive and display text correctly
- [ ] Test button disable state after selection
- [ ] Test reset functionality between questions
- [ ] Verify white outline selection indicator works (if implemented)
- [ ] Run through full quiz flow (load question → select answer → next question → repeat)

## Dependencies
- New `.tscn` scene files must be in place before testing
- No external dependencies or API changes

## Validation Criteria
- All existing unit tests pass (if any exist)
- Manual testing confirms identical functionality to previous implementation
- No console errors or warnings during gameplay
- Color transitions are smooth and visible
- Category label updates correctly for each question

## Notes
- Keep `self_modulate` approach simple to allow future shader implementation
- Maintain all export properties for potential editor customization
- Do not change any public method signatures or signal definitions
