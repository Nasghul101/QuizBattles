# local-user-database Specification

## Purpose
TBD - created by archiving change add-local-user-database. Update Purpose after archive.
## Requirements
### Requirement: User Registration
The system SHALL allow creating new user accounts with username, password, and email.

**Rationale:** Enable players to create accounts for gameplay and progression tracking.

#### Scenario: Successful user registration
**Given** no user exists with username "Player123" or email "player@example.com"  
**When** `create_user("Player123", "password123", "player@example.com")` is called  
**Then** the user is created and stored in memory  
**And** the password is hashed using SHA-256  
**And** the method returns `{success: true, user: {username: "Player123", email: "player@example.com"}}`

---

### Requirement: Duplicate Username Detection
The system SHALL prevent registration of usernames that already exist.

**Rationale:** Ensure unique player identities and prevent account conflicts.

#### Scenario: Reject duplicate username
**Given** a user exists with username "Player123"  
**When** `create_user("Player123", "newpass", "different@example.com")` is called  
**Then** no new user is created  
**And** the method returns `{success: false, error_code: "USERNAME_EXISTS", message: "Username already exists"}`

---

### Requirement: Duplicate Email Detection
The system SHALL prevent registration of email addresses that already exist.

**Rationale:** Prevent multiple accounts with the same email and support future email-based features.

#### Scenario: Reject duplicate email
**Given** a user exists with email "player@example.com"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** no new user is created  
**And** the method returns `{success: false, error_code: "EMAIL_EXISTS", message: "Email already registered"}`

---

### Requirement: Email Format Validation
The system SHALL validate email addresses contain an `@` symbol and a valid top-level domain.

**Rationale:** Ensure email addresses are properly formatted before storage.

**Constraints:**
- Valid TLDs include: .com, .de, .org, .net, .edu, .gov, .co, .uk, .io, .app, .dev, .tech

#### Scenario: Reject invalid email format
**Given** the system is ready to create a user  
**When** `create_user("Player123", "password", "notanemail")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "INVALID_EMAIL", message: "Email format is invalid"}`

#### Scenario: Accept valid email formats
**Given** the system is ready to create a user  
**When** `create_user("Player123", "password", "user@example.de")` is called  
**Then** the user is created successfully

---

### Requirement: Username Length Validation
The system SHALL enforce username length between 5 and 15 characters inclusive.

**Rationale:** Prevent usernames that are too short (hard to distinguish) or too long (display issues).

#### Scenario: Reject username too short
**Given** the system is ready to create a user  
**When** `create_user("ab", "password", "user@example.com")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "USERNAME_TOO_SHORT", message: "Username must be at least 5 characters"}`

#### Scenario: Reject username too long
**Given** the system is ready to create a user  
**When** `create_user("ThisUsernameIsWayTooLong", "password", "user@example.com")` is called  
**Then** no user is created  
**And** the method returns `{success: false, error_code: "USERNAME_TOO_LONG", message: "Username must be at most 15 characters"}`

---

### Requirement: User Authentication
The system SHALL authenticate users with username and password credentials.

**Rationale:** Allow registered users to log into their accounts.

#### Scenario: Successful sign-in
**Given** a user exists with username "Player123" and password "password123"  
**When** `sign_in("Player123", "password123")` is called  
**Then** the user is authenticated  
**And** the current user session is set  
**And** the method returns `{success: true, user: {username: "Player123", email: "player@example.com"}}`

#### Scenario: Reject non-existent user
**Given** no user exists with username "Ghost"  
**When** `sign_in("Ghost", "password")` is called  
**Then** authentication fails  
**And** the method returns `{success: false, error_code: "USER_NOT_FOUND", message: "No user found with this username"}`

#### Scenario: Reject incorrect password
**Given** a user exists with username "Player123" and password "password123"  
**When** `sign_in("Player123", "wrongpassword")` is called  
**Then** authentication fails  
**And** the method returns `{success: false, error_code: "INVALID_PASSWORD", message: "Password is incorrect"}`

---

