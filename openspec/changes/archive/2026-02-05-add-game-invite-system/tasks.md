# Implementation Tasks: Game Invite System

## Task 1: Add timestamp support and expiry filtering to UserDatabase
**Objective**: Add timestamp field to all notifications and implement 3-day expiry logic

**Steps**:
1. Open `autoload/user_database.gd`
2. Locate the `add_notification()` function
3. Modify to add timestamp when creating notifications:
   - Add `notification_data["timestamp"] = Time.get_unix_time_from_system()` before appending to array
4. Locate `get_notifications()` function
5. Add expiry filtering logic:
   - Define constant `const NOTIFICATION_EXPIRY_SECONDS: int = 259200` (3 days)
   - Get current time: `var current_time: float = Time.get_unix_time_from_system()`
   - Filter notifications: keep only those where `current_time - notification.get("timestamp", 0.0) <= NOTIFICATION_EXPIRY_SECONDS`
   - Return filtered array
6. Add documentation comment explaining expiry logic

**Validation**:
- Create notification and verify timestamp exists in JSON
- Manually edit JSON to create old notification (timestamp - 4 days)
- Call `get_notifications()` and verify old notification is filtered out
- Create new notification and verify it's returned

**Dependencies**: None

---

## Task 2: Add game_invite_accepted signal to GlobalSignalBus
**Objective**: Create signal for future multiplayer system to hook into when invites are accepted

**Steps**:
1. Open `autoload/global_signal_bus.gd`
2. Add new signal after existing signals:
   ```gdscript
   ## Emitted when a player accepts a game invitation.
   ## [param inviter_username] String - Username of player who sent invite
   ## [param invitee_username] String - Username of player who accepted invite
   ## This signal serves as a hook for future multiplayer game initialization.
   ## Currently no system connects to this, but multiplayer logic will use it
   ## to start game sessions between the two players.
   signal game_invite_accepted(inviter_username: String, invitee_username: String)
   ```
3. Save file

**Validation**:
- Verify file parses without errors
- Check that signal is defined with correct parameters

**Dependencies**: None

---

## Task 3: Add duplicate game invite prevention to UserDatabase
**Objective**: Prevent sending multiple game invites to same player (similar to friend request logic)

**Steps**:
1. Open `autoload/user_database.gd`
2. Implement new function `_has_pending_game_invite(recipient: String, sender: String) -> bool`:
   - Return false if recipient doesn't exist
   - Get notifications for recipient via `get_notifications(recipient)`
   - Iterate through notifications
   - Check if notification has action_data and `action_data.get("type") == "game_invite"`
   - Check if `notification.get("sender") == sender`
   - Return true if found, false otherwise
3. Locate `_on_notification_received()` function
4. Add game invite duplicate check after friend request check:
   ```gdscript
   if action_data.get("type") == "game_invite":
       var sender: String = notification_data.get("sender", "")
       if _has_pending_game_invite(recipient, sender):
           push_warning("Game invite already sent to %s from %s" % [recipient, sender])
           return
   ```
5. Add documentation comments

**Validation**:
- Send game invite from alice to bob
- Try to send another invite from alice to bob
- Verify second invite is prevented with warning in console
- Verify only one notification exists for bob
- Send game invite from alice to charlie (different recipient)
- Verify invite is sent successfully (different recipients allowed)

**Dependencies**: Task 1 (timestamp support)

---

## Task 4: Add invite button functionality to AccountPopup
**Objective**: Send game invite notification when button is pressed and manage button state

**Steps**:
1. Open `scenes/ui/account_ui/account_popup.gd`
2. Add button state variable at top:
   ```gdscript
   var invite_button_enabled: bool = true
   ```
3. Add @onready reference to button:
   ```gdscript
   @onready var invite_button: Button = $PopupPanel/VBoxContainer/InviteToGameButton
   ```
4. Modify `display_user()` function to reset button state:
   - Add at end: `invite_button.disabled = false`
   - Add comment explaining button is re-enabled on popup open
