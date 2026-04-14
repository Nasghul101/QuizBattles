# answer-review-screen Specification

## Purpose
A modal overlay component that displays a completed quiz question with all four
answer options in their revealed states (correct = green, incorrect = red) and
highlights the player's selected answer with a white shader outline. Instantiated
by `result_component` and shown when a result button is clicked.

## Requirements

### Requirement: The component SHALL have a GDScript to manage data and visibility
The answer review screen component SHALL have an attached GDScript that handles
loading question data, managing visibility, and controlling modal overlay behavior.

#### Scenario: Script attachment
**Given** the answer_review_screen.tscn scene file  
**When** the scene is opened in the Godot editor  
**Then** a GDScript file "answer_review_screen.gd" is attached to the root Control node

#### Scenario: Node references
**Given** the answer_review_screen.gd script  
**When** the script initializes in `_ready()`  
**Then** it has `@onready` references to `QuestionLabel` and `AnswersGrid` using unique names

---

### Requirement: The component SHALL load and display question review data
The component SHALL accept question data and populate all four answer buttons with
the correct text and visual states.

#### Scenario: Load review data method signature
**Given** the answer_review_screen.gd script  
**When** calling `load_review_data`  
**Then** it accepts a Dictionary with keys: "question", "correct_answer",
"incorrect_answers", "player_answer"

#### Scenario: Display question text
**Given** question data with a "question" key  
**When** `load_review_data(question_data)` is called  
**Then** `QuestionLabel.text` equals question_data["question"]

#### Scenario: Populate answer buttons via set_answer API
**Given** question data with correct_answer and incorrect_answers  
**When** `load_review_data(question_data)` is called  
**Then** all four answer buttons are populated via `button.set_answer(answer_text, i)`;
no `.text` property is assigned directly

---

### Requirement: The component SHALL display answer visual states using answer_button API
The component SHALL use the `answer_button` public methods exclusively to set visual
states. No direct StyleBox manipulation is permitted. All buttons are set to a static
(non-pulsating) state.

#### Scenario: Pulsating disabled on all buttons
**Given** a loaded review screen  
**When** `load_review_data()` runs  
**Then** `set_pulsating_enabled(false)` is called on every answer button

#### Scenario: Correct answer is green
**Given** a loaded review screen  
**When** an answer button holds the correct answer  
**Then** `reveal_correct()` is called on that button

#### Scenario: Incorrect answers are red
**Given** a loaded review screen  
**When** an answer button holds an incorrect answer  
**Then** `reveal_wrong()` is called on that button

#### Scenario: Player's choice has white shader outline
**Given** a loaded review screen  
**When** the answer button text matches question_data["player_answer"]  
**Then** `set_shader_outline_color(Color.WHITE)` is called on that button

#### Scenario: Answer buttons are non-interactable
**Given** a loaded review screen  
**When** displaying the review  
**Then** all answer buttons have `disabled = true`

---

### Requirement: The component SHALL manage its own visibility
The component SHALL provide `show_review()` and `hide_review()` methods and start hidden.

#### Scenario: Initial state is hidden
**Given** the answer_review_screen component is instantiated  
**When** `_ready()` completes  
**Then** `visible` is `false`

#### Scenario: show_review makes component visible
**Given** the component is hidden  
**When** `show_review()` is called  
**Then** `visible` is `true`

#### Scenario: hide_review makes component invisible
**Given** the component is visible  
**When** `hide_review()` is called  
**Then** `visible` is `false`

---

### Requirement: The component SHALL handle back button interaction
The component SHALL connect to the BackButton pressed signal and hide itself when clicked.

#### Scenario: Back button dismisses overlay
**Given** a visible review screen  
**When** the back button is clicked  
**Then** `hide_review()` is called and the component becomes invisible

---

### Requirement: The component SHALL block interaction with underlying elements
The component SHALL act as a modal overlay that prevents interaction with elements below it.

#### Scenario: Mouse filter configuration
**Given** the answer_review_screen root Control node  
**When** configured for modal behavior  
**Then** `mouse_filter` is set to `MOUSE_FILTER_STOP`

---

### Requirement: The component SHALL follow GDScript style conventions
The answer review screen component SHALL adhere to the official GDScript style guide
and project documentation conventions.

#### Scenario: Documentation comments
**Given** answer_review_screen.gd  
**When** reviewing the code  
**Then** the class has a `##` doc comment describing purpose and usage

#### Scenario: Static typing
**Given** answer_review_screen.gd  
**When** declaring variables and function parameters  
**Then** static type hints are used (e.g. `func load_review_data(question_data: Dictionary) -> void`)
