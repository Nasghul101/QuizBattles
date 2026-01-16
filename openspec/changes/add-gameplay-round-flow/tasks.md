# Tasks: Add Gameplay Round Flow

## Prerequisites
- [x] Review proposal.md and design.md
- [x] Verify category_popup_component.tscn exists with ProgressBar, 3 category buttons, and Headline label
- [x] Verify quiz_screen.tscn has NextQuestion button

## Implementation Tasks

### 1. Category Selection Popup Component
- [x] Create category_popup_component.gd script
- [x] Add node references for Category1, Category2, Category3 buttons, ProgressBar, Headline label
- [x] Implement `show_categories(categories: Array[String])` to populate buttons with random categories
- [x] Implement `show_loading()` to hide buttons, show progress bar, change headline to "Loading..."
- [x] Implement `hide_popup()` to make component invisible
- [x] Connect category button pressed signals to emit `category_selected(category_name: String)`
- [x] Implement progress bar animation (0-100% over ~1-2 seconds) during loading
- [x] Add signal `category_selected(category_name: String)`
- [ ] Test: Verify category buttons display random categories from TriviaQuestionService
- [ ] Test: Verify progress bar animates during loading state

### 2. Result Component Lifecycle Enhancement
- [x] Add `initialize_empty(num_answer_buttons: int)` method to result_component.gd
- [x] Remove any existing answer buttons in container
- [x] Dynamically create `num_answer_buttons` Button instances and add to answer_button_container
- [x] Set buttons to disabled state and grey visual appearance (modulate or disabled property)
- [x] Set category_symbol texture to greyscale or placeholder
- [x] Store `is_empty` state flag (true until load_result_data called)
- [ ] Test: Verify result components display correct number of grey disabled buttons
- [ ] Test: Verify buttons cannot be pressed when in empty state

### 3. Quiz Screen Flow Management Enhancement
- [x] Add signal `question_answered(was_correct: bool)` to quiz_screen.gd
- [x] Add signal `next_question_requested()` to quiz_screen.gd
- [x] Get reference to NextQuestion button (@onready var next_question_button)
- [x] Hide NextQuestion button in `_ready()` and when `load_question()` is called
- [x] In `_on_answer_selected()`, emit `question_answered(was_correct)` signal
- [x] In `_on_answer_selected()`, show NextQuestion button after answer revealed
- [x] Connect NextQuestion button pressed signal to emit `next_question_requested()`
- [ ] Test: Verify NextQuestion button appears only after answering
- [ ] Test: Verify signals emit correctly

