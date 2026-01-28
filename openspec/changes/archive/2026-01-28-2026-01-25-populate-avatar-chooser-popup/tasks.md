# Tasks: Populate Avatar Chooser Popup

## Task List

### 1. Add utility functions to AvatarComponent
- [x] Add `set_avatar_picture(texture_path: String)` function to load texture from path
- [x] Add `set_avatar_name(name: String)` function to set the name label text
- [x] Validate: Functions set Picture and NameLabel correctly
- **Depends on**: Nothing
- **Blocking**: Task 3

### 2. Configure ChooseAvatarPopup as modal
- [x] Set mouse_filter on PanelContainer to MOUSE_FILTER_STOP to block background interaction
- [x] Validate: Clicks on popup don't interact with elements behind it
- **Depends on**: Nothing
- **Blocks**: Task 3

### 3. Implement UserAvatar button press handler
- [x] Implement `_on_user_avatar_pressed()` in `account_management_screen.gd`
- [x] Clear existing children in AvatarContainer
- [x] Scan `res://assets/profile_pictures/` for `.png` files
- [x] For each PNG:
  - Instantiate AvatarComponent scene
  - Add to AvatarContainer
  - Call `set_avatar_picture()` with resource path
  - Call `set_avatar_name()` with display name (filename without extension, snake_case → Title Case)
- [x] Set popup visible
- [x] Validate: Popup shows with correct number of avatar components
- **Depends on**: Task 1, Task 2
- **Blocks**: Nothing

## Validation Criteria

- [x] Pressing UserAvatar button opens the modal popup
- [x] Popup contains exactly 5 avatar components (one per PNG in profile_pictures)
- [x] Each component displays the correct image
- [x] Each component displays the correct name (filename converted from snake_case to Title Case)
- [x] Clicking behind the popup doesn't interact with background UI