### Requirement: Session Management
The system SHALL track the currently logged-in user.

**Rationale:** Enable access to user information throughout the application.

#### Scenario: Track current user after sign-in
**Given** user "Player123" signs in successfully  
**When** `get_current_user()` is called  
**Then** it returns `{username: "Player123", email: "player@example.com"}`  
**And** `is_signed_in()` returns `true`

#### Scenario: Clear session on sign-out
**Given** user "Player123" is signed in  
**When** `sign_out()` is called  
**Then** `get_current_user()` returns an empty Dictionary  
**And** `is_signed_in()` returns `false`

---

### Requirement: Password Security
The system SHALL hash passwords using SHA-256 before storage and never store plain-text passwords.

**Rationale:** Protect user credentials even in temporary storage, following Firebase security practices.

#### Scenario: Hash password on registration
**Given** a user registers with password "mypassword"  
**When** the user data is stored  
**Then** the password field contains a SHA-256 hash  
**And** the plain-text password is not stored anywhere

#### Scenario: Verify hashed password on sign-in
**Given** a user registered with password "mypassword" (stored as hash)  
**When** `sign_in(username, "mypassword")` is called  
**Then** the provided password is hashed and compared to the stored hash  
**And** authentication succeeds if hashes match

---

### Requirement: Utility Methods
The system SHALL provide helper methods to check user and email existence.

**Rationale:** Enable UI components to provide real-time validation feedback.

#### Scenario: Check username availability
**Given** a user exists with username "Player123"  
**When** `user_exists("Player123")` is called  
**Then** it returns `true`  
**When** `user_exists("AvailableName")` is called  
**Then** it returns `false`

#### Scenario: Check email availability
**Given** a user exists with email "player@example.com"  
**When** `email_exists("player@example.com")` is called  
**Then** it returns `true`  
**When** `email_exists("available@example.com")` is called  
**Then** it returns `false`

---

### Requirement: Store Avatar Path in User Records
The system SHALL store an `avatar_path` field in each user record containing the resource path to the user's profile picture.

**Rationale:** Enable personalized user profiles with persistent avatar selections without storing large binary image data.

**Constraints:**
- `avatar_path` SHALL be a String type
- Default value SHALL be `"res://assets/profile_pictures/man_standard.png"`

#### Scenario: New user receives default avatar
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record is created with `avatar_path: "res://assets/profile_pictures/man_standard.png"`  
**And** the method returns the avatar_path in the user data dictionary

#### Scenario: Avatar path included in current user data
**Given** a user "Player123" is signed in with avatar_path set to "res://assets/profile_pictures/woman_purple.png"  
**When** `get_current_user()` is called  
**Then** it returns `{username: "Player123", email: "player@example.com", avatar_path: "res://assets/profile_pictures/woman_purple.png"}`

---

### Requirement: Update Current User Avatar
The system SHALL provide a method to update the avatar_path of the currently signed-in user.

**Rationale:** Allow users to change their profile picture after account creation.

#### Scenario: Successfully update avatar for signed-in user
**Given** user "Player123" is signed in  
**When** `update_avatar("res://assets/profile_pictures/man_beard.png")` is called  
**Then** the user's avatar_path is updated to "res://assets/profile_pictures/man_beard.png"  
**And** the method returns `{success: true, avatar_path: "res://assets/profile_pictures/man_beard.png"}`  
**And** subsequent calls to `get_current_user()` return the updated avatar_path

#### Scenario: Reject avatar update when not signed in
**Given** no user is signed in  
**When** `update_avatar("res://assets/profile_pictures/man_suit.png")` is called  
**Then** no avatar is updated  
**And** the method returns `{success: false, error_code: "NOT_SIGNED_IN", message: "No user is currently signed in"}`

#### Scenario: Avatar update persists in stored user data
**Given** user "Player123" is signed in  
**When** `update_avatar("res://assets/profile_pictures/woman_standard.png")` is called  
**And** the user signs out  
**And** the user signs in again  
**Then** `get_current_user()` returns avatar_path as "res://assets/profile_pictures/woman_standard.png"

