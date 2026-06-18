# navigation-bar-component Specification

## Purpose
Defines the NavigationBar scene (`res://scenes/ui/navigation_bar.tscn`) — a reusable bottom navigation component with four styled `NavigationButton` instances that emit signals and expose an API for active-state management.

## Requirements

### Requirement: Navigation Button Press Emits Page Signal
The `NavigationBar` scene SHALL emit a `page_changed(index: int)` signal when any navigation button is pressed.

**Rationale:** Decouples the navigation bar from any specific screen — the host scene connects to the signal and acts on it independently.

#### Scenario: Challenge button pressed
**GIVEN** the NavigationBar is displayed  
**WHEN** the user presses the Challenge button  
**THEN** the NavigationBar SHALL emit `page_changed` with `index = 0`

#### Scenario: Shop button pressed
**GIVEN** the NavigationBar is displayed  
**WHEN** the user presses the Shop button  
**THEN** the NavigationBar SHALL emit `page_changed` with `index = 1`

#### Scenario: VS button pressed
**GIVEN** the NavigationBar is displayed  
**WHEN** the user presses the VS button  
**THEN** the NavigationBar SHALL emit `page_changed` with `index = 2`

#### Scenario: Social button pressed
**GIVEN** the NavigationBar is displayed  
**WHEN** the user presses the Social button  
**THEN** the NavigationBar SHALL emit `page_changed` with `index = 3`

---

### Requirement: Active Button Focus Indicator
The `NavigationBar` SHALL expose a `set_active_button(index: int)` method that visually marks one button as the active/focused button using Godot's `grab_focus()` mechanism.

**Rationale:** The `NavigationButton` component already defines a focus StyleBox (purple glow). `grab_focus()` activates it without requiring additional state management.

#### Scenario: Set active button by index
**GIVEN** the NavigationBar is displayed  
**WHEN** `set_active_button(2)` is called  
**THEN** the VS button SHALL have focus (purple glow visible)  
**AND** all other buttons SHALL NOT have focus

#### Scenario: Initialize active button on screen load
**GIVEN** the host screen calls `set_active_button(0)` during `_ready()`  
**WHEN** the scene is fully laid out  
**THEN** the Challenge button SHALL have focus  
**AND** all other buttons SHALL have no focus

---

### Requirement: Page-to-Button Mapping
The NavigationBar SHALL map page indices to buttons in a fixed order: Challenge (0), Shop (1), VS (2), Social (3).

**Rationale:** Fixed order ensures predictable swipe and button-press navigation regardless of which screen hosts the component.

#### Scenario: Button order matches page order
**GIVEN** the NavigationBar scene  
**WHEN** inspected in the scene tree  
**THEN** the HBoxContainer children order SHALL be: ChallengeButton, ShopButton, VSButton, SocialButton  
**AND** their indices (0–3) SHALL correspond to lobby page indices 0–3 respectively
