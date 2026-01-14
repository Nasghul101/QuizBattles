# Design: Gameplay Round Flow

## Architecture Overview

### Component Hierarchy
```
gameplay_screen (orchestrator)
├── category_popup_component (overlay, initially hidden)
├── quiz_screen (pre-instantiated, initially hidden)
├── ResultContainerL (VBoxContainer)
│   └── result_component instances (dynamically created)
└── ResultContainerR (VBoxContainer)
    └── result_component instances (dynamically created)
```

### State Machine
```
IDLE → CATEGORY_SELECTION → LOADING_QUESTIONS → ANSWERING_QUESTIONS → ROUND_COMPLETE → IDLE
```

## Key Design Decisions

### 1. Single Quiz Screen Instance (Reuse Pattern)
**Decision**: Pre-instantiate one quiz_screen and reuse it for all questions
**Rationale**: 
- Better performance than creating/destroying scenes per question
- Simpler memory management
- quiz_screen already supports `load_question()` for dynamic content
**Alternative Rejected**: Creating new quiz_screen instances per question (memory overhead, scene loading delays)

### 2. Signal-Based Communication
**Decision**: quiz_screen emits signals, gameplay_screen listens and orchestrates
**Rationale**:
- Decouples components (quiz_screen doesn't know about gameplay_screen)
- Follows Godot best practices
- Easy to test and extend
**Signals**:
- `quiz_screen.question_answered(was_correct: bool)` - Fired when answer selected
- `quiz_screen.next_question_requested()` - Fired when NextQuestion button pressed

### 3. Question Storage Strategy
**Decision**: Store fetched questions in gameplay_screen for entire round
**Rationale**:
- Both players need same questions (multiplayer requirement)
- Avoid multiple API calls
- TriviaQuestionService cache may be consumed
**Storage**: `fetched_questions: Array` cleared at start of each round

### 4. Result Component Lifecycle
**Decision**: Remove existing result components in `_ready()`, create num_rounds new ones
**Rationale**:
- User wants dynamic count based on num_rounds
- Clean slate prevents stale UI state
- Easier to manage than tracking which components are "used"
**Implementation**: 
```gdscript
# Remove all children from containers
for child in result_container_l.get_children():
    child.queue_free()
    
# Create num_rounds new components
for i in range(num_rounds):
    var component = result_component_scene.instantiate()
    component.initialize_empty(num_questions)  # New method
    result_container_l.add_child(component)
```

### 5. Result Component Initial State
**Decision**: Create new `initialize_empty()` method for grey/disabled state
**Rationale**:
- Existing `load_result_data()` requires complete data
- Need to show components before round completion
- Separates initialization from data loading
**Visual State**:
- Category symbol: greyscale or empty texture
- Answer buttons: disabled, greyed out, no icons

### 6. Category Popup as Overlay
**Decision**: Add category_popup as child of gameplay_screen, control via visibility
**Rationale**:
- Simple show/hide pattern
- Blocks interaction with background (modal behavior)
- No scene transitions needed
**Implementation**:
- Add to scene tree in `_ready()`
- `visible = false` by default
- Show with `category_popup.show()`, hide with `category_popup.hide()`

### 7. Loading State in Category Popup
**Decision**: category_popup_component manages its own loading state (buttons ↔ progress bar)
**Rationale**:
- Self-contained component
- Reusable in other contexts
- Clear separation of concerns
**States**:
- **Selection**: Category buttons visible, progress bar hidden
- **Loading**: Category buttons hidden, progress bar animating, headline changes to "Loading..."

### 8. Round Tracking with Top-to-Bottom Update
**Decision**: Track `current_round` (1-based), use to index into result containers
**Rationale**:
- Simple array indexing: `result_container_l.get_child(current_round - 1)`
- Clear progression visual
- Matches user's mental model (top = round 1, bottom = last round)

### 9. Question Distribution for Multiplayer
**Decision**: Store questions once, reuse for both players when multiplayer implemented
**Rationale**:
- Both players must answer identical questions per round
- Reduces API calls and cache consumption
- `fetched_questions` array can be reused
**Future**: When multiplayer implemented, track separate `player1_results` and `player2_results`

### 10. Error Handling Strategy
**Decision**: Silent fallback with console logging only
**Rationale**:
- User requested no visual error messages
- Fallback questions provide seamless experience
- Developers can debug via console
**Implementation**:
```gdscript
if error_occurred:
    print("API failed, using fallback questions")
    # Continue with fallback_questions
```

## Data Structures

### Round State
```gdscript
var current_round: int = 0  # 1-based when active, 0 when idle
var current_question_index: int = 0  # 0-based index into fetched_questions
var fetched_questions: Array = []  # Questions for current round
var current_round_results: Array = []  # {question_data, was_correct, player_answer}
var selected_category: String = ""  # For result display
```

### Result Component States
```
EMPTY → ACTIVE_ANSWERING → FILLED_WITH_RESULTS
```
- **EMPTY**: Grey buttons, no icons, disabled
- **ACTIVE_ANSWERING**: Still grey (updated in future)
- **FILLED_WITH_RESULTS**: Icons visible, enabled for review

## Integration Points

### TriviaQuestionService
- **Input**: `fetch_questions(category, num_questions)`
- **Output**: Signal `questions_ready(questions: Array)`
- **Error**: Signal `api_failed()` → use fallback
- **Categories**: Call `get_available_categories()` and pick 3 random

### Quiz Screen
- **Existing**: `load_question(data: Dictionary)`
- **Modified**: Control `NextQuestion` button visibility from quiz_screen itself
- **New Signals**: 
  - `question_answered(was_correct: bool)`
  - `next_question_requested()`

### Result Component
- **Existing**: `load_result_data(category_texture, results)`
- **New**: `initialize_empty(num_answer_buttons: int)` - Create disabled grey buttons

### TransitionManager
- **Not Used**: quiz_screen is child of gameplay_screen, no scene transitions during questions
- **Future Use**: When navigating away from gameplay_screen entirely

## Performance Considerations
- Single quiz_screen instance reuse (no scene instantiation overhead per question)
- Result components created once in `_ready()` (not per round)
- Questions fetched once per round (cached and reused)
- Minimal signal overhead (2 signals per question)

## Edge Cases

### Case 1: API Failure on First Question Fetch
- **Handling**: TriviaQuestionService emits `api_failed`, falls back to local questions
- **User Experience**: Progress bar completes, questions load seamlessly
- **Console**: Warning message logged

### Case 2: User Presses PlayButton Multiple Times
- **Handling**: Disable PlayButton when category popup is shown
- **Re-enable**: Only when returning to IDLE state after round

### Case 3: Result Components Exceed Container Height
- **Handling**: ScrollContainer (assumed already in UI, no code change needed)
- **User**: Responsible for UI layout

### Case 4: num_rounds = 0 or num_questions = 0
- **Handling**: No result components created, PlayButton remains disabled
- **Validation**: Should be caught in setup_screen (not this change's responsibility)

### Case 5: Less Than 3 Categories Available
- **Handling**: Show all available categories (TriviaQuestionService has 12 categories)
- **Edge**: If somehow < 3, show what's available

## Testing Strategy
- **Unit Tests**: Not in scope (manual testing per project conventions)
- **Integration Testing**:
  - Test full flow: PlayButton → Category → Questions → Results → PlayButton
  - Test API failure fallback
  - Test multiple round progression
  - Test result component updates (left side, top-to-bottom)

## Future Extensions (Out of Scope)
- Multiplayer turn alternation (player 1 chooses category, both answer, player 2 chooses, etc.)
- Timer per question
- Score calculation and display
- Category icons (currently using icon.svg placeholder)
- Question review from result component buttons
- Animations during round transitions