---

### Requirement: User Data Schema with Notifications
The user database SHALL store a notifications array for each user containing notification objects.

**Rationale:** Notifications must persist across sessions and be tied to user accounts.

#### Scenario: New user has empty notifications array
**Given** a new user is created with username "newuser"  
**When** the user is registered via create_user()  
**Then** the user's data SHALL include a `notifications` key  
**And** the value SHALL be an empty array `[]`

#### Scenario: Existing users retain notifications on save/load
**Given** a user "testuser" has 2 notifications in their notifications array  
**When** the database is saved to disk  **And** the game is restarted  
**And** the database is loaded  
**Then** the user "testuser" SHALL have exactly 2 notifications  
**And** each notification SHALL contain all original data fields

---

### Requirement: Add Notification to User
The user database SHALL provide a function to add a notification to a specific user's notification array.

**Rationale:** Systems need to create notifications and store them for delivery.

#### Scenario: Add notification to existing user
**Given** a user "recipient" exists  
**When** `add_notification("recipient", notification_data)` is called  
**And** notification_data contains `{"id": "notif_001", "message": "Test", "timestamp": "2026-02-02T10:00:00Z", "sender": "sender_name", "is_read": false, "has_actions": true, "action_data": {}}`  
**Then** the notification SHALL be appended to the user's notifications array  
**And** the database SHALL be saved to disk  
**And** the function returns successfully

#### Scenario: Reject notification for non-existent user
**Given** no user exists with username "ghost"  
**When** `add_notification("ghost", notification_data)` is called  
**Then** the function SHALL log an error  
**And** no notification is stored  
**And** the database is not modified

---

### Requirement: Remove Notification from User
The user database SHALL provide a function to remove a notification by ID from a user's notification array.

**Rationale:** Notifications are removed when users interact with them or they expire.

#### Scenario: Remove notification by ID
**Given** user "testuser" has a notification with id "notif_123"  
**When** `remove_notification("testuser", "notif_123")` is called  
**Then** the notification with id "notif_123" SHALL be removed from the array  
**And** other notifications SHALL remain unchanged  
**And** the database SHALL be saved to disk

#### Scenario: Gracefully handle missing notification ID
**Given** user "testuser" has no notification with id "notif_999"  
**When** `remove_notification("testuser", "notif_999")` is called  
**Then** the function completes without error  
**And** the user's notifications array remains unchanged

---

### Requirement: Get User Notifications
The user database SHALL provide a function to retrieve all notifications for a specific user.

**Rationale:** UI components need to load and display user notifications.

#### Scenario: Get notifications for user with notifications
**Given** user "testuser" has 3 notifications  
**When** `get_notifications("testuser")` is called  
**Then** the function SHALL return an array containing all 3 notifications  
**And** each notification SHALL be a complete dictionary with all fields

#### Scenario: Get notifications for user with no notifications
**Given** user "emptyuser" has 0 notifications  
**When** `get_notifications("emptyuser")` is called  
**Then** the function SHALL return an empty array `[]`

#### Scenario: Handle non-existent user gracefully
**Given** no user exists with username "ghost"  
**When** `get_notifications("ghost")` is called  
**Then** the function SHALL return an empty array `[]`  
**And** log a warning about the missing user

---

### Requirement: Mark Notification as Read
The user database SHALL provide a function to mark a specific notification as read.

**Rationale:** Track which notifications the user has acknowledged without removing them immediately.

#### Scenario: Mark notification as read
**Given** user "testuser" has a notification with id "notif_001"  
**And** the notification's `is_read` field is `false`  
**When** `mark_notification_read("testuser", "notif_001")` is called  
**Then** the notification's `is_read` field SHALL be set to `true`  
**And** the database SHALL be saved to disk

#### Scenario: Handle already-read notification
**Given** user "testuser" has a notification with id "notif_002"  
**And** the notification's `is_read` field is already `true`  
**When** `mark_notification_read("testuser", "notif_002")` is called  
**Then** the function completes without error  
**And** the notification remains marked as read

