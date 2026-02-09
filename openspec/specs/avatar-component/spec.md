# avatar-component Specification

## Purpose
The avatar_component provides a reusable UI element for displaying user avatars with profile pictures and names, supporting clickable interactions for navigation to friend profiles or multiplayer matches.

## Requirements

### Requirement: Display Avatar Picture and Name
The avatar component SHALL display a profile picture and name label.

**Rationale:** Provide visual representation of users in the UI.

#### Scenario: Set and display avatar picture
**Given** an avatar_component instance  
**When** `set_avatar_picture("res://assets/profile_pictures/man_beard.png")` is called  
**Then** the Picture TextureRect displays the man_beard.png image

#### Scenario: Set and display avatar name
**Given** an avatar_component instance  
**When** `set_avatar_name("PlayerOne")` is called  
**Then** the NameLabel displays "PlayerOne"

---

### Requirement: Retrieve Avatar Texture Path
The avatar component SHALL provide a method to retrieve the stored avatar texture path.

**Rationale:** Enable querying of the current avatar path for persistence or display purposes.

#### Scenario: Get stored avatar path
**Given** an avatar_component with texture set to "res://assets/profile_pictures/woman_purple.png"  
**When** `get_avatar_path()` is called  
**Then** it returns "res://assets/profile_pictures/woman_purple.png"

---

### Requirement: Emit Signal on Avatar Click
The avatar component SHALL emit an `avatar_clicked` signal with the user_id when the button is pressed.

**Rationale:** Enable parent scenes to react to avatar clicks without tight coupling, supporting the account popup integration pattern.

#### Scenario: Emit user_id on button press
**Given** an avatar_component has user_id set to "PlayerOne"  
**When** the avatar button is pressed  
**Then** the signal `avatar_clicked("PlayerOne")` is emitted

---

### Requirement: Store and Retrieve User ID
The avatar component SHALL provide methods to store and retrieve a user_id string.

**Rationale:** Enable the avatar to know which user it represents so it can pass that information when clicked.

#### Scenario: Set and get user_id
**Given** an avatar_component instance  
**When** `set_user_id("PlayerOne")` is called  
**Then** `get_user_id()` returns "PlayerOne"

---

### Requirement: Store Match ID for Multiplayer Navigation
The avatar_component SHALL provide a method to store a match_id and emit it when clicked.

**Rationale:** Enable navigation to specific multiplayer matches from friendly_battle_page.

#### Scenario: Set and emit match_id
**Given** an avatar_component instance  
**When** `set_match_id("match_123")` is called  
**Then** the match_id is stored internally  
**And** when the avatar is clicked, `avatar_clicked("match_123")` is emitted

#### Scenario: Prioritize user_id over match_id
**Given** an avatar_component has both user_id and match_id set  
**When** the avatar is clicked  
**Then** user_id is emitted (existing friend profile behavior)  
**And** match_id is only emitted if user_id is empty

---
