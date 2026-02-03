# Proposal: Add Friend List Management

## Overview
Implement friend list storage and display functionality so that when a player accepts a friend request, both users are added to each other's friend lists and avatar components are displayed in the FriendsList on the socials page.

## Problem Statement
Currently, the notification system allows players to send and accept friend requests, but there is no persistence of friendships or visual display of friends. When a player accepts a friend request:
- No data is stored to track the friendship
- No avatar components appear in the FriendsList GridContainer
- Players cannot see who their friends are

## Proposed Changes

### User Database Extension
Extend `autoload/user_database.gd` to support friend list management:
- Add `friends` array to user data schema (stores usernames of friends)
- Implement `add_friend(username: String, friend_username: String) -> void` to create bidirectional friendship
- Implement `remove_friend(username: String, friend_username: String) -> void` for future unfriend functionality
- Implement `get_friends(username: String) -> Array` to retrieve friend list with full user data (username, avatar_path)
- Listen to `GlobalSignalBus.notification_action_taken` signal to handle friend request acceptance
- When notification action is "accept" and action_data.type is "friend_request", add both users as friends

### Socials Page Friend List Display
Enhance `scenes/ui/lobby_pages/socials_page.gd` to display friends:
- Add reference to FriendsList GridContainer via @onready
- Implement `_populate_friends_list() -> void` to instantiate avatar components for each friend
- Call `_populate_friends_list()` in `_ready()` to load friends when screen opens
- Connect to `GlobalSignalBus.notification_action_taken` to refresh friend list when new friends are added
- Clear and repopulate FriendsList when friendship changes occur

### Avatar Component Integration
Reuse existing `avatar_component.tscn` to display friends:
- Instantiate one avatar component per friend in FriendsList
- Set avatar name and picture using existing component methods
- Display in grid layout for clean, organized presentation

## User Experience Flow

### Initial Setup (First Time User)
1. User logs in and opens socials page
2. FriendsList is empty (no friends yet)
3. User can search for and send friend requests via existing popup

### Accepting Friend Request
1. User A sends friend request to User B (existing functionality)
2. User B receives notification and clicks "Accept"
3. **NEW**: Both users are added to each other's friends array in database
4. **NEW**: If User B has socials page open, their FriendsList updates immediately with User A's avatar
5. **NEW**: When User A next opens socials page, they see User B's avatar in their FriendsList

### Opening Socials Page
1. User opens socials page (navigates from main lobby)
2. **NEW**: System queries user's friends from UserDatabase
3. **NEW**: For each friend, an avatar component is instantiated showing their name and profile picture
4. **NEW**: Avatar components are displayed in the FriendsList GridContainer

## Technical Considerations

### Data Persistence
- Friends are stored in `data/user_database.json` as part of each user's data
- Format: `"friends": ["username1", "username2", ...]`
- Bidirectional friendships: if A is friends with B, then B must also have A in their friends list

### Signal Flow
```
User clicks Accept on friend request
  ↓
NotificationComponent emits action_taken("notif_id", "accept")
  ↓
MainLobbyScreen handles it and emits GlobalSignalBus.notification_action_taken("notif_id", "accept")
  ↓
UserDatabase listens and checks if action_data.type == "friend_request"
  ↓
UserDatabase adds both users to each other's friends arrays
  ↓
SocialsPage (if listening) refreshes FriendsList display
```

### Performance
- Friend list loading is lightweight (only loads on screen open, not continuous polling)
- Avatar component instantiation is efficient (reuses existing component)
- Grid layout handles varying numbers of friends automatically

## Capabilities Affected

### New Capability
- **friend-list-management**: Core logic for storing, retrieving, and maintaining friend relationships

### Modified Capabilities
- **local-user-database**: Add friends array to user schema and friend management functions
- **socials-page-friend-display**: Add friend list population and refresh logic (Note: socials-page-popup-animation exists, but friend display logic is new)

## Out of Scope
- Unfriend functionality (structure supports it, but UI interaction not included)
- Friend status indicators (online/offline)
- Friend search within FriendsList
- Friend profile viewing on click
- Friend limit enforcement

## Success Criteria
1. When a friend request is accepted, both users have each other in their friends array
2. When opening the socials page, all friends are displayed as avatar components in FriendsList
3. When a new friend is added while socials page is open, the display updates immediately
4. Friends persist across app restarts (stored in user_database.json)
5. Avatar components show correct profile picture and username for each friend

## Dependencies
- Existing notification system (notification_action_taken signal)
- Existing avatar component (avatar_component.tscn)
- Existing user database (user_database.gd)
- Existing socials page UI (socials_page.tscn with FriendsList GridContainer)

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Friendship data inconsistency (A has B but B doesn't have A) | High - breaks user trust | Always add/remove bidirectionally in single transaction |
| Duplicate friend entries | Medium - confusing UX | Check for existing friendship before adding |
| Stale friend list display | Low - user confusion | Listen to signals for real-time updates |
| Performance with large friend lists | Low - slower load times | Implement basic pagination if needed in future |

## Future Enhancements
- Unfriend button on avatar components
- Friend request status (pending sent requests)
- Friend activity indicators
- Friend-specific chat or game invites
- Friend list sorting/filtering
