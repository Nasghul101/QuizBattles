# account-management-screen Specification Delta

## MODIFIED Requirements

### Requirement: Navigate to Setup Screen from Invite Button
When the "Invite to Game" button is pressed on account_popup, the popup SHALL close and navigate to setup_screen with the invited player's username.

**Rationale:** Enable multiplayer invite flow starting from friend profiles.

#### Scenario: Open setup screen with invited player
**Given** account_popup is displaying Player B's profile  
**When** Player A clicks "Invite to Game"  
**Then** the account_popup closes  
**And** setup_screen opens with `{"invited_player": "PlayerB"}` parameter

#### Scenario: Button remains disabled until popup reopens
**Given** Player A clicked "Invite to Game"  
**When** the button is pressed  
**Then** the button becomes disabled  
**And** remains disabled while navigating to setup_screen  
**And** re-enables when popup is reopened later (existing behavior)

---
