# avatar-selection-popup Specification

## Purpose
TBD - created by archiving change 2026-01-25-populate-avatar-chooser-popup. Update Purpose after archive.
## Requirements
### Requirement: Display Avatar Options in Modal Popup
When the user presses the `UserAvatar` button on the Account Management Screen, the `ChooseAvatarPopup` SHALL display as a modal overlay.

#### Scenario: UserAvatar button press shows modal popup
- **Given**: User is on Account Management Screen
- **When**: User presses the `UserAvatar` button
- **Then**: `ChooseAvatarPopup` becomes visible with modal behavior (blocks interaction with elements behind it)

---

### Requirement: Populate Avatar Container with Available Avatars
The `AvatarContainer` SHALL be populated with `AvatarComponent` instances for each PNG file in the `profile_pictures` folder.

#### Scenario: Avatar container populated on popup display
- **Given**: `ChooseAvatarPopup` is about to be shown
- **When**: `_on_user_avatar_pressed()` is called
- **Then**: `AvatarContainer` contains exactly one `AvatarComponent` for each PNG in `res://assets/profile_pictures/`
- **And**: Each component displays the correct image texture
- **And**: Each component displays the filename as a display name (e.g., "man_beard.png" → "Man Beard")

#### Scenario: Avatar container is cleared before repopulation
- **Given**: User pressed `UserAvatar` once and the popup was shown
- **When**: User presses `UserAvatar` again
- **Then**: Previous avatar components are removed
- **And**: `AvatarContainer` is repopulated with fresh instances

---

### Requirement: AvatarComponent Exposes Configuration Functions
`AvatarComponent` SHALL provide utility functions to set its picture and name.

#### Scenario: Set avatar picture via utility function
- **Given**: An `AvatarComponent` instance exists
- **When**: `set_avatar_picture(texture_path: String)` is called with a valid texture path
- **Then**: The `Picture` TextureRect displays the loaded texture

#### Scenario: Set avatar name via utility function
- **Given**: An `AvatarComponent` instance exists
- **When**: `set_avatar_name(name: String)` is called
- **Then**: The `NameLabel` displays the provided text

---

