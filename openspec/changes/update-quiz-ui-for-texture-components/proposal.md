# Proposal: Update Quiz UI for Texture Components

## Problem Statement
The quiz screen UI has been updated to use texture-based components (`TextureButton` and `TextureRect`) instead of standard Godot UI controls (`Button` and `Panel`). Specifically:
- `answer_button.tscn` now uses `TextureButton` instead of `Button` with an `AnswerLabel` child for text display
- `quiz_screen.tscn` now has a `TextureRect` for the question panel and a new category display section with texture background and label

The current GDScript implementations (`answer_button.gd` and `quiz_screen.gd`) still assume the old UI structure and won't work correctly with the new scene files.

## Proposed Solution
Update the GDScript code for both components to work with the new texture-based UI while maintaining identical functionality:

### Answer Button Component (`answer_button.gd`)
- Change base class from `extends Button` to `extends TextureButton`
- Store answer text in an internal variable and expose it via a property getter
- Update `set_answer()` to set the `AnswerLabel` child node's text instead of `self.text`
- Replace `StyleBoxFlat` color animation approach with `self_modulate` to tint the entire button texture
- Keep the same color feedback system (neutral → green for correct, red for wrong)
- Maintain all existing signals, methods, and behavior

### Quiz Screen Component (`quiz_screen.gd`)
- Update answer validation to read answer text from the button's new text property instead of `button.text`
- Add category display functionality using the `CategoryLabel` node
- Extract and display the simplified category name from question data (as configured in `trivia_question_service`)
- Maintain all existing functionality (question loading, answer shuffling, validation, state management)

## Impact Assessment
- **Affected Components**: `answer-button-component`, `quiz-screen-component`
- **Breaking Changes**: None (all public APIs remain the same)
- **Dependencies**: Requires the new `.tscn` files already created
- **Testing**: Manual testing required for color transitions and category display

## Success Criteria
1. Answer buttons display text correctly via `AnswerLabel` child node
2. Color transitions (neutral/green/red) work using `self_modulate`
3. Answer selection and validation work identically to before
4. Category label displays the simplified category name from question data
5. All existing signals and methods work without changes to calling code
6. No visual regressions in button states or transitions

## Future Considerations
- Shader-based color effects will be added later, so the current `self_modulate` approach should be easily replaceable
- The texture button approach allows for more sophisticated visual effects in the future

## Related Specifications
- `answer-button-component` - Modified (implementation details only)
- `quiz-screen-component` - Modified (add category display requirement)
- `trivia-question-service` - Referenced (provides category data)
