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

### Requirement: The component SHALL display three answer outcome buttons
The result component SHALL display exactly 3 buttons in a horizontal layout that indicate correct or incorrect answers.

#### Scenario: Button layout structure
**Given** a result component scene  
**When** the scene loads  
**Then** an HBoxContainer contains exactly 3 Button nodes for answer indicators

#### Scenario: All buttons are visible
**Given** a result component before loading data  
**When** the scene is ready  
**Then** all 3 answer indicator buttons are visible and enabled

---

### Requirement: The component SHALL accept result data for three questions
The result component SHALL accept an array of exactly 3 question result entries containing question data and outcome information.

#### Scenario: Load result data with valid format
**Given** a result component instance  
**When** `load_result_data(texture, results)` is called with a Texture2D and an Array of 3 result dictionaries  
**Then** the component stores all data internally without errors

#### Scenario: Expected result data format
**Given** result data for a round  
**When** each entry contains "question_data" (Dictionary), "was_correct" (bool), and "player_answer" (String)  
**Then** the result component can parse and store this data correctly

#### Scenario: Validate array size
**Given** a result component receiving data  
**When** `load_result_data()` is called with an array that does not contain exactly 3 entries  
**Then** the component logs an error and does not process the invalid data

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

