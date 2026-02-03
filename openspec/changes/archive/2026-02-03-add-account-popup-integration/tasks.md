# Implementation Tasks

## Task Checklist

### 1. Extend UserDatabase Schema
- [x] Add `wins: int`, `losses: int`, `current_streak: int` fields to user creation in `create_user()`
- [x] Implement migration logic in `_load_database()` to add default values (0) to existing users missing these fields
- [x] Implement `get_user_data_for_display(username: String) -> Dictionary` method that returns: username, avatar_path, wins, losses, current_streak (excludes password_hash, email)
- [x] Test migration with existing user_database.json file
- [x] Verify new users get all three statistics fields initialized to 0

**Validation:**
- Run game and verify existing users in database gain new fields
- Create new user and verify stats are initialized to 0
- Call `get_user_data_for_display()` and verify sensitive data is excluded

---

### 2. Modify Avatar Component
- [x] Add member variable `var user_id: String = ""`
- [x] Implement `set_user_id(id: String) -> void` method
- [x] Implement `get_user_id() -> String` method
- [x] Add signal `signal avatar_clicked(user_id: String)`
- [x] Emit `avatar_clicked` signal in button `pressed` signal handler (or create one if missing)
- [x] Verify existing functionality (set_avatar_name, set_avatar_picture, get_avatar_path) remains unchanged

**Validation:**
- Instantiate avatar, set user_id, verify get_user_id() returns correct value
- Connect to avatar_clicked signal, press button, verify signal emits with correct user_id
- Test existing methods to ensure no regression

---

### 3. Implement Account Popup Logic
- [x] Add member variable `var current_displayed_user: String = ""`
- [x] Implement `display_user(user_id: String) -> void` method:
  - Call `UserDatabase.get_user_data_for_display(user_id)`
  - Return early if result is empty (user doesn't exist)
  - Update NameLabel text with username
  - Load and set PlayerAvatar texture from avatar_path
  - Store wins, losses, current_streak for future UI elements
  - Show popup panel and overlay
- [x] Implement `close_popup() -> void` method:
  - Hide popup panel
  - Hide overlay
  - Clear current_displayed_user
- [x] Connect BackButton `pressed` signal to `close_popup()`
- [x] Add gui_input handler to overlay to detect clicks outside popup panel
- [x] In overlay click handler, call `close_popup()` when click is outside popup bounds

**Validation:**
- Open popup with valid user_id, verify data displays correctly
- Click back button, verify popup closes
- Click overlay outside popup, verify popup closes
- Attempt to display non-existent user, verify graceful handling

---

### 4. Integrate Popup in Socials Page
- [x] Add account_popup node to socials_page.tscn scene tree (if not already added)
- [x] Get reference to account_popup in socials_page.gd: `@onready var account_popup: Control = $AccountPopup`
- [x] Modify `_populate_friends_list()` to connect avatar `avatar_clicked` signal to account_popup.display_user
- [x] Update avatar instantiation to call `set_user_id(friend.username)` for each friend avatar

**Validation:**
- Open socials page, verify friend avatars display correctly
- Click friend avatar, verify account popup opens with friend's data
- Click back button or overlay, verify popup closes
- Verify no regressions in existing socials page functionality

---

### 5. Configure Account Popup Scene Layout
- [x] Verify popup panel has appropriate size constraints
- [x] Set popup anchors to center (anchor_left=0.5, anchor_right=0.5, anchor_top=0.5, anchor_bottom=0.5)
- [x] Add margin containers or adjust size so popup doesn't cover entire screen
- [x] Verify overlay covers full screen (anchors_preset=15)
- [x] Test responsive layout on different viewport sizes

**Validation:**
- Open popup, verify it's centered with visible margins around edges
- Resize viewport, verify popup remains centered with appropriate margins

---

### 6. Testing and Verification
- [x] Test with multiple users in socials page friends list
- [x] Verify sensitive data (password, email) is never visible in popup
- [x] Test popup behavior when opened from different parent scenes (if other integration points exist)
- [x] Verify database migration doesn't corrupt existing user data
- [x] Manual testing: click flow from friends list → popup open → close via back button
- [x] Manual testing: click flow from friends list → popup open → close via overlay click
- [x] Edge case: Open popup for user, delete user from database, verify graceful handling

**Validation:**
- All test scenarios pass
- No errors in console output
- Popup displays correct data for all test users
