# Proposal: add-category-color-theming

## Summary
Apply per-category accent colors to the quiz screen UI. When a question is loaded, the `GradientLabel` (category header) and all four `AnswerButton` components update their accent color to match the active category, using hex values defined in `data/color_codes.json`. Categories without a defined color fall back to white (`#ffffff`).

## Motivation
The category colors in `color_codes.json` are only stored as data today — no UI component reads or applies them. This change wires the data to the visual layer so the quiz screen communicates category context through color.

## Scope
Three components are touched, all in the UI layer:

| Component | Change |
|---|---|
| `gradient_label.gd` | Add `set_accent_color(color: Color)` — sets index 0 of the gradient's `PackedColorArray` |
| `answer_button.gd` | Add `set_pulsating_color(color: Color)` — sets the `pulsating_color` shader parameter |
| `quiz_screen.gd` | Resolve category color via `Utils.get_color_codes()` and call both new methods on `load_question()` |

## Decisions
- **Only gradient index 0 changes.** Index 1 (the fixed pink-white `#FBDCF3`) remains unchanged.
- **Fallback color is `Color.WHITE` (`#ffffff`).** Applied when the category key is absent from the data dict *or* when the JSON value is `null`.
- **Color codes are read via `Utils.get_color_codes()`** — the existing autoload already handles file loading and parsing. The quiz screen does not cache the dictionary; it reads it once per `load_question()` call (the file is small).
- **`class_name GradientLabel` is added** to `gradient_label.gd` so `quiz_screen.gd` can type the `%CategoryLabel` onready reference correctly and call `set_accent_color()` without duck typing.

## Out of Scope
- Animating the color transition.
- Changing the gradient's second color.
- Caching or preloading color codes.
- Updating the color when no `load_question()` call has been made yet (initial state remains whatever the scene sets).
