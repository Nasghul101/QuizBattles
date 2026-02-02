# Proposal: Add Notification System

**Change ID:** `2026-02-02-add-notification-system`  
**Date:** 2026-02-02  
**Status:** Proposed

## Summary
Implement a global notification system that allows any scene to send notifications to the user. Notifications appear in a popup on the main lobby screen, support user actions (accept/deny), and persist across sessions in the user database.

## Motivation
The game needs a mechanism for friend requests, game invites, and system messages. Currently, there's no way to asynchronously notify users of events or request their input. A centralized notification system provides:
- Decoupled communication between systems (friend system, matchmaking, etc.)
- User-visible indication of pending actions
- Persistent storage tied to user accounts
- Extensible architecture for future notification types

## Current Behavior
- The main lobby screen has a notifications button and `NotificationsPopUp` panel (currently non-functional)
- No global signaling mechanism exists
- No notification storage or management
- No visual indicators for pending notifications

## Proposed Changes

### New Autoload Singleton: GlobalSignalBus
Create `autoload/global_signal_bus.gd` as a central hub for application-wide signals:
- `notification_received(notification_data: Dictionary)` - emitted when any system sends a notification
- `notification_action_taken(notification_id: String, action: String)` - emitted when user accepts/rejects a notification
- Extensible for future global signals

### Notification Component
Create `scenes/ui/components/notification_component.tscn` with:
- Message text display
- Optional accept/deny buttons (controlled by `has_actions` flag)
- Emits signals when actions are taken
- Clean, minimal design matching existing components

### Main Lobby Screen Integration
Enhance `main_lobby_screen.gd` to:
- Listen for `notification_received` signal
- Instantiate notification components dynamically
- Show visual indicator (color change) on notification button when unread notifications exist
- Make notification list scrollable when content exceeds viewport
- Open/close popup on button press
- Mark notifications as read only when user interacts (accept/deny)

### User Database Extension
Extend `autoload/user_database.gd` and database schema:
- Add `notifications` array to each user record
- Each notification stores: `id`, `message`, `timestamp`, `sender`, `is_read`, `has_actions`, `action_data`
- Provide functions to add, remove, mark as read, and query notifications
- Save/load notifications from `data/user_database.json`

### Test Scenario
Friend request notification when user presses an avatar in the AddFriendsPopup on the socials page:
1. User opens socials page and clicks "Add new friend"
2. User searches for and clicks on another user's avatar
3. System sends notification via GlobalSignalBus to target user
4. Target user sees colored notification button indicator
5. Target user opens notifications popup
6. Notification component displays: "Friend request from [username]"
7. User accepts or denies request
8. Notification is removed from list and database

## Design Decisions & Trade-offs

### Type-Based Action Pattern
- **Decision**: Use flexible `action_data` dictionary instead of hardcoded notification types in core system
- **Rationale**: Allows systems (friend management, matchmaking) to define their own action handling without modifying notification infrastructure
- **Trade-off**: More indirection vs. extensibility and decoupling

### Database Storage
- **Decision**: Store notifications per-user in `user_database.json`
- **Rationale**: Aligns with existing local-first architecture; preserves notifications across sessions
- **Trade-off**: JSON file size grows with notifications vs. persistent user experience

### Visual Indicator Flexibility
- **Decision**: Start with simple color change, expose as easily modifiable property
- **Rationale**: Allows future shader effects or animations without restructuring code
- **Trade-off**: Basic initial implementation vs. future-proofed architecture

### Mark-as-Read Behavior
- **Decision**: Mark as read only on accept/deny interaction, not on popup open
- **Rationale**: Prevents accidental dismissal; ensures user acknowledges notification
- **Trade-off**: Higher unread counts vs. intentional user engagement

## Affected Specs
- **New Spec**: `notification-system` - Core notification infrastructure
- **New Spec**: `global-signal-bus` - Central signaling hub
- **Modified Spec**: `main-lobby-screen` - Adds notification display and interaction
- **Modified Spec**: `local-user-database` - Extends schema with notifications array

## Related Changes
None - this is a foundational system for future features.

## Implementation Approach
1. Create GlobalSignalBus autoload singleton
2. Extend UserDatabase with notification CRUD operations
3. Create NotificationComponent scene and script
4. Update MainLobbyScreen to handle notifications
5. Implement test scenario in socials_page.gd

## Open Questions
None - all clarifications addressed.