---

### Requirement: Get Unread Notification Count
The user database SHALL provide a function to retrieve the count of unread notifications for a user.

**Rationale:** UI needs to display badge counts and determine if visual indicators should appear.

#### Scenario: Count unread notifications
**Given** user "testuser" has 5 notifications  
**And** 3 notifications have `is_read: false`  
**And** 2 notifications have `is_read: true`  
**When** `get_unread_count("testuser")` is called  
**Then** the function SHALL return `3`

#### Scenario: User with no unread notifications
**Given** user "testuser" has 2 notifications  
**And** both have `is_read: true`  
**When** `get_unread_count("testuser")` is called  
**Then** the function SHALL return `0`

#### Scenario: User with no notifications
**Given** user "emptyuser" has 0 notifications  
**When** `get_unread_count("emptyuser")` is called  
**Then** the function SHALL return `0`

---

### Requirement: Generate Unique Notification IDs
The user database SHALL generate unique IDs for notifications when they are added.

**Rationale:** Ensure each notification can be uniquely identified for removal and read-status tracking.

#### Scenario: Auto-generate ID if not provided
**Given** a notification_data dictionary without an `id` field  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the database SHALL generate a unique ID  
**And** add it to the notification before storing  
**And** the ID SHALL be unique across all notifications

#### Scenario: Use provided ID if present
**Given** notification_data contains `{"id": "custom_id_001", ...}`  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the notification SHALL be stored with id "custom_id_001"  
**And** no auto-generated ID is created

---

### Requirement: Notification Timestamp Auto-Population
The user database SHALL automatically add a timestamp to notifications if not provided.

**Rationale:** Track when notifications were created for sorting and expiration purposes.

#### Scenario: Auto-add timestamp to notification
**Given** notification_data does not contain a `timestamp` field  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the database SHALL add a `timestamp` field with the current ISO 8601 datetime  
**And** the notification SHALL be stored with the timestamp

#### Scenario: Preserve provided timestamp
**Given** notification_data contains `{"timestamp": "2026-02-01T10:00:00Z", ...}`  
**When** `add_notification("testuser", notification_data)` is called  
**Then** the notification SHALL be stored with timestamp "2026-02-01T10:00:00Z"  
**And** the timestamp is not overwritten

### Requirement: Friends Array in User Schema
UserDatabase SHALL store a friends array for each user containing usernames of their friends.

**Cross-reference**: Supports `friend-list-management` capability.

#### Scenario: New user has empty friends array
**Given** a new user "alice" is created via `create_user()`  
**When** the user data is stored  
**Then** the user record SHALL include a `friends` field initialized as an empty array  
**And** `get_friends("alice")` returns an empty array

#### Scenario: Existing user without friends field
**Given** a user "bob" exists in the database without a `friends` field (legacy data)  
**When** `get_friends("bob")` is called  
**Then** the function SHALL return an empty array  
**And** no error SHALL be logged

---

### Requirement: Add Friend Bidirectionally
UserDatabase SHALL provide a function to create bidirectional friendships between two users.

**Cross-reference**: Core function for `friend-list-management`.

#### Scenario: Add new friendship
**Given** user "alice" exists with friends array []  
**And** user "bob" exists with friends array []  
**When** `add_friend("alice", "bob")` is called  
**Then** "bob" SHALL be added to alice's friends array  
**And** "alice" SHALL be added to bob's friends array  
**And** the database SHALL be saved to disk  
**And** `are_friends("alice", "bob")` returns true  
**And** `are_friends("bob", "alice")` returns true

#### Scenario: Prevent duplicate friendship
**Given** user "alice" has friends array ["bob"]  
**And** user "bob" has friends array ["alice"]  
**When** `add_friend("alice", "bob")` is called  
**Then** no duplicate entry SHALL be added to either friends array  
**And** alice's friends remains ["bob"]  
**And** bob's friends remains ["alice"]  
**And** a warning SHALL be logged

