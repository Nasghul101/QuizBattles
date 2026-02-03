# Implementation Tasks: Friend List Management

## Task 1: Extend UserDatabase schema and add friend storage functions
**Objective**: Add friends array to user data and implement core friend management functions

**Steps**:
1. Open `autoload/user_database.gd`
2. In `create_user()` function, add `"friends": []` to the user_data dictionary initialization
3. Implement `are_friends(username1: String, username2: String) -> bool`:
   - Check if username1 exists in _users
   - Check if username2 exists in username1's friends array
   - Return true if found, false otherwise
4. Implement `add_friend(username: String, friend_username: String) -> void`:
   - Validate both users exist (early return with error log if not)
   - Prevent self-friending (check username != friend_username)
   - Check if already friends using `are_friends()` (skip with warning if true)
   - Ensure both users have friends array (initialize as [] if missing)
   - Append friend_username to username's friends array
   - Append username to friend_username's friends array
   - Call `_save_database()`
5. Implement `remove_friend(username: String, friend_username: String) -> void`:
   - Validate both users exist (early return silently if not)
   - Ensure both users have friends array
   - Remove friend_username from username's friends array (if exists)
   - Remove username from friend_username's friends array (if exists)
   - Call `_save_database()`
6. Implement `get_friends(username: String) -> Array`:
   - Validate user exists (return empty array with error log if not)
   - Get user's friends array (return empty array if not present)
   - For each friend username in array:
     - Get full user data via `get_user_by_username()`
     - If user exists, append to results array
     - If user doesn't exist (deleted), skip silently
   - Return results array
7. Add documentation comments to all new functions

**Validation**:
- Call `create_user("alice", "pass", "alice@test.de")` and verify friends array exists in JSON
- Call `add_friend("alice", "bob")` and verify both users have each other in friends arrays
- Call `add_friend("alice", "bob")` again and verify no duplicates
- Call `get_friends("alice")` and verify returns array with bob's full data
- Call `remove_friend("alice", "bob")` and verify removed from both sides
- Test edge cases: non-existent users, self-friending, empty friends list

**Dependencies**: None

---

## Task 2: Handle friend request acceptance in UserDatabase
**Objective**: Automatically create friendships when friend requests are accepted via signal

**Steps**:
1. Open `autoload/user_database.gd`
2. In `_ready()` function, add connection to GlobalSignalBus.notification_action_taken:
   ```gdscript
   GlobalSignalBus.notification_action_taken.connect(_on_notification_action_taken)
   ```
3. Implement `_on_notification_action_taken(notification_id: String, action: String) -> void`:
   - Check if action == "accept" (early return if not)
   - Get current user via `is_signed_in()` and `current_user.username` (early return if not signed in)
   - Get notifications for current user via `get_notifications()`
   - Find notification matching notification_id
   - Check if notification has action_data and action_data.type == "friend_request"
   - Extract sender from notification.sender or notification.action_data.sender_id
   - Call `add_friend(current_user.username, sender)`
   - Log success message
4. Add documentation comment explaining signal handling

**Validation**:
- Log in as "alice"
- Log in as "bob" (different session or manual DB edit)
- Send friend request from alice to bob (via socials page avatar click)
- Accept notification as bob
- Verify both users have each other in friends array in user_database.json
- Verify _on_notification_action_taken was called (add debug print)

**Dependencies**: Task 1

---

## Task 3: Add FriendsList reference and populate function in SocialsPage
**Objective**: Display friends as avatar components when socials page opens

**Steps**:
1. Open `scenes/ui/lobby_pages/socials_page.gd`
2. Add constant for avatar component:
   ```gdscript
   const AVATAR_COMPONENT: PackedScene = preload("res://scenes/ui/components/avatar_component.tscn")
   ```
3. Add @onready reference to FriendsList:
   ```gdscript
   @onready var friends_list: GridContainer = %FriendsList
   ```
4. Open `scenes/ui/lobby_pages/socials_page.tscn` in editor
5. Select the FriendsList GridContainer node
6. In Inspector, check "Unique Name in Owner" (adds % prefix for unique name access)
7. Save the scene
8. Return to `socials_page.gd`
9. Implement `_populate_friends_list() -> void`:
   - Clear existing children: `for child in friends_list.get_children(): child.queue_free()`
   - Check if user is signed in (early return if not)
   - Get current user's friends: `var friends: Array = UserDatabase.get_friends(UserDatabase.current_user.username)`
   - For each friend in friends array:
     - Instantiate avatar: `var avatar: Button = AVATAR_COMPONENT.instantiate()`
     - Add to friends_list: `friends_list.add_child(avatar)`
     - Set name: `avatar.set_avatar_name(friend.username)`
     - Set picture: `avatar.set_avatar_picture(friend.avatar_path)`
10. In `_ready()` function, add call to populate friends list:
    ```gdscript
    # After existing initialization
    _populate_friends_list()
    ```
11. Add documentation comments

