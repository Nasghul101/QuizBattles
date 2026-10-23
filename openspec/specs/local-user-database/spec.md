# local-user-database Specification

## Purpose
Defines local user storage, authentication data, social data, and player statistics.
## Requirements
### Requirement: User Registration
The system SHALL create a Firebase Authentication account with the supplied email and password and create a corresponding Firestore profile containing the unique username, default avatar, notifications, friends, and statistics. Registration SHALL report success only after both the Auth account and profile are available.

**Rationale:** Give each player a shared, persistent identity and profile without storing credentials in the game database.

#### Scenario: Successful user registration
- **GIVEN** the email and username are not already registered
- **WHEN** the user submits a valid username, password, and email
- **THEN** Firebase Authentication creates the account and Firestore stores its profile
- **AND** the profile starts with empty notifications, friends, and statistics
- **AND** the returned user data excludes the password

#### Scenario: Profile creation fails after Auth account creation
- **GIVEN** Firebase Authentication creates the account but Firestore cannot create the profile
- **WHEN** registration completes with a backend error
- **THEN** registration SHALL NOT return success
- **AND** the error SHALL be surfaced without substituting local or default user data

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
The system SHALL authenticate users with email and password through Firebase Authentication and set the current user session only after the corresponding Firestore profile is loaded.

**Rationale:** Authenticate the account using Firebase's supported email/password provider and expose its shared game profile.

#### Scenario: Successful sign-in
- **GIVEN** a Firebase Auth account and matching Firestore profile exist for `player@example.com`
- **WHEN** the user signs in with that email and its valid password
- **THEN** the user is authenticated and the current user session is set from the profile
- **AND** the result includes the profile username and email

#### Scenario: Reject invalid credentials
- **GIVEN** no Firebase Auth account matches the supplied credentials
- **WHEN** sign-in completes
- **THEN** authentication fails with a Firebase Auth error
- **AND** the current user session remains empty

#### Scenario: Reject non-existent user
- **GIVEN** no Firebase Auth account exists for the supplied email
- **WHEN** sign-in is attempted
- **THEN** authentication fails with the corresponding Firebase Auth error
- **AND** the current user session remains empty

#### Scenario: Reject incorrect password
- **GIVEN** a Firebase Auth account exists for the supplied email
- **WHEN** an incorrect password is submitted
- **THEN** authentication fails with the corresponding Firebase Auth error
- **AND** the current user session remains empty

#### Scenario: Surface authentication service failure
- **GIVEN** Firebase Authentication is unavailable
- **WHEN** sign-in is attempted
- **THEN** the service failure is returned to the caller
- **AND** the system SHALL NOT report a successful sign-in

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
The system SHALL delegate password storage and verification to Firebase Authentication. The game SHALL NOT hash, persist, or write passwords to Firestore or the legacy user JSON file.

**Rationale:** Keep password handling within Firebase Authentication rather than implementing a custom credential store.

#### Scenario: Register password through Firebase Authentication
- **GIVEN** a user registers with a password
- **WHEN** account creation is submitted
- **THEN** the password is sent only to Firebase Authentication
- **AND** the Firestore profile and local user-data cache contain no password or password hash

#### Scenario: Sign in without reading stored credentials
- **GIVEN** a registered user supplies a password
- **WHEN** sign-in is submitted
- **THEN** Firebase Authentication verifies the password
- **AND** the game does not read a stored password hash from local user data

#### Scenario: Hash password on registration
- **GIVEN** a user registers with a password
- **WHEN** the account is created
- **THEN** Firebase Authentication stores and manages the credential
- **AND** the game stores no password or password hash

#### Scenario: Verify hashed password on sign-in
- **GIVEN** a user has a Firebase Auth account
- **WHEN** the user signs in with a password
- **THEN** Firebase Authentication verifies the credential
- **AND** the game does not retrieve or compare a locally stored hash

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
The system SHALL associate notifications with a Firestore user profile and return the user's notifications as an array containing their complete notification data.