### 4. Gameplay Round Orchestration - Initialization
- [x] Add @onready references to ResultContainerL and ResultContainerR in gameplay_screen.gd
- [x] Add @onready reference to PlayButton
- [x] Load result_component_scene (preload or load res://scenes/ui/components/result_component.tscn)
- [x] Load category_popup_scene and instantiate it
- [x] Load quiz_screen_scene and instantiate it (pre-instantiate, hidden)
- [x] In `_ready()`, remove all existing children from ResultContainerL and ResultContainerR
- [x] Create `num_rounds` result components for left container, call `initialize_empty(num_questions)` on each
- [x] Create `num_rounds` result components for right container, call `initialize_empty(num_questions)` on each
- [x] Add category_popup as child of gameplay_screen, set visible = false
- [x] Add quiz_screen as child of gameplay_screen, set visible = false
- [x] Connect PlayButton pressed signal to `_on_play_button_pressed()`
- [ ] Test: Verify correct number of result components created on both sides
- [ ] Test: Verify result components are grey and disabled

### 5. Gameplay Round Orchestration - State Variables
- [x] Add state variables: `current_round: int = 0` (0 = idle, 1+ = active round)
- [x] Add `current_question_index: int = 0`
- [x] Add `fetched_questions: Array = []`
- [x] Add `current_round_results: Array = []` (stores {question_data, was_correct, player_answer})
- [x] Add `selected_category: String = ""`
- [x] Add `icon_placeholder: Texture2D` (load icon.svg for category symbol)

### 6. Gameplay Round Orchestration - Category Selection Flow
- [x] Implement `_on_play_button_pressed()` to start category selection
- [x] Get 3 random categories from `TriviaQuestionService.get_available_categories()`
- [x] Show category_popup with `show_categories(random_categories)`
- [x] Hide PlayButton when popup shown
- [x] Connect category_popup `category_selected` signal to `_on_category_selected(category_name)`
- [ ] Test: Verify PlayButton shows category popup with 3 random categories
- [ ] Test: Verify PlayButton is hidden during selection

### 7. Gameplay Round Orchestration - Question Fetching
- [x] Implement `_on_category_selected(category_name: String)`
- [x] Store category_name in `selected_category`
- [x] Call `category_popup.show_loading()` to display progress bar
- [x] Connect to TriviaQuestionService signals if not already connected:
  - `questions_ready` → `_on_questions_ready(questions)`
  - `api_failed` → `_on_api_failed()`
- [x] Call `TriviaQuestionService.fetch_questions(category_name, num_questions)`
- [ ] Test: Verify loading state displays after category selection
- [ ] Test: Verify questions_ready signal received

### 8. Gameplay Round Orchestration - Question Loading Handler
- [x] Implement `_on_questions_ready(questions: Array)`
- [x] Store questions in `fetched_questions`
- [x] Hide category_popup
- [x] Set `current_question_index = 0`
- [x] Increment `current_round` (if 0, set to 1)
- [x] Clear `current_round_results = []`
- [x] Show quiz_screen
- [x] Load first question: `quiz_screen.load_question(fetched_questions[0])`
- [x] Connect quiz_screen signals if not already connected:
  - `question_answered` → `_on_question_answered(was_correct)`
  - `next_question_requested` → `_on_next_question_requested()`
- [ ] Test: Verify first question displays after questions loaded
- [ ] Test: Verify quiz_screen becomes visible

### 9. Gameplay Round Orchestration - Answer Tracking
- [x] Implement `_on_question_answered(was_correct: bool)`
- [x] Get current question data: `fetched_questions[current_question_index]`
- [x] Store result: `current_round_results.append({question_data: current_question_data, was_correct: was_correct, player_answer: ""})`
- [x] Note: player_answer extraction from quiz_screen is optional (can be empty string for now)
- [ ] Test: Verify results array populates after each answer

### 10. Gameplay Round Orchestration - Question Progression
- [x] Implement `_on_next_question_requested()`
- [x] Increment `current_question_index`
- [x] Check if more questions remain: `current_question_index < fetched_questions.size()`
- [x] If yes: Load next question with `quiz_screen.load_question(fetched_questions[current_question_index])`
- [x] If no: Call `_complete_round()` to finish round
- [ ] Test: Verify questions progress sequentially
- [ ] Test: Verify _complete_round called after last question

### 11. Gameplay Round Orchestration - Round Completion
- [x] Implement `_complete_round()`
- [x] Hide quiz_screen
- [x] Get result component for current round: `result_container_l.get_child(current_round - 1)`
- [x] Load results into component: `result_component.load_result_data(icon_placeholder, current_round_results)`
- [x] Repeat for right container: `result_container_r.get_child(current_round - 1).load_result_data(...)`
- [x] Check if all rounds complete: `current_round >= num_rounds`
- [x] If not complete: Show PlayButton for next round
- [x] If complete: Hide PlayButton, game over (future: show final results)
- [ ] Test: Verify result components update after round completion
- [ ] Test: Verify PlayButton reappears for next round
- [ ] Test: Verify PlayButton hidden after all rounds complete

### 12. Gameplay Round Orchestration - Error Handling
- [x] Implement `_on_api_failed()` (connected to TriviaQuestionService.api_failed)
- [x] Print console message: "API failed, using fallback questions"
- [x] Continue normal flow (questions_ready will still be emitted with fallback questions)
- [ ] Test: Verify fallback questions work when API fails
- [ ] Test: Verify console message appears

### 13. Integration Testing
- [ ] Test complete flow: setup_screen → gameplay_screen → PlayButton → category selection → questions → results
- [ ] Test multiple rounds: Complete 2-3 rounds, verify result components fill top-to-bottom
- [ ] Test both containers: Verify left and right result containers both update identically
- [ ] Test edge case: Only 1 round configured
- [ ] Test edge case: Many rounds (5+) configured
- [ ] Test API failure: Disconnect network, verify fallback works seamlessly

## Validation
- [ ] Run game from setup_screen with various configurations (1 round, 3 rounds, 5 rounds)
- [ ] Verify no errors in console during normal flow
- [ ] Verify result components display correct number of answer buttons
- [ ] Verify category popup shows different categories each time
- [ ] Verify progress bar animates smoothly
- [ ] Verify NextQuestion button only appears after answering

## Documentation
- [x] Add code comments to complex logic sections
- [x] Document signal flow in gameplay_screen.gd header comment
- [ ] Update any relevant diagrams or architecture docs if needed
