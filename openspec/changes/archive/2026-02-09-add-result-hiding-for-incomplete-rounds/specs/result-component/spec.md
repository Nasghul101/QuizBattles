# result-component Specification Delta

## ADDED Requirements

### Requirement: The component SHALL provide a utility method to hide all results
The result_component SHALL expose a `hide_results()` method that sets all ResultButtonComponent instances to hidden state, used by gameplay_screen when opponent results should not be visible.

**Rationale:** Enable caller (gameplay_screen) to hide opponent results without requiring result_component to know about player/opponent concepts. Maintains separation of concerns and component modularity.

#### Scenario: Hide all result buttons
**Given** a result_component with N loaded ResultButtonComponent instances
**When** `hide_results()` is called
**Then** `set_hidden_state()` is called on each of the N ResultButtonComponent instances

#### Scenario: Hide works regardless of current state
**Given** a result_component with buttons in mixed states (correct, incorrect, empty)
**When** `hide_results()` is called
**Then** all buttons transition to hidden state
**And** previous states are overridden

#### Scenario: Hide works on empty components
**Given** a result_component initialized with `initialize_empty()`
**When** `hide_results()` is called before `load_result_data()`
**Then** all buttons transition to hidden state without errors

#### Scenario: Hide persists until explicitly changed
**Given** a result_component with hidden buttons
**When** time passes without calling other methods
**Then** the buttons remain in hidden state
**And** clicking them produces no response

#### Scenario: Method has proper documentation
**Given** the result_component.gd script
**When** reviewing the `hide_results()` method
**Then** a `##` doc comment explains the method's purpose
**And** the comment mentions use case for hiding opponent results

---

## MODIFIED Requirements

None

---

## REMOVED Requirements

None
