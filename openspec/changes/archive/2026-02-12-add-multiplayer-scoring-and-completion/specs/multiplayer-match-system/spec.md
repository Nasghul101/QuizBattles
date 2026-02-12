# multiplayer-match-system Spec Delta

## ADDED Requirements

### Requirement: Support "finished" match status
The multiplayer match system SHALL recognize and persist a "finished" status for matches where all rounds are complete but not yet dismissed by players.

**Rationale:** Distinguish completed matches from active ones and enable display of finished matches on friendly_battles_page.

#### Scenario: Match with finished status persists in database
**Given** a match has status="finished"  
**When** the database is saved and reloaded  
**Then** the match remains in the multiplayer_matches array  
**And** status field still equals "finished"

#### Scenario: Status transitions from active to finished
**Given** a match with status="active"  
**When** both players complete the final round  
**And** gameplay_screen calls update_match() with status="finished"  
**Then** the match status is updated in the database  
**And** the match is NOT deleted

---

### Requirement: Provide method to retrieve all matches regardless of status
UserDatabase SHALL provide a get_all_matches_for_player() method that returns active AND finished matches.

**Rationale:** Enable friendly_battle_page to display finished matches until players dismiss them.

#### Scenario: Retrieve both active and finished matches
**Given** Player A has 2 active matches and 1 finished match  
**When** get_all_matches_for_player("PlayerA") is called  
**Then** an array with 3 matches is returned  
**And** the array includes matches with status="active"  
**And** the array includes matches with status="finished"

#### Scenario: Filter by player but not by status
**Given** Player A has 1 finished match and Player B has 1 finished match  
**When** get_all_matches_for_player("PlayerA") is called  
**Then** only Player A's match is returned  
**And** Player B's match is excluded  
**And** status field is not used as filter criteria

#### Scenario: Return empty array when player has no matches
**Given** Player C has no matches in the database  
**When** get_all_matches_for_player("PlayerC") is called  
**Then** an empty array is returned

---

### Requirement: Preserve get_active_matches_for_player() behavior
UserDatabase SHALL maintain the existing get_active_matches_for_player() method with unchanged behavior.

**Rationale:** Avoid breaking other systems that may rely on active-only filtering.

#### Scenario: get_active_matches_for_player excludes finished matches
**Given** Player A has 2 active matches and 1 finished match  
**When** get_active_matches_for_player("PlayerA") is called  
**Then** an array with 2 matches is returned  
**And** the array includes only matches with status="active"  
**And** matches with status="finished" are excluded

---

## MODIFIED Requirements

### Requirement: UserDatabase SHALL NOT auto-delete completed matches

The UserDatabase SHALL keep matches with status="finished" in the database until explicitly deleted via delete_match().

**Rationale:** Allow players to review final scores and dismiss matches on their own timeline.

#### Scenario: Finished matches persist across sessions
**Given** a match has status="finished"  
**When** the game is closed and reopened  
**Then** the match still exists in multiplayer_matches array  
**And** UserDatabase did not auto-delete it

#### Scenario: Require explicit deletion call
**Given** a match with status="finished" exists  
**When** delete_match() is called with the match_id  
**Then** the match is removed from the database  
**And** this is the ONLY way to remove finished matches

---

## Relationships
- **Used by:** gameplay-screen-initialization (sets and checks status="finished")
- **Used by:** friendly-battle-page (displays finished matches)
