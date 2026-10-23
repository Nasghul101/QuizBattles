## MODIFIED Requirements

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

### Requirement: Notification Timestamp Support
The system SHALL attach a Firebase-compatible creation timestamp to each notification and preserve it when the notification is read.

#### Scenario: Notification created with timestamp
- **GIVEN** a notification is created without a timestamp
- **WHEN** it is stored in Firestore
- **THEN** it receives a timestamp that can be used for ordering and expiry

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

## REMOVED Requirements

### Requirement: Migrate Existing Users with Friend Wins
**Reason**: The existing local JSON database is not a source for new Firebase records, and this migration only served its local schema.
**Migration**: New Firestore profiles initialize `friend_wins` with an empty map.

## ADDED Requirements

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
