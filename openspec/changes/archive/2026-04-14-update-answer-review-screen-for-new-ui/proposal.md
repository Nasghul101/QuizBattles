# Proposal: update-answer-review-screen-for-new-ui

## Summary
Update `answer_review_screen.gd` so that it works correctly with the new
`answer_review_screen.tscn` layout, which uses `answer_button.tscn` instances
(TextureButton + predefined outline shader) instead of plain Button nodes.
Add two new public methods to `answer_button.gd` to expose shader parameter
control, and create the permanent `answer-review-screen` spec that was never
promoted from the archived change.

## Problem

### 1. answer_review_screen.gd uses a broken API
`answer_review_screen.tscn` was redesigned to use `answer_button.tscn` as the
four answer button instances. The existing script still assumes plain `Button`
nodes and breaks in two places:

| Line | Old assumption | Why it breaks |
|---|---|---|
| `button.text = answer_text` | Button has a `.text` property | TextureButton has no `.text`; answer_button uses `set_answer()` |
| `button.get_theme_stylebox("normal")` | Button exposes a StyleBoxFlat | Returns `null` on TextureButton; all border manipulation then silently fails |

The player-selected-answer white outline never appears at runtime.

### 2. answer_button.gd exposes no shader control methods
The correct-answer visual ("selected" state) requires disabling the pulsating
animation and setting a distinct outline color on individual buttons. Neither
operation can be done cleanly without direct shader-parameter methods on the
component itself.

### 3. answer-review-screen permanent spec is missing
The `2026-01-18-add-answer-review-screen` archive contains a spec delta, but no
`openspec/specs/answer-review-screen/spec.md` was ever created from it.

## Scope

### In scope
- Add `set_pulsating_enabled(enabled: bool) -> void` to `answer_button.gd`
- Add `set_shader_outline_color(color: Color) -> void` to `answer_button.gd`
- Replace broken API calls in `answer_review_screen.gd`:
  - `button.text =` → `button.set_answer(answer_text, i)`
  - Remove all StyleBoxFlat border manipulation
  - Disable pulsating on every button on load
  - Set white shader outline on the player's selected button
- Create `openspec/specs/answer-review-screen/spec.md` (new permanent spec)
- Update spec delta for `answer-button-component` (new methods)
- Update spec delta for `answer-review-screen-component` (corrected visual approach)

### Out of scope
- Changes to `answer_review_screen.tscn` or `answer_button.tscn` (already final)
- Changes to `result_component.gd` or `gameplay_screen.gd`
- Adding selection outlines for the interactive quiz phase (quiz_screen)
- Animations or transitions in the review screen

## Decisions

| Question | Decision |
|---|---|
| How to expose shader control | Two focused methods on answer_button.gd: `set_pulsating_enabled` and `set_shader_outline_color` |
| Selected answer indicator | White shader outline (`Color.WHITE`) + pulsating disabled |
| Pulsating in review screen | Always disabled for all four answer buttons |
| "Correct" and "Wrong" visuals | Existing `reveal_correct()` / `reveal_wrong()` unchanged |
| Permanent spec creation | New `openspec/specs/answer-review-screen/spec.md` added in tasks |

## Affected Specs
- `answer-button-component` (MODIFIED — two new methods)
- `answer-review-screen-component` (MODIFIED — visual approach for selected state)
- `answer-review-screen` (ADDED — new permanent spec, does not yet exist)
