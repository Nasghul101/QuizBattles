# result-button-component Specification

## Purpose
TBD - created by archiving change refactor-result-component-to-use-result-button. Update Purpose after archive.
## Requirements
### Requirement: The component SHALL manage its own visual properties
The ResultButtonComponent SHALL define and control all UI properties including size, colors, icons, and modulation states internally without external configuration.

#### Scenario: Component defines minimum size
**Given** a ResultButtonComponent is instantiated
**When** the component initializes
**Then** custom_minimum_size is set to Vector2(30, 30) internally

#### Scenario: Component manages modulation
**Given** a ResultButtonComponent in different states
**When** the state changes between empty, correct, or incorrect
**Then** the component adjusts its own modulate property accordingly

---

### Requirement: The component SHALL load icon assets internally
The ResultButtonComponent SHALL load and manage the correct/incorrect icon assets without requiring external references.

#### Scenario: Load correct answer icon
**Given** a ResultButtonComponent initializes
**When** `_ready()` is called
**Then** icon_right is loaded from "res://assets/icon_right.png"

#### Scenario: Load incorrect answer icon
**Given** a ResultButtonComponent initializes
**When** `_ready()` is called
**Then** icon_wrong is loaded from "res://assets/icon_wrong.png"

---

### Requirement: The component SHALL expose state configuration methods
The ResultButtonComponent SHALL provide public methods to configure its visual state for correct, incorrect, empty, or hidden display modes.

#### Scenario: Set correct answer state
**Given** a ResultButtonComponent instance
**When** `set_correct_state()` is called
**Then** the button displays icon_right, is enabled, and has full color modulation

#### Scenario: Set incorrect answer state
**Given** a ResultButtonComponent instance
**When** `set_incorrect_state()` is called
**Then** the button displays icon_wrong, is enabled, and has full color modulation

#### Scenario: Set empty state
**Given** a ResultButtonComponent instance
**When** `set_empty_state()` is called
**Then** the button is disabled, displays no icon, and has grey modulation (0.5, 0.5, 0.5)

#### Scenario: Set hidden state
**Given** a ResultButtonComponent instance
**When** `set_hidden_state()` is called
**Then** the button displays icon_hidden, is disabled, and has full color modulation

---

### Requirement: The component SHALL emit custom signals when pressed
The ResultButtonComponent SHALL emit a custom signal containing question index and data when the button is pressed.

#### Scenario: Signal definition
**Given** the result_button_component.gd script
**When** the script is parsed
**Then** a signal named "result_clicked" is defined with parameters (question_index: int, question_data: Dictionary)

#### Scenario: Emit signal on button press
**Given** a ResultButtonComponent with stored question data
**When** the internal Button is pressed
**Then** the component emits "result_clicked(question_index, question_data)"

---

### Requirement: The component SHALL store question data
The ResultButtonComponent SHALL maintain internal storage for question index and question data to include in emitted signals.

#### Scenario: Store question index
**Given** a ResultButtonComponent receives data
**When** question data is assigned via a setter or configuration method
**Then** the question_index is stored internally

#### Scenario: Store question data dictionary
**Given** a ResultButtonComponent receives data
**When** question data is assigned
**Then** the complete question_data dictionary is stored internally

---

### Requirement: The component SHALL provide a hidden state for incomplete rounds
The ResultButtonComponent SHALL provide a `set_hidden_state()` method that displays a hidden/masked icon and disables interaction, used when opponent results should not be visible until both players complete a round.

**Rationale:** Support multiplayer-match-system requirement (line 210) that opponent answers must be hidden until round completion. The hidden state prevents information leakage while maintaining visual consistency.

#### Scenario: Set hidden state displays hidden icon
**Given** a ResultButtonComponent instance
**When** `set_hidden_state()` is called
**Then** the button displays icon_hidden texture
**And** the button remains at full color modulation (1.0, 1.0, 1.0)

#### Scenario: Hidden buttons are non-interactive
**Given** a ResultButtonComponent in hidden state
**When** `set_hidden_state()` is called
**Then** disabled is set to true
**And** the button does not respond to clicks

#### Scenario: Hidden state does not emit signals
**Given** a ResultButtonComponent in hidden state with loaded question data
**When** the user attempts to click the button
**Then** no "result_clicked" signal is emitted
**And** the button remains non-interactive

#### Scenario: Load hidden icon asset
**Given** a ResultButtonComponent with icon_hidden exported property
**When** the component is instantiated in a scene
**Then** icon_hidden is loaded from "res://assets/hidden.png" via the tscn export

---

### Requirement: The component SHALL follow GDScript style conventions
The ResultButtonComponent SHALL adhere to the official GDScript style guide and project documentation conventions.

#### Scenario: Documentation comments
**Given** the result_button_component.gd script
**When** reviewing the code
**Then** the class has a `##` doc comment describing its purpose

#### Scenario: Public method documentation
**Given** public methods like `set_correct_state()`, `set_incorrect_state()`, `set_empty_state()`
**When** reviewing the code
**Then** each public method has a `##` doc comment with description and parameter documentation

#### Scenario: Static typing
**Given** the result_button_component.gd script
**When** declaring variables and function parameters
**Then** static type hints are used where possible

