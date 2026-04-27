# Design: Implement Socials Page Interactions

## Overview

This design adds full interactivity to the rebuilt socials_page, enabling friend statistics display, player search, and friend request sending. The design emphasizes using existing infrastructure (GlobalSignalBus, UserDatabase methods) and placeholder data for features not yet tracked.

## Key Design Decisions

### 1. Friend Statistics Display
**Decision**: Use friend_display_component to show win/loss records and category preferences

**Rationale**:
- friend_display_component already has all needed setters (set_player_name, set_win_count, set_loss_count, set_*_category)
- Displays visual category bars with color coding
- Designed specifically for friend list display

**Win/Loss Calculation**:
- Win count: Current user's wins against this friend (`current_user.friend_wins[friend_username]` or 0)
- Loss count: Friend's wins against current user (`friend_data.friend_wins[current_user.username]` or 0)
- This creates a head-to-head record specific to that friendship

**Category Display**:
- Top 3 categories from `friend_data.category_stats` sorted by play count
- Map category name to color using existing color_codes.json or category color mapping
- Use placeholder data until real tracking implemented

### 2. Category Statistics Tracking (Placeholder)
**Decision**: Add `category_stats: Dictionary` to user schema with placeholder data generation

**Rationale**:
- Database field needed for UI to display category preferences
- Real tracking requires gameplay_screen integration (out of scope for this change)
- Placeholder data allows UI testing and visual design validation
- Easy to replace with real implementation later

**Schema**:
```gdscript
"category_stats": {
    "History": 12,
    "Science": 8,
    "Geography": 5
}
```

**Placeholder Generation**:
```gdscript
func _generate_placeholder_category_stats() -> Dictionary:
    # TODO: Replace with real category tracking from gameplay_screen match completion
    var categories = ["General Knowledge", "Entertainment", "Science", "History", "Geography", "Sports"]
    var stats = {}
    for i in range(3):
        var category = categories[randi() % categories.size()]
        stats[category] = randi() % 20 + 1  # Random count 1-20
    return stats
```

**Future Implementation**:
- Add category tracking to gameplay_screen after match completion
- Increment `category_stats[category_name] += 1` for each round played
- Remove placeholder generation once real tracking is active

### 3. Search Interaction Pattern
**Decision**: Real-time search-as-you-type with name_display_button instantiation

**Rationale**:
- Uses existing UserDatabase.search_users_by_username() method (already case-insensitive, partial match)
- No need for debouncing (database is in-memory, searches are instant)
- Clear and re-populate pattern simplifies state management

**Flow**:
1. User types in NameInput
2. `text_changed` signal triggers `_on_name_input_text_changed()`
3. Clear FriendsContainer (queue_free all children)
4. Call UserDatabase.search_users_by_username(query)
5. Instantiate name_display_button for each result
6. Connect selection_changed signal
7. Add to FriendsContainer

**Edge Cases**:
- Empty query: Clear container, show nothing
- No results: Container remains empty (no error message needed)
- Current user excluded: Already handled by UserDatabase.search_users_by_username()

### 4. Name Display Button Highlight Behavior
**Decision**: Create script for name_display_button with radio-button selection pattern

**Rationale**:
- Radio button behavior (only one selected at a time) matches requirement #3
- Component emits signal for parent to manage selection state
- Visual feedback through button appearance change

**Implementation**:
```gdscript
# name_display_button.gd
signal selection_changed(username: String, is_highlighted: bool)

var is_highlighted: bool = false
var username: String = ""

func set_highlighted(value: bool) -> void:
    is_highlighted = value
    if is_highlighted:
        # Change appearance (e.g., modulate color, add border)
        modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint
    else:
        modulate = Color.WHITE
    selection_changed.emit(username, is_highlighted)

func _on_pressed() -> void:
    set_highlighted(not is_highlighted)
```

**Parent Management**:
- socials_page.gd stores `selected_username: String`
- On selection_changed with is_highlighted=true:
  - Deselect previous button (iterate and call set_highlighted(false))
  - Store new username
  - Enable SendFriendRequestButton
- On selection_changed with is_highlighted=false:
  - Clear selected_username if matches
  - Disable SendFriendRequestButton

### 5. Friend Request Sending Flow
**Decision**: Enable SendFriendRequestButton only when a user is highlighted

**Rationale**:
- Prevents accidental sends without selection
- Clear visual feedback (button disabled = no selection)
- Matches requirement #4 (button disabled if none highlighted)

**Flow**:
1. User highlights name_display_button
2. SendFriendRequestButton becomes enabled
3. User presses SendFriendRequestButton
4. Create notification_data with friend_request type
5. Emit GlobalSignalBus.notification_received
6. Clear selection and disable button
7. Keep popup open for additional requests

**Notification Data Structure** (already defined in UserDatabase):
```gdscript
{
    "recipient_username": selected_username,
    "message": "Friend request from %s" % current_user.username,
    "sender": current_user.username,
    "has_actions": true,
    "action_data": {
        "type": "friend_request",
        "sender_id": current_user.username
    }
}
```

### 6. Popup Cleanup Behavior
**Decision**: Clear NameInput and search results on popup close

**Rationale**:
- Matches requirement #5 (clear nameInput after closing)
- Prevents stale UI state
- Fresh start for next popup open

**Trigger Points**:
- BackButton pressed
- (Future: drag handle dismiss)

