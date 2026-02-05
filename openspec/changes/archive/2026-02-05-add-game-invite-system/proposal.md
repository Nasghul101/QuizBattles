# Change: Add Game Invite System

## Why
Players can add friends but cannot invite them to play duels. A game invitation system enables social gameplay by allowing players to send duel invites, respond to invitations, and provides the foundation for future multiplayer matching.

## What Changes
- Add `game_invite_accepted` signal to GlobalSignalBus for multiplayer integration hook
- Add timestamp to all notifications with automatic 3-day expiry filtering
- Implement game invite button in AccountPopup that sends invite notifications and manages button state (disabled after send, re-enabled on reopen)
- Prevent duplicate game invites to the same player (same sender can invite different players)
- Send rejection notification to inviter when invite is denied (no action buttons, expires after 3 days)
- Handle game invite acceptance/denial in MainLobbyScreen and UserDatabase

**Future Extension Note**: Game mode selection will be added later by extending action_data with game mode field and updating signal parameters.

## Impact
- **Affected specs**: global-signal-bus, local-user-database, notification-component, account-management-screen
- **Affected code**: 
  - `autoload/global_signal_bus.gd` (new signal)
  - `autoload/user_database.gd` (timestamps, expiry, duplicate prevention, rejection notifications)
  - `scenes/ui/account_ui/account_popup.gd` (button logic)
  - `scenes/ui/main_lobby_screen.gd` (invite acceptance handling)

## Detailed Description

### Global Signal Bus Extension
Extend `autoload/global_signal_bus.gd` to support game invite signals:
- Add `game_invite_accepted` signal that emits when a player accepts an invite, containing inviter and invitee usernames for future multiplayer matching

### Account Popup Invite Button Logic
Enhance `scenes/ui/account_ui/account_popup.gd` to handle game invites:
- When "Invite to duel" button is pressed, send a game invite notification to the displayed user
- Disable the button after sending invite (visual feedback)
- Re-enable button when popup reopens

### Notification System Enhancements
Extend notification functionality to support game invites and expiry:
- Add timestamp to all notifications when created
- Implement automatic expiry of notifications after 3 days
- Support game invite notification type in action_data
- Send rejection notifications to invite sender when denied

### User Database Integration
Extend `autoload/user_database.gd` to manage game invites:
- Prevent duplicate game invites to the same player (similar to friend request logic)
- Add timestamps to notifications for expiry tracking
- Remove expired notifications (older than 3 days) when querying
- Handle game invite acceptance/denial actions
- Send rejection notification to original sender when invite is denied

### Main Lobby Screen Handling
Enhance `scenes/ui/main_lobby_screen.gd` to process game invite actions:
- Emit `GlobalSignalBus.game_invite_accepted` signal when player accepts invite
- This signal serves as a hook for future multiplayer functionality

## User Experience Flow

### Sending Game Invite
1. Player A clicks on a friend's avatar (in friends list or search results)
2. Account popup opens showing friend's profile
3. Player A clicks "Invite to duel" button
4. Button becomes disabled (visual feedback)
5. **NEW**: Game invite notification is sent to Player B
6. **NEW**: Notification includes inviter's username and action_data with type "game_invite"
7. If Player A closes and reopens the popup, button is enabled again
8. If Player A tries to send another invite while one is pending, it's prevented silently

### Receiving and Accepting Game Invite
1. Player B receives notification: "PlayerA invites you to a duel"
2. Notification shows Accept/Deny buttons
3. Player B clicks "Accept"
4. **NEW**: Notification is removed
5. **NEW**: `GlobalSignalBus.game_invite_accepted` signal is emitted with both player usernames
6. **NEW**: Future multiplayer system can connect to this signal to initiate game

### Receiving and Denying Game Invite
1. Player B receives notification: "PlayerA invites you to a duel"
2. Player B clicks "Deny"
3. **NEW**: Notification is removed
4. **NEW**: Player A receives notification: "PlayerB rejected your duel" (no action buttons)
5. **NEW**: Rejection notification expires after 3 days

### Notification Expiry
1. Player receives any notification
2. **NEW**: Notification is timestamped on creation
3. After 3 days, notification is automatically removed when notifications are queried
4. Old/stale invites don't clutter the notification list

## Technical Considerations

### Data Structure
Game invite notification format:
```gdscript
{
    "id": "unique_notification_id",
    "recipient_username": "player_b",
    "message": "PlayerA invites you to a duel",
    "sender": "player_a",
    "has_actions": true,
    "timestamp": 1738675200,  # Unix timestamp
    "action_data": {
        "type": "game_invite",
        "inviter_id": "player_a"
    }
}
```

