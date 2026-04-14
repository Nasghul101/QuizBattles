# Spec Delta — result-component
# Change: update-gameplay-screen-result-ui

## MODIFIED Requirements

### Requirement: load_result_data SHALL accept category name and both players' results
`load_result_data()` signature is changed from `(icon: Texture2D, results: Array)` to
`(category_name: String, p1_results: Array, p2_results: Array)`.
The `Texture2D` icon argument is removed. The category name is stored in `CategoryLabel.text`.

**Replaces:** static typing example in "GDScript style conventions" requirement that showed `Texture2D` parameter.

#### Scenario: Category name displayed
**Given** `load_result_data("Science & Nature", p1_results, p2_results)` is called  
**When** the component renders  
**Then** `CategoryLabel.text` equals `"Science & Nature"`

#### Scenario: Both players' results stored and displayed
**Given** p1_results has 3 entries and p2_results has 3 entries  
**When** `load_result_data()` is called  
**Then** `stored_results_p1` contains a deep copy of p1_results  
**And** `stored_results_p2` contains a deep copy of p2_results  
**And** P1 buttons reflect p1 correctness states  
**And** P2 buttons reflect p2 correctness states

---

### Requirement: The component SHALL expose set_round() to display the round number
`set_round(round_number: int)` SHALL update `RoundLabel.text` to `"Round %d" % round_number`.

#### Scenario: Round label text set
**Given** a result component after `initialize_empty(N)` has run  
**When** `set_round(3)` is called  
**Then** `RoundLabel.text` equals `"Round 3"`

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

### Requirement: hide_results() SHALL hide P2 buttons only
`hide_results()` SHALL set every button in `ResultButtonContainerP2` to hidden state,
leaving P1 buttons unaffected.

#### Scenario: P2 buttons hidden, P1 buttons unchanged
**Given** `load_result_data()` has been called  
**When** `hide_results()` is called  
**Then** all buttons in `ResultButtonContainerP2` are in hidden state  
**And** all buttons in `ResultButtonContainerP1` retain their current state
