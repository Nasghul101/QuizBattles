extends Control

var is_popup_open: bool = false
var animation_in_progress: bool = false
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

func _on_add_friend_button_pressed() -> void:
    pass # Replace with function body.


func _on_add_new_friend_button_pressed() -> void:
    toggle_popup()


func _on_drag_handle_component_drag_started(_start_position: Vector2) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
    var popup: Panel = $AddFriendsPopup
    popup_start_y = popup.position.y


func _on_drag_handle_component_drag_updated(delta: Vector2, _total_distance: float, progress: float) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
    var popup: Panel = $AddFriendsPopup
    var overlay: ColorRect = $PopupOverlay
    
    # Update popup position (only allow downward movement)
    var new_y: float = popup_start_y + delta.y
    popup.position.y = max(0.0, new_y)
    
    # Update overlay opacity based on drag progress
    overlay.color = Color(0, 0, 0, lerp(0.4, 0.0, progress))

func _on_drag_handle_component_drag_ended(_final_distance: float, should_dismiss: bool) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
    if should_dismiss:
        close_popup()
    else:
        # Snap back to original position
        var popup: Panel = $AddFriendsPopup
        var tween: Tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(popup, "position:y", 0.0, 0.2)
