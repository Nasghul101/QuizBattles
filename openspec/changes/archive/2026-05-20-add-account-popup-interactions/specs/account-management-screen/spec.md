# Spec Delta: account-management-screen (Account Popup Interactions)

## MODIFIED Requirements

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
