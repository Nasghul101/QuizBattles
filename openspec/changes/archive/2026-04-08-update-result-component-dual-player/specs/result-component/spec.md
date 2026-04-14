# Spec Delta: result-component (update-result-component-dual-player)

## MODIFIED Requirements

### Requirement: The component SHALL display both players' answer outcome buttons in separate containers
The result component SHALL populate **two** HBoxContainers — `ResultButtonContainerP1` and `ResultButtonContainerP2` — each holding the same number of `ResultButtonComponent` instances. The quantity is determined by the call to `initialize_empty(num_answer_buttons)`.

Replaces the previous requirement that created buttons in a single `AnswerButtonContainer`.

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

### Requirement: The component SHALL display the category name as text
The result component SHALL set `CategoryLabel.text` to the category name string passed via `load_result_data()`. The old `CategorySymbol` TextureRect is no longer part of the component.

Replaces the previous requirement that displayed a Texture2D on a CategorySymbol TextureRect.

#### Scenario: Category label text set on load
**Given** a result component with initialized buttons  
**When** `load_result_data("Science", p1_results, p2_results)` is called  
**Then** `CategoryLabel.text` equals `"Science"`

#### Scenario: No category_symbol node required
**Given** the result_component.tscn scene  
**When** the scene loads  
**Then** no node named "CategorySymbol" is required or accessed by the script

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

### Requirement: The component SHALL hide only P2 buttons when hide_results() is called
`hide_results()` SHALL call `set_hidden_state()` only on `answer_buttons_p2` (opponent). P1 buttons (local player) are always visible.

Replaces the previous behavior of hiding all buttons.

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

## REMOVED Requirements

### Requirement: The component SHALL display a category texture
REMOVED — The `CategorySymbol` TextureRect node no longer exists in the scene. Category information is now displayed as text via `CategoryLabel`.

### Requirement: button layout structure references AnswerButtonContainer
REMOVED — `AnswerButtonContainer` no longer exists. Replaced by `ResultButtonContainerP1` and `ResultButtonContainerP2`.
