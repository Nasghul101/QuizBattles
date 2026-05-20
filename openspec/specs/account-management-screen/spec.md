# account-management-screen Specification

## Purpose
TBD - created by archiving change add-account-screen-navigation. Update Purpose after archive.
## Requirements
### Requirement: Navigate Back to Main Lobby on Back Button Press
The account management screen SHALL navigate back to the main lobby screen when the BackButton is pressed.

**Rationale:** Users need to return to the main lobby after viewing their account information.

#### Scenario: Back button returns to main lobby
**Given** the account management screen is visible  
**And** user is on the account management screen  
**When** the user presses the BackButton  
**Then** the screen SHALL call `Utils.navigate_to_scene("main_lobby")`  
**And** the user SHALL be navigated to the main lobby screen

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

### Requirement: Log Off and Navigate to Main Lobby on Log Off Button Press
The account management screen SHALL sign out the current user and navigate to the main lobby screen when the LogOffButton is pressed.

**Rationale:** Users need to log out of their account from the account management screen.

**Cross-reference:** Uses `local-user-database.sign_out()`.

#### Scenario: Log off button signs out and returns to main lobby
**Given** user "Player123" is logged in  
**And** the account management screen is visible  
**When** the user presses the LogOffButton  
**Then** the screen SHALL call `UserDatabase.sign_out()`  
**And** the current user session SHALL be cleared  
**And** the screen SHALL call `Utils.navigate_to_scene("main_lobby")`  
**And** the user SHALL be navigated to the main lobby screen as a guest

#### Scenario: Main lobby shows login screen after log off
**Given** user was logged in and pressed LogOffButton  
**When** the user presses the AccountButton on the main lobby  
**Then** the user SHALL be navigated to the register/login screen (not account management)  
**And** this verifies the log off was successful

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

### Requirement: Populate User Statistics on Screen Load
The account management screen SHALL fetch and display the current logged-in user's statistics when the screen becomes ready, including total games, wins, losses, draws (calculated), pie chart visualization, and per-category statistics.

**Rationale:** Users need to view their performance data when accessing the account management screen. All UI components are already in place with proper unique names, but lack data population logic.

**Cross-reference:** Uses `local-user-database.get_user_data_for_display()` and `local-user-database.total_games` field.

#### Scenario: Display statistics for user with game history
**Given** user "Player123" is logged in with `total_games: 50`, `wins: 30`, `losses: 15`  
**And** user has `category_stats: {"History": {"played": 20, "wins": 12}, "Science": {"played": 15, "wins": 8}}`  
**When** the account management screen `_ready()` function executes  
**Then** the player name label SHALL display "Player123"  
**And** total games label SHALL display "50"  
**And** wins label SHALL display "30"  
**And** draws label SHALL display "5" (calculated as 50 - 30 - 15)  
**And** losses label SHALL display "15"  
**And** the pie chart SHALL be populated by calling `set_chart(30, 5, 50)`  
**And** the History category component SHALL show 12 wins, 20 played, 60% win rate  
**And** the Science category component SHALL show 8 wins, 15 played, 53% win rate  
**And** categories not in `category_stats` SHALL show 0 wins, 0 played, 0% win rate

#### Scenario: Display empty state for new user
**Given** user "NewPlayer" is logged in with `total_games: 0`, `wins: 0`, `losses: 0`  
**And** user has `category_stats: {}`  
**When** the account management screen `_ready()` function executes  
**Then** the player name label SHALL display "NewPlayer"  
**And** total games label SHALL display "0"  
**And** wins label SHALL display "0"  
**And** draws label SHALL display "0"  
**And** losses label SHALL display "0"  
**And** the pie chart SHALL display inspector default values (not call `set_chart()` or call with zeros)  
**And** all category components SHALL show 0 wins, 0 played, 0% win rate

#### Scenario: Calculate draws correctly
**Given** user has `total_games: 100`, `wins: 60`, `losses: 30`  
**When** the account management screen calculates draws  
**Then** draws SHALL equal `100 - 60 - 30 = 10`  
**And** the draws label SHALL display "10"

---

### Requirement: Populate Category Statistics from User Data
The account management screen SHALL iterate through all category statistic display components and populate each with the corresponding category data from the user's `category_stats` dictionary.

**Rationale:** Users need to see their performance breakdown by category to understand their strengths and weaknesses.

**Cross-reference:** Uses restructured `local-user-database.category_stats` with nested `{"played": int, "wins": int}` structure.

#### Scenario: Populate multiple categories with data
**Given** user has `category_stats: {"History": {"played": 25, "wins": 18}, "Geography": {"played": 10, "wins": 4}, "Sports": {"played": 8, "wins": 8}}`  
**When** the account management screen populates category statistics  
**Then** the History component SHALL call `set_win_amount(18)`, `set_played_amount(25)`, and `set_win_rate()` resulting in 72% display  
**And** the Geography component SHALL call `set_win_amount(4)`, `set_played_amount(10)`, and `set_win_rate()` resulting in 40% display  
**And** the Sports component SHALL call `set_win_amount(8)`, `set_played_amount(8)`, and `set_win_rate()` resulting in 100% display  
**And** all other category components SHALL show 0, 0, 0%

