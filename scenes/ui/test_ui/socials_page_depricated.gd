extends Control

## Avatar component scene for displaying search results
const AVATAR_COMPONENT: PackedScene = preload("res://scenes/ui/components/avatar_component.tscn")

var is_popup_open: bool = false
var animation_in_progress: bool = false
var popup_start_y: float = 0.0

@onready var popup: Panel = %AddFriendsPopup
@onready var overlay: ColorRect = %PopupOverlay
@onready var name_input: TextEdit = %NameInput
@onready var search_results: GridContainer = %SearchResults
@onready var friends_list: GridContainer = %FriendsList
@onready var account_popup: Control = $AccountPopup


func _ready() -> void:
    # Connect NameInput text_changed signal
    name_input.text_changed.connect(_on_name_input_text_changed)
    
    # Connect to notification action signal for real-time friend updates
    GlobalSignalBus.notification_action_taken.connect(_on_friendship_changed)
    
    # Populate friends list
    _populate_friends_list()


## Handle text changes in the NameInput field to trigger search
func _on_name_input_text_changed() -> void:
    var query: String = name_input.text
    _update_search_results(query)


## Populate friends list with avatar components
##
## Clears existing avatars and creates new ones for each friend of the current user.
func _populate_friends_list() -> void:
    # Clear existing children
    for child in friends_list.get_children():
        child.queue_free()
    
    # Return early if user is not signed in
    if not UserDatabase.is_signed_in():
        return
    
    # Get current user's friends
    var friends: Array = UserDatabase.get_friends(UserDatabase.current_user.username)
    
    # Create and add avatar component for each friend
    for friend: Dictionary in friends:
        var avatar: Button = AVATAR_COMPONENT.instantiate()
        friends_list.add_child(avatar)
        avatar.set_avatar_name(friend.username)
        avatar.set_avatar_picture(friend.avatar_path)
        avatar.set_user_id(friend.username)
        
        # Connect avatar_clicked signal to account_popup.display_user
        avatar.avatar_clicked.connect(account_popup.display_user)


## Update search results based on query string
##
## Clears existing results and displays new avatar components for matching users.
##
## @param query: Search string to match against usernames
func _update_search_results(query: String) -> void:
    # Clear all existing children from SearchResults container
    for child in search_results.get_children():
        child.queue_free()
    
    # Return early if query is empty
    if query.is_empty():
        return
    
    # Search for users matching the query
    var results: Array = UserDatabase.search_users_by_username(query)
    
    # Create and add avatar component for each result
    for user_data: Dictionary in results:
        var avatar: Button = AVATAR_COMPONENT.instantiate()
        search_results.add_child(avatar)
        avatar.set_avatar_name(user_data.username)
        avatar.set_avatar_picture(user_data.avatar_path)
        
        # Connect pressed signal to send friend request
        avatar.pressed.connect(_on_search_avatar_pressed.bind(user_data.username))


func open_popup() -> void:
    if animation_in_progress:
        return
    
    animation_in_progress = true
    is_popup_open = true
    
    # Get references
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


## Handle avatar clicked in search results - send friend request notification
func _on_search_avatar_pressed(username: String) -> void:
    # Ensure user is signed in before sending friend request
    if not UserDatabase.is_signed_in():
        return
    
    # Create notification data for friend request
    var notification_data: Dictionary = {
        "recipient_username": username,
        "message": "Friend request from %s" % UserDatabase.current_user.username,
        "sender": UserDatabase.current_user.username,
        "has_actions": true,
        "action_data": {
            "type": "friend_request",
            "sender_id": UserDatabase.current_user.username
        }
    }
    
    # Emit notification via GlobalSignalBus
    GlobalSignalBus.notification_received.emit(notification_data)
    
    # Provide user feedback (optional: could show a toast or label)
    print("Friend request sent to %s" % username)


func _on_add_friend_button_pressed() -> void:
    pass # Replace with function body.


func _on_add_new_friend_button_pressed() -> void:
    toggle_popup()


func _on_drag_handle_component_drag_started(_start_position: Vector2) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
    popup_start_y = popup.position.y


func _on_drag_handle_component_drag_updated(delta: Vector2, _total_distance: float, progress: float) -> void:
    if not is_popup_open or animation_in_progress:
        return
    
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
        var tween: Tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(popup, "position:y", 0.0, 0.2)


## Handle friendship changes to update friend list in real-time
##
## Refreshes the friends list when a friend request is accepted.
##
## @param notification_id: ID of the notification that was acted on
## @param action: Action taken ("accept" or "deny")
func _on_friendship_changed(_notification_id: String, action: String) -> void:
    # Only refresh on accept actions (friend requests)
    # The UserDatabase and MainLobbyScreen already handle the friend_request logic
    if action == "accept":
        _populate_friends_list()