**Rationale:** Preserve the notification data contract while storing each user's shared notifications remotely.

#### Scenario: New user has no notifications
- **GIVEN** a new user profile is created
- **WHEN** the user's notifications are queried
- **THEN** the result is an empty array

#### Scenario: New user has empty notifications array
- **GIVEN** a new user profile is created
- **WHEN** the notifications array is requested
- **THEN** the result is an empty array

#### Scenario: Existing notifications persist across sessions
- **GIVEN** a user has two notifications stored in Firestore
- **WHEN** the user signs in from a later session and loads notifications
- **THEN** both notifications and their original fields are returned

#### Scenario: Existing users retain notifications on save/load
- **GIVEN** a user has two notifications stored in Firestore
- **WHEN** the application restarts and reloads that user's notifications
- **THEN** both notifications and all original fields are returned

### Requirement: Add Notification to User
The user database SHALL create a notification associated with the specified recipient in Firestore and SHALL return success only after the write succeeds.

**Rationale:** Deliver notifications across sessions and devices without storing them in a local file.

#### Scenario: Add notification to existing user
- **GIVEN** the recipient exists and the notification data is valid
- **WHEN** the notification is added
- **THEN** the recipient's remote notification data includes the notification
- **AND** the operation completes successfully after Firebase confirms the write

#### Scenario: Reject notification for non-existent user
- **GIVEN** no user exists for the requested recipient
- **WHEN** a notification is added
- **THEN** no notification is stored
- **AND** the caller receives an explicit error

### Requirement: Remove Notification from User
The user database SHALL remove the specified notification from Firestore without changing other notifications for the recipient.

**Rationale:** Keep notification dismissal and expiry synchronized across devices.

#### Scenario: Remove notification by ID
- **GIVEN** a recipient has a notification with the requested ID
- **WHEN** the notification is removed
- **THEN** that remote notification is deleted
- **AND** other notifications remain unchanged

#### Scenario: Remove a missing notification
- **GIVEN** the requested notification ID does not exist
- **WHEN** removal is attempted
- **THEN** no other notification is changed
- **AND** the operation reports the backend result explicitly

#### Scenario: Gracefully handle missing notification ID
- **GIVEN** the requested notification ID does not exist
- **WHEN** removal is attempted
- **THEN** the user's other notifications remain unchanged
- **AND** no unrelated Firebase record is modified

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
The user database SHALL persist notification read-state changes in Firestore for the notification recipient.

**Rationale:** Keep unread state consistent across sessions and devices.

#### Scenario: Mark notification as read
- **GIVEN** the recipient has an unread notification
- **WHEN** it is marked as read
- **THEN** Firestore stores `is_read: true`

#### Scenario: Already-read notification
- **GIVEN** the notification is already marked as read
- **WHEN** it is marked as read again
- **THEN** it remains read and no other notification is changed

#### Scenario: Handle already-read notification
- **GIVEN** the notification is already marked as read
- **WHEN** it is marked as read again
- **THEN** it remains read and no other notification is changed

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
The system SHALL provide each user's friends as an array of usernames backed by Firestore friendship records.

**Rationale:** Keep the existing friends-list behavior while representing shared relationships remotely.

#### Scenario: New user has no friends
- **GIVEN** a new user profile is created
- **WHEN** the user's friends are queried
- **THEN** the result is an empty array

#### Scenario: New user has empty friends array
- **GIVEN** a new user profile is created
- **WHEN** `get_friends()` is called
- **THEN** it returns an empty array

#### Scenario: Read friends for an existing user
- **GIVEN** Firestore contains friendship records for the user
- **WHEN** the user's friends are queried
- **THEN** the result contains the usernames of those friends

#### Scenario: Existing user without friends field
- **GIVEN** a Firestore profile has no friendship records
- **WHEN** the user's friends are queried
- **THEN** the result is an empty array without an error

### Requirement: Add Friend Bidirectionally
The system SHALL create one Firestore friendship record that represents the relationship in both directions.

