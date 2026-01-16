# Proposal: Add Gameplay Round Flow

## Overview
Implement the complete round-based gameplay flow including category selection, question answering, result tracking, and round progression. This change enables players to play through multiple rounds by selecting categories, answering questions, and viewing results.

## Problem Statement
The gameplay_screen currently only stores configuration (num_rounds, num_questions) but has no logic to execute rounds. There is no way for players to:
- Select a category from available options
- Answer questions within a round
- See their results after completing questions
- Progress through multiple rounds sequentially

## Proposed Solution
Add four new capabilities that work together to create a complete round flow:

1. **Category Selection Popup** - Modal popup displaying 3 random categories with loading state during question fetch
2. **Gameplay Round Orchestration** - Central coordinator managing round state, question storage, and flow control
3. **Result Component Lifecycle** - Dynamic instantiation and state management of result components based on num_rounds
4. **Quiz Screen Flow Management** - Handle question progression, answer tracking, and navigation back to gameplay

### Key Features
- PlayButton triggers category popup at start of each round
- Category popup displays 3 random categories from TriviaQuestionService
- Progress bar shows loading state while fetching questions
- Quiz screen displays questions sequentially with NextQuestion button
- Results populate result components from top to bottom after each round
- Both players (left/right) get identical questions per round (for future multiplayer)
- Graceful fallback to local questions on API failure

## User Impact
- Players can now play complete quiz rounds with category selection
- Clear visual feedback during loading and question progression
- Results are displayed immediately after each round
- Foundation for multiplayer functionality (same questions for both players)

## Technical Approach

### Architecture
- **gameplay_screen.gd**: Central orchestrator managing all flow states
- **category_popup_component.gd**: Self-contained category selection and loading UI
- **quiz_screen.gd**: Enhanced with signal-based communication for flow control
- **result_component.gd**: Existing component with disabled state support

### Data Flow
1. PlayButton pressed → Show category popup with 3 random categories
2. Category selected → Fetch questions, show progress bar
3. Questions ready → Hide popup, show quiz_screen with first question
4. Question answered → Show NextQuestion button
5. NextQuestion pressed → Load next question or return to gameplay_screen
6. All questions complete → Update next available result component, show PlayButton

### State Management
- `current_round`: Track which round is active (1-based)
- `current_question_index`: Track position in question sequence
- `fetched_questions`: Store questions for current round (reusable for both players)
- `round_results`: Store answers and correctness for result display

## Dependencies
- Existing: TriviaQuestionService (fetch_questions, get_available_categories)
- Existing: TransitionManager (scene transitions)
- Existing: quiz_screen component
- Existing: result_component
- New: category_popup_component.tscn (already created by user)

## Risks & Mitigations
- **Risk**: Complex state management across multiple screens
  - **Mitigation**: Use signal-based communication, clear state tracking
- **Risk**: UI not created yet (loading indicator, popup overlay)
  - **Mitigation**: User already created category_popup with progress bar
- **Risk**: Multiplayer not implemented yet
  - **Mitigation**: Design flow to store questions once, reusable for future multiplayer

## Out of Scope
- Multiplayer turn alternation logic
- Category icons (using icon.svg placeholder)
- Score calculation
- Timer functionality
- Question review from result components

## Success Criteria
- Player can press PlayButton and see 3 random categories
- Selecting category fetches questions and shows progress bar
- Questions display sequentially with NextQuestion button
- After answering all questions, results appear in next result component
- PlayButton reappears after round completion
- Both left and right result containers have num_rounds components
- Graceful fallback to local questions on API failure

## Related Specifications
- Modifies: gameplay-screen-initialization
- Modifies: quiz-screen-component
- Adds: category-selection-popup
- Adds: gameplay-round-orchestration
- Adds: result-component-lifecycle
- Adds: quiz-screen-flow-management
