extends Control

var is_popup_open: bool = false
var animation_in_progress: bool = false
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var popup_start_y: float = 0.0


func open_popup() -> void:
    if animation_in_progress:
        return
    
    animation_in_progress = true
    is_popup_open = true
    
    # Get references
    var popup: Panel = $AddFriendsPopup
    var overlay: ColorRect = $PopupOverlay
    var viewport_height: float = get_viewport_rect().size.y
    
    # Show overlay and popup
    overlay.visible = true
    popup.visible = true
    
    # Set starting position (off-screen below)
    popup.position.y = viewport_height
    
    # Create tween for animations
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    # Animate popup position
    tween.tween_property(popup, "position:y", 0.0, 0.3)
    
    # Animate overlay opacity
    tween.tween_property(overlay, "color", Color(0, 0, 0, 0.4), 0.3)
    
    # On complete
    tween.finished.connect(func() -> void:
        animation_in_progress = false
    )


func close_popup() -> void:
    if animation_in_progress:
        return
    
    animation_in_progress = true
    is_popup_open = false
    
    # Get references
    var popup: Panel = $AddFriendsPopup
    var overlay: ColorRect = $PopupOverlay
    var viewport_height: float = get_viewport_rect().size.y
    
    # Create tween for animations
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
    
    # Animate popup position
    tween.tween_property(popup, "position:y", viewport_height, 0.3)
    
    # Animate overlay opacity
    tween.tween_property(overlay, "color", Color(0, 0, 0, 0.0), 0.3)
    
    # On complete
    tween.finished.connect(func() -> void:
        animation_in_progress = false
        overlay.visible = false
        popup.visible = false
    )


func toggle_popup() -> void:
    if is_popup_open:
        close_popup()
    else:
        open_popup()


func _ready() -> void:
    var drag_handle: Panel = $AddFriendsPopup/DragHandle
    drag_handle.gui_input.connect(_on_popup_gui_input)


func _on_popup_gui_input(event: InputEvent) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
    var popup: Panel = $AddFriendsPopup
    
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                # Start dragging
                is_dragging = true
                drag_start_position = event.position
                popup_start_y = popup.position.y
            else:
                # End dragging
                if is_dragging:
                    is_dragging = false
                    var drag_distance: float = popup.position.y - popup_start_y
                    
                    # If dragged down more than 100 pixels, close the popup
                    if drag_distance > 100:
                        close_popup()
                    else:
                        # Snap back to original position
                        var tween: Tween = create_tween()
                        tween.set_ease(Tween.EASE_OUT)
                        tween.set_trans(Tween.TRANS_CUBIC)
                        tween.tween_property(popup, "position:y", 0.0, 0.2)
    
    elif event is InputEventMouseMotion and is_dragging:
        # Update popup position while dragging
        var drag_delta: float = event.position.y - drag_start_position.y
        var new_y: float = popup_start_y + drag_delta
        
        # Only allow dragging downward, not upward
        popup.position.y = max(0.0, new_y)
        
        # Update overlay opacity based on drag distance
        var viewport_height: float = get_viewport_rect().size.y
        var drag_progress: float = clamp(popup.position.y / viewport_height, 0.0, 1.0)
        var overlay: ColorRect = $PopupOverlay
        overlay.color = Color(0, 0, 0, lerp(0.4, 0.0, drag_progress))


func _on_add_friend_button_pressed() -> void:
    pass # Replace with function body.


func _on_add_new_friend_button_pressed() -> void:
    toggle_popup()
