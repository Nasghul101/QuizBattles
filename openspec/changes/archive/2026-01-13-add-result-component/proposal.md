# Change Proposal: add-result-component

## Summary
Add a reusable result component that displays a category summary with answer outcomes for a round of 3 questions. The component shows a category symbol/icon and three answer indicator buttons that can be clicked to review the answered questions in a popup (popup implementation is out of scope).

## Problem
After answering 3 questions from a category in a round, players need a visual summary showing:
- Which category was played
- Which of the 3 questions were answered correctly/incorrectly
- Ability to review individual questions by clicking on the answer indicators

Currently, no component exists to display this per-category round result information.

## Motivation
**Why is this change necessary?**
- The game flow requires showing round results after each category (3 questions)
- Players need visual feedback on their performance per category
- Players should be able to review their answered questions
- The result component will be reused multiple times on a result screen (5 categories per player = 10 components total in a full game)

**What user/developer pain does it solve?**
- Provides clear, structured feedback on round performance
- Enables question review functionality
- Creates a reusable building block for result screens

**Why now?**
- Foundational component needed for game flow
- Depends on existing quiz-screen-component and answer-button-component
- Logical progression after implementing question answering

## Proposed Changes

### New Capabilities
- **result-component**: A UI component that displays category icon and answer outcomes for a round of 3 questions, with clickable review buttons

### Modified Capabilities
None.

### Removed Capabilities
None.

## Design Decisions

### Component Responsibilities
The result component is responsible for:
- Displaying a category texture/icon
- Showing 3 answer indicators (correct/incorrect icons)
- Storing question data and answer outcomes for each of the 3 questions
- Emitting events when an answer indicator is clicked (with the question data)

The result component is NOT responsible for:
- Creating or managing the review popup (handled by parent/screen)
- Result screen layout (handled by parent container)
- Player identification (handled by parent container)
- Category texture loading/management (textures passed from parent)

### Data Flow
1. Parent screen provides: category texture + array of 3 question results
2. Result component stores: question data, answer outcomes, player answers
3. On button click: component emits signal with stored question data
4. Parent screen: handles popup creation/display (out of scope)

### Visual Design
- Category symbol displayed as TextureRect at top
- Three answer indicator buttons in horizontal layout below
- Buttons show icon_right.png (correct) or icon_wrong.png (incorrect)
- Clicking a button emits signal with that question's data

## Implementation Scope

### In Scope
- ResultComponent scene with script (result_component.gd)
- Data structure for storing category and question results
- Method to initialize component with category texture and question data
- Three clickable buttons that emit signals with question data
- Correct/incorrect icon display on buttons

### Out of Scope
- Review popup implementation
- Result screen layout/container
- Player identification/labeling
- Category texture atlas/loading system
- Animations or transitions

## Testing Strategy
- Manual testing: Load component with sample data, verify icons display
- Manual testing: Click buttons, verify signals emit correct question data
- Manual testing: Test with all-correct, all-incorrect, and mixed scenarios

## Dependencies
- Existing: quiz-screen-component (for question data format)
- Existing: icon_right.png and icon_wrong.png assets
- Future: Review popup (will consume signals from this component)

## Alternatives Considered

### Alternative 1: Embed quiz screen instances
Store actual quiz screen scene instances instead of data.
**Rejected because**: Memory inefficient, tight coupling, unnecessary complexity for simple display/storage needs.

### Alternative 2: Component manages popup
Result component creates and manages its own popup.
**Rejected because**: Violates single responsibility, reduces reusability, makes parent screen layout harder to control.

## Open Questions
None - all clarifications received from user.

## Approvals
- [ ] User approval required before implementation
