extends Control
## Account Management Screen
##
## Displays user account information and settings with navigation back to main lobby.

@onready var avatar_container: GridContainer = %AvatarContainer
@onready var choose_avatar_popup: PanelContainer = %ChooseAvatarPopup

var avatar_component_scene: PackedScene = preload("res://scenes/ui/components/avatar_component.tscn")


func _ready() -> void:
    # Display username
    _display_username()
    

## Display the current user's username in NameLabel
func _display_username() -> void:
    var name_label: Label = %NameLabel
    if name_label:
        var current_user: Dictionary = UserDatabase.get_current_user()
        if not current_user.is_empty() and current_user.has("username"):
            name_label.text = current_user["username"]
        # If no user or no username, keep existing label text as fallback


## Handle BackButton press - return to main lobby
func _on_back_button_pressed() -> void:
    NavigationUtils.navigate_to_scene("main_lobby")


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
    NavigationUtils.navigate_to_scene("register_login")


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
