# gameplay-screen-initialization Specification Delta

## MODIFIED Requirements

### Requirement: Accept Match ID Parameter for Multiplayer
The gameplay_screen initialize() method SHALL accept an optional `match_id` parameter to enable multiplayer mode.

**Rationale:** Distinguish between single-player practice and multiplayer matches using the same screen.

#### Scenario: Initialize with match_id for multiplayer
**Given** a match with ID "match_123" exists in UserDatabase  
**When** `initialize({"match_id": "match_123"})` is called  
**Then** multiplayer mode is activated  
**And** match data is loaded from UserDatabase  
**And** `num_rounds` and `num_questions` are set from match config

#### Scenario: Initialize without match_id for single-player
**Given** no match_id is provided  
**When** `initialize({"rounds": 5, "questions": 3})` is called  
**Then** single-player mode is activated  
**And** `num_rounds` and `num_questions` are set from parameters  
**And** no match data is loaded

#### Scenario: Handle invalid match_id
**Given** match_id "match_invalid" does not exist  
**When** `initialize({"match_id": "match_invalid"})` is called  
**Then** an error is logged  
**And** the player is navigated back to main_lobby_screen

---

### Requirement: Enable Play Button Based on Turn State
The play button SHALL be enabled only when it is the player's turn AND they have not yet answered the current round.

**Rationale:** Enforce turn-based gameplay rules and prevent out-of-turn actions.

#### Scenario: Enable button on player's turn
**Given** a multiplayer match where current_turn equals the player's username  
**And** the player has not answered the current round  
**When** gameplay_screen loads  
**Then** the play button is enabled

#### Scenario: Disable button when not player's turn
**Given** a multiplayer match where current_turn equals the opponent's username  
**When** gameplay_screen loads  
**Then** the play button is disabled

#### Scenario: Disable button after answering round
**Given** the player has already answered the current round  
**When** gameplay_screen loads  
**Then** the play button is disabled  
**And** remains disabled until the opponent answers and the round advances

#### Scenario: Always enable in single-player mode
**Given** single-player mode (no match_id)  
**When** gameplay_screen loads  
**Then** the play button is always enabled

---

### Requirement: Conditional Category Selection
The gameplay_screen SHALL show category selection only if the current round's category is not yet chosen.

**Rationale:** First player in each round chooses category; second player uses pre-selected category.

#### Scenario: Show category popup as first player
**Given** a multiplayer round where category equals empty string  
**When** the play button is pressed  
**Then** the category selection popup is displayed  
**And** the player can choose from 3 random categories

#### Scenario: Skip category selection as second player
**Given** a multiplayer round where category is already set to "Science"  
**When** the play button is pressed  
**Then** no category popup is shown  
**And** quiz_screen loads immediately with the saved questions

---

### Requirement: Store Questions for Opponent
After the category chooser selects a category and receives questions, the gameplay_screen SHALL store those questions in the match data.

**Rationale:** Ensure both players answer identical questions for fair gameplay.

#### Scenario: Save questions after category selection
**Given** Player A chooses category "History"  
**When** TriviaQuestionService returns 3 questions  
**Then** the questions are stored in `match.rounds_data[current_round-1].questions`  
**And** the category "History" is stored in `match.rounds_data[current_round-1].category`  
**And** UserDatabase.update_match() is called

---

### Requirement: Submit Answers to Match Data
After answering all questions in a round, the gameplay_screen SHALL store the player's results in the match data.

**Rationale:** Enable opponent to view results and track match progress.

#### Scenario: Store player answers after round completion
**Given** Player A answers 3 questions in round 1  
**When** the last question is answered  
**Then** `match.rounds_data[0].player_answers["PlayerA"].answered` is set to true  
**And** `match.rounds_data[0].player_answers["PlayerA"].results` contains all 3 answer results  
**And** UserDatabase.update_match() is called

---

### Requirement: Switch Turn After Round Completion
After a player completes their questions, the gameplay_screen SHALL update the turn state based on opponent status.

**Rationale:** Manage turn alternation and round progression automatically.

#### Scenario: Switch turn to opponent when only one player answered
**Given** Player A completes round 1  
**And** Player B has not answered round 1 yet  
**When** Player A submits the last answer  
**Then** `match.current_turn` is set to Player B's username  
**And** the play button becomes disabled for Player A

#### Scenario: Advance round when both players answered
**Given** Player A completed round 1  
**And** Player B also completes round 1  
**When** Player B submits the last answer  
**Then** `match.current_round` is incremented to 2  
**And** `match.current_turn` is set to round 2's category_chooser

#### Scenario: Complete match after final round
**Given** both players completed all rounds  
**When** the last player submits their final answer  
**Then** `match.status` is set to "completed"  
**And** players are navigated to main_lobby_screen

---

### Requirement: Display Opponent Answers After Round Complete
When both players complete a round, the gameplay_screen SHALL reveal the opponent's results by updating result_components.

**Rationale:** Provide competitive feedback while maintaining suspense until both players finish.

#### Scenario: Hide opponent answers until round complete
**Given** Player A has answered round 1  
**And** Player B has not answered round 1 yet  
**When** Player B views gameplay_screen  
**Then** Player A's result_component shows grey placeholder buttons  
**And** no colored results are visible

#### Scenario: Reveal opponent answers after round complete
**Given** both Player A and Player B completed round 1  
**When** the second player submits their last answer  
**Then** both players' result_components update with colored buttons (green/red)  
**And** Player A can see Player B's right/wrong answers  
**And** Player B can see Player A's right/wrong answers

---

### Requirement: Load Existing Match State on Screen Open
When gameplay_screen opens with a match_id, it SHALL load and display all previous round results.

**Rationale:** Enable players to review past performance and understand match progress.

#### Scenario: Display previous round results
**Given** Player A previously completed rounds 1 and 2  
**And** Player B also completed rounds 1 and 2  
**When** Player A opens gameplay_screen for this match  
**Then** result_components for rounds 1 and 2 show colored results for both players  
**And** round 3's result_components show grey placeholders

---

### Requirement: Determine Opponent for Display
The gameplay_screen SHALL identify the opponent from match data and display their avatar on the left side.

**Rationale:** Provide clear visual distinction between current player (right) and opponent (left).

#### Scenario: Display opponent on left, player on right
**Given** a match between Player A and Player B  
**When** Player A views gameplay_screen  
**Then** Player B's avatar is shown on the left side  
**And** Player A's avatar is shown on the right side

---
