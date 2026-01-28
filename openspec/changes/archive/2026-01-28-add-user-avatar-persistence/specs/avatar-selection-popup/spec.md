# avatar-selection-popup Spec Delta

## ADDED Requirements

### Requirement: Enable Avatar Selection via Component Press
Each `AvatarComponent` in the popup SHALL be pressable and SHALL trigger avatar update when pressed.

**Rationale:** Allow users to select their desired avatar by tapping/clicking on it.

#### Scenario: Avatar component press triggers selection
**Given** `ChooseAvatarPopup` is visible with populated avatar components  
**And** user is signed in as "Player123"  
**When** the user presses an `AvatarComponent` displaying "man_beard.png"  
**Then** UserDatabase.update_avatar() is called with "res://assets/profile_pictures/man_beard.png"  
**And** the database update succeeds

#### Scenario: Multiple avatar components are independently selectable
**Given** `ChooseAvatarPopup` contains 5 avatar components  
**When** the user presses the component for "woman_purple.png"  
**Then** only that specific avatar is selected  
**And** other components remain unpressed

---

### Requirement: Update UserAvatar Button After Selection
When an avatar is selected, the `UserAvatar` button on Account Management Screen SHALL update to display the newly selected avatar.

**Rationale:** Provide immediate visual feedback that the selection was successful.

#### Scenario: UserAvatar button reflects new selection
**Given** user's current avatar is "man_standard.png"  
**And** the `UserAvatar` button displays "man_standard.png"  
**When** the user selects "woman_standard.png" from the popup  
**Then** the `UserAvatar` button texture updates to display "woman_standard.png"  
**And** the change is visible immediately without requiring screen refresh

---

### Requirement: Close Popup After Avatar Selection
The `ChooseAvatarPopup` SHALL close automatically and immediately after an avatar is selected.

**Rationale:** Provide quick, mobile-friendly selection flow without requiring additional confirmation steps.

#### Scenario: Popup closes on selection
**Given** `ChooseAvatarPopup` is visible  
**When** the user presses any `AvatarComponent`  
**Then** the popup closes with the standard close animation  
**And** the popup's visible property becomes false

#### Scenario: Drag behavior still functional before selection
**Given** `ChooseAvatarPopup` is visible  
**When** the user drags the popup downward  
**Then** the drag gesture is processed normally  
**And** the popup can be dismissed by dragging if threshold is met  
**And** tapping an avatar (without dragging) still triggers selection

---

### Requirement: Handle Invalid Avatar Paths Gracefully
If an avatar path fails to load, the system SHALL fall back to the default avatar without crashing.

**Rationale:** Ensure robust behavior even if avatar files are missing or corrupted.

#### Scenario: Missing avatar file falls back to default
**Given** user's avatar_path is "res://assets/profile_pictures/deleted_file.png"  
**And** the file does not exist  
**When** the Account Management Screen attempts to load the avatar  
**Then** the texture load returns null  
**And** the system loads "res://assets/profile_pictures/man_standard.png" instead  
**And** the `UserAvatar` button displays the default avatar  
**And** a warning is logged to console

---

## MODIFIED Requirements

### Requirement: AvatarComponent Exposes Configuration Functions
`AvatarComponent` SHALL provide utility functions to set its picture and name, and SHALL store the texture path for retrieval.

**Changes from previous version:**
- Added internal storage of texture_path for later retrieval
- Added get_avatar_path() method

#### Scenario: Set avatar picture and store path
**Given** an `AvatarComponent` instance exists  
**When** `set_avatar_picture("res://assets/profile_pictures/man_suit.png")` is called  
**Then** the `Picture` TextureRect displays the loaded texture  
**And** the component internally stores the path "res://assets/profile_pictures/man_suit.png"

#### Scenario: Retrieve stored avatar path
**Given** an `AvatarComponent` has been configured with `set_avatar_picture("res://assets/profile_pictures/woman_purple.png")`  
**When** `get_avatar_path()` is called  
**Then** it returns "res://assets/profile_pictures/woman_purple.png"

---
