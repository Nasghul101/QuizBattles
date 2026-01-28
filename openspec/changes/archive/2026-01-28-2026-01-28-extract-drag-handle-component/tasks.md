# Implementation Tasks

## Task Checklist

### Phase 1: Create DragHandle Component Script
- [x] Create `scenes/ui/components/drag_handle_component.gd` script
- [x] Define signals: `drag_started(start_position: Vector2)`, `drag_updated(delta: Vector2, total_distance: float, progress: float)`, `drag_ended(final_distance: float, should_dismiss: bool)`
- [x] Add exported enum `DragDirection` with values: UP, DOWN, LEFT, RIGHT
- [x] Add exported variable `drag_threshold: float = 100.0` for dismissal threshold
- [x] Add exported variable `snap_back_duration: float = 0.2` for animation timing
- [x] Add exported variable `drag_direction: DragDirection = DragDirection.DOWN`
- [x] Implement `_gui_input()` to handle mouse button and motion events
- [x] Track drag state: `is_dragging: bool`, `drag_start_pos: Vector2`
- [x] Calculate drag deltas based on selected direction (ignore perpendicular axis)
- [x] Emit `drag_started` on mouse press
- [x] Emit `drag_updated` on mouse motion with delta, distance, and progress (0.0-1.0)
- [x] Emit `drag_ended` on mouse release with final distance and dismissal decision
- [x] Implement snap-back animation using Tween when threshold not met
- [x] Add GDScript documentation comments (`##`) for class and public methods

### Phase 2: Update SocialsPage to Use DragHandle Component
- [x] Attach `drag_handle_component.gd` script to DragHandle node in `socials_page.tscn`
- [x] Remove drag-related variables from `socials_page.gd`: `is_dragging`, `drag_start_position`, `popup_start_y`
- [x] Remove `_ready()` connection to `drag_handle.gui_input`
- [x] Remove `_on_popup_gui_input()` method entirely
- [x] Add `_ready()` connection to DragHandle signals: `drag_started`, `drag_updated`, `drag_ended`
- [x] Implement `_on_drag_started()` handler to store initial popup position
- [x] Implement `_on_drag_updated()` handler to update popup position and overlay opacity based on progress
- [x] Implement `_on_drag_ended()` handler to call `close_popup()` if `should_dismiss` is true, otherwise animate snap-back
- [x] Ensure drag only works when `is_popup_open` and not `animation_in_progress`
- [x] Test drag-to-dismiss behavior matches previous implementation

### Phase 3: Validation
- [x] Manually test opening AddFriendsPopup
- [x] Manually test dragging down < 100px triggers snap-back
- [x] Manually test dragging down > 100px dismisses popup
- [x] Manually test overlay opacity updates smoothly during drag
- [x] Manually test drag is blocked during popup animations
- [x] Manually test drag is blocked when popup is closed
- [x] Verify no console errors or warnings
- [x] Confirm DragHandle component can be reused in other popups (code review)

## Validation Criteria
- ✅ DragHandle component script exists with all exported properties
- ✅ DragHandle emits three signals with correct parameters
- ✅ SocialsPage no longer contains drag input handling logic
- ✅ Popup drag behavior identical to pre-refactor implementation
- ✅ Snap-back animation timing matches original (~0.2s)
- ✅ Code follows GDScript style guide and documentation conventions
- ✅ Component is decoupled and reusable for other popups