Rejection notification format:
```gdscript
{
    "id": "unique_notification_id",
    "recipient_username": "player_a",
    "message": "PlayerB rejected your duel",
    "sender": "System",
    "has_actions": false,
    "timestamp": 1738675200,  # Unix timestamp
    "action_data": {
        "type": "game_invite_rejection"
    }
}
```

### Duplicate Prevention
- Check if recipient already has a pending game invite notification from the same sender
- Search through recipient's notifications for matching sender and type "game_invite"
- If found, prevent duplicate and log warning (similar to friend request duplicate prevention)

### Timestamp and Expiry Logic
- Add `timestamp` field to all notifications (Unix timestamp in seconds)
- When querying notifications with `get_notifications()`, filter out any older than 3 days
- Calculate expiry: `Time.get_unix_time_from_system() - notification.timestamp > 259200` (3 days in seconds)
- Expired notifications are not displayed but remain in database until next query

### Signal Flow for Accept
```
Player B clicks Accept on game invite
  ↓
NotificationComponent emits action_taken("notif_id", "accept")
  ↓
MainLobbyScreen handles it and emits GlobalSignalBus.notification_action_taken("notif_id", "accept")
  ↓
MainLobbyScreen checks if action_data.type == "game_invite"
  ↓
MainLobbyScreen emits GlobalSignalBus.game_invite_accepted(inviter_id, invitee_id)
  ↓
Notification is removed from database
  ↓
Future multiplayer system listens and initiates game
```

### Signal Flow for Deny
```
Player B clicks Deny on game invite
  ↓
NotificationComponent emits action_taken("notif_id", "deny")
  ↓
MainLobbyScreen handles it and emits GlobalSignalBus.notification_action_taken("notif_id", "deny")
  ↓
UserDatabase checks if action_data.type == "game_invite"
  ↓
UserDatabase creates rejection notification for original sender
  ↓
Rejection notification: "PlayerB rejected your duel" (has_actions: false)
  ↓
Original invite notification is removed
```

## Capabilities Affected

### Modified Capabilities
- **global-signal-bus**: Add game_invite_accepted signal for multiplayer integration hook
- **notification-component**: Support timestamp field and expiry logic (already has structure, just needs timestamp support)
- **local-user-database**: Add duplicate game invite prevention, timestamp support, expiry filtering, rejection notification creation
- **account-management-screen**: Add game invite button logic and state management (Note: This is the account_popup which may need its own spec or be part of account management)

## Out of Scope
- Actual multiplayer game functionality (this is just the invitation foundation)
- Game mode selection in invites (noted for future: will need mode info in action_data)
- Invite expiry UI indicators (e.g., "expires in 2 days")
- Invite history or log
- Canceling sent invites
- Batch invites to multiple players
- Custom invite messages

## Success Criteria
1. When "Invite to duel" button is pressed in account popup, a game invite notification is sent to the displayed user
2. Button becomes disabled after sending invite and re-enables when popup reopens
3. Duplicate game invites to the same player are prevented
4. All notifications receive timestamps on creation
5. Notifications older than 3 days are automatically filtered out when queried
6. When player accepts game invite, `GlobalSignalBus.game_invite_accepted` signal is emitted with both usernames
7. When player denies game invite, sender receives rejection notification without action buttons
8. Rejection notifications expire after 3 days like all other notifications

## Dependencies
- Existing notification system (notification_received, notification_action_taken signals)
- Existing account popup (account_popup.tscn, account_popup.gd)
- Existing user database (user_database.gd)
- Existing GlobalSignalBus (global_signal_bus.gd)
- Existing notification component (notification_component.tscn)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Duplicate invites bypass prevention | Medium - notification spam | Implement same duplicate checking as friend requests |
| Expired notifications not cleaned up | Low - database bloat | Filter on query, consider periodic cleanup in future |
| Button state persists incorrectly | Low - confusing UX | Always reset button state in display_user() |
| Signal not connected for future multiplayer | Medium - invites don't work | Document signal clearly, add TODO comments |
| Timestamp precision issues | Low - incorrect expiry | Use Unix timestamp from system time |

## Future Enhancements
- Game mode selection in invite (requires action_data extension)
- Invite status indicators (pending, accepted, rejected, expired)
- Invite history panel showing past invites
- Cancel sent invites before acceptance
- Invite multiple players simultaneously (for future team modes)
- Custom invite messages or challenges
- Push notification support when player is offline
- Invite cooldown/rate limiting per player
