# Add Answer Review Screen

## Summary
Implement an answer review system that allows players to review their answers after completing a round. When clicking a result button, a modal overlay displays the question, all four answer options with visual indicators (correct answer in green, wrong answers in red), and highlights which answer the player selected with a white outline. The review screen is reusable, managed by the result component, and includes a back button to dismiss it.

## Why
Players need to understand their performance after completing a round. Simply showing correct/incorrect icons doesn't provide enough context—players can't remember which question each icon represents or review their choices. This creates a frustrating experience where mistakes can't be learned from and correct answers can't be verified. By adding an interactive review system, players gain immediate feedback on their knowledge gaps and can better understand the quiz content, improving both learning outcomes and player satisfaction.

## Problem
Currently, after completing a round, players see only correct/incorrect indicators on result buttons but cannot review what questions were asked or which specific answers they chose. This limits learning opportunities and makes it difficult to understand mistakes or verify correct answers.

## Solution
Create an `answer_review_screen` component with:
1. **Script Creation**: Add GDScript to handle data loading, display logic, and lifecycle management
2. **Data Flow Enhancement**: Extend existing data capture in `gameplay_screen._on_question_answered()` to include the player's selected answer text
3. **Result Component Integration**: Pre-instantiate the review screen in `result_component`, manage its visibility, and handle showing/hiding with proper data
4. **Visual Presentation**: Reuse existing `answer_button` component to display answers with the same visual states as `quiz_screen` (green for correct, red for wrong, white outline for player's choice)

This keeps the implementation straightforward—reusing existing components and patterns while extending only the minimal necessary data flow.

## Scope

### In Scope
- Create `answer_review_screen.gd` script with methods to load and display question data
- Modify `gameplay_screen._on_question_answered()` to capture player's selected answer text
- Modify `result_component` to instantiate, manage, and show/hide the review screen
- Modify `result_button_component` to store complete question data including player answer
- Wire up back button in `answer_review_screen` to hide the overlay
- Ensure only one review screen can be shown at a time

### Out of Scope
- UI/layout changes to `answer_review_screen.tscn` (already complete)
- Timer or time-tracking features
- Category/difficulty display in review screen
- Animation or transition effects
- Keyboard shortcuts for navigation
- Changes to question fetching or storage outside of answer capture

## Dependencies
- **result-component**: Extends to manage review screen lifecycle
- **result-button-component**: Extends to store player answer data
- **answer-button-component**: Reused for display in review screen
- **gameplay-screen-initialization**: Modifies to capture player answer text
- **quiz-screen-component**: No changes, but data flows from it

## Success Criteria
1. After completing a round, clicking any result button opens the review screen for that question
2. Review screen displays question text, all four answers with correct visual states (green/red/white outline)
3. Only one review screen can be open at a time
4. Back button closes the review screen and returns to interactive gameplay screen
5. Review screen blocks interaction with elements behind it (modal behavior)
6. All answer data (question, correct answer, incorrect answers, player's choice) is correctly preserved and displayed

## Testing Approach
- **Manual Testing**: Play through a round, click each result button, verify correct question data displays
- **State Testing**: Open review screen, verify back button closes it, verify gameplay screen becomes interactive again
- **Data Integrity**: Verify player's selected answer matches what they clicked in quiz screen
- **Visual Testing**: Confirm visual states match quiz screen (colors, outline positioning)

## Alternatives Considered
1. **Create review screen on-demand**: Would simplify initialization but require instantiation/destruction overhead for each button click
2. **Store data in gameplay_screen**: Would centralize data but create tight coupling and complicate the component hierarchy
3. **Create separate review component**: Would allow more flexibility but adds unnecessary complexity when answer_button already exists

Chosen approach (pre-instantiate in result_component, reuse answer_button) provides best balance of performance, code simplicity, and component reusability.
