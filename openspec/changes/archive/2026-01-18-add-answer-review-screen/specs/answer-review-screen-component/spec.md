# answer-review-screen-component Specification Delta

## ADDED Requirements

### Requirement: The component SHALL have a GDScript to manage data and visibility
The answer review screen component SHALL have an attached GDScript that handles loading question data, managing visibility, and controlling the modal overlay behavior.

#### Scenario: Script attachment
**Given** the answer_review_screen.tscn scene file  
**When** the scene is opened in the Godot editor  
**Then** a GDScript file "answer_review_screen.gd" is attached to the root Control node

#### Scenario: Node references
**Given** the answer_review_screen.gd script  
**When** the script initializes in `_ready()`  
**Then** it has @onready references to QuestionLabel, AnswersGrid, and BackButton using unique names

---

### Requirement: The component SHALL load and display question review data
The component SHALL accept question data and display it with appropriate visual states for all answer options.

#### Scenario: Load review data method signature
**Given** the answer_review_screen.gd script  
**When** calling the load_review_data method  
**Then** it accepts a Dictionary parameter with keys: "question", "correct_answer", "incorrect_answers", "player_answer"

#### Scenario: Display question text
**Given** question data with "question" key  
**When** `load_review_data(question_data)` is called  
**Then** the QuestionLabel text is set to question_data["question"]

#### Scenario: Populate answer buttons
**Given** question data with correct_answer and incorrect_answers  
**When** `load_review_data(question_data)` is called  
**Then** all four answer buttons in AnswersGrid are populated with shuffled answers (1 correct + 3 incorrect)

---

### Requirement: The component SHALL display answer visual states matching quiz_screen
The component SHALL use the existing answer_button component to display answers with green (correct), red (incorrect), and white outline (player's choice) visual states.

#### Scenario: Correct answer is green
**Given** a loaded review screen with answer buttons populated  
**When** an answer button contains the correct answer  
**Then** that button calls `reveal_correct()` to display green background

#### Scenario: Incorrect answers are red
**Given** a loaded review screen with answer buttons populated  
**When** an answer button contains an incorrect answer  
**Then** that button calls `reveal_wrong()` to display red background

#### Scenario: Player's choice has white outline
**Given** a loaded review screen with answer buttons populated  
**When** an answer button text matches question_data["player_answer"]  
**Then** that button's StyleBox has border_width set to 3 and border_color set to white (1.0, 1.0, 1.0, 1.0)

#### Scenario: Answer buttons are non-interactable
**Given** a loaded review screen with answer buttons populated  
**When** displaying the review  
**Then** all answer buttons have `disabled` property set to true

---

### Requirement: The component SHALL manage its own visibility
The component SHALL provide methods to show and hide itself, implementing modal overlay behavior.

#### Scenario: Show review method
**Given** the answer_review_screen.gd script  
**When** `show_review()` is called  
**Then** the component's `visible` property is set to true

#### Scenario: Hide review method
**Given** the answer_review_screen.gd script  
**When** `hide_review()` is called  
**Then** the component's `visible` property is set to false

#### Scenario: Initial state is hidden
**Given** the answer_review_screen component is instantiated  
**When** `_ready()` completes  
**Then** the component's `visible` property is false

---

### Requirement: The component SHALL handle back button interaction
The component SHALL connect to the back button's pressed signal and hide itself when clicked.

#### Scenario: Back button connection
**Given** the answer_review_screen.gd script in `_ready()`  
**When** the script initializes  
**Then** the BackButton.pressed signal is connected to a handler that calls `hide_review()`

#### Scenario: Back button dismisses overlay
**Given** a visible review screen  
**When** the back button is clicked  
**Then** the `hide_review()` method is called and the screen becomes invisible

---

### Requirement: The component SHALL block interaction with underlying elements
The component SHALL act as a modal overlay that prevents interaction with gameplay screen elements.

#### Scenario: Mouse filter configuration
**Given** the answer_review_screen root Control node  
**When** configured for modal behavior  
**Then** the `mouse_filter` property is set to `MOUSE_FILTER_STOP`

#### Scenario: Block clicks to underlying elements
**Given** a visible review screen overlaying the gameplay screen  
**When** the user clicks on the review screen background (not on buttons)  
**Then** the click does not reach elements behind the review screen

---

### Requirement: The component SHALL follow GDScript style conventions
The answer review screen component SHALL adhere to official GDScript style guide and project documentation conventions.

#### Scenario: Documentation comments
**Given** the answer_review_screen.gd script  
**When** reviewing the code  
**Then** the class has a `##` doc comment describing its purpose and usage

#### Scenario: Method documentation
**Given** public methods like `load_review_data()`, `show_review()`, `hide_review()`  
**When** reviewing the code  
**Then** each method has a `##` doc comment with description and parameter documentation

#### Scenario: Static typing
**Given** the answer_review_screen.gd script  
**When** declaring variables and function parameters  
**Then** static type hints are used (e.g., `func load_review_data(question_data: Dictionary) -> void`)