**Cross-reference**: Core function for `friend-list-management`.

#### Scenario: Add new friendship
- **GIVEN** both users exist and no friendship record exists
- **WHEN** the friendship is accepted
- **THEN** one remote relationship is stored for both users
- **AND** each user's friends query includes the other username

#### Scenario: Prevent duplicate friendship
- **GIVEN** a friendship already exists
- **WHEN** it is added again
- **THEN** no duplicate relationship is created

#### Scenario: Reject friendship with non-existent user
- **GIVEN** either participant does not exist
- **WHEN** a friendship is added
- **THEN** no relationship is created and an explicit error is returned

#### Scenario: Prevent self-friending
- **GIVEN** both participant identifiers refer to the same user
- **WHEN** a friendship is added
- **THEN** no relationship is created and an error is returned

### Requirement: Remove Friend Bidirectionally
The system SHALL remove the Firestore friendship record representing the relationship between two users.

**Cross-reference**: Supports the unfriend feature in `friend-list-management`.

#### Scenario: Remove existing friendship
- **GIVEN** a friendship exists between two users
- **WHEN** either user removes the friend
- **THEN** the shared relationship is removed
- **AND** neither user's friends query includes the other

#### Scenario: Remove non-existent friendship
- **GIVEN** no friendship exists between the users
- **WHEN** removal is attempted
- **THEN** no other relationship is changed

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
The system SHALL attach a Firebase-compatible creation timestamp to each notification and preserve it when the notification is read.

#### Scenario: Notification created with timestamp
- **GIVEN** a notification is created without a timestamp
- **WHEN** it is stored in Firestore
- **THEN** it receives a timestamp that can be used for ordering and expiry

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
The system SHALL store each multiplayer match as a Firestore match record addressable by a unique match ID.

**Rationale:** Enable asynchronous multiplayer gameplay with persistent state shared across sessions.

#### Scenario: No match records exist
- **GIVEN** no match has been created for a user
- **WHEN** the user's matches are queried
- **THEN** the result is an empty array
- **AND** no local database file is created to initialize match storage

#### Scenario: Initialize schema on first load
- **GIVEN** no Firestore match record exists
- **WHEN** the user requests matches
- **THEN** an empty result is returned without creating a local `multiplayer_matches` array

### Requirement: Provide Match CRUD Operations
The system SHALL expose create, retrieve, update, delete, and player-query operations backed by Firestore match records.

**Rationale:** Centralize match data management while allowing participants to resume matches on another device.

#### Scenario: Create match returns unique ID
- **GIVEN** two valid participants and match configuration are supplied
- **WHEN** a match is created
- **THEN** a unique match ID is returned after Firestore confirms creation

#### Scenario: Retrieve match by ID
- **GIVEN** a match with the requested ID exists
- **WHEN** it is retrieved
- **THEN** the complete match data is returned

#### Scenario: Update match persists changes
- **GIVEN** a participant updates a match
- **WHEN** the update succeeds
- **THEN** the Firestore match record contains the updated data

#### Scenario: Query active matches for player
- **GIVEN** a player has active and completed matches
- **WHEN** active matches are queried
- **THEN** only that player's active matches are returned

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

### Requirement: Store Friend-Specific Win Counts
The system SHALL store a `friend_wins` Dictionary in each user record mapping friend usernames to win counts against that friend.

**Rationale:** Enable players to track competitive head-to-head records with specific friends, providing personalized rivalry metrics.

**Constraints:**
- `friend_wins` SHALL be a Dictionary type (compatible with Firebase object structure)
- Keys SHALL be friend usernames (String)
- Values SHALL be win counts (int)
- New users SHALL have `friend_wins` initialized as empty Dictionary `{}`

#### Scenario: New user has empty friend_wins
**Given** no user exists with username "NewPlayer"  
**When** `create_user("NewPlayer", "password", "player@example.com")` is called  
**Then** the user record is created with `friend_wins: {}`  
**And** the user data contains an empty friend_wins Dictionary

