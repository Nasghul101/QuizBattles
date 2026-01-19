# Tasks for add-answer-review-screen

## Tasks
- [x] Create answer_review_screen.gd script
- [x] Attach script to answer_review_screen.tscn
- [x] Modify gameplay_screen to capture player answer
- [x] Extend result_component to manage review screen
- [x] Update result_button_component data storage
- [x] Implement answer_review_screen data display logic
- [x] Configure modal overlay behavior
- [x] Manual integration testing

## Implementation Tasks

### 1. Create answer_review_screen.gd script
**Description**: Create GDScript file for answer_review_screen component with data loading and lifecycle methods.

**Steps**:
- Create `scenes/ui/components/answer_review_screen.gd`
- Add node references (`@onready`) for QuestionLabel, AnswersGrid, and BackButton
- Implement `load_review_data(question_data: Dictionary)` method to populate UI
- Implement `show_review()` and `hide_review()` methods for visibility management
- Connect BackButton.pressed signal to hide_review
- Set up answer buttons to display correct visual states based on question data

**Validation**: Script compiles without errors; methods accept correct parameter types.

---

### 2. Attach script to answer_review_screen.tscn
**Description**: Link the created script to the existing scene file.

**Steps**:
- Open `scenes/ui/components/answer_review_screen.tscn`
- Attach `answer_review_screen.gd` as root node script
- Verify unique names (%QuestionLabel, %AnswersGrid) are accessible

**Validation**: Scene loads without errors; script is attached to root Control node.

---

### 3. Modify gameplay_screen to capture player answer
**Description**: Update `_on_question_answered()` to store the player's selected answer text.

**Steps**:
- Modify `gameplay_screen.gd._on_question_answered()` signature to accept player answer text
- Update `quiz_screen.gd._on_answer_selected()` to emit `question_answered` signal with both correctness AND selected answer text
- Store player answer text in `current_round_results` dictionary entry

**Validation**: After answering a question, the result data includes "player_answer" field with correct text.

---

### 4. Extend result_component to manage review screen
**Description**: Pre-instantiate answer_review_screen, handle showing/hiding, and wire up signals.

**Steps**:
- Add `answer_review_screen` scene preload to `result_component.gd`
- Instantiate and add as child in `_ready()`, initially hidden
- Add as popup layer (z_index configuration or CanvasLayer)
- Connect to `question_review_requested` signal handler
- Implement `_show_answer_review(question_data: Dictionary)` to load and show review screen
- Ensure only one review screen shows at a time (hide before showing new one)
- Connect review screen's hide signal/callback to cleanup

**Validation**: Clicking a result button shows review screen; clicking back button hides it.

---

### 5. Update result_button_component data storage
**Description**: Ensure result buttons store and emit complete question data including player answer.

**Steps**:
- Verify `result_button_component.load_question_data()` receives full data including "player_answer"
- Verify `result_button_component._on_button_pressed()` emits complete data via `result_clicked` signal
- Update `result_component._update_button_states()` to pass complete result data (including player_answer) to buttons

**Validation**: Clicking a result button emits signal with dictionary containing question, correct_answer, incorrect_answers, was_correct, and player_answer.

---

### 6. Implement answer_review_screen data display logic
**Description**: Populate review screen with question data and configure answer button visual states.

**Steps**:
- In `load_review_data()`, set QuestionLabel text to question_data["question"]
- Create shuffled answers list (correct_answer + incorrect_answers), matching quiz_screen behavior
- Populate four answer buttons with shuffled answers
- For each button: disable interaction, set correct state (green) if matches correct_answer, set incorrect state (red) otherwise
- Add white outline border to button matching player_answer
- Ensure visual styling matches quiz_screen (same colors, same outline width)

**Validation**: Review screen displays correct question text, all four answers, green/red colors, and white outline on player's choice.

---

### 7. Configure modal overlay behavior
**Description**: Ensure review screen blocks interaction with gameplay screen and appears as popup.

**Steps**:
- Set `mouse_filter` property to `MOUSE_FILTER_STOP` on review screen root Control node
- Configure proper z-index or use CanvasLayer to ensure review screen appears above gameplay elements
- Test clicking outside review screen area - interaction should be blocked
- Verify back button properly dismisses overlay

**Validation**: When review screen is open, clicking gameplay screen elements has no effect; back button closes overlay.

---

### 8. Manual integration testing
**Description**: Test complete flow end-to-end.

**Steps**:
- Start game, select category, answer all questions in a round
- Click each result button (correct and incorrect ones)
- Verify correct question data appears for each button
- Verify player's selected answer has white outline
- Verify correct answer is green, wrong answers are red
- Test back button closes review and re-enables gameplay screen
- Test clicking multiple result buttons in sequence

**Validation**: All review screens show correct data; no crashes or visual glitches; back button works consistently.

---

## Dependencies & Ordering
- Task 1 and 2 can be done first (script creation)
- Task 3 should be done before Task 5 (data flow: gameplay → result_component → result_button)
- Task 4 should be done after Task 1-2 (result_component needs review screen to exist)
- Task 5 should be done after Task 3 (needs player answer data)
- Task 6 should be done after Task 1-2 (implements methods in review screen script)
- Task 7 should be done after Task 4 (configures instantiated screen)
- Task 8 should be done last (integration testing)

**Suggested order**: 1 → 2 → 3 → 5 → 4 → 6 → 7 → 8

---

## Estimated Effort
- **Task 1-2**: 30 minutes (script creation and attachment)
- **Task 3**: 15 minutes (simple data capture modification)
- **Task 4**: 30 minutes (integration with result_component)
- **Task 5**: 10 minutes (data verification, likely already correct)
- **Task 6**: 45 minutes (display logic with visual state management)
- **Task 7**: 15 minutes (modal configuration)
- **Task 8**: 20 minutes (manual testing)

**Total**: ~2.5 hours
