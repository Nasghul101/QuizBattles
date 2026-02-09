# multiplayer-match-system Specification

## ADDED Requirements

### Requirement: Store Match Data in UserDatabase
The system SHALL persist multiplayer match data in UserDatabase's JSON file storage under a `multiplayer_matches` array.

**Rationale:** Provide single source of truth for match state that persists across sessions and prepares for future Firebase migration.

#### Scenario: Database schema initialization
**Given** the game starts for the first time  
**When** UserDatabase loads  
**Then** `data.multiplayer_matches` is initialized as an empty array  
**And** the database is saved with the new schema

#### Scenario: Match structure completeness
**Given** a match is created  
**When** the match data is stored  
**Then** it includes `match_id`, `players`, `inviter`, `config`, `current_turn`, `current_round`, `status`, `rounds_data`, and `created_at` fields  
**And** `rounds_data` contains pre-initialized structures for all rounds

---

### Requirement: Create Multiplayer Match
UserDatabase SHALL provide a `create_match()` method that generates a new match with unique ID and initial state.

**Rationale:** Centralize match creation logic to ensure consistent initialization and proper data structure.

#### Scenario: Generate unique match ID
**Given** two players agree to play  
**When** `create_match(inviter, invitee, rounds, questions)` is called  
**Then** a unique `match_id` is generated using timestamp  
**And** the match_id follows format `"match_<unix_timestamp>"`

#### Scenario: Initialize inviter as first player
**Given** Player A invites Player B  
**When** the match is created  
**Then** `current_turn` is set to Player A's username  
**And** `current_round` is set to 1  
**And** `inviter` field contains Player A's username

#### Scenario: Pre-initialize round structures
**Given** a match with 3 rounds is created  
**When** the match is stored  
**Then** `rounds_data` contains 3 dictionaries  
**And** each round has `round_number`, `category`, `category_chooser`, `questions`, and `player_answers` fields  
**And** both players' `answered` flags are set to false

#### Scenario: Determine category choosers
**Given** a match with multiple rounds  
**When** the match is created  
**Then** odd-numbered rounds (1, 3, 5...) have `category_chooser` set to inviter  
**And** even-numbered rounds (2, 4, 6...) have `category_chooser` set to invitee

---

### Requirement: Retrieve Match by ID
UserDatabase SHALL provide a `get_match()` method that returns match data for a given match_id.

**Rationale:** Enable screens to load match state by unique identifier.

#### Scenario: Retrieve existing match
**Given** a match with ID "match_123" exists  
**When** `get_match("match_123")` is called  
**Then** the complete match Dictionary is returned  
**And** the Dictionary includes all match fields

#### Scenario: Handle non-existent match
**Given** no match with ID "match_999" exists  
**When** `get_match("match_999")` is called  
**Then** an empty Dictionary is returned  
**And** a warning is logged with the match_id

---

### Requirement: Retrieve Active Matches for Player
UserDatabase SHALL provide a `get_active_matches_for_player()` method that returns all active matches where a player is a participant.

**Rationale:** Enable friendly_battle_page to display all ongoing games for the current user.

#### Scenario: Filter matches by player
**Given** Player A has 3 active matches and Player B has 2 active matches  
**When** `get_active_matches_for_player("PlayerA")` is called  
**Then** only Player A's 3 matches are returned  
**And** Player B's matches are excluded

#### Scenario: Filter by active status
**Given** Player A has 2 active matches and 1 completed match  
**When** `get_active_matches_for_player("PlayerA")` is called  
**Then** only the 2 active matches are returned  
**And** the completed match is excluded

#### Scenario: Handle player with no matches
**Given** Player C has no matches  
**When** `get_active_matches_for_player("PlayerC")` is called  
**Then** an empty array is returned

---

### Requirement: Update Match State
UserDatabase SHALL provide an `update_match()` method that persists changes to match data.

**Rationale:** Enable gameplay_screen and other systems to save turn progress, answers, and state transitions.

#### Scenario: Update existing match
**Given** a match with ID "match_123" exists  
**When** modified match data with same match_id is passed to `update_match()`  
**Then** the match in the database is replaced with the new data  
**And** the database file is saved to disk

#### Scenario: Handle invalid match update
**Given** match data without a `match_id` field  
**When** `update_match(match_data)` is called  
**Then** an error is logged  
**And** no database changes occur

#### Scenario: Handle non-existent match update
**Given** no match with ID "match_999" exists  
**When** `update_match()` is called with match_id "match_999"  
**Then** a warning is logged  
**And** no database changes occur

---

### Requirement: Auto-Create Match on Invite Acceptance
UserDatabase SHALL listen to `GlobalSignalBus.game_invite_accepted` and automatically create a match with configuration from the notification.

**Rationale:** Decouple match creation from UI logic and ensure consistent match initialization.

#### Scenario: Create match when invite accepted
**Given** Player A sent a game invite to Player B with 3 rounds and 2 questions  
**When** Player B accepts the invite  
**And** `GlobalSignalBus.game_invite_accepted` is emitted  
**Then** UserDatabase creates a match between Player A and Player B  
**And** the match has 3 rounds and 2 questions configured

