# avatar-component Specification Delta

## MODIFIED Requirements

### Requirement: Store Match ID for Multiplayer Navigation
The avatar_component SHALL provide a method to store a match_id and emit it when clicked.

**Rationale:** Enable navigation to specific multiplayer matches from friendly_battle_page.

#### Scenario: Set and emit match_id
**Given** an avatar_component instance  
**When** `set_match_id("match_123")` is called  
**Then** the match_id is stored internally  
**And** when the avatar is clicked, `avatar_clicked("match_123")` is emitted

#### Scenario: Prioritize user_id over match_id
**Given** an avatar_component has both user_id and match_id set  
**When** the avatar is clicked  
**Then** user_id is emitted (existing friend profile behavior)  
**And** match_id is only emitted if user_id is empty

---
