# Implementation Tasks: Add User Avatar Persistence

## Prerequisites
- [x] Review proposal.md and design.md
- [x] Understand existing UserDatabase, AvatarComponent, and account screen implementations
- [x] Verify all profile pictures exist in `assets/profile_pictures/`

## Task Sequence

### 1. Extend UserDatabase with avatar_path field
**File:** `autoload/user_database.gd`

- [x] Add `DEFAULT_AVATAR_PATH` constant: `"res://assets/profile_pictures/man_standard.png"`
- [x] Modify `create_user()` to include `avatar_path` field in user_data with default value
- [x] Modify `current_user` assignment in `sign_in()` to include avatar_path from stored user_data
- [x] Update `get_current_user()` to return avatar_path field

**Validation:**
- Create new user and verify returned user dict includes avatar_path
- Sign in and check `get_current_user()` includes avatar_path
- Print current_user dict to console and confirm avatar_path field exists

---

### 2. Add update_avatar() method to UserDatabase
**File:** `autoload/user_database.gd`

- [x] Create `update_avatar(avatar_path: String) -> Dictionary` method
- [x] Check if user is signed in (return error if not)
- [x] Update avatar_path in stored user data (_users dictionary)
- [x] Update avatar_path in current_user session
- [x] Return success dictionary with avatar_path

**Validation:**
- Call update_avatar() while signed in → verify success response
- Call update_avatar() while not signed in → verify error response
- Check get_current_user() after update → verify avatar_path changed
- Sign out and sign back in → verify avatar_path persisted in _users storage

---

### 3. Set default avatar in account registration
**File:** `scenes/ui/account_ui/account_registration_screen.gd`

- [x] No code changes required (UserDatabase now handles default automatically)
- [x] Verify create_user() call works with updated UserDatabase

**Validation:**
- Create new account through registration screen
- Check console log output includes avatar_path field
- Sign in with new account and verify default avatar in get_current_user()

---

### 4. Add get_avatar_path() method to AvatarComponent
**File:** `scenes/ui/components/avatar_component.gd`

- [x] Add instance variable `var texture_path: String = ""`
- [x] Store texture_path in `set_avatar_picture()` method
- [x] Add `get_avatar_path() -> String` method that returns texture_path

**Validation:**
- Instantiate AvatarComponent, call set_avatar_picture(path)
- Call get_avatar_path() and verify it returns the same path
- Test with multiple different paths

---

### 5. Display current user avatar in Account Management Screen
**File:** `scenes/ui/account_ui/account_management_screen.gd`

- [x] Add `@onready var user_avatar_button: Button = %UserAvatar` reference
- [x] Create `_display_current_avatar()` method
- [x] Load current user's avatar_path from UserDatabase.get_current_user()
- [x] Load texture using `load(avatar_path)`
- [x] Handle null texture (fallback to DEFAULT_AVATAR_PATH)
- [x] Set texture on user_avatar_button (likely has TextureRect child or icon property)
- [x] Call `_display_current_avatar()` in `_ready()` after `_display_username()`

**Validation:**
- Sign in with user that has default avatar → verify man_standard.png displays
- Manually change user's avatar_path in database → reload screen → verify new avatar displays
- Test with invalid avatar_path → verify fallback to default works
- Check console for warning when fallback occurs

---

### 6. Connect avatar selection signals in popup
**File:** `scenes/ui/account_ui/account_management_screen.gd`

- [x] Modify `_populate_avatar_container()` to connect pressed signals
- [x] Connect each avatar_component.pressed signal to handler with texture_path parameter
- [x] Use lambda/bind to pass texture_path: `avatar_component.pressed.connect(_on_avatar_selected.bind(texture_path))`
- [x] Create `_on_avatar_selected(avatar_path: String)` handler method (stub for now)

**Validation:**
- Open popup and click an avatar
- Verify handler is called (add print statement)
- Verify correct texture_path is received in handler
- Click multiple different avatars and verify each passes correct path

---

### 7. Implement avatar selection handler
**File:** `scenes/ui/account_ui/account_management_screen.gd`

- [x] Implement `_on_avatar_selected(avatar_path: String)` method body
- [x] Call `UserDatabase.update_avatar(avatar_path)`
- [x] Check result.success (log error if failed)
- [x] Call `_display_current_avatar()` to refresh UI
- [x] Call `_close_popup_with_animation()` to dismiss popup

**Validation:**
- Open popup, select an avatar
- Verify UserAvatar button updates immediately
- Verify popup closes with animation
- Check UserDatabase.get_current_user() includes new avatar_path
- Navigate away and back → verify avatar persists
- Sign out and sign in → verify avatar persists across sessions

---

### 8. Add error handling and logging
**Files:** `autoload/user_database.gd`, `scenes/ui/account_ui/account_management_screen.gd`

- [x] Add console warnings when texture loading fails
- [x] Add console error when update_avatar() called without sign-in
- [x] Add console debug message when avatar updated successfully (optional)

**Validation:**
- Trigger each error condition and verify appropriate console messages
- Check that errors don't crash the game or break UI
- Verify fallback behavior works correctly

---

### 9. Test complete flow end-to-end
**Manual Testing**

- [x] Create new account → verify default avatar appears in Account Management
- [x] Click UserAvatar button → verify popup opens with all avatars
- [x] Select different avatar → verify button updates and popup closes
- [x] Navigate to lobby and back → verify avatar persists
- [x] Sign out and sign in → verify avatar persists
- [x] Select multiple different avatars in sequence → verify each selection works
- [x] Test drag gesture still works (drag popup up/down without selecting)
- [x] Delete an avatar image file → verify fallback to default works

**Validation:**
- All scenarios pass without errors
- Console logs are clean (no unexpected errors)
- Avatar selection feels responsive and immediate

---

## Checklist Summary
- [x] UserDatabase extended with avatar_path field
- [x] update_avatar() method implemented and tested
- [x] AvatarComponent can store and return texture_path
- [x] Account Management displays current user avatar on load
- [x] Avatar selection signals connected and working
- [x] Avatar selection handler updates database and UI
- [x] Popup closes after selection
- [x] Error handling and fallbacks working
- [x] Complete flow tested end-to-end
