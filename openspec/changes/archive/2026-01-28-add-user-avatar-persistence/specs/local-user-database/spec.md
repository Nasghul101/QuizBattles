# local-user-database Spec Delta

## ADDED Requirements

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
