# Proposal: Add Quiz Screen Component

**Change ID:** `add-quiz-screen-component`  
**Status:** Proposed  
**Created:** 2026-01-09  
**Author:** AI Assistant

## Summary

Create a quiz screen component for gameplay that displays a question and 4 answer buttons. The screen handles answer randomization, validates user selection, reveals correct/wrong states, and signals when the player answers correctly for scoring purposes.

## Problem Statement

The quiz duel game needs a core gameplay screen where players can:
- View a trivia question
- Select from 4 possible answers
- Receive immediate visual feedback on their choice
- Have their correct answers tracked for scoring

Currently, only the answer button component exists. There is no screen that orchestrates the quiz question flow, manages multiple answer buttons, or handles the game logic for answer validation.

## Proposed Solution

Create a `quiz_screen` component located at `scenes/ui/quiz_screen.tscn` that:

1. **Displays the question** in a styled panel at the top of the screen
2. **Arranges 4 answer buttons** in a 2x2 grid below the question
3. **Randomizes answer distribution** by shuffling the correct answer and 3 incorrect answers among the 4 buttons
4. **Validates answers** when a button is pressed and reveals all buttons with correct/wrong states
5. **Signals correct answers** by emitting an `answer_correct` signal (for future scoreboard integration)

### Key Features

- **Question Loading**: Public method `load_question(question_data: Dictionary)` accepts question data in Open Trivia DB format
- **Answer Shuffling**: Internal logic shuffles answers so the correct answer appears at a random position
- **Answer Validation**: Tracks which button has the correct answer and validates on press
- **Visual Feedback**: All 4 buttons reveal their states (green for correct, red for wrong) immediately after selection
- **Scoring Signal**: Emits `answer_correct` signal only when player selects the correct answer
- **Single-Use Design**: Intended to be replaced/transitioned after each question (transition logic handled separately)

### Question Data Format

Expected input format (Open Trivia DB structure):
```gdscript
{
    "question": "What is the capital of France?",
    "correct_answer": "Paris",
    "incorrect_answers": ["London", "Berlin", "Madrid"]
}
```

### Component Hierarchy

```
QuizScreen (Control)
├── QuestionPanel (Panel)
│   └── QuestionLabel (Label)
└── AnswersGrid (GridContainer, 2 columns)
    ├── AnswerButton1 (answer_button.tscn instance)
    ├── AnswerButton2 (answer_button.tscn instance)
    ├── AnswerButton3 (answer_button.tscn instance)
    └── AnswerButton4 (answer_button.tscn instance)
```

## Affected Capabilities

- **New Capability**: `quiz-screen-component` - Full specification in spec delta

## Design Decisions

### Why shuffle answers internally?
The quiz screen is responsible for presentation logic. By handling shuffling internally, we keep the external API simple - callers just provide raw question data without worrying about randomization.

### Why signal only on correct answers?
The current requirement is to track points for correct answers only. Signaling both correct and wrong would require the scoreboard to filter. This keeps the signal semantics clear and the integration simple.

### Why reveal all buttons immediately?
This provides instant feedback to the player about what the correct answer was, which is educational and maintains game flow. Delayed reveals would require additional timing logic and could frustrate players.

### Why single-use screen?
Per the game's scene-based architecture and the user's intent to handle transitions externally, the quiz screen focuses solely on one question's lifecycle. This simplifies state management and aligns with the pattern of replacing screens between questions.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Answer button signal timing | If signals fire in wrong order, validation could fail | Connect answer button signals in `_ready()` and ensure validation happens before reveal |
| Incorrect shuffle logic | Correct answer might not be tracked after shuffle | Unit test shuffle and validation logic; store correct index after shuffle |
| Question data format changes | Open Trivia DB might use different format | Design flexible parsing; document expected format clearly |
| Memory leaks from repeated instantiation | Creating/destroying screens could leak | Ensure proper cleanup; follow Godot best practices for scene lifecycle |

## Dependencies

- **Requires**: `answer-button-component` (already implemented)
- **Blocks**: Future scoreboard integration (will connect to `answer_correct` signal)

## Testing Approach

- **Manual testing**: Load various question formats, verify shuffling works, test visual feedback
- **Validation testing**: Ensure correct/wrong answers trigger appropriate reveals
- **Signal testing**: Verify `answer_correct` emits only for correct selections
- **Edge cases**: Test with empty strings, long question text, special characters

## Future Considerations

- Timer integration (per-question timeout)
- Animation/transitions between states
- Sound effects on answer selection
- Difficulty indicator display
- Category badge display
- Accessibility features (larger text, high contrast modes)

## Open Questions

None - all clarifications received from user.

## Approval Checklist

- [ ] Proposal reviewed and approved
- [ ] Spec deltas validated
- [ ] Implementation tasks clear and actionable
- [ ] Dependencies confirmed available
- [ ] Ready to proceed with implementation