#### Scenario: Friend wins persist across sessions
**Given** user "PlayerA" has `friend_wins: {"PlayerB": 3, "PlayerC": 1}`  
**When** the database is saved to disk  
**And** the game is restarted  
**And** the database is loaded  
**Then** user "PlayerA" SHALL have exactly the same friend_wins Dictionary  
**And** `friend_wins["PlayerB"]` equals 3  
**And** `friend_wins["PlayerC"]` equals 1

---

### Requirement: Update Player Statistics on Match Completion
The system SHALL update both players' statistics exactly once for a completed multiplayer match and persist the match-processing state and statistics in Firebase.

**Rationale:** Preserve consistent match results and statistics when the app is used across devices.

**Constraints:**
- SHALL only update statistics for multiplayer matches
- SHALL only process a match once
- SHALL update both players' statistics atomically
- SHALL emit `GlobalSignalBus.player_stats_updated` for each affected player after successful persistence

#### Scenario: Update winner and loser statistics
- **GIVEN** an unprocessed completed match has a winner and a loser
- **WHEN** its statistics are processed
- **THEN** the winner and loser statistics are updated in one atomic backend operation
- **AND** the match is marked as processed

#### Scenario: Draw leaves win and loss counts unchanged
- **GIVEN** an unprocessed completed match is a draw
- **WHEN** its statistics are processed
- **THEN** wins and losses remain unchanged and the match is marked as processed

#### Scenario: Prevent duplicate statistics updates
- **GIVEN** a match has already been processed
- **WHEN** statistics processing is requested again
- **THEN** no statistics are changed and no update signals are emitted

#### Scenario: Backend failure does not report success
- **GIVEN** Firebase cannot atomically persist the match and statistics
- **WHEN** statistics processing is attempted
- **THEN** the error is surfaced and the match is not treated as successfully processed

#### Scenario: Update winner statistics after match completion
- **GIVEN** a completed match has a winner and an unprocessed statistics state
- **WHEN** statistics are processed
- **THEN** the winner's wins and current streak are updated in the Firebase transaction

#### Scenario: Update loser statistics after match completion
- **GIVEN** a completed match has a loser and an unprocessed statistics state
- **WHEN** statistics are processed
- **THEN** the loser's losses are updated and current streak is reset in the Firebase transaction

#### Scenario: Draw leaves statistics unchanged
- **GIVEN** a completed match is a draw
- **WHEN** statistics are processed
- **THEN** wins and losses remain unchanged and the match is marked processed

#### Scenario: Update friend wins when players are friends
- **GIVEN** the winner and loser have a friendship record
- **WHEN** the winner completes the match
- **THEN** only the winner's friend-specific win count is incremented

#### Scenario: Skip friend wins when players are not friends
- **GIVEN** the winner and loser do not have a friendship record
- **WHEN** the winner completes the match
- **THEN** no friend-specific win count is changed

#### Scenario: Initialize friend wins entry on first win against friend
- **GIVEN** the winner has no friend-specific count for the opponent
- **WHEN** the winner completes a match against that friend
- **THEN** the winner's friend-specific count is created as one

#### Scenario: Emit signals for both players
- **GIVEN** both players' statistics were committed successfully
- **WHEN** the statistics transaction completes
- **THEN** `GlobalSignalBus.player_stats_updated` is emitted for both players

### Requirement: Update Category Statistics After Match Completion
The system SHALL update category statistics (played count and win count) for both players when a match completes, tracking each category that appeared in the match rounds.

**Rationale:** Provide category-level performance tracking to show users their strengths and weaknesses across different quiz categories.

**Implementation:** Category updates occur in `update_player_statistics()` function after winner determination.

