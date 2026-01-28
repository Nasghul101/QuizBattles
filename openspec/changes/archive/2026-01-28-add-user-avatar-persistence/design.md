# Design Document: User Avatar Persistence

## Overview

This design extends the user account system to support avatar selection and persistence. The implementation follows Godot's composition pattern and maintains separation between data storage (UserDatabase), UI components (screens), and reusable elements (AvatarComponent).

## Architecture

### Component Responsibilities

**UserDatabase (autoload/user_database.gd)**
- Stores `avatar_path` as a string field in user records
- Provides `update_avatar(avatar_path: String)` method for current user
- Returns avatar_path in `current_user` dictionary and `get_current_user()` responses
- Defaults to `"res://assets/profile_pictures/man_standard.png"` for new users

**AccountRegistrationScreen (scenes/ui/account_ui/account_registration_screen.gd)**
- No changes to UI or validation logic
- Passes default avatar_path to UserDatabase.create_user() as new parameter

**AccountManagementScreen (scenes/ui/account_ui/account_management_screen.gd)**
- Displays current user's avatar in `UserAvatar` button on `_ready()`
- Connects `pressed` signal from each `AvatarComponent` when populating popup
- Handles avatar selection: calls UserDatabase.update_avatar(), refreshes UI, closes popup
- Gracefully handles missing textures (fallback to default)

**AvatarComponent (scenes/ui/components/avatar_component.gd)**
- Stores `texture_path` as instance variable for retrieval on button press
- Exposes `get_avatar_path()` method to retrieve stored path

## Data Flow

### Account Creation Flow
```
User fills registration form
  → CreateAccountButton pressed
  → account_registration_screen.gd validates inputs
  → UserDatabase.create_user(username, password, email, avatar_path)
  → Default avatar_path = "res://assets/profile_pictures/man_standard.png"
  → User record stored with avatar_path field
  → User signed in automatically
  → Navigate to Account Management Screen
```

### Avatar Display Flow
```
Account Management Screen loads
  → _ready() calls _display_current_avatar()
  → Get current_user from UserDatabase
  → Load texture from current_user["avatar_path"]
  → Set UserAvatar button texture
  → Fallback to default if texture fails to load
```

### Avatar Selection Flow
```
User presses UserAvatar button
  → Popup shown and populated with AvatarComponents
  → Each AvatarComponent.pressed signal connected to _on_avatar_selected(texture_path)
  → User clicks an AvatarComponent
  → _on_avatar_selected() receives texture_path from component
  → UserDatabase.update_avatar(texture_path) called
  → UserAvatar button texture updated
  → Popup closed with animation
```

## Technical Decisions

### 1. Store Paths, Not Images
**Decision:** Store avatar_path as a string reference  
**Rationale:**
- Minimal memory footprint in database
- Images are already resources in Godot's filesystem
- Easy to validate and debug (human-readable paths)
- No serialization complexity

### 2. Default Avatar Strategy
**Decision:** Use `man_standard.png` as the default avatar  
**Rationale:**
- Neutral, generic option suitable for all users
- Already exists in assets/profile_pictures/
- Provides consistent fallback for error cases

### 3. Avatar Update Method Signature
**Decision:** `update_avatar(avatar_path: String) -> Dictionary`  
**Rationale:**
- Similar to create_user() and sign_in() patterns (returns success/error dict)
- Only allows updating current user (no username parameter needed)
- String parameter simple and type-safe

### 4. Button Press Signal Flow
**Decision:** Connect each AvatarComponent's `pressed` signal dynamically  
**Rationale:**
- Standard Godot pattern for button interactions
- Allows texture_path to be passed through signal connection lambda
- Clean separation: AvatarComponent doesn't need to know about database

### 5. Immediate Popup Closure
**Decision:** Close popup immediately after avatar selection  
**Rationale:**
- Consistent with mobile UX patterns (tap-to-select)
- Doesn't interfere with existing drag-to-dismiss behavior
- Provides instant feedback without extra confirmation

## Error Handling

### Missing Texture Files
**Scenario:** avatar_path references a file that doesn't exist  
**Handling:**
- `load(avatar_path)` returns null
- Check if texture is null before assignment
- Fall back to loading default avatar path
- Log warning to console for debugging

### User Not Signed In
**Scenario:** update_avatar() called when no user is signed in  
**Handling:**
- Check `is_signed_in()` before updating
- Return error dictionary: `{success: false, error_code: "NOT_SIGNED_IN"}`
- Log error to console

### Invalid Path Format
**Scenario:** avatar_path doesn't start with "res://"  
**Handling:**
- Accept any string (lenient validation)
- Godot's load() will return null for invalid paths
- Fallback mechanism handles null textures

## Implementation Notes

### Backward Compatibility
Existing user records created before this change won't have `avatar_path` field:
- Use `get("avatar_path", DEFAULT_PATH)` when accessing the field
- Or check `has("avatar_path")` and assign default if missing

### Scene References
- `UserAvatar` button already exists in account_management_screen.tscn
- No new UI nodes required
- AvatarComponent scene already has Picture TextureRect for display

### Performance Considerations
- Avatar loading happens once per screen load (negligible impact)
- Texture resources are cached by Godot's resource loader
- No continuous polling or updates required

## Testing Strategy

### Manual Testing Scenarios
1. Create new account → verify default avatar appears
2. Click UserAvatar → verify popup shows all avatars
3. Click different avatar → verify UserAvatar button updates
4. Navigate away and back → verify avatar persists
5. Delete avatar file → verify fallback to default works

### Edge Cases
- Spam-clicking avatars rapidly
- Closing popup during drag gesture
- Switching users (sign out/in) with different avatars
