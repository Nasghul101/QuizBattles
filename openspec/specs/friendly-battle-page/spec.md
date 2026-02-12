# friendly-battle-page Specification

## Purpose
The friendly_battle_page displays all active multiplayer matches for the current user, providing quick access to ongoing quiz duels with turn status indicators.

## Requirements

### Requirement: Display All Multiplayer Matches (Active and Finished)
The friendly_battle_page SHALL display avatar_component instances for all multiplayer matches (both active and finished) involving the current user, excluding matches that the user has already dismissed.

**Rationale:** Provide visual overview of all ongoing and completed quiz duels so players can see their active games and finished matches that require dismissal.

#### Scenario: Load matches on page open
**Given** Player A has 2 active matches and 1 finished match  
**When** friendly_battle_page becomes visible  
**Then** 3 avatar_components are instantiated in the FriendsList GridContainer  
**And** each avatar corresponds to a different match

#### Scenario: Call get_all_matches_for_player instead of get_active_matches_for_player
**Given** friendly_battle_page is populating matches  
**When** _populate_active_matches() executes  
**Then** UserDatabase.get_all_matches_for_player() is called  
**And** NOT get_active_matches_for_player()  
**And** the returned array includes matches with status="finished"

#### Scenario: Filter out matches dismissed by current user
**Given** Player A has finished a match and dismissed it  
**When** friendly_battle_page loads matches  
**Then** the dismissed match is filtered out  
**And** only matches where Player A is NOT in `dismissed_by` array are shown

#### Scenario: Empty state when no matches
**Given** Player A has no active or undismissed finished matches  
**When** friendly_battle_page loads  
**Then** a message "No active matches" is displayed  
**And** no avatar_components are shown

---

### Requirement: Display Opponent Information in Avatar
Each avatar_component SHALL display the opponent's profile picture and name from UserDatabase.

**Rationale:** Provide clear visual identification of who the player is competing against.

#### Scenario: Show opponent's avatar
**Given** Player A has a match with Player B  
**And** Player B's avatar_path is "res://assets/profile_pictures/man_beard.png"  
**When** the avatar_component is created for this match  
**Then** the avatar displays Player B's profile picture  
**And** not Player A's picture

---

### Requirement: Display Turn Status or Game Finished Label
Each avatar_component SHALL display whose turn it is for active matches, or "Game Finished" for completed matches.

**Rationale:** Enable players to quickly identify which matches require their action and which are awaiting dismissal.

#### Scenario: Show "Game Finished" for finished match
**Given** a match with status="finished" exists  
**When** the avatar_component is created for this match  
**Then** the avatar name label displays "Game Finished"  
**And** no turn information is shown

#### Scenario: Prioritize finished status over turn status
**Given** a match with status="finished" and current_turn="Alice"  
**When** avatar label logic executes  
**Then** label displays "Game Finished"  
**And** NOT "Your Turn" or "Alice Turn"

#### Scenario: Show "Your Turn" when it's player's turn
**Given** an active match where `current_turn` equals the current user's username  
**When** the avatar is displayed   for both active and finished matches.

**Rationale:** Enable players to open specific matches for gameplay or to review finished matches and dismiss them.

#### Scenario: Pass match_id on avatar click
**Given** an avatar_component representing match "match_123"  
**When** the avatar is clicked  
**Then** `NavigationUtils.navigate_to_scene("gameplay_screen", {"match_id": "match_123"})` is called

#### Scenario: Open finished match in gameplay_screen
**Given** an avatar representing a finished match is clicked  
**When** _on_avatar_clicked() executes  
**Then** TransitionManager.change_scene() is called with gameplay_screen path  
**And** match_id parameter is passed  
**And** FinishGamePopup is shown automatically with winner/draw announcement

---

### Requirement: Navigate to Gameplay Screen with Match Context
Clicking an avatar_component SHALL navigate to gameplay_screen with the match_id parameter.

**Rationale:** Enable players to open specific matches for gameplay.

#### Scenario: Pass match_id on avatar click
**Given** an avatar_component representing match "match_123"  
**When** the avatar is clicked  
**Then** `NavigationUtils.navigate_to_scene("gameplay_screen", {"match_id": "match_123"})` is called

#### Scenario: Validate match exists before navigation
**Given** an avatar_component with match_id "match_invalid"  
**And** the match no longer exists in UserDatabase  
**When** the avatar is clicked  
**Then** a warning is logged  
**And** the match list is refreshed  
**And** no navigation occurs

---

### Requirement: Refresh Match List on Visibility Change
The friendly_battle_page SHALL reload active matches when the page becomes visible.

**Rationale:** Ensure turn status labels update after players complete rounds in gameplay_screen.

#### Scenario: Update turn labels after returning from gameplay
**Given** Player A views friendly_battle_page with label "Your Turn"  
**When** Player A plays their turn and returns to friendly_battle_page  
**Then** the match list is reloaded  
**And** the label updates to "[Opponent] Turn"

---

### Requirement: Handle Signed-Out State
The friendly_battle_page SHALL show no matches when user is not signed in.

**Rationale:** Prevent errors and maintain consistent behavior with other authenticated features.

#### Scenario: Clear matches when not signed in
**Given** the user is not signed in  
**When** friendly_battle_page loads  
**Then** no avatar_components are displayed  
**And** no database queries are attempted

---
