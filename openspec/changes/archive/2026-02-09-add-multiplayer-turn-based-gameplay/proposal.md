# Proposal: Add Multiplayer Turn-Based Gameplay

## Change ID
`add-multiplayer-turn-based-gameplay`

## Context
The game currently supports only single-player quiz gameplay initiated from the setup screen. While the infrastructure for game invites exists (players can send invites via the account popup), there is no multiplayer gameplay system to handle asynchronous turn-based matches between friends. Players cannot compete against each other in quiz duels, which is a core feature of the Quizduell game concept.

Existing foundations:
- `GlobalSignalBus.game_invite_accepted` signal emits when invites are accepted (currently unused)
- Game invite notifications include inviter information but not match configuration
- `gameplay_screen` supports round-based play but only for single-player
- `setup_screen` allows configuration of rounds and questions but only for local play
- `friendly_battle_page` exists but is empty (no active match UI)
- `UserDatabase` stores user data locally in JSON but has no multiplayer match storage

## Problem
1. **No multiplayer match initialization**: Clicking "Invite to Game" sends a basic notification but doesn't configure a match with rounds/questions
2. **No match persistence**: No system to store and track multiplayer game state (current turn, rounds played, answers, scores)
3. **No visual representation of active games**: Players can't see their ongoing matches or whose turn it is
4. **No turn-based gameplay flow**: `gameplay_screen` doesn't support alternating turns between players
5. **No opponent answer tracking**: Players can't see when opponents have answered or view results after rounds complete
6. **Setup screen disconnected**: Setup screen only transitions to gameplay for single-player; no multiplayer flow exists
7. **No match-specific navigation**: No way to pass `match_id` context when opening gameplay for a specific match

## Proposed Solution
Implement a complete asynchronous turn-based multiplayer system using local UserDatabase storage (Firebase integration deferred). The system will support multiple simultaneous matches with different friends, alternating category selection, and automatic answer reveal after both players complete each round.

### High-Level Flow
1. **Invite Flow**: Player A clicks "Invite to Game" → opens setup_screen → configures rounds/questions → notification sent to Player B with config data
2. **Match Creation**: When Player B accepts, create persistent match in UserDatabase with unique match_id
3. **Active Match Display**: Both players see avatar_component on friendly_battle_page showing opponent's picture and turn status
4. **Gameplay Flow**: Players click avatar → open gameplay_screen with match_id → play button enabled only on their turn → alternate rounds (inviter chooses odd rounds, invitee chooses even rounds)
5. **Answer Tracking**: Grey placeholders show unanswered questions; after both players finish a round, colored results reveal automatically
6. **Match Completion**: After last question answered, return to main_lobby_screen (result screen deferred)

### Capabilities Involved

#### New Capabilities
1. **multiplayer-match-system** (NEW)
   - Store match state in UserDatabase (match_id, players, config, current_turn, rounds_data)
   - Track whose turn it is and which rounds have been completed by each player
   - Determine category selection rights (inviter: odd rounds, invitee: even rounds)
   - Automatically update turn after player answers all questions in a round
   - Persist match state across sessions until all rounds complete
   - Support multiple simultaneous matches per player

2. **friendly-battle-page** (NEW spec, existing empty scene)
   - Display avatar_component for each active multiplayer match
   - Show opponent's profile picture in avatar
   - Display turn status label ("Your Turn" vs "[Player] Turn")
   - Load and instantiate avatar_components from UserDatabase on page load
   - Pass match_id when avatar clicked to navigate to gameplay_screen
   - Update turn status labels when matches update

#### Modified Capabilities
3. **account-management-screen** (MODIFY account_popup logic)
   - Navigate from account_popup to setup_screen when "Invite to Game" clicked
   - Close account_popup before opening setup_screen

4. **setup-screen-logic** (MODIFY)
   - Store pending invite context (invited_player_username) when opened from account_popup
   - Send notification with rounds/questions data when "Start Game" pressed
   - Navigate to main_lobby_screen after sending invite (remove direct gameplay transition)
   - Clear pending invite context after notification sent

5. **local-user-database** (MODIFY)
   - Add `multiplayer_matches` array to database schema
   - Provide CRUD operations for matches (create, get, update, delete)
   - Store game invite notifications with rounds/questions in action_data
   - Create match when game invite accepted via signal handler
   - Update match state when players complete rounds
   - Clean up completed matches

