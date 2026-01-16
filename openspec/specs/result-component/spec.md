# result-component Specification

## Purpose
TBD - created by archiving change add-result-component. Update Purpose after archive.
## Requirements
### Requirement: The component SHALL display a category texture
The result component SHALL display a category symbol/icon as a TextureRect at the top of the component.

#### Scenario: Category texture display
**Given** a result component is instantiated  
**When** `load_result_data(texture, results)` is called with a valid Texture2D  
**Then** the CategorySymbol TextureRect displays the provided texture

#### Scenario: Category texture node structure
**Given** the result_component.tscn scene  
**When** the scene loads  
**Then** a TextureRect node named "CategorySymbol" exists in the scene hierarchy

---

### Requirement: The component SHALL display correct/incorrect icons on buttons
The result component SHALL show icon_right.png for correct answers and icon_wrong.png for incorrect answers on the three answer buttons.

#### Scenario: Display correct answer icon
**Given** a result entry where "was_correct" is true  
**When** `load_result_data()` is called  
**Then** the corresponding button displays the icon_right.png texture

#### Scenario: Display incorrect answer icon
**Given** a result entry where "was_correct" is false  
**When** `load_result_data()` is called  
**Then** the corresponding button displays the icon_wrong.png texture

#### Scenario: Icon asset paths
**Given** the result component loading icons  
**When** setting button icons  
**Then** icon_right.png is loaded from "res://assets/icon_right.png" and icon_wrong.png from "res://assets/icon_wrong.png"

---

### Requirement: The component SHALL store question data for review
The result component SHALL store complete question data and outcome information for all three questions to enable review functionality.

#### Scenario: Store question data
**Given** a result component receiving data via `load_result_data()`  
**When** the data contains question dictionaries in Open Trivia DB format  
**Then** all question data is stored internally and accessible for later retrieval

#### Scenario: Store answer outcomes
**Given** result data with correctness information  
**When** `load_result_data()` is called  
**Then** the "was_correct" and "player_answer" fields are stored for each question

---

### Requirement: The component SHALL emit signals when answer buttons are clicked
The result component SHALL emit a signal containing the question index and stored question data when an answer indicator button is pressed.

#### Scenario: Signal definition
**Given** the result_component script  
**When** the script is parsed  
**Then** a signal named "question_review_requested" is defined with parameters (question_index: int, question_data: Dictionary)

#### Scenario: Emit signal on button click
**Given** a result component with loaded data  
**When** the user clicks the second answer button (index 1)  
**Then** the component emits "question_review_requested(1, question_data_for_index_1)"

#### Scenario: Signal contains complete data
**Given** an answer button is clicked  
**When** the "question_review_requested" signal is emitted  
**Then** the signal payload includes the complete question data dictionary with question, correct_answer, incorrect_answers, was_correct, and player_answer

---

### Requirement: The component SHALL follow GDScript style conventions
The result component SHALL adhere to the official GDScript style guide and project documentation conventions.

#### Scenario: Documentation comments
**Given** the result_component.gd script  
**When** reviewing the code  
**Then** the class has a `##` doc comment describing its purpose

#### Scenario: Public method documentation
**Given** public methods like `load_result_data()`  
**When** reviewing the code  
**Then** each public method has a `##` doc comment with description and parameter documentation

#### Scenario: Static typing
**Given** the result_component.gd script  
**When** declaring variables and function parameters  
**Then** static type hints are used where possible (e.g., `var texture: Texture2D`, `func load_result_data(texture: Texture2D, results: Array) -> void`)

---

### Requirement: The component SHALL display answer outcome buttons
The result component SHALL dynamically instantiate ResultButtonComponent instances to indicate correct or incorrect answers, with the quantity determined by the number of questions.

#### Scenario: Button instantiation in initialize_empty
**Given** a result component at game start
**When** `initialize_empty(num_answer_buttons)` is called with count N
**Then** exactly N ResultButtonComponent instances are created and added to the AnswerButtonContainer

#### Scenario: Button layout structure
**Given** a result component scene
**When** the scene loads
**Then** an HBoxContainer named "AnswerButtonContainer" exists to hold dynamically created ResultButtonComponent instances

#### Scenario: Variable button count support
**Given** a result component
**When** `initialize_empty()` is called with different counts (1, 3, 5, etc.)
**Then** the component creates the specified number of ResultButtonComponent instances

---

### Requirement: The component SHALL accept result data for questions
The result component SHALL accept an array of question result entries and configure ResultButtonComponent instances accordingly, supporting variable question counts.

#### Scenario: Load result data with variable size
**Given** a result component instance
**When** `load_result_data(texture, results)` is called with an Array of N result dictionaries
**Then** the first N ResultButtonComponent instances are configured with result data

#### Scenario: Handle fewer results than buttons
**Given** a result component with more button instances than results
**When** `load_result_data()` is called
**Then** unused ResultButtonComponent instances remain in empty state

#### Scenario: Validate array size constraints
**Given** a result component receiving data
**When** `load_result_data()` is called with more results than button instances
**Then** the component logs an error and does not process the invalid data

---

### Requirement: The component SHALL configure ResultButtonComponent states
The result component SHALL call ResultButtonComponent methods to set correct/incorrect states instead of directly manipulating button properties.

#### Scenario: Configure correct answer state
**Given** a result entry where "was_correct" is true
**When** `load_result_data()` is called
**Then** the corresponding ResultButtonComponent's `set_correct_state()` method is called

#### Scenario: Configure incorrect answer state
**Given** a result entry where "was_correct" is false
**When** `load_result_data()` is called
**Then** the corresponding ResultButtonComponent's `set_incorrect_state()` method is called

---

### Requirement: The component SHALL connect to ResultButtonComponent signals
The result component SHALL connect to the ResultButtonComponent's "result_clicked" signal and forward the data through its own "question_review_requested" signal.

#### Scenario: Connect to child component signals
**Given** ResultButtonComponent instances are created
**When** `initialize_empty()` instantiates each component
**Then** the result_component connects to each ResultButtonComponent's "result_clicked" signal

#### Scenario: Forward button press events
**Given** a ResultButtonComponent emits "result_clicked(index, data)"
**When** result_component receives the signal
**Then** result_component emits "question_review_requested(index, data)"

---

