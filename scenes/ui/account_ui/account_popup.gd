extends Panel

## Currently displayed user's username
var current_displayed_user: String = ""

@onready var name_label: Label = %NameLabel
@onready var player_avatar: TextureRect = %PlayerAvatar
@onready var invite_button: Button = %InviteToGameButton


## Display account information for a specific user
##
## @param user_id: Username of the user to display
func display_user(user_id: String) -> void:
    # Fetch user data from UserDatabase
    var user_data: Dictionary = UserDatabase.get_user_data_for_display(user_id)
    
    # Return early if user doesn't exist
    if user_data.is_empty():
        push_warning("Cannot display user: user '%s' does not exist" % user_id)
        return
    
    # Update UI elements with user data
    name_label.text = user_data.username
    
    # Load and set avatar texture
    var avatar_path: String = user_data.avatar_path
    var texture: Texture2D = load(avatar_path)
    if texture:
        player_avatar.texture = texture
    
    # Store user data for potential future use (wins, losses, current_streak)
    # These can be displayed in additional UI elements when needed
    current_displayed_user = user_id
    
    # Re-enable invite button on popup open
    invite_button.disabled = false
    
    # Show popup
    visible = true


## Close the popup and clear displayed user
func close_popup() -> void:
    visible = false
    current_displayed_user = ""


func _on_back_button_pressed() -> void:
    close_popup()


## Handle clicks on the overlay to close popup when clicking outside
func _on_overlay_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
            # Check if click is outside popup panel bounds
            var popup_rect: Rect2 = self.get_global_rect()
            if not popup_rect.has_point(mouse_event.global_position):
                close_popup()


## Handle invite to game button press
## Opens setup screen for configuring game parameters before sending invite
func _on_invite_to_game_button_pressed() -> void:
    # Check if user is signed in
    if not UserDatabase.is_signed_in():
        push_warning("Cannot send game invite: user not signed in")
        return
    
    # Check if a user is displayed
    if current_displayed_user.is_empty():
        push_warning("Cannot send game invite: no user displayed")
        return
    
    # Disable button to provide visual feedback
    invite_button.disabled = true
    
    # Store username before closing popup (close_popup clears current_displayed_user)
    var invited_username: String = current_displayed_user
    
    # Close popup
    close_popup()
    
    # Navigate to setup screen with invited player context
    var params: Dictionary = {"invited_player": invited_username}
    TransitionManager.change_scene("res://scenes/ui/setup_screen.tscn", params)
