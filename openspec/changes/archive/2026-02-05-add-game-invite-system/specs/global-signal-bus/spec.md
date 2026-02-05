## ADDED Requirements

### Requirement: Game Invite Accepted Signal
GlobalSignalBus SHALL expose a `game_invite_accepted` signal that is emitted when a player accepts a game invitation.

#### Scenario: Player accepts game invite
**Given** Player A sends a game invite to Player B  
**And** Player B receives the invite notification  
**When** Player B clicks the Accept button on the invite notification  
**Then** `GlobalSignalBus.game_invite_accepted.emit(inviter_username, invitee_username)` is called  
**And** the signal includes Player A's username as inviter_username  
**And** the signal includes Player B's username as invitee_username  
**And** future multiplayer systems can connect to this signal to initiate game sessions

#### Scenario: Multiple systems can listen to game invite acceptances
**Given** a multiplayer matchmaking system exists in the future  
**When** the system connects to `GlobalSignalBus.game_invite_accepted`  
**Then** it receives all game invite acceptance events  
**And** can use the inviter and invitee usernames to start a game session  
**And** multiple listeners can connect without interfering with each other

---

## MODIFIED Requirements

None - this change only adds a new signal without modifying existing functionality.