5. Implement `_on_invite_to_game_button_pressed()` function:
   - Check if user is signed in (early return if not)
   - Disable button: `invite_button.disabled = true`
   - Create notification data dictionary:
     ```gdscript
     var notification_data: Dictionary = {
         "recipient_username": current_displayed_user,
         "message": "%s invites you to a duel" % UserDatabase.current_user.username,
         "sender": UserDatabase.current_user.username,
         "has_actions": true,
         "action_data": {
             "type": "game_invite",
             "inviter_id": UserDatabase.current_user.username
         }
     }
     ```
   - Emit signal: `GlobalSignalBus.notification_received.emit(notification_data)`
   - Log success message
6. Verify signal connection exists in .tscn file for button pressed event
7. Add documentation comments

**Validation**:
- Log in as alice
- Open account popup for bob
- Click "Invite to duel" button
- Verify button becomes disabled
- Verify notification is created for bob in database JSON
- Close popup and reopen for bob
- Verify button is enabled again
- Click button again
- Verify duplicate prevention works (warning in console)

**Dependencies**: Task 2 (signal), Task 3 (duplicate prevention)

---

## Task 5: Handle game invite acceptance in MainLobbyScreen
**Objective**: Emit game_invite_accepted signal when player accepts game invite

**Steps**:
1. Open `scenes/ui/main_lobby_screen.gd`
2. Locate `_on_notification_action_taken()` function
3. Find the section that handles action == "accept"
4. Add game invite handling before or after friend request handling:
   ```gdscript
   # Handle game invite acceptance
   if action_data.get("type") == "game_invite":
       var inviter_id: String = action_data.get("inviter_id", "")
       if inviter_id.is_empty():
           push_warning("Game invite missing inviter_id")
       else:
           # Emit signal for future multiplayer integration
           GlobalSignalBus.game_invite_accepted.emit(inviter_id, UserDatabase.current_user.username)
           print("Game invite accepted: %s vs %s" % [inviter_id, UserDatabase.current_user.username])
           # TODO: Connect multiplayer game initialization to GlobalSignalBus.game_invite_accepted signal
   ```
5. Add documentation comment explaining future multiplayer hook
6. Save file

**Validation**:
- Log in as bob
- Manually add game invite notification to bob's notifications in JSON
- Accept notification in UI
- Verify `game_invite_accepted` signal is emitted (check console for print)
- Verify notification is removed after acceptance

**Dependencies**: Task 2 (signal), Task 4 (sending invites)

---

## Task 6: Handle game invite denial and send rejection notification
**Objective**: When player denies game invite, send rejection notification to original sender

**Steps**:
1. Open `autoload/user_database.gd`
2. Locate or create `_on_notification_action_taken()` function (may need to be added)
3. If function doesn't exist:
   - Add in `_ready()`: `GlobalSignalBus.notification_action_taken.connect(_on_notification_action_taken)`
   - Implement function signature: `func _on_notification_action_taken(notification_id: String, action: String) -> void:`
4. Add denial handling logic:
   ```gdscript
   # Only handle deny actions
   if action != "deny":
       return
   
   # Get current user
   if not is_signed_in():
       return
   
   var current_username: String = current_user.username
   
   # Find the notification being denied
   var notifications: Array = get_notifications(current_username)
   var denied_notification: Dictionary = {}
   
   for notification: Dictionary in notifications:
       if notification.get("id") == notification_id:
           denied_notification = notification
           break
   
   # Check if it's a game invite
   if denied_notification.has("action_data"):
       var action_data: Dictionary = denied_notification.action_data
       if action_data.get("type") == "game_invite":
           # Send rejection notification to original sender
           var inviter: String = denied_notification.get("sender", "")
           if not inviter.is_empty():
               var rejection_data: Dictionary = {
                   "recipient_username": inviter,
                   "message": "%s rejected your duel" % current_username,
                   "sender": "System",
                   "has_actions": false,
                   "action_data": {
                       "type": "game_invite_rejection"
                   }
               }
               # Emit through signal bus to trigger notification creation
               GlobalSignalBus.notification_received.emit(rejection_data)
               print("Rejection notification sent to %s" % inviter)
   ```
5. Add documentation comments
6. Save file

**Validation**:
- Log in as alice (create invite sender)
- Log in as bob (or manually add notification)
- Send game invite from alice to bob
- As bob, deny the invitation
- Verify alice receives rejection notification
- Verify rejection notification has no action buttons (has_actions: false)
- Verify rejection notification message shows correct username
- Verify rejection notification has timestamp and will expire in 3 days

