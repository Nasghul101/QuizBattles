# drag-handle-component Specification

## Purpose
TBD - created by archiving change 2026-01-28-extract-drag-handle-component. Update Purpose after archive.
## Requirements
### Requirement: The component SHALL detect and track drag interactions
The DragHandle component SHALL detect mouse press, motion, and release events to track drag gestures.

#### Scenario: Start drag on mouse press
**Given** a DragHandle component is attached to a popup panel  
**When** the user presses the left mouse button on the drag handle area  
**Then** the component enters dragging state and records the initial mouse position

#### Scenario: Track drag motion
**Given** a DragHandle component in dragging state  
**When** the user moves the mouse while holding the button  
**Then** the component calculates drag delta and total distance traveled

#### Scenario: End drag on mouse release
**Given** a DragHandle component tracking an active drag  
**When** the user releases the left mouse button  
**Then** the component exits dragging state and evaluates dismissal threshold

---

### Requirement: The component SHALL emit signals for drag lifecycle events
The DragHandle component SHALL emit three signals to notify parent nodes of drag state changes and progress.

#### Scenario: Emit drag_started signal
**Given** a DragHandle component  
**When** the user begins dragging  
**Then** the component emits `drag_started(start_position: Vector2)` with the initial mouse position

#### Scenario: Emit drag_updated signal during motion
**Given** a DragHandle component tracking an active drag  
**When** the user moves the mouse  
**Then** the component emits `drag_updated(delta: Vector2, total_distance: float, progress: float)` with current drag delta, accumulated distance, and progress ratio (0.0-1.0)

#### Scenario: Emit drag_ended signal on release
**Given** a DragHandle component finishing a drag gesture  
**When** the user releases the mouse button  
**Then** the component emits `drag_ended(final_distance: float, should_dismiss: bool)` with total distance and whether dismissal threshold was exceeded

---

### Requirement: The component SHALL support configurable drag directions
The DragHandle component SHALL allow single-axis dragging in four cardinal directions, configurable via exported enum.

#### Scenario: Export drag direction enum
**Given** a DragHandle component in the Godot editor  
**When** viewing the component's inspector properties  
**Then** `drag_direction` property is visible as an enum with options: UP, DOWN, LEFT, RIGHT

#### Scenario: Restrict drag to vertical axis (DOWN)
**Given** a DragHandle with `drag_direction = DOWN`  
**When** the user drags diagonally  
**Then** only the downward (positive Y) component of motion is tracked and reported in signals

#### Scenario: Restrict drag to vertical axis (UP)
**Given** a DragHandle with `drag_direction = UP`  
**When** the user drags diagonally  
**Then** only the upward (negative Y) component of motion is tracked and reported in signals

#### Scenario: Restrict drag to horizontal axis (LEFT)
**Given** a DragHandle with `drag_direction = LEFT`  
**When** the user drags diagonally  
**Then** only the leftward (negative X) component of motion is tracked and reported in signals

#### Scenario: Restrict drag to horizontal axis (RIGHT)
**Given** a DragHandle with `drag_direction = RIGHT`  
**When** the user drags diagonally  
**Then** only the rightward (positive X) component of motion is tracked and reported in signals

---

### Requirement: The component SHALL support configurable dismissal threshold
The DragHandle component SHALL expose a drag distance threshold that determines when dismissal is triggered.

#### Scenario: Export drag threshold property
**Given** a DragHandle component in the Godot editor  
**When** viewing the component's inspector properties  
**Then** `drag_threshold` property is visible and editable with default value 100.0

#### Scenario: Trigger dismissal when threshold exceeded
**Given** a DragHandle with `drag_threshold = 100.0`  
**When** the user drags 101 pixels in the configured direction and releases  
**Then** `drag_ended` signal is emitted with `should_dismiss = true`

#### Scenario: Prevent dismissal when threshold not met
**Given** a DragHandle with `drag_threshold = 100.0`  
**When** the user drags 99 pixels in the configured direction and releases  
**Then** `drag_ended` signal is emitted with `should_dismiss = false`

---

### Requirement: The component SHALL provide snap-back animation for incomplete drags
The DragHandle component SHALL internally animate a visual snap-back when drag threshold is not met, without requiring parent intervention.

#### Scenario: Trigger snap-back animation on insufficient drag
**Given** a DragHandle component where drag distance < threshold  
**When** `drag_ended` is emitted with `should_dismiss = false`  
**Then** the component triggers an internal snap-back animation

#### Scenario: Configurable snap-back duration
**Given** a DragHandle component in the Godot editor  
**When** viewing the component's inspector properties  
**Then** `snap_back_duration` property is visible and editable with default value 0.2

#### Scenario: Snap-back animation uses easing
**Given** a snap-back animation is triggered  
**When** the animation plays  
**Then** it uses EASE_OUT and TRANS_CUBIC for smooth deceleration

---

### Requirement: The component SHALL calculate normalized drag progress
The DragHandle component SHALL calculate and report drag progress as a ratio (0.0 to 1.0) based on distance relative to threshold.

#### Scenario: Report progress during drag
**Given** a DragHandle with `drag_threshold = 100.0`  
**When** the user drags 50 pixels in the configured direction  
**Then** `drag_updated` signal includes `progress = 0.5`

#### Scenario: Clamp progress to maximum 1.0
**Given** a DragHandle with `drag_threshold = 100.0`  
**When** the user drags 200 pixels in the configured direction  
**Then** `drag_updated` signal includes `progress = 1.0` (clamped, not 2.0)

---

### Requirement: The component SHALL ignore motion perpendicular to drag direction
The DragHandle component SHALL only track motion along the configured axis and ignore perpendicular movement.

#### Scenario: Ignore horizontal motion when dragging vertically
**Given** a DragHandle with `drag_direction = DOWN`  
**When** the user moves the mouse 50 pixels right and 30 pixels down  
**Then** `drag_updated` reports `total_distance = 30.0` (only Y-axis distance)

#### Scenario: Ignore vertical motion when dragging horizontally
**Given** a DragHandle with `drag_direction = RIGHT`  
**When** the user moves the mouse 40 pixels down and 60 pixels right  
**Then** `drag_updated` reports `total_distance = 60.0` (only X-axis distance)

---

### Requirement: The component SHALL follow GDScript style and documentation conventions
The DragHandle component SHALL adhere to project coding standards and documentation guidelines.

#### Scenario: Class documentation comment
**Given** the `drag_handle_component.gd` script  
**When** reviewing the code  
**Then** the class has a `##` doc comment describing its purpose

#### Scenario: Signal documentation
**Given** the `drag_handle_component.gd` script  
**When** reviewing signal definitions  
**Then** each signal has a `##` doc comment explaining when it's emitted and parameter meanings

#### Scenario: Public method documentation
**Given** public methods in `drag_handle_component.gd`  
**When** reviewing the code  
**Then** each public method has a `##` doc comment with description and parameter documentation

#### Scenario: Static typing
**Given** the `drag_handle_component.gd` script  
**When** reviewing variables and parameters  
**Then** all variables, function parameters, and return types use static typing

---

### Requirement: The component SHALL remain visually transparent
The DragHandle component SHALL maintain its transparent appearance to overlay the popup content without visual interference.

#### Scenario: Preserve transparency settings
**Given** the DragHandle scene file  
**When** the component is instantiated  
**Then** `modulate` and `self_modulate` remain set to Color(1, 1, 1, 0)

#### Scenario: Maintain custom minimum size
**Given** the DragHandle scene file  
**When** the component is instantiated  
**Then** `custom_minimum_size` remains set to Vector2(0, 60) for touch target area