#### Scenario: Extract configuration from notification
**Given** a game invite notification with `action_data.rounds = 5` and `action_data.questions = 3`  
**When** the invite is accepted  
**Then** the created match has `config.rounds = 5` and `config.questions = 3`

#### Scenario: Handle missing notification data
**Given** no game invite notification found for the accepted invite  
**When** the match creation handler runs  
**Then** default values (3 rounds, 2 questions) are used  
**And** a match is still created

---

### Requirement: Track Current Turn
The match data SHALL maintain a `current_turn` field indicating which player should act next.

**Rationale:** Enable gameplay_screen to determine play button state and display turn status.

#### Scenario: Initialize turn to inviter
**Given** a new match is created  
**When** match initialization completes  
**Then** `current_turn` is set to the inviter's username

#### Scenario: Switch turn after round completion
**Given** Player A answers all questions in a round  
**And** Player B has not yet answered  
**When** Player A's answers are submitted  
**Then** `current_turn` is updated to Player B's username

#### Scenario: Advance turn to next round chooser
**Given** both players completed round N  
**When** the match advances to round N+1  
**Then** `current_turn` is set to round N+1's `category_chooser`

---

### Requirement: Track Round Progress
The match data SHALL maintain a `current_round` field (1-based) indicating the active round number.

**Rationale:** Enable proper round sequencing and completion detection.

#### Scenario: Initialize to round 1
**Given** a new match is created  
**When** match initialization completes  
**Then** `current_round` is set to 1

#### Scenario: Advance round after both players answer
**Given** both players completed all questions in round 2  
**When** the second player's answers are submitted  
**Then** `current_round` is incremented to 3

#### Scenario: Mark match complete after last round
**Given** both players completed all questions in the final round  
**When** the second player's answers are submitted  
**Then** `status` is set to "completed"  
**And** `current_round` remains at the final round number

---

### Requirement: Store Player Answers Per Round
The match data SHALL store each player's answers separately in `rounds_data[N].player_answers`.

**Rationale:** Enable answer comparison and result display after both players complete a round.

#### Scenario: Store answers after round completion
**Given** Player A answers 3 questions in round 1  
**When** Player A submits the last answer  
**Then** `rounds_data[0].player_answers["PlayerA"].answered` is set to true  
**And** `rounds_data[0].player_answers["PlayerA"].results` contains the 3 answer results

#### Scenario: Hide opponent answers until round complete
**Given** Player A has answered round 1  
**And** Player B has not answered round 1 yet  
**When** Player B loads the gameplay_screen  
**Then** Player B sees grey placeholders for Player A's answers  
**And** actual results are not visible to Player B

#### Scenario: Reveal opponent answers after round complete
**Given** both Player A and Player B have answered round 1  
**When** Player B submits the last answer  
**Then** both players' colored results are visible on the gameplay_screen  
**And** Player A can see Player B's results  
**And** Player B can see Player A's results

---

### Requirement: Store Questions for Opponent
The match data SHALL store the fetched questions in `rounds_data[N].questions` after the category chooser fetches them.

**Rationale:** Ensure both players answer identical questions for fair competition.

#### Scenario: Save questions after category selection
**Given** Player A chooses category "Science" in round 1  
**When** TriviaQuestionService returns 3 questions  
**Then** `rounds_data[0].questions` contains the 3 question dictionaries  
**And** `rounds_data[0].category` is set to "Science"

#### Scenario: Load saved questions for opponent
**Given** Player A chose category and answered 3 questions  
**When** Player B opens gameplay_screen for the same round  
**Then** Player B sees the exact same 3 questions Player A answered  
**And** no API call is made to fetch new questions

---

### Requirement: Support Multiple Simultaneous Matches
The system SHALL allow a player to have multiple active matches with different opponents concurrently.

**Rationale:** Enable rich social gameplay experience without artificial limitations.

#### Scenario: Create multiple matches for one player
**Given** Player A invites Player B  
**And** Player A invites Player C  
**When** both invites are accepted  
**Then** Player A has 2 active matches in the database  
**And** each match has a unique match_id

#### Scenario: Display all active matches
**Given** Player A has 3 active matches with different opponents  
**When** Player A navigates to friendly_battle_page  
**Then** 3 avatar_components are displayed  
**And** each avatar represents a different match

#### Scenario: Navigate to specific match
**Given** Player A has multiple active matches  
**When** Player A clicks on a specific avatar  
**Then** gameplay_screen loads the correct match by match_id  
**And** opponent data corresponds to the clicked avatar

---

### Requirement: Persist Match State Across Sessions
Match data SHALL persist to disk and reload on app restart.

**Rationale:** Enable asynchronous play where players can close and reopen the app between turns.

#### Scenario: Resume match after app restart
**Given** Player A answers questions and closes the app  
**When** Player A reopens the app  
**And** navigates to gameplay_screen for the match  
**Then** Player A's previous answers are still displayed  
**And** the play button state reflects the current turn

#### Scenario: Opponent can play after inviter closes app
**Given** Player A creates a match and closes the app  
**When** Player B accepts the invite  
**And** Player B clicks play  
**Then** Player B can choose category and answer questions  
**And** the match progresses even though Player A is offline

---
