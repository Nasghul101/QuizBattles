extends Control
## Account Management Screen
##
## Displays user account information and settings with navigation back to main lobby.

@onready var avatar_container: GridContainer = %AvatarContainer
@onready var choose_avatar_popup: PanelContainer = %ChooseAvatarPopup
@onready var user_avatar_button: Button = $VBoxContainer/UserAvatar
 
var avatar_component_scene: PackedScene = preload("res://scenes/ui/components/avatar_component.tscn")

## Track popup start position for drag interaction
var popup_start_y: float = 0.0


func _ready() -> void:
    # Display username
    _display_username()
    # Display current user avatar
    _display_current_avatar()
    

## Display the current user's username in NameLabel
func _display_username() -> void:
    var name_label: Label = %NameLabel
    if name_label:
        var current_user: Dictionary = UserDatabase.get_current_user()
        if not current_user.is_empty() and current_user.has("username"):
            name_label.text = current_user["username"]
        # If no user or no username, keep existing label text as fallback


## Display the current user's avatar in UserAvatar button
func _display_current_avatar() -> void:
    var current_user: Dictionary = UserDatabase.get_current_user()
    
    # Get avatar path from user data, default to man_standard.png if missing
    var avatar_path: String = current_user.get("avatar_path", UserDatabase.DEFAULT_AVATAR_PATH)
    
    # Load texture from path
    var texture: Texture2D = load(avatar_path)
    
    # Fallback to default if texture loading fails
    if not texture:
        push_warning("Failed to load avatar texture from path: %s, falling back to default" % avatar_path)
        texture = load(UserDatabase.DEFAULT_AVATAR_PATH)
    
    # Set button icon
    if texture:
        user_avatar_button.icon = texture


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    Utils.navigate_to_scene("main_lobby")


## Handle LogOffButton press - log out user and return to login screen
func _on_log_off_button_pressed() -> void:
    # Get username before logging out for console message
    var current_user: Dictionary = UserDatabase.get_current_user()
    var username: String = current_user.get("username", "Unknown") if not current_user.is_empty() else "Unknown"
    
    # Log out the user
    UserDatabase.sign_out()
    
    # Log confirmation to console
    print("User %s logged out" % username)
    
    # Navigate to register/login screen
    Utils.navigate_to_scene("register_login")


## Handle UserAvatar button press - populate and show avatar chooser popup
func _on_user_avatar_pressed() -> void:
    _populate_avatar_container()
    choose_avatar_popup.visible = true


## Populate the avatar container with avatar components from profile_pictures folder
func _populate_avatar_container() -> void:
    # Clear existing children
    for child in avatar_container.get_children():
        child.queue_free()
    
    # Get all PNG files from profile_pictures folder
    var dir: DirAccess = DirAccess.open("res://assets/profile_pictures/")
    if dir:
        dir.list_dir_begin()
        var file_name: String = dir.get_next()
        
        while file_name != "":
            # Only process PNG files (skip .import files)
            if file_name.ends_with(".png"):
                var texture_path: String = "res://assets/profile_pictures/" + file_name
                var display_name: String = ""
                
                # Instantiate avatar component
                var avatar_component: Button = avatar_component_scene.instantiate()
                avatar_container.add_child(avatar_component)
                
                # Configure the component
                avatar_component.set_avatar_picture(texture_path)
                avatar_component.set_avatar_name(display_name)
                
                # Connect pressed signal to avatar selection handler
                avatar_component.pressed.connect(_on_avatar_selected.bind(texture_path))
            
            file_name = dir.get_next()


## Convert filename (e.g., "man_beard.png") to display name (e.g., "Man Beard")
func _get_display_name_from_filename(file_name: String) -> String:
    # Remove extension
    var name_without_ext: String = file_name.trim_suffix(".png")
    
    # Split on underscore and capitalize each word
    var words: PackedStringArray = name_without_ext.split("_")
    var display_name_parts: PackedStringArray = []
    
    for word in words:
        if word.length() > 0:
            # Capitalize first letter, keep rest as is
            display_name_parts.append(word[0].to_upper() + word.substr(1))
    
    return " ".join(display_name_parts)


## Handle avatar selection from the popup
func _on_avatar_selected(avatar_path: String) -> void:
    # Update avatar in database
    var result: Dictionary = UserDatabase.update_avatar(avatar_path)
    
    # Check if update was successful
    if not result.success:
        push_error("Failed to update avatar: %s" % result.message)
        return
    
    # Refresh the UserAvatar button to show new avatar
    _display_current_avatar()
    
    # Close the popup with animation
    _close_popup_with_animation()


## Handle drag start - record initial popup position
func _on_drag_handle_drag_started(_start_position: Vector2) -> void:
    if not choose_avatar_popup.visible:
        return
    
    popup_start_y = choose_avatar_popup.position.y


## Handle drag update - move popup with drag gesture
func _on_drag_handle_drag_updated(delta: Vector2, _total_distance: float, _progress: float) -> void:
    if not choose_avatar_popup.visible:
        return
    
    # Update popup position (only allow downward movement)
    var new_y: float = popup_start_y + delta.y
    choose_avatar_popup.position.y = max(0.0, new_y)


## Handle drag end - dismiss popup or snap back based on threshold
func _on_drag_handle_drag_ended(_final_distance: float, should_dismiss: bool) -> void:
    if not choose_avatar_popup.visible:
        return
    
    if should_dismiss:
        _close_popup_with_animation()
    else:
        # Snap back to original position
        var tween: Tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(choose_avatar_popup, "position:y", 0.0, 0.2)


## Animate popup off screen and hide it
func _close_popup_with_animation() -> void:
    var screen_height: float = get_viewport_rect().size.y
    
    var tween: Tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(choose_avatar_popup, "position:y", screen_height, 0.3)
    tween.tween_callback(func() -> void:
        choose_avatar_popup.visible = false
        choose_avatar_popup.position.y = 0.0
    )
