## ADDED Requirements

### Requirement: Notification Timestamp Support
UserDatabase SHALL add a timestamp to all notifications when they are created.

#### Scenario: Notification created with timestamp
**Given** a system emits a notification via GlobalSignalBus  
**When** UserDatabase receives the notification and adds it to a user's notification list  
**Then** a `timestamp` field is added to the notification data  
**And** the timestamp uses Unix time in seconds from `Time.get_unix_time_from_system()`  
**And** the timestamp is stored as a float in the database JSON

---

### Requirement: Automatic Notification Expiry
UserDatabase SHALL filter out notifications older than 3 days when querying a user's notifications.

#### Scenario: Recent notifications are returned
**Given** a user has a notification created 1 day ago  
**When** `get_notifications(username)` is called  
**Then** the notification is included in the returned array  
**And** the notification has all its original data intact

#### Scenario: Expired notifications are filtered out
**Given** a user has a notification created 4 days ago  
**When** `get_notifications(username)` is called  
**Then** the old notification is NOT included in the returned array  
**And** only notifications newer than 3 days are returned

#### Scenario: Expiry threshold is exactly 3 days
**Given** a user has a notification created exactly 3 days ago (259200 seconds)  
**When** `get_notifications(username)` is called  
**Then** the notification is included in the returned array (3 days is the maximum age, inclusive)

---

### Requirement: Game Invite Duplicate Prevention
UserDatabase SHALL prevent sending duplicate game invites to the same player from the same sender.

#### Scenario: First game invite is allowed
**Given** Player A wants to send a game invite to Player B  
**And** Player B has no pending game invites from Player A  
**When** the game invite notification is created  
**Then** the notification is added to Player B's notification list  
**And** no warning is logged

#### Scenario: Duplicate game invite is prevented
**Given** Player A has already sent a game invite to Player B  
**And** Player B has not yet accepted or denied the invite  
**When** Player A tries to send another game invite to Player B  
**Then** the duplicate notification is NOT added to Player B's notification list  
**And** a warning is logged: "Game invite already sent to [recipient] from [sender]"

#### Scenario: Multiple invites to different players are allowed
**Given** Player A sends a game invite to Player B  
**When** Player A sends a game invite to Player C  
**Then** both invitations are created successfully  
**And** Player B has Player A's invite in their notifications  
**And** Player C has Player A's invite in their notifications

#### Scenario: Game invite from different sender is allowed
**Given** Player A sends a game invite to Player C  
**And** Player B sends a game invite to Player C  
**When** Player C checks their notifications  
**Then** Player C has two game invite notifications  
**And** one is from Player A  
**And** one is from Player B

---

### Requirement: Game Invite Rejection Notification
UserDatabase SHALL send a rejection notification to the inviter when a player denies a game invitation.

#### Scenario: Player denies game invite
**Given** Player A sent a game invite to Player B  
**And** Player B receives the notification  
**When** Player B clicks Deny on the notification  
**Then** the original invite notification is removed from Player B's list  
**And** a rejection notification is sent to Player A  
**And** the rejection message is "[Player B username] rejected your duel"  
**And** the rejection notification has `has_actions: false` (no buttons)  
**And** the rejection notification sender is "System"  
**And** the rejection notification has `action_data.type: "game_invite_rejection"`

#### Scenario: Rejection notification has timestamp and expires
**Given** Player B denies Player A's game invite  
**When** the rejection notification is created for Player A  
**Then** the notification includes a timestamp field  
**And** the notification will expire after 3 days like all other notifications

---

## MODIFIED Requirements

None - existing notification and friend request functionality remains unchanged.