#### Scenario: Increment category played count for both players
**Given** user "Player1" has `category_stats: {"History": {"played": 10, "wins": 6}}`  
**And** user "Player2" has `category_stats: {"History": {"played": 8, "wins": 3}}`  
**When** `update_player_statistics(match_data)` is called for a match with one History round  
**Then** Player1's History SHALL be updated to `{"played": 11, "wins": 6}` (or 7 if winner)  
**And** Player2's History SHALL be updated to `{"played": 9, "wins": 3}` (or 4 if winner)

#### Scenario: Increment category win count for winner only
**Given** match with categories ["History", "Science", "Geography"]  
**And** Player1 wins the match  
**When** `update_player_statistics(match_data)` is called  
**Then** Player1's History SHALL increment both `played` and `wins`  
**And** Player1's Science SHALL increment both `played` and `wins`  
**And** Player1's Geography SHALL increment both `played` and `wins`  
**And** Player2's categories SHALL increment only `played`, not `wins`

#### Scenario: Initialize new category with both played and wins
**Given** user "Player1" has `category_stats: {}` (empty)  
**When** `update_player_statistics(match_data)` is called for a match with "History" category  
**Then** Player1's `category_stats` SHALL be updated to `{"History": {"played": 1, "wins": 0 or 1}}`  
**And** the category SHALL be properly initialized with nested structure

#### Scenario: Track multiple categories in single match
**Given** match with 3 rounds using categories ["History", "Science", "History"]  
**When** category statistics are updated  
**Then** History SHALL increment `played` by 2 (appears twice)  
**And** Science SHALL increment `played` by 1  
**And** winner's categories SHALL also increment `wins` by the same amounts

#### Scenario: Handle draw with category updates
**Given** match ends in a draw with categories ["History", "Science"]  
**When** `update_player_statistics(match_data)` is called  
**Then** both players' History and Science SHALL increment `played` by 1  
**And** neither player's `wins` SHALL be incremented (draw means no winner)  
**And** `total_games` SHALL still be incremented for both players

#### Scenario: Extract categories from match rounds_data
**Given** `match_data.rounds_data` contains `[{"category": "History", ...}, {"category": "Science", ...}]`  
**When** categories are extracted for statistics update  
**Then** the system SHALL iterate through `rounds_data`  
**And** extract the `category` field from each round  
**And** build a list of categories to update statistics for

#### Scenario: Save database after category updates
**Given** category statistics have been updated for both players  
**When** `update_player_statistics()` completes  
**Then** `_save_database()` SHALL be called to persist changes  
**And** the match SHALL be updated with `stats_processed: true` flag

---

### Requirement: Get User Data Safe for Display
The system SHALL provide a `get_user_data_for_display()` method that returns a sanitized Dictionary containing username, avatar_path, wins, losses, current_streak, total_games, friend_wins, and category_stats for UI display purposes.

**Rationale:** Enable UI components to display user profile information and friend-specific win records while excluding sensitive data like passwords.

#### Scenario: Include friend_wins in display data
**Given** user "PlayerA" exists with `friend_wins: {"PlayerB": 3, "PlayerC": 1}`  
**When** `get_user_data_for_display("PlayerA")` is called  
**Then** the returned Dictionary includes `"friend_wins": {"PlayerB": 3, "PlayerC": 1}`  
**And** all other fields (username, avatar_path, wins, losses, current_streak, total_games, category_stats) are still included

### Requirement: Track Total Games Played
The system SHALL store a `total_games` integer in each Firestore profile and increment it for each completed multiplayer match, including draws.

**Rationale:** Allow account screens to report the total number of completed matches.

#### Scenario: New profile receives total_games
- **GIVEN** a new Firebase profile is created
- **WHEN** its statistics are initialized
- **THEN** `total_games`, `wins`, and `losses` are zero

#### Scenario: New user receives total_games field
- **GIVEN** a new Firebase profile is created
- **WHEN** its statistics are initialized
- **THEN** it contains `total_games: 0`

#### Scenario: Increment total games after completion
- **GIVEN** a completed match includes two players
- **WHEN** match statistics are successfully processed
- **THEN** both profiles' `total_games` values increase by one

