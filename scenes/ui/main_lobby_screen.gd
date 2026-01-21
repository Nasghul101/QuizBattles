extends Control
## Main Lobby Screen
##
## Entry point screen that provides access to game features and account management.
## Conditionally navigates to account screens based on user login state.
## Supports multi-page navigation with swipe gestures and bottom navigation buttons.

## Reference to the container holding page content
@onready var page_clip_container: Control = $VBoxContainer/PageClipContainer
@onready var pages_container: HBoxContainer = $VBoxContainer/PageClipContainer/PagesContainer

## Swipe detection state
var swipe_start_pos := Vector2.ZERO
var is_swiping := false
var swipe_threshold := 100.0  # Minimum pixels to trigger page change
var drag_start_container_pos := 0.0
var page_width := 0.0

## Current page tracking
var current_page := 0
var is_animating := false


func _ready() -> void:
    # Calculate page width from viewport
    await get_tree().process_frame  # Wait for layout
    page_width = page_clip_container.size.x
    
    # Set each page to take full width
    for page: Node in pages_container.get_children():
        if page is Control:
            (page as Control).custom_minimum_size.x = page_width
    
    # Force layout update
    pages_container.queue_sort()
    await get_tree().process_frame
    
    # Initialize page system - position at first page
    _set_page_position(0, false)
    _update_page_indicator(0)


## Get total number of pages dynamically
func _get_total_pages() -> int:
    return pages_container.get_child_count()


## Handle input events for swipe gestures
func _input(event: InputEvent) -> void:
    if is_animating:
        return
    
    # Handle touch/mouse drag for swiping
    if event is InputEventScreenTouch or event is InputEventMouseButton:
        if event.pressed:
            swipe_start_pos = event.position
            drag_start_container_pos = pages_container.position.x
            is_swiping = true
        else:
            if is_swiping:
                _handle_swipe_end(event.position)
            is_swiping = false
    
    elif event is InputEventScreenDrag or event is InputEventMouseMotion:
        if is_swiping and event.button_mask != 0:
            # Follow finger - move container with drag
            var drag_offset: float = event.position.x - swipe_start_pos.x
            var target_pos: float = drag_start_container_pos + drag_offset
            
            # Clamp to prevent dragging beyond first/last page
            var min_pos: float = -(page_width * (_get_total_pages() - 1))
            var max_pos: float = 0.0
            pages_container.position.x = clampf(target_pos, min_pos, max_pos)


## Process swipe gesture and change page if threshold met
func _handle_swipe_end(end_pos: Vector2) -> void:
    var swipe_vector := end_pos - swipe_start_pos
    var swipe_distance := swipe_vector.x
    
    # Determine target page based on swipe direction and distance
    var target_page := current_page
    
    if abs(swipe_distance) >= swipe_threshold:
        if swipe_distance > 0:  # Swipe right → go to previous page
            target_page = current_page - 1
        else:  # Swipe left → go to next page
            target_page = current_page + 1
    
    # Animate to target page (or snap back to current if threshold not met)
    _navigate_to_page(target_page)


## Navigate to specific page with bounds checking and animation
func _navigate_to_page(page_index: int) -> void:
    # Clamp to valid page range
    page_index = clampi(page_index, 0, _get_total_pages() - 1)
    
    if page_index == current_page and not is_swiping:
        # Already on target page, snap back if mid-drag
        _set_page_position(current_page, true)
        return
    
    current_page = page_index
    _set_page_position(current_page, true)
    _update_page_indicator(current_page)


## Set page position with optional animation
func _set_page_position(page_index: int, animate: bool = false) -> void:
    var target_x: float = -page_width * page_index
    
    if animate:
        is_animating = true
        var tween: Tween = create_tween()
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.set_ease(Tween.EASE_OUT)
        tween.tween_property(pages_container, "position:x", target_x, 0.3)
        tween.finished.connect(func() -> void: is_animating = false)
    else:
        pages_container.position.x = target_x


## Update bottom navigation buttons to reflect current page
func _update_page_indicator(page_index: int) -> void:
    # Get references to bottom navigation buttons
    var bottom_container: HBoxContainer = $VBoxContainer/PanelContainer3/HBoxContainer
    
    # Update button states dynamically - buttons correspond to pages by index
    for i: int in range(bottom_container.get_child_count()):
        var button: Button = bottom_container.get_child(i) as Button
        if button:
            button.disabled = (page_index == i)


## Handle DuelPage button press
func _on_duel_page_pressed() -> void:
    _navigate_to_page(0)


## Handle Page2 button press
func _on_page_2_pressed() -> void:
    _navigate_to_page(1)


## Handle SocialPage button press
func _on_social_page_pressed() -> void:
    _navigate_to_page(2)


## Handle AccountButton press with conditional navigation based on login state
func _on_account_button_pressed() -> void:
    if UserDatabase.is_signed_in():
        # User is logged in - navigate to account management
        _navigate_to_account_management()
    else:
        # User is not logged in - navigate to register/login
        _navigate_to_register_login()

## Navigate to register/login screen
func _navigate_to_register_login() -> void:
    var scene_path := "res://scenes/ui/account_ui/register_login_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: register_login_screen.tscn not found at " + scene_path)


## Navigate to account management screen
func _navigate_to_account_management() -> void:
    var scene_path := "res://scenes/ui/account_ui/account_management_screen.tscn"
    if ResourceLoader.exists(scene_path):
        TransitionManager.change_scene(scene_path)
    else:
        push_error("Failed to navigate: account_management_screen.tscn not found at " + scene_path)
