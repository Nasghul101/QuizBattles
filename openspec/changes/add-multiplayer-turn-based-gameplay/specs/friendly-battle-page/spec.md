# friendly-battle-page Specification

## ADDED Requirements

### Requirement: Display Active Multiplayer Matches
The friendly_battle_page SHALL display avatar_component instances for each active multiplayer match involving the current user.

**Rationale:** Provide visual overview of all ongoing quiz duels so players can see their active games at a glance.

#### Scenario: Load matches on page open
**Given** Player A has 2 active matches  
**When** friendly_battle_page becomes visible  
**Then** 2 avatar_components are instantiated in the FriendsList GridContainer  
**And** each avatar corresponds to a different match

#### Scenario: Empty state when no matches
**Given** Player A has no active matches  
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

### Requirement: Display Turn Status Label
Each avatar_component SHALL display whose turn it is using the avatar name label.

**Rationale:** Enable players to quickly identify which matches require their action.

#### Scenario: Show "Your Turn" when it's player's turn
**Given** a match where `current_turn` equals the current user's username  
**When** the avatar is displayed  
**Then** the label text is set to "Your Turn"

#### Scenario: Show opponent's turn
**Given** a match with Player A vs Player B  
**And** `current_turn` equals Player B's username  
**When** Player A views the avatar  
**Then** the label text is set to "Player B Turn" (using opponent's username)

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