#### Scenario: Total games incremented after match completion
- **GIVEN** both players have existing total-games counts
- **WHEN** a completed match is processed
- **THEN** each player's count increases by one

#### Scenario: Total games incremented even in draw
- **GIVEN** a completed match is a draw
- **WHEN** match statistics are successfully processed
- **THEN** both players' total-games counts increase by one
- **AND** their wins and losses remain unchanged

#### Scenario: Include total games in display data
- **GIVEN** a profile has a stored `total_games` value
- **WHEN** display data is requested
- **THEN** the returned data includes that value

#### Scenario: Total games included in display data
- **GIVEN** a profile has a stored `total_games` value
- **WHEN** display data is requested
- **THEN** the returned data includes `total_games`

#### Scenario: Migrate existing users with total_games field
- **GIVEN** a Firestore profile predates the `total_games` field
- **WHEN** the profile is loaded
- **THEN** the Firebase profile schema is completed with a zero default without reading the legacy JSON file

### Requirement: Restructure Category Stats to Track Wins and Played
The system SHALL store each category statistic in the profile as `{"played": int, "wins": int}` and preserve that structure in returned display data.

**Rationale:** Support category-specific performance metrics without relying on migration of the local JSON schema.

#### Scenario: New profile has empty category stats
- **GIVEN** a new Firebase profile is created
- **WHEN** its statistics are initialized
- **THEN** `category_stats` is an empty dictionary

#### Scenario: New user receives empty category stats with new structure
- **GIVEN** a new Firebase profile is created
- **WHEN** its category statistics are initialized
- **THEN** `category_stats` is an empty dictionary

#### Scenario: Record category results
- **GIVEN** a completed match includes category results
- **WHEN** statistics are processed
- **THEN** category entries use integer `played` and `wins` values in the nested format

#### Scenario: Category stats stored in new nested format
- **GIVEN** category results are processed for a user
- **WHEN** the Firebase profile is updated
- **THEN** each category has integer `played` and `wins` values

#### Scenario: Return category stats for display
- **GIVEN** a profile contains category statistics
- **WHEN** profile display data is requested
- **THEN** the nested category statistics are included unchanged

#### Scenario: Category stats included in display data with new structure
- **GIVEN** a Firestore profile has nested category statistics
- **WHEN** profile display data is requested
- **THEN** the nested category statistics are returned unchanged

#### Scenario: Keep category stats out of current-user summary
- **GIVEN** a user is signed in
- **WHEN** the current-user summary is requested
- **THEN** it contains only the established current-user fields and excludes `category_stats`

#### Scenario: Category stats excluded from current user data
- **GIVEN** a user is signed in
- **WHEN** the current-user summary is requested
- **THEN** it excludes `category_stats`

#### Scenario: Migrate existing category stats to new format
- **GIVEN** a Firestore profile has an older category-stat representation
- **WHEN** that profile is loaded
- **THEN** its category statistics are normalized to the current nested format without reading the legacy JSON file

#### Scenario: Migrate user without category stats field
- **GIVEN** a Firestore profile has no `category_stats` field
- **WHEN** the profile is loaded
- **THEN** the field is initialized as an empty dictionary without reading the legacy JSON file

#### Scenario: Empty category stats remain empty after migration
- **GIVEN** a Firestore profile has empty category statistics
- **WHEN** the current profile schema is loaded
- **THEN** the field remains empty and no placeholder categories are persisted

### Requirement: Provide Placeholder Category Data Generation
The system SHALL provide a helper function to generate placeholder category statistics for testing and UI development before real category tracking is implemented.

**Rationale:** Allow social features to be developed and tested visually without waiting for gameplay integration.

**Note:** This is temporary functionality marked with TODO comments for future replacement.

#### Scenario: Generate random placeholder category data
**Given** no real category tracking exists yet  
**When** `_generate_placeholder_category_stats()` is called  
**Then** it SHALL return a Dictionary with 3 random category names  
**And** each category SHALL have a random play count between 1 and 20  
**And** the function SHALL include comment: "TODO: Replace with real category tracking from gameplay_screen match completion"

