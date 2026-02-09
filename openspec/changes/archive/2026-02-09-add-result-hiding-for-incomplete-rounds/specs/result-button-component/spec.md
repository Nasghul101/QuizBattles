# result-button-component Specification Delta

## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: The component SHALL expose state configuration methods
The ResultButtonComponent SHALL provide public methods to configure its visual state for correct, incorrect, empty, **or hidden** display modes.

**Changes:** Added hidden state support to the existing state configuration requirement.

#### Scenario: Set hidden state
**Given** a ResultButtonComponent instance
**When** `set_hidden_state()` is called
**Then** the button displays icon_hidden, is disabled, and has full color modulation

---

## REMOVED Requirements

None
