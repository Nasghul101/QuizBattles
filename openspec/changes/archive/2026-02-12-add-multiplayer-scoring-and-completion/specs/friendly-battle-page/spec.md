# friendly-battle-page Spec Delta

## MODIFIED Requirements

### Requirement: Friendly battle page SHALL display all matches including finished ones

The friendly battle page SHALL show both active and finished matches instead of only active matches.

**Rationale:** Allow players to see completed matches with "Game Finished" status until they explicitly dismiss them from gameplay_screen.

#### Scenario: Load both active and finished matches
**Given** Player A has 2 active matches and 1 finished match  
**When** friendly_battle_page becomes visible  
**Then** 3 avatar_components are displayed  
**And** all matches appear regardless of status

#### Scenario: Call get_all_matches_for_player instead of get_active_matches_for_player
**Given** friendly_battle_page is populating matches  
**When** _populate_active_matches() executes  
**Then** UserDatabase.get_all_matches_for_player() is called  
**And** NOT get_active_matches_for_player()  
**And** the returned array includes matches with status="finished"

---

### Requirement: Friendly battle page SHALL display "Game Finished" label for completed matches

The friendly battle page SHALL show "Game Finished" text for matches with status="finished" instead of turn status.

**Rationale:** Distinguish completed matches from active ones and indicate they require dismissal.

#### Scenario: Show "Game Finished" for finished match
**Given** a match with status="finished" exists  
**When** the avatar_component is created for this match  
**Then** the avatar name label displays "Game Finished"  
**And** no turn information is shown

#### Scenario: Prioritize finished status over turn status
**Given** a match with status="finished" and current_turn="Alice"  
**When** avatar label logic executes  
**Then** label displays "Game Finished"  
**And** NOT "Your Turn" or "Alice Turn"

#### Scenario: Keep turn status for active matches
**Given** a match with status="active" and current_turn="Alice"  
**When** avatar label logic executes  
**Then** label displays "Your Turn" or "Bob Turn" (existing behavior)  
**And** status="active" does not change display logic

---

### Requirement: Friendly battle page SHALL navigate to gameplay_screen for finished matches

The friendly battle page SHALL allow clicking finished match avatars to open gameplay_screen showing final state and FinishGamePopup.

**Rationale:** Enable players to review final scores and dismiss matches from within gameplay_screen.

#### Scenario: Open finished match in gameplay_screen
**Given** an avatar representing a finished match is clicked  
**When** _on_avatar_clicked() executes  
**Then** TransitionManager.change_scene() is called with gameplay_screen path  
**And** match_id parameter is passed  
**And** same navigation logic as active matches

#### Scenario: Display FinishGamePopup when finished match loads
**Given** gameplay_screen is initialized with a match_id for a finished match  
**When** _load_existing_match_state() completes  
**And** match status is "finished"  
**Then** FinishGamePopup is shown with winner/draw announcement  
**And** all round results are visible

---

## Relationships
- **Depends on:** multiplayer-match-system (uses match status field)
- **Related to:** gameplay-screen-initialization (finished matches lead to gameplay_screen with popup)
