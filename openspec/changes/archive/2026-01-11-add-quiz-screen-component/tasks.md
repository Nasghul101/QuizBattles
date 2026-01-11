# Implementation Tasks: Add Quiz Screen Component

**Change ID:** `add-quiz-screen-component`

## Task List

### 1. Create quiz screen scene file
- [x] Create `scenes/ui/quiz_screen.tscn` in Godot editor
- [x] Add root node as `Control` type
- [x] Set up basic layout anchors for mobile portrait orientation
- [x] Save scene and generate `.uid` file

**Validation:** Scene file exists at correct path and opens without errors

---

### 2. Create question display panel
- [x] Add `Panel` node as child of root Control (name: `QuestionPanel`)
- [x] Add `Label` node as child of QuestionPanel (name: `QuestionLabel`)
- [x] Position panel at top of screen with appropriate margins
- [x] Configure label properties: autowrap enabled, align center, vertical center
- [x] Apply placeholder styling to panel (subtle background, rounded corners)

**Validation:** Question panel displays at top with label centered inside

---

### 3. Create answer button grid
- [x] Add `GridContainer` node as child of root Control (name: `AnswersGrid`)
- [x] Set GridContainer columns property to 2
- [x] Position grid below question panel with appropriate spacing
- [x] Instance `answer_button.tscn` 4 times as children of AnswersGrid
- [x] Name instances: `AnswerButton1`, `AnswerButton2`, `AnswerButton3`, `AnswerButton4`
- [x] Configure grid spacing and padding for mobile-friendly touch targets

**Validation:** 4 answer buttons arranged in 2x2 grid, properly spaced

---

### 4. Create quiz screen script
- [x] Create `scenes/ui/quiz_screen.gd` script file
- [x] Set script to extend `Control`
- [x] Add docstring comment describing component purpose and usage
- [x] Define `signal answer_correct` at top of script
- [x] Attach script to root node in `quiz_screen.tscn`

**Validation:** Script attached to scene, no syntax errors

---

### 5. Implement node references
- [x] Add `@onready` variables for QuestionLabel reference
- [x] Add `@onready` variable for AnswersGrid reference
- [x] Add `@onready` array variable for all 4 answer button references
- [x] Verify node paths are correct using Godot's autocomplete

**Validation:** All node references resolve without errors when scene runs

---

### 6. Implement load_question method
- [x] Create `load_question(data: Dictionary) -> void` public method
- [x] Add parameter validation to check required keys exist
- [x] Extract question text and set QuestionLabel.text
- [x] Extract correct_answer and incorrect_answers from data
- [x] Create combined array of all 4 answers
- [x] Store correct answer text for later validation

**Validation:** Method accepts dictionary and displays question text

---

### 7. Implement answer shuffling logic
- [x] In `load_question()`, shuffle the array of 4 answers using `Array.shuffle()`
- [x] Loop through shuffled answers and call `set_answer(text, index)` on each button
- [x] Store which button index received the correct answer
- [x] Ensure correct answer tracking persists after shuffle

**Validation:** Run multiple times; correct answer appears at different button positions

---

### 8. Connect answer button signals
- [x] In `_ready()` method, loop through all 4 answer buttons
- [x] Connect each button's `answer_selected` signal to handler method
- [x] Create handler method: `_on_answer_selected(answer_index: int) -> void`
- [x] Ensure connections persist and don't duplicate

**Validation:** Signal connections appear in Remote tab; pressing buttons triggers handler

---

### 9. Implement answer validation logic
- [x] In `_on_answer_selected()` handler, get selected button reference
- [x] Get text from selected button
- [x] Compare selected text with stored correct answer text
- [x] Set boolean flag `is_correct` based on comparison
- [x] Add debug print to verify validation works correctly

**Validation:** Selecting correct answer logs true; incorrect logs false

---

### 10. Implement button reveal logic
- [x] In `_on_answer_selected()`, loop through all 4 buttons
- [x] For each button, get its answer text
- [x] If text matches correct answer, call `button.reveal_correct()`
- [x] Otherwise, call `button.reveal_wrong()`
- [x] Ensure all buttons reveal immediately (no delays)

**Validation:** All buttons show green/red states after selection

---

### 11. Implement signal emission
- [x] In `_on_answer_selected()`, check if answer was correct
- [x] If correct, emit `answer_correct` signal
- [x] If incorrect, do not emit any signal
- [x] Remove or comment out debug prints

**Validation:** Connect test signal handler; verify signal emits only for correct answers

---

### 12. Implement interaction prevention
- [x] After validation, set all buttons to disabled
- [x] Alternatively, disconnect all button signals after first selection
- [x] Verify buttons cannot be pressed again after one selection

**Validation:** After selecting one button, other buttons do not respond to presses

---

### 13. Test with sample question data
- [x] Create test script or main scene to load quiz_screen
- [x] Create sample question dictionary with real question/answers
- [x] Call `load_question()` with sample data
- [x] Test selecting correct answer - verify green reveal and signal
- [x] Test selecting wrong answer - verify red reveal and no signal
- [x] Test multiple sequential questions to verify reset works

**Validation:** All scenarios work as expected with sample data

---

### 14. Visual polish and mobile testing
- [ ] Test on mobile resolution (portrait 1080x1920 or similar)
- [ ] Ensure touch targets are large enough (minimum 48x48 dp)
- [ ] Verify text is readable at mobile sizes
- [ ] Adjust margins, padding, and font sizes as needed
- [ ] Ensure layout adapts to different screen sizes

**Validation:** Component is usable and readable on mobile viewport

---

### 15. Code cleanup and documentation
- [x] Add GDScript docstring comments to all public methods
- [x] Add inline comments for complex logic (shuffling, validation)
- [x] Ensure consistent code formatting and indentation (spaces only)
- [x] Add static typing to all variables and function parameters
- [x] Remove any debug print statements

**Validation:** Code is clean, well-documented, and follows project conventions

---

## Dependencies

- Task 1 must complete before all other tasks
- Tasks 2-3 must complete before task 5
- Task 4 must complete before tasks 5-15
- Tasks 5-7 can be done in parallel after task 4
- Tasks 8-12 must be sequential
- Tasks 13-15 require all previous tasks complete

## Validation Summary

After completing all tasks:
- ✅ Scene loads without errors
- ✅ Question displays in top panel
- ✅ 4 answer buttons arranged in 2x2 grid
- ✅ Answers shuffle randomly on each load
- ✅ Correct answer validation works
- ✅ All buttons reveal states after selection
- ✅ `answer_correct` signal emits only for correct answers
- ✅ Cannot select multiple answers per question
- ⏳ Component is mobile-friendly and readable (needs testing in Task 14)
- ✅ Code is clean and documented
