# socials-page-popup-animation Specification Delta

## ADDED Requirements

### Requirement: Popup Drag-to-Dismiss via DragHandle Component
The system SHALL use the DragHandle component to enable drag-to-dismiss functionality for the AddFriendsPopup.

#### Scenario: DragHandle component attached to AddFriendsPopup
**Given** the AddFriendsPopup in `socials_page.tscn`  
**When** the scene is loaded  
**Then** the DragHandle node has `drag_handle_component.gd` script attached with `drag_direction = DOWN` and `drag_threshold = 100.0`

#### Scenario: SocialsPage connects to DragHandle signals
**Given** the SocialsPage script initializes  
**When** `_ready()` is called  
**Then** the script connects to DragHandle's `drag_started`, `drag_updated`, and `drag_ended` signals

#### Scenario: Update popup position during drag
**Given** the AddFriendsPopup is open and user is dragging  
**When** DragHandle emits `drag_updated(delta, distance, progress)`  
**Then** SocialsPage updates popup `position.y` based on drag delta (only allowing downward movement)

#### Scenario: Update overlay opacity during drag
**Given** the AddFriendsPopup is open and user is dragging  
**When** DragHandle emits `drag_updated(delta, distance, progress)`  
**Then** SocialsPage updates PopupOverlay color opacity by lerping from 0.4 to 0.0 based on `progress`

#### Scenario: Dismiss popup when drag threshold exceeded
**Given** the AddFriendsPopup is open  
**When** DragHandle emits `drag_ended(final_distance, should_dismiss = true)`  
**Then** SocialsPage calls `close_popup()` to animate the popup closed

#### Scenario: Snap back popup when drag threshold not met
**Given** the AddFriendsPopup is open  
**When** DragHandle emits `drag_ended(final_distance, should_dismiss = false)`  
**Then** SocialsPage animates popup back to `position.y = 0.0` using Tween with EASE_OUT and TRANS_CUBIC over 0.2 seconds

#### Scenario: Block drag during popup animations
**Given** the popup is currently animating open or closed  
**When** the user attempts to interact with the DragHandle  
**Then** the SocialsPage does not respond to drag signals until `animation_in_progress = false`

#### Scenario: Block drag when popup is closed
**Given** the AddFriendsPopup is currently closed  
**When** the user attempts to interact with the DragHandle  
**Then** the SocialsPage does not respond to drag signals