#### Scenario: Reject friendship with non-existent user
**Given** user "alice" exists  
**And** user "ghost" does not exist  
**When** `add_friend("alice", "ghost")` is called  
**Then** no friendship SHALL be created  
**And** alice's friends array SHALL remain unchanged  
**And** an error SHALL be logged

#### Scenario: Prevent self-friending
**Given** user "alice" exists  
**When** `add_friend("alice", "alice")` is called  
**Then** "alice" SHALL NOT be added to their own friends array  
**And** an error SHALL be logged

---

### Requirement: Remove Friend Bidirectionally
UserDatabase SHALL provide a function to remove friendships between two users bidirectionally.

**Cross-reference**: Supports future unfriend feature in `friend-list-management`.

#### Scenario: Remove existing friendship
**Given** user "alice" has friends array ["bob", "charlie"]  
**And** user "bob" has friends array ["alice"]  
**When** `remove_friend("alice", "bob")` is called  
**Then** "bob" SHALL be removed from alice's friends array  
**And** "alice" SHALL be removed from bob's friends array  
**And** alice's friends becomes ["charlie"]  
**And** bob's friends becomes []  
**And** the database SHALL be saved to disk

#### Scenario: Remove non-existent friendship
**Given** user "alice" has friends array ["charlie"]  
**And** user "bob" has friends array []  
**When** `remove_friend("alice", "bob")` is called  
**Then** no error SHALL occur  
**And** alice's friends array SHALL remain ["charlie"]  
**And** bob's friends array SHALL remain []

---

### Requirement: Get Friends with Full Data
UserDatabase SHALL provide a function to retrieve the full list of friends with their user data.

**Cross-reference**: Used by `socials-page-friend-display` to populate UI.

#### Scenario: Get friends for user with multiple friends
**Given** user "alice" has friends array ["bob", "charlie"]  
**And** user "bob" has data {username: "bob", email: "bob@test.de", avatar_path: "res://assets/profile_pictures/man_standard.png"}  
**And** user "charlie" has data {username: "charlie", email: "charlie@test.de", avatar_path: "res://assets/profile_pictures/man_beard.png"}  
**When** `get_friends("alice")` is called  
**Then** the function SHALL return an array containing:
```gdscript
[
  {username: "bob", email: "bob@test.de", avatar_path: "res://assets/profile_pictures/man_standard.png"},
  {username: "charlie", email: "charlie@test.de", avatar_path: "res://assets/profile_pictures/man_beard.png"}
]
```

#### Scenario: Get friends for user with no friends
**Given** user "alice" has friends array []  
**When** `get_friends("alice")` is called  
**Then** the function SHALL return an empty array

#### Scenario: Get friends for non-existent user
**Given** no user "ghost" exists in the database  
**When** `get_friends("ghost")` is called  
**Then** the function SHALL return an empty array  
**And** an error SHALL be logged

#### Scenario: Skip deleted friends
**Given** user "alice" has friends array ["bob", "deleted_user"]  
**And** user "bob" exists  
**And** user "deleted_user" does not exist  
**When** `get_friends("alice")` is called  
**Then** the function SHALL return an array containing only bob's data  
**And** "deleted_user" SHALL be skipped without error

---

### Requirement: Check Friendship Status
UserDatabase SHALL provide a function to check if two users are friends.

**Cross-reference**: Helper for preventing duplicate friends in `friend-list-management`.

#### Scenario: Check existing friendship
**Given** user "alice" has friends array ["bob"]  
**And** user "bob" has friends array ["alice"]  
**When** `are_friends("alice", "bob")` is called  
**Then** the function SHALL return true

#### Scenario: Check non-existent friendship
**Given** user "alice" has friends array ["charlie"]  
**And** user "bob" has friends array []  
**When** `are_friends("alice", "bob")` is called  
**Then** the function SHALL return false

#### Scenario: Check with non-existent user
**Given** user "alice" exists  
**And** user "ghost" does not exist  
**When** `are_friends("alice", "ghost")` is called  
**Then** the function SHALL return false

