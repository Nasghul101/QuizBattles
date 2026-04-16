# Tasks: add-category-color-theming

## Ordered Implementation Checklist

- [x] **1. Add `class_name GradientLabel` and `set_accent_color()` to `gradient_label.gd`**
  - Add `class_name GradientLabel` at the top of the script.
  - Implement `set_accent_color(color: Color) -> void` that retrieves the `Gradient` resource from `gradient.texture` and sets `colors[0]` to the given color.
  - _Validation: instantiate the scene in the editor, call the method in a test script, verify the gradient header changes color._

- [x] **2. Add `set_pulsating_color()` to `answer_button.gd`**
  - Implement `set_pulsating_color(color: Color) -> void` following the same null-guard pattern already used in `set_pulsating_enabled()` and `set_shader_outline_color()`.
  - _Validation: manually call the method in an editor test; confirm the shader pulsating glow changes color._

- [x] **3. Update `quiz_screen.gd` to retype `category_label` and apply category colors in `load_question()`**
  - Change `@onready var category_label: Label = %CategoryLabel` → `@onready var category_label: GradientLabel = %CategoryLabel`.
  - Add private helper `_resolve_category_color(category: String) -> Color` that calls `Utils.get_color_codes()`, looks up `category_colors[category]`, and returns `Color.WHITE` when the key is missing or the value is `null`.
  - In `load_question()`, after writing `category_label.text`, call `_apply_category_color(category)`.
  - Add private method `_apply_category_color(category: String) -> void` that resolves the color and calls `category_label.set_accent_color(color)` + iterates `answer_buttons` calling `button.set_pulsating_color(color)`.
  - _Validation: load several questions with different categories; confirm gradient and pulsating colors update; load a question with a null-color or missing category; confirm white fallback._

## Dependencies
- Task 3 depends on Tasks 1 and 2 (needs `GradientLabel` class_name and `set_pulsating_color` to exist).
- Tasks 1 and 2 are independent and can be done in parallel.
