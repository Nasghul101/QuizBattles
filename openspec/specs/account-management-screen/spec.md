# account-management-screen Specification

## Purpose
TBD - created by archiving change add-account-screen-navigation. Update Purpose after archive.
## Requirements
### Requirement: Back Navigation to Main Lobby
The account management screen SHALL provide navigation back to the main lobby screen.

**Rationale:** Allow users to return to the main lobby after viewing or managing account settings.

#### Scenario: Navigate back to main lobby
**GIVEN** the user is on the account management screen  
**WHEN** the BackButton is pressed  
**THEN** the screen SHALL transition to `res://scenes/ui/main_lobby_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

---

### Requirement: Navigation Error Handling
The account management screen SHALL handle navigation failures gracefully by returning to the main lobby.

**Rationale:** Ensure users can recover from navigation errors and have a safe fallback screen.

#### Scenario: Handle transition failure and return to main lobby
**GIVEN** a scene transition is initiated  
**WHEN** the transition fails (e.g., scene path not found)  
**THEN** the screen SHALL log an error to the console using `push_error()`  
**AND** the screen SHALL transition back to `res://scenes/ui/main_lobby_screen.tscn`  
**AND** the fallback transition SHALL use TransitionManager with fade effects

### Requirement: Display Current User Username
The account management screen SHALL display the currently logged-in user's username in the NameLabel when the screen loads.

**Rationale:** Users need to see which account they are currently logged into for confirmation and context.

#### Scenario: Display username on screen load
**GIVEN** a user is logged in and the account management screen is loaded  
**WHEN** the screen's `_ready()` method executes  
**THEN** the screen SHALL query `UserDatabase.get_current_user()` to retrieve user data  
**AND** the NameLabel SHALL display the username from `current_user["username"]`

#### Scenario: Fallback when no user is logged in
**GIVEN** no user is logged in (empty current_user)  
**WHEN** the screen's `_ready()` method executes and attempts to display username  
**THEN** the NameLabel SHALL retain its existing text as fallback  
**AND** no error SHALL be raised

---

### Requirement: Log Off Functionality
The account management screen SHALL provide a LogOffButton that logs out the current user and returns to the login screen.

**Rationale:** Users need the ability to log out from their account to switch users or secure their session.

#### Scenario: User logs off successfully
**GIVEN** a user is logged in and on the account management screen  
**WHEN** the LogOffButton is pressed  
**THEN** the screen SHALL call `UserDatabase.sign_out()` to clear the user session  
**AND** the screen SHALL log a message to the console confirming logout with the username  
**AND** the screen SHALL transition to `res://scenes/ui/account_ui/register_login_screen.tscn` using TransitionManager  
**AND** the transition SHALL include fade effects

#### Scenario: Console logging on logout
**GIVEN** a user named "TestUser" is logged in  
**WHEN** the LogOffButton is pressed  
**THEN** a message SHALL be logged to the console indicating the user logged out  
**AND** the message SHALL include the username (e.g., "User TestUser logged out")

### Requirement: Display Current User Avatar in UserAvatar Button
The `UserAvatar` button SHALL display the current user's profile picture from their avatar_path field.

**Rationale:** Provide visual representation of the user's selected avatar on the Account Management Screen.

#### Scenario: Load and display avatar on screen ready
**Given** user "Player123" is signed in with avatar_path "res://assets/profile_pictures/man_beard.png"  
**When** the Account Management Screen loads (\_ready() is called)  
**Then** the `UserAvatar` button texture is set to display "man_beard.png"  
**And** the image is visible in the button

#### Scenario: Display default avatar for new users
**Given** a new user "NewPlayer" just registered with default avatar  
**When** the Account Management Screen loads after registration  
**Then** the `UserAvatar` button displays "man_standard.png"

#### Scenario: Handle missing avatar gracefully
**Given** user's avatar_path is "res://assets/profile_pictures/nonexistent.png"  
**And** the file does not exist  
**When** the Account Management Screen loads  
**Then** texture loading fails (returns null)  
**And** the system falls back to loading "res://assets/profile_pictures/man_standard.png"  
**And** the `UserAvatar` button displays the default avatar  
**And** a warning is logged to console

---

### Requirement: Connect Avatar Component Selection Signals
When populating the `ChooseAvatarPopup`, each `AvatarComponent` SHALL have its `pressed` signal connected to trigger avatar update.

**Rationale:** Enable user interaction to select and persist avatar choices.

#### Scenario: Connect pressed signals during popup population
**Given** the `ChooseAvatarPopup` is being populated  
**When** each `AvatarComponent` is instantiated and added to `AvatarContainer`  
**Then** the component's `pressed` signal is connected to a handler function  
**And** the handler receives the avatar's resource path as a parameter

