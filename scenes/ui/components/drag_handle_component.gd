extends Panel
## Reusable drag handle component for popup panels with drag-to-dismiss behavior.
##
## Provides configurable single-axis dragging that emits signals for parent popups
## to handle positioning and overlay effects. Supports UP, DOWN, LEFT, RIGHT drag
## directions with customizable threshold and snap-back animation.

## Emitted when drag interaction begins
## @param start_position: Initial mouse position when drag started
signal drag_started(start_position: Vector2)

## Emitted during active drag motion
## @param delta: Current drag delta from start position
## @param total_distance: Accumulated distance traveled in drag direction
## @param progress: Normalized progress ratio (0.0-1.0) relative to threshold
signal drag_updated(delta: Vector2, total_distance: float, progress: float)

## Emitted when drag interaction ends
## @param final_distance: Total distance dragged in configured direction
## @param should_dismiss: Whether drag exceeded threshold to trigger dismissal
signal drag_ended(final_distance: float, should_dismiss: bool)

## Drag direction constraint for single-axis dragging
enum DragDirection {
    UP,    ## Allow dragging upward (negative Y)
    DOWN,  ## Allow dragging downward (positive Y)
    LEFT,  ## Allow dragging leftward (negative X)
    RIGHT  ## Allow dragging rightward (positive X)
}

## The drag direction for this handle
@export var drag_direction: DragDirection = DragDirection.DOWN

## Distance threshold in pixels to trigger dismissal
@export var drag_threshold: float = 100.0

## Duration in seconds for snap-back animation when threshold not met
@export var snap_back_duration: float = 0.2

## Current drag state
var is_dragging: bool = false

## Initial mouse position when drag started
var drag_start_pos: Vector2 = Vector2.ZERO


## Handle mouse and touch input for drag detection
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _start_drag(event.global_position)
            else:
                _end_drag(event.global_position)
    
    elif event is InputEventMouseMotion and is_dragging:
        _update_drag(event.global_position)


## Start drag interaction
func _start_drag(position: Vector2) -> void:
    is_dragging = true
    drag_start_pos = position
    drag_started.emit(position)


## Update drag state and emit progress
func _update_drag(position: Vector2) -> void:
    var delta: Vector2 = position - drag_start_pos
    var distance: float = _calculate_directional_distance(delta)
    var progress: float = clamp(distance / drag_threshold, 0.0, 1.0)
    
    drag_updated.emit(delta, distance, progress)


## End drag interaction and determine dismissal
func _end_drag(position: Vector2) -> void:
    if not is_dragging:
        return
    
    is_dragging = false
    
    var delta: Vector2 = position - drag_start_pos
    var final_distance: float = _calculate_directional_distance(delta)
    var should_dismiss: bool = final_distance >= drag_threshold
    
    drag_ended.emit(final_distance, should_dismiss)


## Calculate distance traveled along configured drag direction
func _calculate_directional_distance(delta: Vector2) -> float:
    match drag_direction:
        DragDirection.DOWN:
            return max(0.0, delta.y)
        DragDirection.UP:
            return max(0.0, -delta.y)
        DragDirection.RIGHT:
            return max(0.0, delta.x)
        DragDirection.LEFT:
            return max(0.0, -delta.x)
        _:
            return 0.0
