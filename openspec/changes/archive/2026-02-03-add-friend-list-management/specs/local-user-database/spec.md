# Spec Delta: Local User Database (Friend List Management)

## ADDED Requirements

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

## MODIFIED Requirements

None. All changes are additive to the existing local-user-database specification.