#### Scenario: Signal connection includes texture path
**Given** an `AvatarComponent` for "woman_purple.png" is being added  
**When** the `pressed` signal is connected  
**Then** the connection includes "res://assets/profile_pictures/woman_purple.png" as a bound parameter  
**And** pressing the component will trigger the handler with this path

---

### Requirement: Handle Avatar Selection and Update
When an `AvatarComponent` is pressed, the system SHALL update the user's avatar in the database, refresh the UI, and close the popup.

**Rationale:** Complete the avatar selection flow with immediate feedback and persistence.

#### Scenario: Update avatar on component press
**Given** user "Player123" is signed in  
**And** `ChooseAvatarPopup` is visible  
**When** the user presses the component for "man_suit.png"  
**Then** `UserDatabase.update_avatar("res://assets/profile_pictures/man_suit.png")` is called  
**And** the database update succeeds

#### Scenario: Refresh UserAvatar button after selection
**Given** the `UserAvatar` button currently displays "man_standard.png"  
**When** the user selects "woman_standard.png" from the popup  
**Then** the `UserAvatar` button texture is updated to display "woman_standard.png"  
**And** the change is immediately visible

#### Scenario: Close popup after selection
**Given** `ChooseAvatarPopup` is visible  
**When** an avatar is selected  
**Then** `_close_popup_with_animation()` is called  
**And** the popup animates off screen  
**And** the popup's visible property becomes false

---

### Requirement: Game Invite Button Functionality
AccountPopup SHALL allow players to send game invitations by clicking the "Invite to duel" button.

#### Scenario: Player sends game invite
**Given** AccountPopup is displaying Player B's profile  
**And** Player A is signed in  
**When** Player A clicks the "Invite to duel" button  
**Then** a game invite notification is emitted via `GlobalSignalBus.notification_received`  
**And** the notification recipient is Player B  
**And** the notification message is "[Player A username] invites you to a duel"  
**And** the notification has `has_actions: true` (shows Accept/Deny buttons)  
**And** the notification includes action_data with type "game_invite"  
**And** the notification includes inviter_id matching Player A's username

---

### Requirement: Invite Button State Management
AccountPopup SHALL disable the "Invite to duel" button after it is pressed and re-enable it when the popup reopens.

#### Scenario: Button disabled after sending invite
**Given** AccountPopup is displaying Player B's profile  
**And** the "Invite to duel" button is enabled  
**When** Player A clicks the button  
**Then** the button becomes disabled immediately  
**And** the button remains disabled while the popup stays open  
**And** Player A cannot click it again during this popup session

#### Scenario: Button re-enabled on popup reopen
**Given** Player A sent an invite to Player B and the button is disabled  
**When** Player A closes the AccountPopup  
**And** Player A reopens the AccountPopup for Player B (or any other player)  
**Then** the "Invite to duel" button is enabled again  
**And** Player A can send invites (subject to duplicate prevention rules)

#### Scenario: Button state is visual feedback only
**Given** the button state management exists  
**When** a player tries to send duplicate invites  
**Then** duplicate prevention is handled by UserDatabase logic  
**And** the button state provides immediate visual feedback  
**And** the button state does not replace duplicate prevention logic

---

### Requirement: Game Invite Notification Structure
AccountPopup SHALL create game invite notifications with the correct data structure for processing by UserDatabase and notification handlers.

#### Scenario: Notification includes required fields
**Given** Player A clicks "Invite to duel" for Player B  
**When** the notification is created  
**Then** it includes `recipient_username: Player B's username`  
**And** it includes `sender: Player A's username`  
**And** it includes `has_actions: true`  
**And** it includes action_data Dictionary with:
  - `type: "game_invite"`
  - `inviter_id: Player A's username`

**Note**: The timestamp field is added automatically by UserDatabase when the notification is received, so AccountPopup does not need to add it.

---

### Requirement: Navigate to Setup Screen from Invite Button
When the "Invite to Game" button is pressed on account_popup, the popup SHALL close and navigate to setup_screen with the invited player's username.

**Rationale:** Enable multiplayer invite flow starting from friend profiles.

#### Scenario: Open setup screen with invited player
**Given** account_popup is displaying Player B's profile  
**When** Player A clicks "Invite to Game"  
**Then** the account_popup closes  
**And** setup_screen opens with `{"invited_player": "PlayerB"}` parameter

#### Scenario: Button remains disabled until popup reopens
**Given** Player A clicked "Invite to Game"  
**When** the button is pressed  
**Then** the button becomes disabled  
**And** remains disabled while navigating to setup_screen  
**And** re-enables when popup is reopened later (existing behavior)

---