#### Scenario: Use placeholder data when category stats empty
**Given** user "Player123" has category_stats: {} (empty)  
**When** UI components need to display category preferences  
**Then** they MAY call `_generate_placeholder_category_stats()` to get display data  
**And** the generated data SHALL NOT be saved to the database (display only)

---

### Requirement: Category Stats Data Type and Constraints
The `category_stats` field SHALL be a Dictionary where keys are category name Strings and values are nested Dictionaries with integer fields `"played"` and `"wins"`.

**Rationale:** Provide clear data structure for tracking both play frequency and wins per category.

**Constraints:**
- Keys: String type (category names from TriviaQuestionService.CATEGORY_MAPPING)
- Values: Dictionary with `"played": int` (non-negative) and `"wins": int` (non-negative)
- Empty dictionary allowed (new users, no games played)

#### Scenario: Valid category stats format
**Given** a user record is being created or updated  
**When** category_stats is set  
**Then** it SHALL be a Dictionary type  
**And** all keys SHALL be Strings  
**And** all values SHALL be Dictionaries with "played" and "wins" integer fields >= 0

---

### Requirement: Persist Shared User Data in Firestore
The system SHALL read and write profiles, notification records, friendship records, match records, and statistics through Firebase Auth and Firestore, and SHALL NOT use the local user JSON file as a source or destination for those records.

#### Scenario: Load shared data from Firebase
- **GIVEN** the signed-in user has profile and game data in Firestore
- **WHEN** the application requests that data
- **THEN** it returns the remote records after the Firebase operation completes

#### Scenario: Backend operation fails
- **GIVEN** a Firebase read or write fails
- **WHEN** the operation completes
- **THEN** the caller receives an explicit failure
- **AND** the system SHALL NOT substitute a successful result from stale in-memory or local JSON data

### Requirement: Enforce Firebase Data Ownership
The system SHALL use Firebase Authentication identity and Firestore security rules to restrict profile and private user-data access to authorized users and match or relationship participants.

#### Scenario: User cannot access another user's private account data
- **GIVEN** a signed-in user requests another user's private data
- **WHEN** Firestore evaluates the request
- **THEN** the request is denied
- **AND** public profile search returns no password, authentication token, or private email data

#### Scenario: Unauthenticated user attempts protected data access
- **GIVEN** no Firebase Auth user is signed in
- **WHEN** a protected Firestore read or write is attempted
- **THEN** Firestore security rules deny the operation

### Requirement: Isolate Development and Test Data in Firebase Emulators
Development and test runs SHALL use the Firebase Authentication, Firestore, and Cloud Functions emulators. They SHALL NOT contact production services when an emulator is unavailable or misconfigured.

#### Scenario: Development run connects to emulators
- **GIVEN** the Authentication, Firestore, and Functions emulators are configured and running
- **WHEN** a development or test run performs Auth, Firestore, or match-statistics operations
- **THEN** the operations reach only the configured local emulators

#### Scenario: Emulator is unavailable
- **GIVEN** an emulator endpoint cannot be reached
- **WHEN** a development or test run performs an operation
- **THEN** the operation fails visibly
- **AND** no request is redirected to a production Firebase endpoint

### Requirement: Do Not Import the Legacy User Database
The system SHALL NOT read, migrate, seed from, or write `data/user_database.json` during startup or any account or game-data operation.

#### Scenario: Start with legacy JSON present
- **GIVEN** `data/user_database.json` contains prior local data
- **WHEN** the application starts
- **THEN** no data from that file is sent to Firebase
- **AND** new Firebase accounts and records start without those legacy users or matches

#### Scenario: Start without legacy JSON
- **GIVEN** `data/user_database.json` is absent
- **WHEN** the application starts
- **THEN** Firebase-backed account and game-data behavior remains available
- **AND** the application does not create the JSON file
