# gameplay-screen-initialization Spec Delta

## ADDED Requirements

### Requirement: Display cumulative score labels for multiplayer matches
The gameplay screen SHALL display running totals of correct answers for both players in ScoreP1 and ScoreP2 labels.

**Rationale:** Provide visual feedback of match progress and competitive standing throughout the game.

#### Scenario: Initialize score labels to zero for new match
**Given** a new multiplayer match is starting  
**When** gameplay_screen._ready() executes  
**Then** ScoreP1 label displays "0"  
**And** ScoreP2 label displays "0"

#### Scenario: Update scores after round completion
**Given** Player A completed round 1 with 2 correct answers out of 3  
**When** _display_round_results() completes for Player A  
**Then** ScoreP1 label displays "2"  
**And** ScoreP2 still displays "0" (opponent not revealed yet)

#### Scenario: Accumulate scores across multiple rounds
**Given** ScoreP1 currently shows "2" after round 1  
**And** Player A completes round 2 with 1 correct answer  
**When** _display_round_results() completes for round 2  
**Then** ScoreP1 label displays "3"  
**And** the score reflects cumulative total, not round-only count

#### Scenario: Hide scores in single-player mode
**Given** gameplay_screen is initialized with single-player configuration  
**When** rounds are completed  
**Then** ScoreP1 and ScoreP2 remain empty or hidden  
**And** no score calculation logic runs

---

### Requirement: Calculate scores from result component data
The gameplay screen SHALL count correct answers by iterating through result_component children and their stored_results arrays.

**Rationale:** Use result components as single source of truth for answer correctness to avoid data duplication.

#### Scenario: Count correct answers from result components
**Given** result_container_l has 2 result_components with visible results  
**And** first component has stored_results with 2 correct and 1 incorrect  
**And** second component has stored_results with 1 correct and 2 incorrect  
**When** _calculate_score_from_results(result_container_l) is called  
**Then** the method returns 3 (total correct answers)

#### Scenario: Skip empty result components
**Given** result_container_l has 3 result_components  
**And** first component has is_empty = false with 2 correct answers  
**And** second component has is_empty = true (not yet played)  
**When** _calculate_score_from_results(result_container_l) is called  
**Then** the method returns 2  
**And** empty component is excluded from count

#### Scenario: Handle zero correct answers
**Given** result_container_l has result_components with all incorrect answers  
**When** _calculate_score_from_results(result_container_l) is called  
**Then** the method returns 0

---

### Requirement: Display winner announcement popup when match completes
The gameplay screen SHALL show FinishGamePopup with winner name or "Draw" when both players complete the final round.

**Rationale:** Provide clear closure to the match with explicit winner announcement before returning to lobby.

#### Scenario: Show winner name when one player has more points
**Given** both players completed all rounds in a 3-round match  
**And** logged-in player username is "Alice"  
**And** ScoreP1 is 5 and ScoreP2 is 3  
**When** _show_finish_popup() is called  
**Then** WinnerDisplay.text is set to '"Alice" won'  
**And** FinishGamePopup.visible is true

#### Scenario: Show opponent name when opponent has more points
**Given** both players completed all rounds  
**And** opponent username is "Bob"  
**And** ScoreP1 is 3 and ScoreP2 is 5  
**When** _show_finish_popup() is called  
**Then** WinnerDisplay.text is set to '"Bob" won'

#### Scenario: Show draw when scores are equal
**Given** both players completed all rounds  
**And** ScoreP1 is 4 and ScoreP2 is 4  
**When** _show_finish_popup() is called  
**Then** WinnerDisplay.text is set to "Draw"  
**And** no player name is shown

---

### Requirement: Block background interaction when FinishGamePopup is visible
The gameplay screen SHALL prevent clicks on background elements when the finish popup is displayed.

**Rationale:** Ensure players acknowledge match completion and see final scores before navigating away.

#### Scenario: Prevent PlayButton clicks through popup
**Given** FinishGamePopup is visible  
**When** player clicks in the area of PlayButton behind the popup  
**Then** no action occurs  
**And** the popup remains visible

#### Scenario: Prevent BackButton clicks through popup
**Given** FinishGamePopup is visible  
**When** player clicks in the area of BackButton behind the popup  
**Then** no navigation occurs  
**And** the popup remains visible

---

### Requirement: Delete match and return to lobby on FinishGameButton press
The gameplay screen SHALL remove the finished match from the database and navigate to main_lobby_screen when FinishGameButton is clicked.

**Rationale:** Allow player to explicitly dismiss finished matches when ready.

#### Scenario: Delete match on button press
**Given** FinishGamePopup is showing for match "match_123"  
**When** FinishGameButton is clicked  
**Then** UserDatabase.delete_match("match_123") is called  
**And** the match is removed from multiplayer_matches array

#### Scenario: Navigate to lobby after deletion
**Given** FinishGameButton is clicked  
**When** match deletion completes  
**Then** TransitionManager.change_scene() is called with main_lobby_screen path  
**And** player returns to main lobby

---

## MODIFIED Requirements

### Requirement: Gameplay screen SHALL set match status to "finished" instead of deleting on completion

The gameplay screen SHALL set match status to "finished" and display FinishGamePopup when both players complete all rounds, instead of immediately deleting the match and navigating away.

**Rationale:** Preserve finished matches for display on friendly_battles_page and allow proper completion flow.

#### Scenario: Set status to finished when last round completes
**Given** both players completed all questions in the final round  
**When** second player's answers are submitted  
**Then** match_data.status is set to "finished"  
**And** UserDatabase.update_match() is called  
**And** UserDatabase.delete_match() is NOT called  
**And** FinishGamePopup is shown

#### Scenario: Do not navigate away immediately after match completion
**Given** both players completed the final round  
**When** _handle_round_completion() executes  
**Then** _show_finish_popup() is called  
**And** TransitionManager.change_scene() is NOT called at this point  
**And** player remains on gameplay_screen viewing final scores

---

### Requirement: Gameplay screen SHALL display cumulative scores when resuming matches

The gameplay screen SHALL calculate and display cumulative scores from already-completed rounds when loading an in-progress match.

**Rationale:** Provide consistent score visibility whether match is new or resumed.

#### Scenario: Display scores for resumed match
**Given** a match with 2 completed rounds exists in database  
**And** round 1 results show 2 correct for logged-in player  
**And** round 2 results show 1 correct for logged-in player  
**When** gameplay_screen loads this match  
**And** _load_existing_match_state() completes  
**Then** ScoreP1 displays "3"  
**And** scores reflect all completed rounds, not just visible ones

---

## Relationships
- **Depends on:** result-component (uses stored_results array with was_correct field)
- **Depends on:** multiplayer-match-system (uses match status field)
- **Related to:** friendly-battle-page (finished matches displayed there)
