# Design Document: Notification System

## Architecture Overview

The notification system follows a publish-subscribe pattern with three primary layers:

```
┌─────────────────────────────────────────────────────┐
│              Any Scene/System                       │
│  (socials_page, matchmaking, achievements, etc.)    │
└──────────────────┬──────────────────────────────────┘
                   │ GlobalSignalBus.notification_received(data)
                   ▼
┌─────────────────────────────────────────────────────┐
│         GlobalSignalBus (Autoload)                  │
│  • notification_received(notification_data)         │
│  • notification_action_taken(id, action)            │
└──────────────────┬──────────────────────────────────┘
                   │ Signal relay
                   ▼
┌─────────────────────────────────────────────────────┐
│         MainLobbyScreen                             │
│  • Listens for notification_received               │
│  • Instantiates NotificationComponent              │
│  • Manages popup visibility                         │
│  • Shows visual indicator                           │
└──────────────────┬──────────────────────────────────┘
                   │ User interaction
                   ▼
┌─────────────────────────────────────────────────────┐
│         NotificationComponent                       │
│  • Displays message                                 │
│  • Shows/hides action buttons                       │
│  • Emits action signals                             │
└──────────────────┬──────────────────────────────────┘
                   │ GlobalSignalBus.notification_action_taken()
                   ▼
┌─────────────────────────────────────────────────────┐
│         UserDatabase (Autoload)                     │
│  • Stores notifications per user                    │
│  • Persists to JSON                                 │
│  • Provides CRUD operations                         │
└─────────────────────────────────────────────────────┘
```

## Data Flow

### Sending a Notification
1. Any system calls `GlobalSignalBus.notification_received.emit(notification_data)`
2. `notification_data` contains: `{recipient_username, message, has_actions, action_data, sender}`
3. UserDatabase receives signal and adds notification to target user's record
4. If target user is current_user, MainLobbyScreen updates UI immediately

### Displaying Notifications
1. MainLobbyScreen connects to `GlobalSignalBus.notification_received` on `_ready()`
2. On signal, instantiate NotificationComponent and add to scrollable list
3. Update notification button color indicator if unread notifications exist
4. Load existing notifications from UserDatabase on screen load

### Handling Actions
1. User clicks accept/deny on NotificationComponent
2. Component emits `action_taken(notification_id, action_string)`
3. MainLobbyScreen receives signal and:
   - Calls UserDatabase to remove notification
   - Emits `GlobalSignalBus.notification_action_taken(id, action)`
   - Removes component from UI
4. Interested systems (friend manager, matchmaking) listen to `notification_action_taken` and handle their types

## Component Design

### GlobalSignalBus
**Purpose**: Decouple notification senders from receivers; provide extensible global communication hub

**Signals**:
- `notification_received(notification_data: Dictionary)` - Any system emits when creating a notification
- `notification_action_taken(notification_id: String, action: String)` - Emitted after user interacts with notification

**Future Extensions**: Can add `friend_request_sent`, `match_started`, etc. as needed

### NotificationComponent
**Purpose**: Reusable UI element for displaying notification content and action buttons

**Structure**:
```
NotificationComponent (PanelContainer)
├── MarginContainer
    └── VBoxContainer
        ├── MessageLabel (shows notification.message)
        └── HBoxContainer (visible if has_actions)
            ├── AcceptButton
            └── DenyButton
```

**Exported Properties**:
- `notification_data: Dictionary` - Stores full notification object
- `indicator_color: Color` - Allows customization for future visual effects

**Signals**:
- `action_taken(notification_id: String, action: String)` - Emitted on accept/deny

### UserDatabase Extension
**New Functions**:
- `add_notification(username: String, notification: Dictionary) -> void`
- `remove_notification(username: String, notification_id: String) -> void`
- `get_notifications(username: String) -> Array[Dictionary]`
- `mark_notification_read(username: String, notification_id: String) -> void`
- `get_unread_count(username: String) -> int`

**Schema Addition**:
```json
{
  "username": {
    "username": "string",
    "email": "string",
    "password_hash": "string",
    "avatar_path": "string",
    "notifications": [
      {
        "id": "uuid_string",
        "message": "Friend request from PlayerName",
        "timestamp": "2026-02-02T14:30:00Z",
        "sender": "PlayerName",
        "is_read": false,
        "has_actions": true,
        "action_data": {
          "type": "friend_request",
          "sender_id": "player_username"
        }
      }
    ]
  }
}
```

### MainLobbyScreen Updates
**New State Variables**:
- `notification_components: Array[Control]` - Track instantiated components
- `has_unread_notifications: bool` - Control button indicator

**New Methods**:
- `_on_notification_received(notification_data: Dictionary) -> void`
- `_load_existing_notifications() -> void`
- `_update_notification_indicator() -> void`
- `_on_notification_action(notification_id: String, action: String) -> void`

**UI Changes**:
- Wrap notification list in ScrollContainer for overflow handling
- Add color modulation to NotificationsButton based on unread state
- Connect ClosePopUpButton signal (if not already connected)

## Notification Type Patterns

### Friend Request Example
```gdscript
# In socials_page.gd when avatar clicked
func _on_avatar_clicked(target_username: String) -> void:
    var notification_data = {
        "recipient_username": target_username,
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

### System Message Example (Future)
```gdscript
# In achievement system
func _on_achievement_unlocked(achievement_name: String) -> void:
    var notification_data = {
        "recipient_username": UserDatabase.current_user.username,
        "message": "Achievement unlocked: %s" % achievement_name,
        "sender": "System",
        "has_actions": false,
        "action_data": {
            "type": "achievement_notification"
        }
    }
    GlobalSignalBus.notification_received.emit(notification_data)
```

## Error Handling

### Notification Creation
- Validate `recipient_username` exists before adding to database
- Generate unique ID using `Time.get_unix_time_from_system()` + random component
- Handle case where recipient is currently logged in vs. offline

### UI Robustness
- Gracefully handle missing notification data fields
- Prevent duplicate instantiation of same notification
- Handle notification removal while popup is closed

## Performance Considerations

### Notification Count Limits
- Future consideration: Implement max notification count per user (e.g., 100)
- Auto-prune old read notifications after threshold
- Current implementation: No limit (acceptable for MVP)

### Database Saves
- Call `_save_database()` on every notification add/remove
- Acceptable for local JSON; would batch for remote database

### UI Updates
- Only load notifications for `current_user` on lobby screen load
- Lazy instantiation: create components only when popup opens (future optimization)
- Current implementation: Instantiate immediately for simpler state management

## Testing Strategy

### Unit Tests (Manual Verification)
1. Send notification to logged-in user → verify button indicator changes
2. Send notification to offline user → verify persists in JSON
3. Open popup → verify all notifications displayed with correct data
4. Accept notification → verify removal from UI and database
5. Deny notification → verify removal from UI and database
6. Test with 20+ notifications → verify scrolling works
7. Restart game → verify notifications persist

### Integration Test
Full friend request flow:
1. User A sends friend request to User B (via avatar click)
2. User B's notification button shows indicator
3. User B opens popup and sees "Friend request from UserA"
4. User B clicks Accept
5. Notification removed, friend added to both users (future friend system)

## Future Enhancements
- Notification expiration (TTL)
- Rich content (images, embedded buttons)
- Batch notification clearing
- Notification categories/filtering
- Push notifications (mobile)
- Notification sounds/haptics
- Dismiss without action (X button per notification)
