# Implementation Tasks: Notification System

## Task 1: Create GlobalSignalBus autoload singleton
**Objective:** Implement the central signal hub for application-wide notifications

**Steps:**
1. Create `autoload/global_signal_bus.gd`
2. Define `notification_received` signal with Dictionary parameter
3. Define `notification_action_taken` signal with String ID and String action parameters
4. Add comprehensive documentation comments for each signal
5. Register GlobalSignalBus in Project Settings > Autoload

**Validation:**
- Verify GlobalSignalBus is accessible from any scene via `GlobalSignalBus`
- Test emitting `notification_received` from a test scene
- Confirm signal can be connected to in other scripts

**Dependencies:** None

---

## Task 2: Extend UserDatabase with notification storage functions
**Objective:** Add CRUD operations for notifications tied to user accounts

**Steps:**
1. Modify user schema to include `notifications` array (initialized as empty on user creation)
2. Implement `add_notification(username: String, notification_data: Dictionary) -> void`
   - Validate user exists
   - Auto-generate unique ID if not provided (use `Time.get_ticks_msec()` + random component)
   - Auto-add timestamp if not provided (ISO 8601 format)
   - Append to user's notifications array
   - Call `_save_database()`
3. Implement `remove_notification(username: String, notification_id: String) -> void`
   - Find and remove notification by ID
   - Call `_save_database()`
4. Implement `get_notifications(username: String) -> Array[Dictionary]`
   - Return user's notifications array or empty array if user doesn't exist
5. Implement `mark_notification_read(username: String, notification_id: String) -> void`
   - Set `is_read` to true for specified notification
   - Call `_save_database()`
6. Implement `get_unread_count(username: String) -> int`
   - Count notifications where `is_read` is false
7. Update existing users in `data/user_database.json` to include empty `notifications` array

**Validation:**
- Create test user and add notification - verify JSON file contains notification
- Remove notification - verify it's gone from JSON
- Check unread count matches expected value
- Restart game and verify notifications persist

**Dependencies:** None

---

## Task 3: Create NotificationComponent scene and script
**Objective:** Build reusable UI component for displaying notifications

**Steps:**
1. Create `scenes/ui/components/notification_component.tscn`
2. Build scene structure:
   - Root: PanelContainer (name: NotificationComponent)
   - MarginContainer (10px margins)
   - VBoxContainer (spacing: 10)
     - Label (name: MessageLabel, autowrap enabled)
     - HBoxContainer (name: ActionButtonsContainer)
       - Button (name: AcceptButton, text: "Accept")
       - Button (name: DenyButton, text: "Deny")
3. Create `scenes/ui/components/notification_component.gd`
4. Define `@export var indicator_color: Color = Color.WHITE` for future customization
5. Define signal `action_taken(notification_id: String, action: String)`
6. Store notification_data as instance variable
7. Implement `set_notification_data(data: Dictionary) -> void`:
   - Store data
   - Set MessageLabel.text to data.message
   - Show/hide ActionButtonsContainer based on data.has_actions
8. Connect AcceptButton.pressed to emit `action_taken(notification_data.id, "accept")`
9. Connect DenyButton.pressed to emit `action_taken(notification_data.id, "deny")`
10. Match visual style to existing components (answer_button, result_component)

**Validation:**
- Instantiate component programmatically and call set_notification_data() with test data
- Verify message displays correctly
- Verify buttons show when has_actions is true, hide when false
- Click accept/deny and verify action_taken signal is emitted with correct parameters

**Dependencies:** None (can be developed in parallel with Task 2)

---

## Task 4: Update MainLobbyScreen scene structure
**Objective:** Prepare UI for notification display with scrolling support

**Steps:**
1. Open `scenes/ui/main_lobby_screen.tscn`
2. Inside NotificationsPopUp > MarginContainer > NotificationContainer:
   - Add ScrollContainer as child (name: NotificationScrollContainer)
   - Set ScrollContainer properties:
     - horizontal_scroll_mode: SCROLL_MODE_DISABLED
     - vertical_scroll_mode: SCROLL_MODE_AUTO
   - Add VBoxContainer as child of ScrollContainer (name: NotificationListContainer)
     - This will hold dynamically instantiated NotificationComponent instances
3. Connect ClosePopUpButton.pressed signal if not already connected
4. Ensure NotificationsButton has a unique name or @onready reference

**Validation:**
- Open scene in editor and verify hierarchy matches specification
- Manually add multiple PanelContainers to NotificationListContainer to test scrolling
- Verify ScrollContainer scrolls when content exceeds height

**Dependencies:** None (can be developed in parallel)

---

