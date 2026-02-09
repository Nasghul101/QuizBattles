# setup-screen-logic Specification

## Purpose
TBD - created by archiving change add-game-setup-and-transition-logic. Update Purpose after archive.
## Requirements
### Requirement: Setup screen MUST synchronize slider values with amount labels
The setup screen SHALL synchronize slider values with their corresponding amount labels in real-time so players can see their current selections.

#### Scenario: Player adjusts rounds slider
**Given** the setup screen is displayed  
**And** the rounds slider is at value 3  
**When** the player drags the slider to value 5  
**Then** the rounds amount label must immediately display "5"

#### Scenario: Player adjusts questions slider
**Given** the setup screen is displayed  
**And** the questions slider is at value 2  
**When** the player drags the slider to value 4  
**Then** the questions amount label must immediately display "4"

---

### Requirement: Setup screen MUST initialize with default configuration values
The setup screen SHALL initialize with sensible default values when loaded.

#### Scenario: Setup screen loads for the first time
**Given** no previous game configuration exists  
**When** the setup screen loads  
**Then** the rounds slider must be set to 5  
**And** the rounds amount label must display "5"  
**And** the questions slider must be set to 3  
**And** the questions amount label must display "3"

---

### Requirement: Sliders MUST only allow integer values
The sliders SHALL only allow integer values to ensure whole numbers for rounds and questions.

#### Scenario: Player moves slider between integer positions
**Given** the setup screen is displayed  
**When** the player drags a slider to a position between integers  
**Then** the slider must snap to the nearest integer value  
**And** the amount label must display only integer values

---

### Requirement: Start game button MUST trigger scene transition with configured values
The start game button SHALL trigger scene transition with configured values when pressed.

#### Scenario: Player starts game with custom settings
**Given** the setup screen is displayed  
**And** the rounds slider is set to 6  
**And** the questions slider is set to 4  
**When** the player presses the "Start Game" button  
**Then** the scene transition must be initiated with fade effect  
**And** the gameplay screen must receive rounds=6 and questions=4

#### Scenario: Player starts game with default settings
**Given** the setup screen is displayed  
**And** the sliders are at default values (5 rounds, 3 questions)  
**When** the player presses the "Start Game" button  
**Then** the scene transition must be initiated with fade effect  
**And** the gameplay screen must receive rounds=5 and questions=3

---

### Requirement: Setup screen script MUST correctly reference nodes from scene tree
The setup screen script SHALL correctly reference nodes from the scene tree for proper functionality.

#### Scenario: Script accesses slider nodes
**Given** the setup screen script is attached to setup_screen.tscn  
**When** the script initializes  
**Then** it must successfully reference both HSlider nodes  
**And** it must successfully reference both Amount label nodes  
**And** it must successfully reference the StartGameButton node

---

### Requirement: Setup screen MUST connect to node signals for event-driven updates
The setup screen SHALL connect to node signals for event-driven updates.

#### Scenario: Slider value changes trigger updates
**Given** the setup screen has initialized  
**When** a slider value changes  
**Then** the corresponding amount label must update via signal connection  
**And** no manual polling or timer-based updates are used

#### Scenario: Button press triggers transition
**Given** the setup screen has initialized  
**When** the start button is pressed  
**Then** the button pressed signal must trigger the scene transition logic

---

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

