# Design Document: Populate Avatar Chooser Popup

## Architecture Overview

### Component Responsibilities

**AccountManagementScreen (`account_management_screen.gd`)**
- Owns the `ChooseAvatarPopup` instance
- Handles `UserAvatar` button press → shows popup and populates it
- Iterates through profile pictures folder to discover available avatars
- Instantiates `AvatarComponent` for each picture
- Calls utility functions on `AvatarComponent` to configure it with picture path and display name

**AvatarComponent (`avatar_component.gd`)**
- Provides `set_avatar_picture(texture_path: String)` to load and display a texture
- Provides `set_avatar_name(name: String)` to display the avatar's display name
- Component itself is passive—only receives function calls, does not scan the filesystem

**ChooseAvatarPopup (Scene)**
- Configured as modal (mouse filter behavior on PanelContainer)
- Contains `AvatarContainer` (GridContainer) to hold avatar component instances

## Implementation Details

### Popup Modal Behavior
Set `mouse_filter` to `MOUSE_FILTER_STOP` on `ChooseAvatarPopup/PanelContainer` to prevent clicks from passing through to background elements.

### Avatar Discovery & Instantiation Flow
1. User presses `UserAvatar` button → `_on_user_avatar_pressed()` triggered
2. Function clears existing children in `AvatarContainer`
3. Function scans `res://assets/profile_pictures/` for `.png` files
4. For each PNG found:
   - Instantiate `AvatarComponent` scene
   - Add as child to `AvatarContainer`
   - Call `set_avatar_picture(resource_path)` 
   - Call `set_avatar_name(display_name)` (derived from filename, e.g., "man_beard.png" → "Man Beard")
5. Set popup visible

### Filename to Display Name Conversion
Convert snake_case filenames to Title Case:
- `man_beard.png` → "Man Beard"
- `woman_standard.png` → "Woman Standard"
- Split on `_`, capitalize each word, join with space

## Why This Design

- **Single Responsibility**: `AvatarComponent` only knows how to display a picture and name; it doesn't scan folders
- **Reusability**: Utility functions on `AvatarComponent` can be called from any context
- **Testability**: Screen logic (folder scanning + instantiation) is separate from component rendering
- **Maintainability**: Adding a new avatar is as simple as adding a PNG to the folder; no code changes needed
