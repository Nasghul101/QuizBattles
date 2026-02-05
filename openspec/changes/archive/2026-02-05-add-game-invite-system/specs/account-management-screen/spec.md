## ADDED Requirements

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

## MODIFIED Requirements

None - AccountPopup's existing functionality (displaying user profiles, handling button clicks) remains unchanged.
