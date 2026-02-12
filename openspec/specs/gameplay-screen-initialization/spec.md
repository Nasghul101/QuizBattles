# gameplay-screen-initialization Specification

## Purpose
TBD - created by archiving change add-game-setup-and-transition-logic. Update Purpose after archive.
## Requirements
### Requirement: Gameplay screen MUST provide initialization method for configuration
The gameplay screen SHALL provide a method to receive and store game configuration from external sources.

#### Scenario: Receive configuration on scene load
**Given** the gameplay screen is instantiated  
**When** the `initialize()` method is called with rounds=5 and questions=3  
**Then** the screen must store num_rounds=5  
**And** the screen must store num_questions=3  
**And** these values must be accessible throughout the scene's lifecycle

#### Scenario: Receive custom configuration
**Given** the gameplay screen is instantiated  
**When** the `initialize()` method is called with rounds=6 and questions=4  
**Then** the screen must store num_rounds=6  
**And** the screen must store num_questions=4

---

### Requirement: Gameplay screen MUST maintain configuration as instance variables
The gameplay screen SHALL maintain configuration values as instance variables for access by future game logic.

#### Scenario: Access stored configuration
**Given** the gameplay screen has been initialized with rounds=5 and questions=3  
**When** gameplay logic queries num_rounds  
**Then** the value must be 5  
**When** gameplay logic queries num_questions  
**Then** the value must be 3

---

### Requirement: Gameplay screen MUST use static typing for configuration parameters
The gameplay screen SHALL use static typing for configuration parameters to ensure type safety and prevent errors.

#### Scenario: Type validation at initialization
**Given** the gameplay screen script uses static typing  
**When** the `initialize()` method is called  
**Then** the rounds parameter must accept only integer values  
**And** the questions parameter must accept only integer values  
**And** passing non-integer types must result in compile-time or runtime error

---

### Requirement: Gameplay screen MUST handle initialization before or after ready
The gameplay screen SHALL be prepared to receive initialization before or after the `_ready()` callback.

#### Scenario: Initialize before ready
**Given** the gameplay screen is instantiated but not yet added to tree  
**When** the `initialize()` method is called  
**Then** the configuration must be stored successfully  
**And** the values must be available when `_ready()` is called

#### Scenario: Initialize after ready
**Given** the gameplay screen is added to tree and `_ready()` has executed  
**When** the `initialize()` method is called  
**Then** the configuration must be stored successfully  
**And** the values must override any defaults

---

### Requirement: Gameplay screen MUST have default configuration values
The gameplay screen SHALL have sensible default values if initialized without explicit configuration.

#### Scenario: Screen loaded without initialization
**Given** the gameplay screen is instantiated  
**When** `initialize()` is not called  
**And** the screen is added to the scene tree  
**Then** num_rounds must default to 0 or a safe null value  
**And** num_questions must default to 0 or a safe null value  
**And** future gameplay logic can detect uninitialized state

---

### Requirement: Configuration storage MUST be Firebase-compatible
The configuration storage SHALL be structured to easily integrate with Firebase persistence in the future.

#### Scenario: Data structure supports serialization
**Given** the gameplay screen stores configuration  
**When** Firebase integration is added later  
**Then** the num_rounds and num_questions variables must be easily serializable  
**And** the variable names must follow Firebase-friendly conventions (snake_case)  
**And** no complex nested structures that complicate persistence

---

### Requirement: Gameplay screen MUST initialize result component containers dynamically
The gameplay screen SHALL create result components dynamically based on num_rounds.

#### Scenario: Remove existing result components
**Given** ResultContainerL and ResultContainerR have child nodes from the tscn  
**When** `_ready()` executes  
**Then** all existing children in both containers are removed via `queue_free()`

#### Scenario: Create result components based on configuration
**Given** `num_rounds` is set to 3  
**When** `_ready()` executes after initialization  
**Then** 3 result component instances are created and added to ResultContainerL  
**And** 3 result component instances are created and added to ResultContainerR  
**And** each component is initialized with `initialize_empty(num_questions)`

