# friendly-battle-page Spec Delta

## ADDED Requirements

### Requirement: Display Active Multiplayer Matches with Friendly Duel Buttons
The friendly_battle_page SHALL display friendly_duel_button_l and friendly_duel_button_r instances (alternating) for each active multiplayer match involving the current user.

**Rationale:** Provide visual overview of ongoing quiz duels with richer game state information directly on the button, including cumulative scores, current round, and opponent name. The dual-button design creates a visually balanced layout.

#### Scenario: Load matches on page open
**Given** Player A has 2 active matches  
**When** friendly_battle_page becomes visible  
**Then** 2 friendly_duel_button instances are created  
**And** first button is instantiated in FriendsListL container  
**And** second button is instantiated in FriendsListR container  
**And** each button corresponds to a different match

#### Scenario: Alternate button placement for multiple matches
**Given** Player A has 5 active matches  
**When** friendly_battle_page populates the lists  
**Then** buttons are placed in order: L, R, L, R, L  
**And** FriendsListL contains 3 buttons  
**And** FriendsListR contains 2 buttons

#### Scenario: Only show active matches
**Given** Player A has 2 active matches and 1 finished match  
**When** friendly_battle_page loads  
**Then** only 2 buttons are displayed  
**And** the finished match does NOT appear in either list

#### Scenario: Empty state when no active matches
**Given** Player A has no active matches (only finished or dismissed)  
**When** friendly_battle_page loads  
**Then** NoMatchesLabel is visible  
**And** no buttons are instantiated

---

### Requirement: Display Cumulative Match Scores on Button
Each friendly_duel_button SHALL display the cumulative score (total correct answers) for both the player and opponent across all completed rounds.

**Rationale:** Provide at-a-glance information about match progress and current standings without requiring navigation.

#### Scenario: Calculate player's cumulative score
**Given** a match where Player A has completed 2 rounds  
**And** Round 1: Player A answered 2/3 correct  
**And** Round 2: Player A answered 3/3 correct  
**When** the button is populated  
**Then** `set_player_points(5)` is called  
**And** button displays "5" as player score

#### Scenario: Calculate opponent's cumulative score
**Given** a match where Player B has completed 2 rounds  
**And** Round 1: Player B answered 1/3 correct  
**And** Round 2: Player B answered 2/3 correct  
**When** the button is populated  
**Then** `set_opponents_points(3)` is called  
**And** button displays "3" as opponent score

#### Scenario: Handle unanswered rounds
**Given** a match where Player A has completed 1 round  
**And** Round 2 is not yet answered by Player A  
**When** calculating Player A's score  
**Then** only Round 1 results are counted  
**And** Round 2 does not contribute to the score

---

### Requirement: Display Current Round Number on Button
Each friendly_duel_button SHALL display the current round number from match.current_round.

**Rationale:** Inform players of their progress through the match (e.g., "Round: 2" out of 6 total).

#### Scenario: Display current round in progress
**Given** a match with current_round = 3  
**When** the button is populated  
**Then** `set_round_count(3)` is called  
**And** button displays "Round: 3"

#### Scenario: Round number updates after page refresh
**Given** a match currently on round 2  
**And** Player A completes round 2 in gameplay_screen  
**And** match.current_round is now 3  
**When** Player A returns to friendly_battle_page  
**Then** _populate_active_matches() is called (via NOTIFICATION_VISIBILITY_CHANGED)  
**And** button updates to display "Round: 3"

---

### Requirement: Display Opponent Name on Button
Each friendly_duel_button SHALL display the opponent's username via set_opponent_name().

**Rationale:** Provide clear identification of who the player is competing against without requiring hover or click.

#### Scenario: Show opponent's username
**Given** Player A has a match with Player B  
**When** the button is populated  
**Then** `set_opponent_name("PlayerB")` is called  
**And** button displays "PlayerB" in the opponent name label

---

### Requirement: Indicate Turn Status via Button Highlighting
Each friendly_duel_button SHALL use highlight() when it's the player's turn and un_highlight() when it's the opponent's turn.

**Rationale:** Provide immediate visual feedback about which matches require player action, replacing text-based turn indicators with a clearer visual cue.

#### Scenario: Highlight button when player's turn
**Given** an active match where match.current_turn equals the current user's username  
**When** the button is populated  
**Then** `button.highlight()` is called  
**And** the highlight texture becomes visible on the button

#### Scenario: Unhighlight button when opponent's turn
**Given** an active match where match.current_turn equals the opponent's username  
**When** the button is populated  
**Then** `button.un_highlight()` is called  
**And** the highlight texture is hidden on the button

#### Scenario: Highlight state updates after turn completion
**Given** Player A views a highlighted button (their turn)  
**When** Player A completes their turn in gameplay_screen  
**And** match.current_turn changes to opponent's username  
**And** Player A returns to friendly_battle_page  
**Then** the button is unhighlighted  
**And** indicates it's now the opponent's turn

---

## REMOVED Requirements

### Requirement: Display All Multiplayer Matches (Active and Finished)
**Reason**: Page now filters to show only active matches. Finished matches are hidden to reduce clutter and focus on matches requiring player action.

### Requirement: Display Opponent Information in Avatar
**Reason**: Replaced by new friendly_duel_button requirements. Opponent information is now displayed via set_opponent_name() instead of set_avatar_picture().

### Requirement: Display Turn Status or Game Finished Label
**Reason**: Turn status is now indicated via highlight/unhighlight functions instead of text labels. Finished matches are no longer displayed on this page.

### Requirement: Navigate to Gameplay Screen with Match Context
**Reason**: Still supported but implementation changed from avatar_clicked signal to button.pressed signal with bound match_id.

---

## Notes

### Implementation Details
- Use `FRIENDLY_DUEL_BUTTON_L` and `FRIENDLY_DUEL_BUTTON_R` preloaded constants
- Alternate buttons using modulo logic: `match_index % 2 == 0` → left, else → right
- Score calculation iterates through `match.rounds_data[i].player_answers[username].results` array
- Connect `button.pressed` signal with match_id bound via `.bind(match.match_id)`
- Clear both `friend_list_l` and `friend_list_r` containers at the start of `_populate_active_matches()`

### Backward Compatibility
- Removes dependency on avatar_component for match display
- Maintains compatibility with existing UserDatabase match structure
- Navigation to gameplay_screen unchanged (still uses match_id parameter)
- _on_match_created signal handler unchanged (still refreshes match list)
