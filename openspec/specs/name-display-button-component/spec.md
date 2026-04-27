# name-display-button-component Specification

## Purpose
TBD - created by archiving change implement-socials-page-interactions. Update Purpose after archive.
## Requirements
### Requirement: Display Username Text
The component SHALL display a username as text on a button with appropriate styling from BasicTheme.

**Rationale:** Provide clear, readable user identification in search results.

#### Scenario: Set username text
**Given** a name_display_button instance is created  
**When** the button's text property is set to "alice"  
**Then** the button SHALL display "alice" as its text  
**And** the text SHALL use BasicTheme font size 40

---

### Requirement: Toggle Highlight State on Click
The component SHALL toggle its highlight state between highlighted and normal when clicked, providing visual feedback for selection.

**Rationale:** Allow users to select and deselect search results with clear visual indication.

#### Scenario: Highlight button on first click
**Given** a name_display_button is in normal (unhighlighted) state  
**When** the player clicks the button  
**Then** the button SHALL change to highlighted state  
**And** `is_highlighted` property SHALL be set to true  
**And** visual appearance SHALL change to indicate selection (e.g., color modulation, border)

#### Scenario: Unhighlight button on second click
**Given** a name_display_button is in highlighted state  
**When** the player clicks the button again  
**Then** the button SHALL change to normal state  
**And** `is_highlighted` property SHALL be set to false  
**And** visual appearance SHALL return to normal

---

### Requirement: Emit Selection Changed Signal
The component SHALL emit a `selection_changed` signal whenever its highlight state changes, passing the username and new highlight state as parameters.

**Rationale:** Allow parent components to manage selection state and update UI accordingly.

**Signal Signature:** `selection_changed(username: String, is_highlighted: bool)`

#### Scenario: Emit signal on highlight
**Given** a name_display_button for user "alice" is clicked  
**And** the button changes from normal to highlighted state  
**When** the highlight state is updated  
**Then** the signal `selection_changed("alice", true)` SHALL be emitted  
**And** connected handlers SHALL receive both parameters

#### Scenario: Emit signal on unhighlight
**Given** a name_display_button for user "bob" is clicked  
**And** the button changes from highlighted to normal state  
**When** the highlight state is updated  
**Then** the signal `selection_changed("bob", false)` SHALL be emitted

---

### Requirement: Store Username Property
The component SHALL store the associated username as a property that can be set by the parent component when instantiating the button.

**Rationale:** Link button visual state to specific user identity for signal emission and parent tracking.

#### Scenario: Set username property
**Given** a name_display_button instance is created  
**When** the `username` property is set to "charlie"  
**Then** the username SHALL be stored in the component  
**And** it SHALL be included in selection_changed signal emissions

---

### Requirement: Programmatic Highlight Control
The component SHALL provide a `set_highlighted(value: bool)` method that allows parent components to programmatically change the highlight state without user interaction.

**Rationale:** Enable parent to implement radio-button behavior by unhighlighting previously selected buttons.

#### Scenario: Programmatically highlight button
**Given** a name_display_button is in normal state  
**When** `set_highlighted(true)` is called by parent  
**Then** the button SHALL change to highlighted state  
**And** visual appearance SHALL update to highlighted style  
**And** `is_highlighted` property SHALL be true  
**And** selection_changed signal SHALL be emitted

#### Scenario: Programmatically unhighlight button
**Given** a name_display_button is in highlighted state  
**When** `set_highlighted(false)` is called by parent  
**Then** the button SHALL change to normal state  
**And** visual appearance SHALL return to normal style  
**And** `is_highlighted` property SHALL be false  
**And** selection_changed signal SHALL be emitted

---

### Requirement: Visual Highlight Indication
The component SHALL provide clear visual feedback when highlighted, using color modulation or other visual effects to distinguish selected from non-selected state.

**Rationale:** Ensure players can easily identify which user is currently selected.

**Design Note:** Visual style should be consistent with overall theme but clearly distinguishable. Suggested implementation: slight color tint (e.g., yellow modulation) or border overlay.

#### Scenario: Highlighted appearance differs from normal
**Given** two name_display_button instances exist  
**And** one is highlighted and one is normal  
**When** displayed side-by-side  
**Then** the highlighted button SHALL have visually distinct appearance  
**And** the difference SHALL be obvious to the player  
**And** the change SHALL be smooth (no jarring transitions)

---

### Requirement: Minimum Height for Touch Targets
The component SHALL maintain a minimum height of 120 pixels to ensure adequate touch target size for mobile interaction.

**Rationale:** Follow mobile UX best practices for touchable UI elements.

#### Scenario: Button meets minimum size requirement
**Given** a name_display_button is instantiated  
**When** measured in the scene tree  
**Then** the button's minimum height SHALL be at least 120 pixels  
**And** the button SHALL be easily tappable on mobile devices

---