#### Scenario: Handle missing category data gracefully
**Given** user has `category_stats: {"History": {"played": 5, "wins": 3}}`  
**And** 11 other categories have no data  
**When** the account management screen populates category statistics  
**Then** the History component SHALL show 3 wins, 5 played, 60% win rate  
**And** all 11 other category components SHALL show 0 wins, 0 played, 0% win rate  
**And** no errors SHALL occur for missing categories

#### Scenario: Iterate through all category components
**Given** the CategoryStatisticsContainer has 12 child category components  
**When** the account management screen populates statistics  
**Then** the screen SHALL iterate through all 12 children  
**And** for each child, extract the `category` export variable  
**And** look up that category in user's `category_stats`  
**And** populate the component with the data (or zeros if not found)

---

### Requirement: Open AccountPopup and Populate Friend Data
AccountPopup SHALL expose an `open_for_friend(friend_username: String)` method that populates all UI elements and shows the popup.

**Rationale:** Centralise popup population logic in one callable method so callers (SocialsPage) stay simple.

**Cross-reference**: Triggered by `socials-page-friend-display` friend press interaction.

#### Scenario: Open popup for friend with stats
**Given** user "alice" is signed in  
**And** alice has friend "bob" with `wins = 12`, `losses = 5`, `total_games = 20`  
**When** `AccountPopup.open_for_friend("bob")` is called  
**Then** the `FriendName` label SHALL display "bob"  
**And** `TotalGamesAmount` label SHALL display "20"  
**And** `WinsAmount` label SHALL display "12"  
**And** `LossAmount` label SHALL display "5"  
**And** `DrawsAmount` label SHALL display "3" (20 - 12 - 5)  
**And** `Piechart.set_chart(12, 3, 20)` SHALL be called  
**And** the AccountPopup `visible` property SHALL be set to `true`

#### Scenario: Open popup resets invite button state
**Given** the "Invite to duel" button was disabled in a previous popup session  
**When** `open_for_friend(friend_username)` is called  
**Then** the "Invite to duel" button SHALL be re-enabled (`disabled = false`)  
**And** the `UnfriendPopup` SHALL remain hidden

#### Scenario: Open popup for friend with zero total games
**Given** friend "charlie" has `total_games = 0`  
**When** `open_for_friend("charlie")` is called  
**Then** `TotalGamesAmount` SHALL display "0"  
**And** `WinsAmount`, `DrawsAmount`, `LossAmount` SHALL all display "0"  
**And** no division-by-zero error SHALL occur  
**And** the piechart SHALL be called with `set_chart(0, 0, 0)`

---

### Requirement: Close AccountPopup on Back Button Press
AccountPopup SHALL hide itself when the back button is pressed.

#### Scenario: Back button hides the popup
**Given** the AccountPopup is visible  
**When** the user presses the back (AccountBackButton) button  
**Then** the AccountPopup `visible` property SHALL be set to `false`  
**And** the `UnfriendPopup` SHALL NOT remain visible after the popup closes

---

### Requirement: Show Unfriend Confirmation Popup
AccountPopup SHALL show `UnfriendPopup` when the unfriend button is pressed and hide it when the No button is pressed.

#### Scenario: Unfriend button shows confirmation popup
**Given** the AccountPopup is visible  
**When** the user presses the "Unfriend" button  
**Then** `UnfriendPopup.visible` SHALL be set to `true`

#### Scenario: No button dismisses confirmation popup
**Given** `UnfriendPopup` is visible  
**When** the user presses the "No" button  
**Then** `UnfriendPopup.visible` SHALL be set to `false`  
**And** the AccountPopup SHALL remain visible  
**And** the friendship SHALL remain intact

---

### Requirement: Confirm Unfriend Removes Friendship Bidirectionally
When the user confirms unfriending by pressing "Yes" in UnfriendPopup, AccountPopup SHALL remove the friendship bidirectionally and close both popups.

**Cross-reference**: Uses `local-user-database.remove_friend()`. Triggers friend list refresh in `socials-page-friend-display`.

#### Scenario: Yes button removes friendship and closes popups
**Given** user "alice" is signed in  
**And** alice and "bob" are friends  
**And** `AccountPopup` is displaying "bob"'s profile  
**And** `UnfriendPopup` is visible  
**When** the user presses the "Yes" button  
**Then** `UserDatabase.remove_friend(alice_username, "bob")` SHALL be called  
**And** "bob" SHALL be removed from alice's friends array in the database  
**And** "alice" SHALL be removed from bob's friends array in the database  
**And** `UnfriendPopup.visible` SHALL be set to `false`  
**And** `AccountPopup.visible` SHALL be set to `false`

#### Scenario: Friend list refreshes after unfriend confirmation
**Given** the unfriend was confirmed  
**When** both popups close  
**Then** the socials page FriendDisplayContainer SHALL no longer show "bob"'s component  
**And** the refresh SHALL happen without requiring a page reload

#### Scenario: Yes button when user is not signed in
**Given** the current user is somehow not signed in at the moment Yes is pressed  
**When** the "Yes" button is pressed  
**Then** no crash SHALL occur  
**And** an error SHALL be logged  
**And** both popups SHALL still close

---

