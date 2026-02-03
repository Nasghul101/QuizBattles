# Design Document: Friend List Management

## Architectural Overview

This change introduces friend list management as a core social feature, building on the existing notification system. The design emphasizes bidirectional friendship consistency, real-time UI updates via signals, and clean separation between data persistence (UserDatabase) and presentation (SocialsPage).

## Component Responsibilities

### UserDatabase (autoload/user_database.gd)
**Role**: Single source of truth for friend relationships

**New Functions**:
- `add_friend(username: String, friend_username: String) -> void`
  - Validates both users exist
  - Adds bidirectional friendship (A→B and B→A)
  - Prevents duplicate entries
  - Persists to database
  
- `remove_friend(username: String, friend_username: String) -> void`
  - Validates friendship exists
  - Removes bidirectionally
  - Persists to database
  
- `get_friends(username: String) -> Array`
  - Returns array of friend data dictionaries
  - Each dictionary: `{username: String, email: String, avatar_path: String}`
  - Empty array if user has no friends or doesn't exist
  
- `are_friends(username1: String, username2: String) -> bool`
  - Helper to check if two users are already friends
  - Used to prevent duplicate friend entries

**Signal Handling**:
- Listen to `GlobalSignalBus.notification_action_taken`
- Filter for `action == "accept"` and `action_data.type == "friend_request"`
- Extract sender from stored notification data before it's removed
- Call `add_friend()` with current user and sender

### SocialsPage (scenes/ui/lobby_pages/socials_page.gd)
**Role**: Display and manage friend list UI

**New State**:
- `@onready var friends_list: GridContainer` - Reference to FriendsList container from scene

**New Functions**:
- `_populate_friends_list() -> void`
  - Clears all existing children from friends_list
  - Calls `UserDatabase.get_friends(current_user.username)`
  - Instantiates avatar component for each friend
  - Sets avatar name and picture using component methods
  
- `_on_friendship_changed() -> void`
  - Called when GlobalSignalBus.notification_action_taken fires
  - Filters for friend_request acceptance
  - Re-calls `_populate_friends_list()` to refresh display

**Lifecycle**:
- `_ready()`: Call `_populate_friends_list()` if user is signed in
- Connect to `GlobalSignalBus.notification_action_taken` for live updates

### GlobalSignalBus (autoload/global_signal_bus.gd)
**Role**: Unchanged - already provides notification_action_taken signal

No modifications needed. Both UserDatabase and SocialsPage will listen to the existing signal.

## Data Flow

### Friend Request Acceptance Flow
```
┌─────────────────────────────────────────────────────────────┐
│ User B clicks "Accept" on notification from User A         │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ NotificationComponent emits action_taken(notif_id, "accept")│
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ MainLobbyScreen:                                            │
│ - Stores notification_data (includes action_data)           │
│ - Removes notification from DB                              │
│ - Emits GlobalSignalBus.notification_action_taken(id, act.) │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├────────────────────┬────────────────────────┐
                 ▼                    ▼                        ▼
┌────────────────────────┐  ┌─────────────────────┐  ┌────────────────────┐
│ UserDatabase           │  │ SocialsPage         │  │ Other listeners    │
│ (listener #1)          │  │ (listener #2)       │  │ (future)           │
└────────────────┬───────┘  └─────────┬───────────┘  └────────────────────┘
                 │                    │
                 ▼                    ▼
┌────────────────────────┐  ┌─────────────────────┐
│ Filter for:            │  │ Filter for:         │
│ - action == "accept"   │  │ - friend_request    │
│ - type == friend_req.  │  │ - action == accept  │
└────────────────┬───────┘  └─────────┬───────────┘
                 │                    │
                 ▼                    ▼
┌────────────────────────┐  ┌─────────────────────┐
│ add_friend(A, B)       │  │ _populate_friends() │
│ - Check if exists      │  │ - Clear list        │
│ - Add A to B's friends │  │ - Query DB          │
│ - Add B to A's friends │  │ - Instantiate       │
│ - Save to JSON         │  │   avatars           │
└────────────────────────┘  └─────────────────────┘
```

### Opening Socials Page Flow
```
┌─────────────────────────────────────────────────────────────┐
│ User navigates to socials page                              │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ SocialsPage._ready()                                        │
│ - Check if user is signed in                                │
│ - Call _populate_friends_list()                             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ _populate_friends_list()                                    │
│ 1. Clear existing children from FriendsList                 │
│ 2. Call UserDatabase.get_friends(current_user.username)     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ UserDatabase.get_friends(username)                          │
│ - Validate user exists                                      │
│ - Get user's friends array ["user1", "user2", ...]          │
│ - For each friend username, get full user data              │
│ - Return array of {username, email, avatar_path}            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ For each friend in results:                                 │
│ 1. Instantiate AVATAR_COMPONENT                             │
│ 2. Add to FriendsList GridContainer                         │
│ 3. Set avatar name (friend.username)                        │
│ 4. Set avatar picture (friend.avatar_path)                  │
└─────────────────────────────────────────────────────────────┘
```

