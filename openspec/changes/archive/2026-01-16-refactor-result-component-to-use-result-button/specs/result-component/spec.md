# result-component Specification Delta

## ADDED Requirements

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

## REMOVED Requirements

### Requirement: The component SHALL display three answer outcome buttons
~~The result component SHALL display exactly 3 buttons in a horizontal layout that indicate correct or incorrect answers.~~

**Reason:** Replaced by support for variable button counts determined at initialization.

---

### Requirement: The component SHALL accept result data for three questions
~~The result component SHALL accept an array of exactly 3 question result entries containing question data and outcome information.~~

**Reason:** Replaced by support for variable result array sizes matching the number of instantiated buttons.

---

## Implementation Notes

### Removed Code
- Direct Button node instantiation logic
- Button UI property management (custom_minimum_size, modulate, icon assignment)
- Icon asset loading (icon_right, icon_wrong) from result_component
- Hardcoded AnswerButton1, AnswerButton2, AnswerButton3 nodes from scene file
- `answer_buttons_minimum_size` variable
- Direct button icon manipulation in `_update_button_icons()`

### Added Code
- Preloaded ResultButtonComponent scene reference
- ResultButtonComponent instantiation in `initialize_empty()`
- Signal connection to ResultButtonComponent's "result_clicked"
- Method calls to `set_correct_state()` and `set_incorrect_state()`
- Simplified signal forwarding in button press handler
