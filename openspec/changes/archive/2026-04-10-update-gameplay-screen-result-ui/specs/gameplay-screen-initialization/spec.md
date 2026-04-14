# Spec Delta — gameplay-screen-initialization
# Change: update-gameplay-screen-result-ui

## MODIFIED Requirements

### Requirement: Gameplay screen MUST display player names in the header
The gameplay screen SHALL populate the `NameP1` and `NameP2` labels in the scene header during `_ready()`.

#### Scenario: Multiplayer — both labels populated
**Given** the gameplay screen is in multiplayer mode  
**And** `initialize({"match_id": ...})` has been called  
**When** `_ready()` completes  
**Then** `NameP1.text` equals `UserDatabase.current_user.username`  
**And** `NameP2.text` equals `opponent_username`

#### Scenario: Single-player — NameP2 left blank
**Given** the gameplay screen is in single-player mode  
**When** `_ready()` completes  
**Then** `NameP1.text` equals `UserDatabase.current_user.username`  
**And** `NameP2.text` equals `""`

---

### Requirement: Gameplay screen MUST initialize result components in a single container
The gameplay screen SHALL create `num_rounds` result components exclusively inside the single `ResultContainer` node.
The previous dual-container design (`ResultContainerL` / `ResultContainerR`) is removed.

**Replaces:** former requirement "Gameplay screen MUST initialize result component containers dynamically"

#### Scenario: Correct number of components created
**Given** `num_rounds` is 6  
**When** `_initialize_result_components()` runs  
**Then** exactly 6 result component instances are children of `ResultContainer`

#### Scenario: Each component is initialised with button count and round number
**Given** `num_questions` is 3  
**And** `num_rounds` is 6  
**When** `_initialize_result_components()` runs  
**Then** each result component has `initialize_empty(3)` called  
**And** has `set_round(i + 1)` called (where `i` is the 0-based loop index)

---

### Requirement: Gameplay screen MUST call load_result_data with the updated dual-results signature
All calls to `result_component.load_result_data()` SHALL use the signature
`load_result_data(category_name: String, p1_results: Array, p2_results: Array)`.

#### Scenario: Single-player round completion
**Given** the player finishes all questions for a round  
**When** `_complete_round()` runs  
**Then** `load_result_data(selected_category, current_round_results, [])` is called on the matching component  
**And** `hide_results()` is called immediately after to hide the empty P2 buttons

#### Scenario: Multiplayer — both players answered
**Given** both players have answered a round  
**When** `_display_round_results(round_idx)` runs  
**Then** `load_result_data(category_name, p1_results, p2_results)` is called on `result_container.get_child(round_idx)`  
**Where** `category_name` is `match_data.rounds_data[round_idx].category`  
**And** `p1_results` is the current player's answers for that round  
**And** `p2_results` is the opponent's answers for that round

#### Scenario: Multiplayer — opponent results hidden until both answer
**Given** the current player has answered but the opponent has not  
**When** `_load_existing_match_state()` processes that round  
**Then** `hide_results()` is called on `result_container.get_child(round_idx)`

---

### Requirement: Gameplay screen MUST calculate scores from the unified result container
`_calculate_score_from_results()` SHALL iterate the single `ResultContainer` and sum correct answers
from `stored_results_p1` (for P1 score) or `stored_results_p2` (for P2 score).

**Replaces:** former signature `_calculate_score_from_results(container: VBoxContainer) -> int`

#### Scenario: P1 score calculated correctly
**Given** two completed rounds where P1 answered 2 correct in round 1 and 3 correct in round 2  
**When** `_calculate_score_from_results("p1")` is called  
**Then** the return value is 5

#### Scenario: P2 score calculated correctly
**Given** two completed rounds where P2 answered 1 correct in round 1 and 2 correct in round 2  
**When** `_calculate_score_from_results("p2")` is called  
**Then** the return value is 3

#### Scenario: Empty components skipped
**Given** a result component with `is_empty == true`  
**When** either score is calculated  
**Then** that component contributes 0 to the total
