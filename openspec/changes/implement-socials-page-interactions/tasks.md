# Tasks: Implement Socials Page Interactions

## 1. Database Schema Extension

- [x] Add `category_stats: Dictionary` field to user schema in UserDatabase._users
- [x] Implement migration in `_migrate_user_data()` to add `category_stats: {}` for existing users
- [x] Add placeholder category data generation function `_generate_placeholder_category_stats() -> Dictionary`
  - Returns random counts for 3 random categories
  - Add comment: `# TODO: Replace with real category tracking from gameplay_screen match completion`
- [x] Test: Verify new users get empty category_stats
- [x] Test: Verify existing users auto-migrate with empty dictionary

## 2. Name Display Button Component Script

- [x] Create `scenes/ui/components/name_display_button.gd` script
- [x] Add `is_highlighted: bool` property with setter
- [x] Add `username: String` property to store associated username
- [x] Implement `set_highlighted(value: bool)` to change button appearance
  - Change background color or add visual indicator
  - Update `is_highlighted` property
- [x] Emit custom signal `selection_changed(username: String, is_highlighted: bool)` on highlight state change
- [x] Add GDScript documentation comments
- [x] Test: Verify highlight visual appears on set_highlighted(true)
- [x] Test: Verify signal emits with correct parameters

## 3. Friend Display with Statistics

- [x] Modify `socials_page.gd._populate_friends_list()` to use friend_display_component
- [x] For each friend, call UserDatabase.get_user_data_for_display(friend_username)
- [x] Instantiate friend_display_component and populate:
  - `set_player_name(friend_username)`
  - `set_win_count()` using `friend_wins[current_user.username]` or 0
  - `set_loss_count()` using `current_user.friend_wins[friend_username]` or 0
  - `set_first_category()`, `set_second_category()`, `set_third_category()` using top 3 from category_stats
- [x] Use placeholder category_stats data (call _generate_placeholder_category_stats if empty)
- [x] Add to FriendDisplayContainer above AddNewFriendsButton
- [x] Test: Verify friend_display_components show with correct names
- [x] Test: Verify win/loss counts display correctly
- [x] Test: Verify category colors display (even with placeholder data)

## 4. Search Interaction Implementation

- [x] Implement `_on_name_input_text_changed()` in socials_page.gd
- [x] Call UserDatabase.search_users_by_username(query)
- [x] Clear FriendsContainer (queue_free all children)
- [x] For each result, instantiate name_display_button from scene
- [x] Set button text to username
- [x] Connect button's `selection_changed` signal to `_on_name_selection_changed()`
- [x] Add button to FriendsContainer
- [x] Test: Verify typing filters user list in real-time
- [x] Test: Verify empty query clears results

## 5. Selection State Management

- [x] Add `selected_username: String` variable to socials_page.gd
- [x] Implement `_on_name_selection_changed(username: String, is_highlighted: bool)`
- [x] If is_highlighted == true:
  - Deselect previously selected button (set_highlighted(false))
  - Store username in selected_username
  - Enable SendFriendRequestButton
- [x] If is_highlighted == false and username == selected_username:
  - Clear selected_username
  - Disable SendFriendRequestButton
- [x] Test: Verify only one button highlighted at a time (radio behavior)
- [x] Test: Verify SendFriendRequestButton enabled/disabled correctly

## 6. Friend Request Sending

- [x] Implement `_on_send_friend_request_button_pressed()` in socials_page.gd
- [x] Check if selected_username is not empty
- [x] Create notification_data dictionary with friend_request type
- [x] Emit GlobalSignalBus.notification_received with selected_username as recipient
- [x] Clear selected_username and disable SendFriendRequestButton
- [x] Log feedback message
- [x] Test: Verify notification sent to correct user
- [x] Test: Verify button resets after sending

## 7. Popup Cleanup Behavior

- [x] Modify `_on_back_button_pressed()` in socials_page.gd
- [x] Clear name_input text (set to empty string)
- [x] Clear FriendsContainer (queue_free all children)
- [x] Clear selected_username
- [x] Disable SendFriendRequestButton
- [x] Make AddFriendsPopup invisible
- [x] Test: Verify name_input clears on popup close
- [x] Test: Verify search results clear on close

## 8. Share Button Placeholder

- [x] Implement `_on_share_button_pressed()` in socials_page.gd
- [x] Add comment: `# TODO: Implement native share menu integration for mobile`
- [x] Log message indicating feature not yet implemented
- [x] Test: Verify button press logs message without errors

## 9. Friend List Update Integration

- [x] Verify existing connection to GlobalSignalBus.notification_action_taken in socials_page._ready()
- [x] Verify `_on_friendship_changed()` calls `_populate_friends_list()` on "accept" action
- [x] Test: Accept friend request while page open, verify friend appears in list
- [x] Test: Verify non-friend-request notifications don't trigger refresh

## 10. SendFriendRequestButton Initial State

- [x] Set SendFriendRequestButton disabled initially in _ready()
- [x] Test: Verify button starts disabled
- [x] Test: Verify button enables only after selection

## 11. Documentation and Validation

- [x] Add GDScript documentation comments to all new methods in socials_page.gd
- [x] Add documentation to name_display_button.gd
- [x] Update category_stats field documentation in user_database.gd
- [x] Run `openspec validate implement-socials-page-interactions --strict`
- [x] Fix any validation errors
- [x] Test full user flow: login → open socials → view friends → search → select → send request

## 12. Edge Cases and Polish

- [x] Handle case where friend has no category_stats (show empty or default colors)
- [x] Handle case where search returns no results (show empty container)
- [x] Ensure highlight state persists during scroll in FriendsContainer
- [x] Test rapid typing in search field (debouncing not required, but verify no errors)