---

### Requirement: Handle Friend Request Acceptance
UserDatabase SHALL listen to GlobalSignalBus.notification_action_taken and automatically create friendships when friend requests are accepted.

**Cross-reference**: Integrates with `global-signal-bus` and `notification-component`.

#### Scenario: Accept friend request creates friendship
**Given** user "alice" sent a friend request to user "bob"  
**And** user "bob" has a notification with action_data: {type: "friend_request", sender_id: "alice"}  
**And** UserDatabase is connected to GlobalSignalBus.notification_action_taken  
**When** the signal emits with notification_id "notif_123", action "accept", and the action_data contains sender "alice"  
**Then** `add_friend("bob", "alice")` SHALL be called automatically  
**And** both users SHALL have each other in their friends arrays

#### Scenario: Deny friend request does not create friendship
**Given** user "alice" sent a friend request to user "bob"  
**And** user "bob" has a notification with action_data: {type: "friend_request", sender_id: "alice"}  
**When** GlobalSignalBus.notification_action_taken emits with action "deny"  
**Then** no friendship SHALL be created  
**And** neither user SHALL have the other in their friends array

#### Scenario: Ignore non-friend-request notifications
**Given** user "bob" has a notification with action_data: {type: "game_invite"}  
**When** GlobalSignalBus.notification_action_taken emits with action "accept"  
**Then** UserDatabase SHALL not attempt to create a friendship  
**And** no friend-related functions SHALL be called

---

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

### Requirement: Store Multiplayer Matches Array
UserDatabase SHALL include a `multiplayer_matches` array in its data structure to persist match state.

**Rationale:** Enable asynchronous multiplayer gameplay with persistent state across sessions.

#### Scenario: Initialize schema on first load
**Given** the database file does not contain `multiplayer_matches` key  
**When** UserDatabase loads  
**Then** `data.multiplayer_matches` is initialized as an empty array  
**And** the database is saved with the updated schema

---

### Requirement: Provide Match CRUD Operations
UserDatabase SHALL expose methods for creating, retrieving, updating, and querying multiplayer matches.

**Rationale:** Centralize match data management in the database layer.

#### Scenario: Create match returns unique ID
**Given** `create_match(inviter, invitee, rounds, questions)` is called  
**When** the match is created  
**Then** a unique match_id is returned  
**And** the match is appended to `data.multiplayer_matches`

#### Scenario: Retrieve match by ID
**Given** a match with ID "match_123" exists  
**When** `get_match("match_123")` is called  
**Then** the complete match Dictionary is returned

#### Scenario: Update match persists changes
**Given** a match is modified  
**When** `update_match(modified_match)` is called  
**Then** the match in the array is replaced  
**And** the database file is saved

#### Scenario: Query active matches for player
**Given** Player A has 2 active matches and 1 completed match  
**When** `get_active_matches_for_player("PlayerA")` is called  
**Then** only the 2 active matches are returned

---

### Requirement: Handle Game Invite Acceptance Signal
UserDatabase SHALL connect to `GlobalSignalBus.game_invite_accepted` and automatically create matches when invites are accepted.

**Rationale:** Decouple match creation from UI logic and ensure consistent initialization.

#### Scenario: Auto-create match on signal
**Given** GlobalSignalBus.game_invite_accepted emits with ("PlayerA", "PlayerB")  
**When** UserDatabase receives the signal  
**Then** a new match is created between PlayerA and PlayerB  
**And** configuration is extracted from the game invite notification

---

### Requirement: Store Game Configuration in Notification Action Data
Game invite notifications SHALL include `rounds` and `questions` fields in their `action_data`.

**Rationale:** Enable match creation with correct configuration when invite is accepted.

#### Scenario: Enhanced notification structure
**Given** a game invite notification is created  
**When** the notification includes action_data  
**Then** `action_data.rounds` contains the configured rounds value  
**And** `action_data.questions` contains the configured questions value  
**And** existing fields (type, inviter_id) are preserved

---

