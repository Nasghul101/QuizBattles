# result-component Specification

## Purpose
TBD - created by archiving change add-result-component. Update Purpose after archive.
## Requirements
### Requirement: The component SHALL display the category name as text
The result component SHALL set `CategoryLabel.text` to the category name string passed via `load_result_data()`. The old `CategorySymbol` TextureRect is no longer part of the component.

#### Scenario: Category label text set on load
**Given** a result component with initialized buttons  
**When** `load_result_data("Science", p1_results, p2_results)` is called  
**Then** `CategoryLabel.text` equals `"Science"`

#### Scenario: No category_symbol node required
**Given** the result_component.tscn scene  
**When** the scene loads  
**Then** no node named "CategorySymbol" is required or accessed by the script

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
**Then** static type hints are used where possible (e.g., `var category_name: String`, `func load_result_data(category_name: String, p1_results: Array, p2_results: Array) -> void`)

---

### Requirement: The component SHALL display both players' answer outcome buttons in separate containers
The result component SHALL populate **two** HBoxContainers — `ResultButtonContainerP1` and `ResultButtonContainerP2` — each holding the same number of `ResultButtonComponent` instances. The quantity is determined by the call to `initialize_empty(num_answer_buttons)`.

#### Scenario: Button instantiation in initialize_empty — P1
**Given** a result component at game start  
**When** `initialize_empty(num_answer_buttons)` is called with count N  
**Then** exactly N ResultButtonComponent instances are created and added to `ResultButtonContainerP1`

#### Scenario: Button instantiation in initialize_empty — P2
**Given** a result component at game start  
**When** `initialize_empty(num_answer_buttons)` is called with count N  
**Then** exactly N ResultButtonComponent instances are created and added to `ResultButtonContainerP2`

#### Scenario: Equal button counts
**Given** `initialize_empty(N)` is called  
**When** the component is ready  
**Then** `ResultButtonContainerP1.get_child_count()` equals `ResultButtonContainerP2.get_child_count()` equals N

#### Scenario: Variable button count support
**Given** a result component  
**When** `initialize_empty()` is called with different counts (1, 3, 5, etc.)  
**Then** both containers each hold the specified number of ResultButtonComponent instances

---

### Requirement: The component SHALL display the round number via set_round()
The result component SHALL expose a `set_round(round_number: int) -> void` method that sets `RoundLabel.text` to `"Round %d" % round_number`. The caller (gameplay screen) is responsible for passing the correct round number after instantiation.

#### Scenario: Set round label text
**Given** a result component is instantiated  
**When** `set_round(3)` is called  
**Then** `RoundLabel.text` equals `"Round 3"`

#### Scenario: First round
**Given** a result component  
**When** `set_round(1)` is called  
**Then** `RoundLabel.text` equals `"Round 1"`

---

### Requirement: The component SHALL accept separate P1 and P2 result data
The result component SHALL accept two result arrays — one per player — and configure the respective button containers.

New method signature: `load_result_data(category_name: String, p1_results: Array, p2_results: Array) -> void`

Both arrays must be non-empty and equal in size, and must not exceed the number of initialized buttons.

#### Scenario: Load P1 and P2 results
**Given** a result component with N initialized buttons per container  
**When** `load_result_data("History", p1_results, p2_results)` is called with arrays of size N  
**Then** P1 buttons are updated from `p1_results` and P2 buttons are updated from `p2_results`

#### Scenario: Arrays must be equal size
**Given** `p1_results.size() != p2_results.size()`  
**When** `load_result_data()` is called  
**Then** the component logs an error and does not process the invalid data

#### Scenario: Handle fewer results than buttons
**Given** both arrays have size M < N (fewer results than buttons)  
**When** `load_result_data()` is called  
**Then** the first M buttons in each container are configured; remaining buttons stay in empty state

#### Scenario: Validate array size is not larger than button count
**Given** `p1_results.size() > answer_buttons_p1.size()`  
**When** `load_result_data()` is called  
**Then** the component logs an error and does not process the data

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

### Requirement: The component SHALL hide only P2 buttons when hide_results() is called
`hide_results()` SHALL call `set_hidden_state()` only on `answer_buttons_p2` (opponent). P1 buttons (local player) are always visible.

#### Scenario: Hide only P2 buttons
**Given** a result_component with loaded P1 and P2 ResultButtonComponent instances  
**When** `hide_results()` is called  
**Then** `set_hidden_state()` is called on each P2 button  
**And** P1 buttons retain their current state

#### Scenario: Hide works regardless of current state
**Given** P2 buttons in mixed states (correct, incorrect, empty)  
**When** `hide_results()` is called  
**Then** all P2 buttons transition to hidden state

---

### Requirement: stored_results_p1 and stored_results_p2 SHALL replace the former stored_results array
Internal result storage is split into two arrays to support per-player score retrieval.

#### Scenario: stored_results_p1 accessible after load
**Given** `load_result_data()` has been called with valid p1_results  
**When** external code reads `stored_results_p1`  
**Then** it returns the stored p1 results array

#### Scenario: stored_results_p2 accessible after load
**Given** `load_result_data()` has been called with valid p2_results  
**When** external code reads `stored_results_p2`  
**Then** it returns the stored p2 results array

---