## Task 5: Implement MainLobbyScreen notification logic
**Objective:** Handle notification display, actions, and visual indicators

**Steps:**
1. Open `scenes/ui/main_lobby_screen.gd`
2. Add constant: `const NOTIFICATION_COMPONENT = preload("res://scenes/ui/components/notification_component.tscn")`
3. Add exported color for indicator: `@export var notification_indicator_color: Color = Color(1.0, 0.8, 0.0)` # Yellow
4. Add @onready references:
   - `@onready var notifications_button: Button = ...`
   - `@onready var notifications_popup: Panel = ...`
   - `@onready var notification_list_container: VBoxContainer = ...`
5. Create `notification_components: Array[Control] = []` to track instances
6. In `_ready()`:
   - Connect GlobalSignalBus.notification_received to `_on_notification_received`
   - Call `_load_existing_notifications()`
   - Call `_update_notification_indicator()`
7. Implement `_load_existing_notifications() -> void`:
   - Get notifications from UserDatabase for current_user
   - For each notification, instantiate NotificationComponent and add to list
8. Implement `_on_notification_received(notification_data: Dictionary) -> void`:
   - Check if notification is for current_user
   - If yes, instantiate component, add to list, update indicator
   - Call UserDatabase.add_notification()
9. Implement `_update_notification_indicator() -> void`:
   - Get unread count from UserDatabase
   - If count > 0, apply color modulation to notifications_button
   - Else, reset modulation to white
10. Implement `_on_notifications_button_pressed() -> void`:
    - Set notifications_popup.visible = true
11. Implement `_on_close_popup_button_pressed() -> void`:
    - Set notifications_popup.visible = false
12. Connect NotificationComponent.action_taken signals dynamically when instantiated
13. Implement `_on_notification_action(notification_id: String, action: String) -> void`:
    - Find and remove component from UI
    - Call UserDatabase.remove_notification()
    - Emit GlobalSignalBus.notification_action_taken()
    - Update indicator

**Validation:**
- Load lobby with existing notifications in database - verify they display
- Manually emit GlobalSignalBus.notification_received - verify new component appears
- Accept/deny notification - verify it's removed from UI and database
- Check notification button color changes with unread notifications
- Open/close popup - verify visibility toggles

**Dependencies:** Tasks 2, 3, 4

---

## Task 6: Implement friend request test scenario
**Objective:** Demonstrate end-to-end notification flow with real use case

**Steps:**
1. Open `scenes/ui/lobby_pages/socials_page.gd`
2. Locate avatar button instantiation in search results (likely in `_populate_search_results()` or similar)
3. Connect avatar button pressed signal to new function `_on_search_avatar_pressed(username: String)`
4. Implement `_on_search_avatar_pressed(username: String) -> void`:
   ```gdscript
   var notification_data = {
       "recipient_username": username,
       "message": "Friend request from %s" % UserDatabase.current_user.username,
       "sender": UserDatabase.current_user.username,
       "has_actions": true,
       "action_data": {
           "type": "friend_request",
           "sender_id": UserDatabase.current_user.username
       }
   }
   GlobalSignalBus.notification_received.emit(notification_data)
   ```
5. Add user feedback (e.g., "Friend request sent!" message or button state change)

**Validation:**
- Log in as User A
- Open socials page, search for User B
- Click User B's avatar
- Log out and log in as User B
- Verify notification appears on main lobby
- Accept notification - verify it's removed
- (Future: Verify friend system processes the action)

**Dependencies:** Tasks 2, 3, 5

---

## Task 7: Test and polish
**Objective:** Verify all requirements are met and fix edge cases

**Steps:**
1. Test with 0 notifications - verify no errors
2. Test with 20+ notifications - verify scrolling works smoothly
3. Test rapid notification creation - verify UI updates correctly
4. Test logging out and back in - verify notifications persist
5. Test notification for wrong user - verify it doesn't display
6. Test accepting last notification - verify indicator disappears
7. Verify notification component styling matches project aesthetic
8. Add console logs for debugging (can be removed later)
9. Test on mobile viewport sizes - verify responsive behavior

**Validation:**
- All scenarios from specs pass manual testing
- No console errors during normal operation
- UI remains responsive with many notifications
- Data persists correctly across sessions

**Dependencies:** Tasks 1-6

---

## Completion Criteria
- GlobalSignalBus autoload is registered and functional
- UserDatabase supports full notification CRUD operations
- NotificationComponent displays messages and optional action buttons
- MainLobbyScreen loads, displays, and handles notifications
- Notification button visual indicator works correctly
- Friend request test scenario works end-to-end
- All manual tests pass without errors
- Code is documented with GDScript doc comments