**Validation**:
- Manually edit user_database.json to add friends: `"friends": ["bob", "charlie"]`
- Log in as that user
- Navigate to socials page
- Verify avatar components appear in FriendsList
- Verify correct names and avatars are displayed
- Verify GridContainer layout displays avatars properly

**Dependencies**: Task 1

---

## Task 4: Add real-time friend list updates to SocialsPage
**Objective**: Refresh friend list when new friendships are created while page is open

**Steps**:
1. Open `scenes/ui/lobby_pages/socials_page.gd`
2. In `_ready()` function, add signal connection:
   ```gdscript
   GlobalSignalBus.notification_action_taken.connect(_on_friendship_changed)
   ```
3. Implement `_on_friendship_changed(notification_id: String, action: String) -> void`:
   - Get current user's notifications to find the one that was acted on
   - Check if action == "accept" (early return if not)
   - Get the notification data by ID from UserDatabase
   - Check if action_data.type == "friend_request" (early return if not)
   - Call `_populate_friends_list()` to refresh display
   - Log debug message
4. Add documentation comment

**Alternative simpler approach** (if notification data access is complex):
```gdscript
func _on_friendship_changed(notification_id: String, action: String) -> void:
    # Simple approach: refresh on any accept action
    # UserDatabase already filtered for friend_request
    if action == "accept":
        _populate_friends_list()
```

**Validation**:
- Log in as "alice" with 1 existing friend
- Open socials page and verify 1 avatar appears
- Keep socials page open
- In another window/test, accept a friend request as alice (or manually add friend to JSON and trigger signal)
- Verify FriendsList updates immediately to show 2 avatars
- Verify no duplicates appear

**Dependencies**: Task 2, Task 3

---

## Task 5: Integration testing and edge case validation
**Objective**: Verify complete end-to-end flow and handle edge cases

**Steps**:
1. **Full flow test**:
   - Log in as "alice" (new user, no friends)
   - Open socials page - verify empty FriendsList
   - Send friend request to "bob"
   - Log out, log in as "bob"
   - Accept friend request
   - Verify notification disappears
   - Open socials page - verify alice's avatar appears
   - Log out, log in as "alice"
   - Open socials page - verify bob's avatar appears
   - Restart game and verify friends persist

2. **Edge case: Multiple friends**:
   - Create user with 5+ friends
   - Open socials page
   - Verify all avatars display correctly in grid layout
   - Verify no overlap or visual issues

3. **Edge case: Deleted friend**:
   - Manually edit user_database.json to add non-existent user to friends array
   - Open socials page
   - Verify no error occurs
   - Verify only valid friends are displayed

4. **Edge case: Not signed in**:
   - Sign out
   - Navigate to socials page (if possible in UI flow)
   - Verify no errors occur
   - Verify FriendsList remains empty

5. **Edge case: Simultaneous friend request acceptance**:
   - User A sends request to User B
   - User B sends request to User A
   - Accept both requests
   - Verify only one bidirectional friendship exists (no duplicates)

**Validation**:
- All edge cases pass without errors
- Database remains consistent (bidirectional friendships)
- UI updates correctly in all scenarios
- No memory leaks (avatars properly freed on repopulation)

**Dependencies**: Tasks 1-4

---

## Task 6: Clean up and documentation
**Objective**: Ensure code quality and proper documentation

**Steps**:
1. Review all new code for GDScript style guide compliance:
   - Static typing on all variables and function signatures
   - Proper naming conventions (snake_case)
   - Documentation comments on all public functions
2. Check for hardcoded values and replace with constants if needed
3. Verify all error messages are clear and helpful
4. Add any missing inline comments for complex logic
5. Test performance with large friend lists (20+ friends)
6. Verify no console errors or warnings appear during normal use

**Validation**:
- Code passes style guide review
- All functions have documentation comments
- No console errors in any test scenario
- Performance is acceptable (< 100ms to populate 20 friends)

**Dependencies**: Tasks 1-5

---

## Implementation Checklist

- [x] Task 1: Extend UserDatabase schema and add friend storage functions
- [x] Task 2: Handle friend request acceptance in UserDatabase
- [x] Task 3: Add FriendsList reference and populate function in SocialsPage
- [x] Task 4: Add real-time friend list updates to SocialsPage
- [x] Task 5: Integration testing and edge case validation
- [x] Task 6: Clean up and documentation

## Parallel Work Opportunities
- Task 1 and Task 3 can be developed in parallel (independent)
- Task 2 depends on Task 1
- Task 4 depends on Task 2 and Task 3
- Task 5 and Task 6 must be done after all implementation

## Estimated Effort
- Task 1: 30-45 minutes (core data layer)
- Task 2: 15-20 minutes (signal handling)
- Task 3: 20-30 minutes (UI population)
- Task 4: 10-15 minutes (real-time updates)
- Task 5: 30-45 minutes (thorough testing)
- Task 6: 15-20 minutes (polish)

**Total**: ~2-3 hours
