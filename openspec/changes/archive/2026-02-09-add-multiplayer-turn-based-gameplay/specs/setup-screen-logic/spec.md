# setup-screen-logic Specification Delta

## MODIFIED Requirements

### Requirement: Accept Invited Player Parameter
The setup_screen SHALL accept an optional `invited_player` parameter to enable multiplayer invite flow.

**Rationale:** Distinguish between single-player setup and multiplayer invite configuration.

#### Scenario: Initialize with invited player for multiplayer
**Given** Player A clicks "Invite to Game" for Player B  
**When** setup_screen opens with `{"invited_player": "PlayerB"}`  
**Then** the invited player username is stored internally  
**And** the screen displays normally for configuration

#### Scenario: Initialize without invited player for single-player
**Given** setup_screen is opened without parameters  
**When** the screen initializes  
**Then** no invited player is stored  
**And** the screen operates in single-player mode

---

### Requirement: Send Game Invite Notification with Configuration
When "Start Game" is pressed with a pending invite, setup_screen SHALL emit a notification containing rounds and questions configuration.

**Rationale:** Include match settings in the invite so invitee knows game parameters before accepting.

#### Scenario: Include configuration in notification
**Given** Player A configured 3 rounds and 2 questions  
**And** invited Player B  
**When** Player A presses "Start Game"  
**Then** a notification is emitted with `action_data.rounds = 3` and `action_data.questions = 2`  
**And** the notification message includes "(3 rounds, 2 questions)" text

#### Scenario: Notification includes inviter information
**Given** Player A invites Player B  
**When** the notification is created  
**Then** `action_data.inviter_id` equals Player A's username  
**And** `action_data.type` equals "game_invite"  
**And** `sender` equals Player A's username

---

### Requirement: Navigate to Main Lobby After Invite Sent
After sending a multiplayer invite, setup_screen SHALL navigate to main_lobby_screen instead of gameplay_screen.

**Rationale:** Allow inviter to continue app usage while waiting for acceptance; matches start only when both players are ready.

#### Scenario: Return to lobby after invite
**Given** Player A sends a game invite  
**When** "Start Game" is pressed  
**Then** `NavigationUtils.navigate_to_scene("main_lobby")` is called  
**And** Player A sees the main lobby  
**And** Player A does NOT enter gameplay_screen immediately

#### Scenario: Single-player still transitions to gameplay
**Given** no pending invite exists  
**When** "Start Game" is pressed  
**Then** `TransitionManager.change_scene("gameplay_screen")` is called  
**And** gameplay begins immediately (existing behavior)

---

### Requirement: Clear Pending Invite After Sending
After sending a notification, setup_screen SHALL clear the pending invite state.

**Rationale:** Prevent duplicate notifications if player reopens setup_screen.

#### Scenario: Reset invite state after send
**Given** Player A configured and sent an invite to Player B  
**When** the notification is emitted  
**Then** the internal `pending_invite_player` variable is set to empty string  
**And** subsequent "Start Game" presses operate in single-player mode

---