6. **gameplay-screen-initialization** (MODIFY)
   - Accept match_id parameter in initialize() method
   - Load match state from UserDatabase if match_id provided
   - Determine whose turn it is and enable/disable play button accordingly
   - Show opponent's avatar and name on left side, current player on right
   - Track current player's round completion separately from opponent
   - Automatically reveal opponent answers after both players complete round
   - Navigate to main_lobby_screen after last question answered (instead of staying in gameplay)

7. **avatar-component** (MODIFY)
   - Add method to store match_id: `set_match_id(id: String)`
   - Emit match_id when avatar clicked for navigation context
   - Support dynamic label updates for turn status

## Goals
- Enable asynchronous turn-based multiplayer quiz duels between friends
- Support multiple simultaneous matches with different opponents
- Provide clear visual feedback on whose turn it is
- Persist match state across sessions using local UserDatabase
- Maintain separation between single-player and multiplayer modes
- Lay foundation for future Firebase synchronization (local mock first)

## Non-Goals
- Firebase/online synchronization (explicitly deferred, local UserDatabase only)
- Real-time multiplayer (async turn-based only)
- Push notifications when turn changes (players discover on app open)
- Final result screen UI (return to lobby, proper UI later)
- Mid-game quitting or match deletion (matches persist until complete)
- Rematch functionality (one match per invite)
- Score/statistics tracking display (visual UI deferred)
- Performance optimizations for large match lists

## User Impact
Players will be able to:
- Invite friends to quiz duels with custom rounds/questions configuration
- See all active matches on friendly_battle_page with turn indicators
- Play asynchronous turn-based matches that persist across sessions
- Alternate category selection fairly (inviter chooses odd rounds, invitee even)
- View opponent answers automatically after completing rounds
- Manage multiple simultaneous matches with different friends

## Dependencies
- Existing: UserDatabase autoload (JSON file storage)
- Existing: GlobalSignalBus.game_invite_accepted signal
- Existing: Notification system for invites
- Existing: TransitionManager for scene navigation
- Existing: gameplay_screen, setup_screen, friendly_battle_page scenes
- Existing: avatar_component
- New: Multiplayer match data structure in UserDatabase

## Risks & Mitigations
- **Risk**: JSON file corruption with concurrent match updates
  - **Mitigation**: Single-player local testing only; proper locking with Firebase later
  
- **Risk**: Complex turn logic may have edge cases
  - **Mitigation**: Clear state machine with explicit turn tracking; thorough scenario testing
  
- **Risk**: Match state synchronization when switching between screens
  - **Mitigation**: Always load from UserDatabase on screen open; single source of truth
  
- **Risk**: Large number of active matches may cause performance issues
  - **Mitigation**: Deferred optimization; display limit can be added later
  
- **Risk**: Players may not understand when it's their turn
  - **Mitigation**: Clear "Your Turn" vs "[Player] Turn" labels on avatars

## Alternatives Considered
1. **Firebase-first implementation**: Rejected due to requirement to prove gameplay loop first with local storage
2. **Real-time synchronous multiplayer**: Rejected in favor of async turn-based per requirements
3. **Single match only**: Rejected to avoid limiting user experience
4. **Separate multiplayer database file**: Rejected in favor of extending existing UserDatabase
5. **Show opponent answers immediately**: Rejected to maintain suspense until round complete

## Open Questions
None - all clarifications obtained through discussion.

## Success Criteria
- [ ] Players can send game invites with configured rounds/questions
- [ ] Invitees receive notifications with full match configuration
- [ ] Both players see avatar_components for active matches on friendly_battle_page
- [ ] Turn status labels accurately reflect whose turn it is
- [ ] Play button enables/disables based on turn state
- [ ] Category selection alternates correctly (inviter: odd, invitee: even)
- [ ] Opponent answers remain hidden until both players complete round
- [ ] Answers reveal automatically after round completion
- [ ] Match persists across app restarts
- [ ] Multiple simultaneous matches work without conflicts
- [ ] Last question returns players to main_lobby_screen
- [ ] All existing single-player functionality remains unchanged