**Dependencies**: Task 1 (timestamp), Task 4 (sending invites), Task 5 (action handling)

---

## Task 7: Update notification component documentation (optional)
**Objective**: Document that notifications now support timestamps and expiry

**Steps**:
1. Open `scenes/ui/components/notification_component.gd`
2. Update class documentation comment to mention timestamp field:
   ```gdscript
   ## NotificationComponent
   ##
   ## Displays notification messages with optional action buttons.
   ## Notifications are automatically filtered by the database to remove expired items (>3 days old).
   ## The timestamp field is managed automatically by UserDatabase.
   ```
3. Save file

**Validation**:
- Read documentation to ensure clarity
- Verify no functional changes (only documentation)

**Dependencies**: None

---

## Task 8: Integration testing
**Objective**: Test complete flow end-to-end

**Test Scenarios**:
1. **Send invite flow**:
   - [ ] Log in as Player A
   - [ ] Open friend's profile (Player B)
   - [ ] Click "Invite to duel"
   - [ ] Verify button becomes disabled
   - [ ] Verify notification appears for Player B in database
   - [ ] Close and reopen popup
   - [ ] Verify button is enabled again

2. **Accept invite flow**:
   - [ ] Log in as Player B
   - [ ] See game invite notification from Player A
   - [ ] Click Accept button
   - [ ] Verify `game_invite_accepted` signal is emitted (console log)
   - [ ] Verify notification is removed from Player B's list

3. **Deny invite flow**:
   - [ ] Log in as Player B
   - [ ] See game invite notification from Player A
   - [ ] Click Deny button
   - [ ] Verify notification is removed from Player B's list
   - [ ] Log in as Player A
   - [ ] Verify rejection notification appears for Player A
   - [ ] Verify rejection notification has no action buttons

4. **Duplicate prevention**:
   - [ ] Log in as Player A
   - [ ] Send invite to Player B
   - [ ] Try to send another invite to Player B
   - [ ] Verify warning in console
   - [ ] Verify only one notification exists for Player B
   - [ ] Send invite to Player C (different player)
   - [ ] Verify invite is sent successfully

5. **Expiry testing**:
   - [ ] Create notification with timestamp 4 days ago (manual JSON edit)
   - [ ] Query notifications
   - [ ] Verify old notification is filtered out
   - [ ] Create notification with timestamp 1 day ago
   - [ ] Verify recent notification is returned

**Dependencies**: All previous tasks

---

## Validation Checklist

- [x] All notifications receive timestamps on creation
- [x] Notifications older than 3 days are filtered when queried
- [x] Game invite notifications are sent when button is pressed
- [x] Button becomes disabled after sending invite
- [x] Button is re-enabled when popup reopens
- [x] Duplicate game invites to same player are prevented
- [x] Multiple invites to different players are allowed
- [x] `game_invite_accepted` signal emits with correct usernames when invite accepted
- [x] Rejection notification is sent to inviter when invite denied
- [x] Rejection notification has no action buttons
- [x] Rejection notification expires after 3 days
- [x] All functions have documentation comments
- [x] No errors in Godot console during normal operation

---

## Notes for Implementation

### Timestamp Format
- Use `Time.get_unix_time_from_system()` which returns float (seconds since Unix epoch)
- Store as float in JSON for precision
- 3 days = 259200 seconds

### Button State Management
- Reset button to enabled in `display_user()` ensures clean state each time popup opens
- Disabled state provides immediate visual feedback
- Duplicate prevention handles the actual logic (button state is just UX)

### Signal Design
- `game_invite_accepted` signal uses explicit username parameters (not Dictionary)
- This makes future multiplayer code cleaner and type-safe
- Signal includes both inviter and invitee for complete game context

### Future Extensions
When adding game mode selection:
- Extend `action_data` with `game_mode` field
- Modify invite notification message to include mode
- Update `game_invite_accepted` signal to include mode parameter (breaking change)
- Update duplicate prevention to allow multiple invites with different modes

### Testing Notes
- Manual JSON editing useful for testing expiry (change timestamp to past)
- Console logs help verify signal emissions during testing
- Test with two separate user accounts (or manual JSON edits) for full flow