## Database Schema Changes

### User Record Structure
```json
{
  "username": {
    "username": "string",
    "password_hash": "string",
    "email": "string",
    "avatar_path": "string",
    "notifications": [],
    "friends": ["username1", "username2"]  // NEW FIELD
  }
}
```

### Migration Strategy
- Existing users without `friends` field will have it initialized as empty array on first friend operation
- No data migration needed (backward compatible)
- `get_friends()` returns empty array for users without the field

## Error Handling

### UserDatabase Error Cases
| Error | Handling |
|-------|----------|
| User doesn't exist | Log error, return empty array or early return |
| Friend already exists | Skip add operation, log warning |
| Self-friending attempted | Prevent in validation, log warning |
| Asymmetric friendship detected | Log error, attempt to repair by adding missing link |
| Database write fails | Log error, attempt retry |

### SocialsPage Error Cases
| Error | Handling |
|-------|----------|
| Not signed in | Skip population, display empty state |
| No friends | Display empty FriendsList (no error) |
| Avatar component instantiation fails | Log error, continue with remaining friends |
| Friend data incomplete | Skip that friend, log warning |

## Performance Considerations

### Friend List Loading
- **Complexity**: O(n) where n = number of friends
- **Bottleneck**: Avatar texture loading
- **Mitigation**: Avatar textures are small PNGs, should be fast
- **Future**: If friend counts exceed 50+, implement pagination

### Real-Time Updates
- **Signal propagation**: Near-instant (in-memory event bus)
- **UI refresh**: Full clear-and-repopulate on change
- **Optimization opportunity**: Smart diff-based updates (not needed for MVP)

### Memory
- Avatar components are lightweight (Button with TextureRect and Label)
- Each friend: ~1-2 KB in memory
- 100 friends: ~100-200 KB (negligible)

## Testing Strategy

### Unit Tests (Manual Verification)
1. **Add Friend**:
   - User A sends request to User B
   - User B accepts
   - Verify both have each other in friends array
   
2. **Display Friends**:
   - User with 5 friends opens socials page
   - Verify 5 avatar components appear
   - Verify correct names and avatars
   
3. **Real-Time Update**:
   - User has socials page open
   - Accept friend request via notification
   - Verify new friend appears in list without page refresh
   
4. **Empty State**:
   - New user with no friends opens socials page
   - Verify FriendsList is empty (no crash)
   
5. **Persistence**:
   - Add friends
   - Restart game
   - Login and open socials page
   - Verify friends still appear

### Edge Cases
- Accepting multiple friend requests rapidly
- Opening socials page while not signed in
- Friend who changes their avatar (should show new avatar)
- User with 0 friends, 1 friend, 50+ friends

### Data Integrity Tests
- Verify bidirectional friendship after acceptance
- Check for duplicate entries in friends array
- Validate JSON structure after friend operations

## Future Extension Points

### Features Buildable on This Foundation
1. **Unfriend**: Already structured with `remove_friend()` - just add UI button
2. **Friend Status**: Add `online` field to friend data returned by `get_friends()`
3. **Friend Search**: Filter friends_list children based on search input
4. **Friend Invites**: Use friend list to populate game invitation UI
5. **Friend Chat**: Use friend list to show chat contacts

### Scalability Considerations
- Current design assumes <100 friends (reasonable for mobile game)
- If friend counts grow large, consider:
  - Pagination in `get_friends()`
  - Virtual scrolling in FriendsList
  - Lazy loading of avatar textures
  - Caching friend data in memory

## Alternative Designs Considered

### Alternative 1: Store Friend Requests as Separate Entity
**Rejected**: Adds complexity without benefit for current scope. Notification system already handles pending requests.

### Alternative 2: Refresh Friends List on Timer
**Rejected**: Polling is inefficient. Signal-based updates are instant and event-driven.

### Alternative 3: Store Only One Side of Friendship
**Rejected**: Would require joins/lookups to check friendships. Bidirectional storage is more performant for reads.

### Alternative 4: Separate FriendManager Autoload
**Considered**: Would provide cleaner separation but adds overhead. UserDatabase is already the single source for user relationships - extending it is simpler.

## Implementation Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Notification removed before reading action_data | Medium | High | Read notification before removal in MainLobbyScreen |
| Race condition on simultaneous acceptance | Low | Medium | Database write is synchronous, second write will see first |
| FriendsList not refreshing | Low | High | Ensure signal connection in _ready() |
| Avatar textures not loading | Low | Medium | Use default avatar on load failure |

## Open Questions
✅ None - all requirements clarified with user
