# account-management-screen Spec Delta

## ADDED Requirements

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