#### Scenario: Handle variable round counts
**Given** `num_rounds` is set to 5  
**When** `_ready()` executes  
**Then** 5 result components are created in each container  
**Given** `num_rounds` is set to 1  
**When** `_ready()` executes  
**Then** 1 result component is created in each container

---

### Requirement: Gameplay screen MUST instantiate child components on ready
The gameplay screen SHALL create and configure category popup and quiz screen as children during initialization.

#### Scenario: Instantiate category popup
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** a category_popup_component instance is created  
**And** added as a child of gameplay screen  
**And** set to invisible by default

#### Scenario: Instantiate quiz screen
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** a quiz_screen instance is created  
**And** added as a child of gameplay screen  
**And** set to invisible by default

---

### Requirement: Gameplay screen MUST connect to child component signals
The gameplay screen SHALL establish signal connections during initialization to coordinate flow.

#### Scenario: Connect category popup signals
**Given** the category popup is instantiated  
**When** `_ready()` completes  
**Then** the `category_selected` signal is connected to `_on_category_selected` handler

#### Scenario: Connect quiz screen signals
**Given** the quiz screen is instantiated  
**When** `_ready()` completes  
**Then** the `question_answered` signal is connected to `_on_question_answered` handler  
**And** the `next_question_requested` signal is connected to `_on_next_question_requested` handler

#### Scenario: Connect service signals
**Given** the gameplay screen is ready  
**When** TriviaQuestionService signals are connected  
**Then** `questions_ready` is connected to `_on_questions_ready` handler  
**And** `api_failed` is connected to `_on_api_failed` handler

---

### Requirement: Gameplay screen MUST connect PlayButton signal
The gameplay screen SHALL respond to PlayButton presses to initiate round flow.

#### Scenario: Connect PlayButton
**Given** the gameplay screen has a PlayButton child node  
**When** `_ready()` executes  
**Then** the PlayButton `pressed` signal is connected to `_on_play_button_pressed` handler

---

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
**Then** answers are stored in match.rounds_data[0].player_a_answers  
**And** correct/incorrect flags are stored  
**And** UserDatabase.update_match() is called  
**And** current_turn is updated to Player B

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
**Then** `match.status` is set to "finished"  
**And** UserDatabase.update_match() is called  
**And** _show_finish_popup() is displayed with winner/draw  
**And** players remain on gameplay_screen viewing final scores

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

**Rationale:** Provide clear closure to the match with explicit winner announcement before dismissal.

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

#### Scenario: Show popup immediately for finished matches
**Given** gameplay_screen is initialized with a match_id for a finished match  
**When** _load_existing_match_state() completes  
**And** match status is "finished"  
**Then** FinishGamePopup is shown with winner/draw announcement  
**And** all round results are visible

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

### Requirement: Dismiss finished match when FinishGameButton is pressed
The gameplay screen SHALL add current player to dismissed_by list when FinishGameButton is clicked, and only delete match when both players have dismissed.

**Rationale:** Allow each player to dismiss finished matches independently without prematurely deleting for opponent.

#### Scenario: First player dismisses match
**Given** FinishGamePopup is showing for match "match_123"  
**And** dismissed_by array is empty  
**When** Player A clicks FinishGameButton  
**Then** Player A's username is added to dismissed_by array  
**And** UserDatabase.update_match() is called  
**And** the match is NOT deleted from the database  
**And** Player A navigates to main_lobby_screen

#### Scenario: Second player dismisses match and triggers deletion
**Given** FinishGamePopup is showing for match "match_123"  
**And** Player A already dismissed the match  
**When** Player B clicks FinishGameButton  
**Then** Player B's username is added to dismissed_by array  
**And** UserDatabase.delete_match("match_123") is called  
**And** the match is removed from multiplayer_matches array  
**And** Player B navigates to main_lobby_screen

#### Scenario: Display scores for resumed match
**Given** a match with 2 completed rounds exists in database  
**And** round 1 results show 2 correct for logged-in player  
**And** round 2 results show 1 correct for logged-in player  
**When** gameplay_screen loads this match  
**And** _load_existing_match_state() completes  
**Then** ScoreP1 displays "3"  
**And** scores reflect all completed rounds, not just visible ones

---