**Cleanup Actions**:
1. Clear NameInput.text = ""
2. Clear FriendsContainer (queue_free all children)
3. Clear selected_username
4. Disable SendFriendRequestButton
5. Hide AddFriendsPopup

### 7. Friend List Update Integration
**Decision**: Reuse existing GlobalSignalBus.notification_action_taken connection

**Rationale**:
- Signal already connected in current socials_page.gd
- Already filters for "accept" actions on friend_request type
- No new signal infrastructure needed
- Matches requirement #6

**Existing Code** (already implemented in deprecated version):
```gdscript
func _on_friendship_changed(_notification_id: String, action: String) -> void:
    if action == "accept":
        _populate_friends_list()
```

**Verification Needed**:
- Ensure connection exists in new socials_page.gd _ready()
- Verify UserDatabase.add_friend() is called before signal emission
- Test real-time update while page is open

### 8. Share Button Placeholder
**Decision**: Add TODO comment and log message for future implementation

**Rationale**:
- Native share menu requires platform-specific implementation
- Out of scope for this change (social functionality focus)
- Matches requirement #5 (should not do something yet but add a node there)

**Implementation**:
```gdscript
func _on_share_button_pressed() -> void:
    # TODO: Implement native share menu integration for mobile
    # Should open phone's native share dialog with game invite link
    print("Share button pressed - feature not yet implemented")
```

## Component Relationships

```
socials_page.gd
    ├─ FriendDisplayContainer
    │   ├─ friend_display_component (instantiated per friend)
    │   └─ AddNewFriendsButton
    └─ AddFriendsPopup
        ├─ NameInput (TextEdit)
        ├─ FriendsContainer
        │   └─ name_display_button (instantiated per search result)
        ├─ SendFriendRequestButton (enabled when selection exists)
        └─ ShareButton (placeholder)
```

## Data Flow

### Friend Display Flow
```
_ready() / _on_friendship_changed()
    ↓
_populate_friends_list()
    ↓
UserDatabase.get_friends(current_user.username)
    ↓
For each friend:
    UserDatabase.get_user_data_for_display(friend_username)
    ↓
    Instantiate friend_display_component
    ↓
    set_player_name(), set_win_count(), set_loss_count()
    ↓
    Calculate top 3 categories from category_stats
    ↓
    set_first_category(), set_second_category(), set_third_category()
    ↓
    Add to FriendDisplayContainer
```

### Search and Request Flow
```
User types in NameInput
    ↓
_on_name_input_text_changed()
    ↓
UserDatabase.search_users_by_username(query)
    ↓
Clear FriendsContainer
    ↓
For each result:
    Instantiate name_display_button
    ↓
    Connect selection_changed signal
    ↓
    Add to FriendsContainer
    ↓
User clicks button
    ↓
button._on_pressed() → set_highlighted(true)
    ↓
Emit selection_changed(username, true)
    ↓
_on_name_selection_changed()
    ↓
Deselect previous button, store username, enable SendFriendRequestButton
    ↓
User clicks SendFriendRequestButton
    ↓
_on_send_friend_request_button_pressed()
    ↓
Emit GlobalSignalBus.notification_received
    ↓
Clear selection, disable button
```

## Testing Strategy

### Unit Tests (Manual)
1. Friend display with various data states (0 friends, multiple friends, missing stats)
2. Search with various queries (empty, partial match, no results)
3. Highlight behavior (single select, deselect, rapid clicking)
4. Button state management (enable/disable on selection)
5. Popup cleanup (verify all fields cleared)

### Integration Tests
1. Login → view friends → verify stats display correctly
2. Open popup → search → select → send request → verify notification received
3. Accept friend request on another account → verify real-time update on socials_page
4. Close and reopen popup → verify clean state

### Edge Cases
1. Friend with empty category_stats (use placeholder or hide)
2. User with 0 wins and 0 losses (display "0")
3. Search query matching no users (empty container, no errors)
4. Rapid typing in search field (verify no race conditions)
5. Friend request to already-friend user (UserDatabase should handle duplicate prevention)

## Migration Considerations

**Database Migration**:
- Add `category_stats: {}` to all existing users via _migrate_user_data()
- No data loss or breaking changes
- Migration runs automatically on first database load

**Backward Compatibility**:
- All new fields optional (default to empty dictionary)
- Existing friend_wins data preserved
- No changes to authentication or friendship logic

## Future Enhancements

### Real Category Tracking
Replace placeholder with:
```gdscript
# In gameplay_screen.gd after match completion
func _update_category_stats() -> void:
    var username = UserDatabase.current_user.username
    var user_data = UserDatabase._users[username]
    
    if not user_data.has("category_stats"):
        user_data.category_stats = {}
    
    # Increment each category played in this match
    for round_data in match_data.rounds_data:
        var category = round_data.category
        if not category.is_empty():
            user_data.category_stats[category] = user_data.category_stats.get(category, 0) + 1
    
    UserDatabase._save_database()
```

### Native Share Integration
```gdscript
# Platform-specific share dialog
if OS.has_feature("android"):
    var share_intent = JavaClassWrapper.wrap("android.content.Intent")
    # ... implement Android share
elif OS.has_feature("ios"):
    # ... implement iOS share using UIActivityViewController
```

## Open Questions
None - all requirements clarified with user.
