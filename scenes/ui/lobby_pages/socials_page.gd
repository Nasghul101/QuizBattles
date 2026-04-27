extends Control

@onready var friend_display: VBoxContainer = %FriendDisplayContainer
@onready var bg_texture: TextureRect = %BGTexture
@onready var add_friends_popup: MarginContainer = %AddFriendsPopup
@onready var name_input: TextEdit = %NameInput
@onready var friends_container: VBoxContainer = %FriendsContainer
@onready var send_friend_request_button: Button = %SendFriendRequestButton

# Preload friend display component scene
const FRIEND_DISPLAY_COMPONENT = preload("res://scenes/ui/components/friend_display_component.tscn")
const NAME_DISPLAY_BUTTON = preload("res://scenes/ui/components/name_display_button.tscn")

# Category colors loaded from color_codes.json
var category_colors: Dictionary = {}

# Selection state for friend requests
var selected_username: String = ""
var selected_button: Button = null


func _ready() -> void:
    var colors : Dictionary = Utils.get_color_codes()
    bg_texture.self_modulate = Color(colors["miscellaneous"]["App foreground"])
    
    # Load category colors
    category_colors = colors.get("category_colors", {})
    
    # Connect to notification actions for friend list updates
    GlobalSignalBus.notification_action_taken.connect(_on_friendship_changed)
    
    # Connect to name input for search-as-you-type
    name_input.text_changed.connect(_on_name_input_text_changed)
    
    # Disable send friend request button initially
    send_friend_request_button.disabled = true
    
    # Populate friends list on startup
    _populate_friends_list()


## Populate the friends list with friend display components showing statistics
func _populate_friends_list() -> void:
    # Clear existing friend displays (keep AddNewFriendsButton)
    for child in friend_display.get_children():
        if child.has_method("set_player_name"):  # Only remove friend_display_components
            child.queue_free()
    
    # Check if user is signed in
    if not UserDatabase.is_signed_in():
        return
    
    var current_username: String = UserDatabase.current_user.username
    var friends_list: Array = UserDatabase.get_friends(current_username)
    var current_user_data: Dictionary = UserDatabase.get_user_data_for_display(current_username)
    
    # Create a display component for each friend
    for friend: Dictionary in friends_list:
        var friend_username: String = friend.username
        var friend_data: Dictionary = UserDatabase.get_user_data_for_display(friend_username)
        
        # Skip if friend data couldn't be loaded
        if friend_data.is_empty():
            continue
        
        # Instantiate friend display component
        var display: FriendDisplayComponent = FRIEND_DISPLAY_COMPONENT.instantiate()
        
        # Set player name
        display.set_player_name(friend_username)
        
        # Calculate win/loss counts (head-to-head record)
        var wins: int = current_user_data.friend_wins.get(friend_username, 0)
        var losses: int = friend_data.friend_wins.get(current_username, 0)
        display.set_win_count(wins)
        display.set_loss_count(losses)
        
        # Get top 3 categories and set colors
        var top_categories: Array = _get_top_categories(friend_data.category_stats)
        _set_category_colors(display, top_categories)
        
        # Add to container (before AddNewFriendsButton)
        friend_display.add_child(display)
        friend_display.move_child(display, friend_display.get_child_count() - 2)


## Get top 3 categories sorted by play count.
## Generates placeholder data if category_stats is empty.
## @param category_stats: Dictionary mapping category names to play counts
## @return Array of category names sorted by count (up to 3)
func _get_top_categories(category_stats: Dictionary) -> Array:
    # Use placeholder data if category_stats is empty
    var stats: Dictionary = category_stats
    if stats.is_empty():
        stats = UserDatabase._generate_placeholder_category_stats()
    
    # Sort categories by play count
    var sorted_categories: Array = []
    for category_name: String in stats.keys():
        sorted_categories.append({"name": category_name, "count": stats[category_name]})
    
    # Sort by count descending
    sorted_categories.sort_custom(func(a, b): return a.count > b.count)
    
    # Return top 3 category names
    var top_3: Array = []
    for i in range(min(3, sorted_categories.size())):
        top_3.append(sorted_categories[i].name)
    
    return top_3


## Set category colors on the friend display component.
## Uses default gray color for categories without defined colors.
## @param display: FriendDisplayComponent to update
## @param categories: Array of up to 3 category names
func _set_category_colors(display: FriendDisplayComponent, categories: Array) -> void:
    var default_color: Color = Color(0.3, 0.3, 0.3)  # Gray for undefined categories
    
    # Set first category
    if categories.size() > 0:
        var color: Color = _get_category_color(categories[0], default_color)
        display.set_first_category(color)
    
    # Set second category
    if categories.size() > 1:
        var color: Color = _get_category_color(categories[1], default_color)
        display.set_second_category(color)
    
    # Set third category
    if categories.size() > 2:
        var color: Color = _get_category_color(categories[2], default_color)
        display.set_third_category(color)


## Get color for a category from the color_codes.json.
## @param category_name: Name of the category
## @param default_color: Fallback color if category has no defined color
## @return Color object
func _get_category_color(category_name: String, default_color: Color) -> Color:
    if category_colors.has(category_name):
        var color_value = category_colors[category_name]
        if color_value != null:
            return Color(color_value)
    return default_color


## Handle friendship changes (friend request accepted).
## Repopulates the friend list when a friend request is accepted.
func _on_friendship_changed(notification_id: String, action: String) -> void:
    if action == "accept":
        _populate_friends_list()


## Handle name input text changed for search-as-you-type functionality.
## Searches for users matching the input query and displays results.
func _on_name_input_text_changed() -> void:
    var query: String = name_input.text.strip_edges()
    
    # Clear previous search results
    for child in friends_container.get_children():
        child.queue_free()
    
    # Clear selection state when search changes
    selected_username = ""
    selected_button = null
    send_friend_request_button.disabled = true
    
    # Skip search if query is empty
    if query.is_empty():
        return
    
    # Search for users
    var results: Array = UserDatabase.search_users_by_username(query)
    
    # Create a button for each result
    for user_data: Dictionary in results:
        var button: Button = NAME_DISPLAY_BUTTON.instantiate()
        var username: String = user_data.username
        
        # Set username (this also sets the button text)
        button.set_username(username)
        
        # Connect selection changed signal (will be handled by selection state management)
        button.selection_changed.connect(_on_name_selection_changed)
        
        # Add to container
        friends_container.add_child(button)


## Handle name selection changed (radio button behavior).
## Manages selection state ensuring only one button is highlighted at a time.
func _on_name_selection_changed(username: String, is_highlighted: bool) -> void:
    if is_highlighted:
        # Deselect previous button if exists
        if selected_button != null and selected_button.username != username:
            selected_button.set_highlighted(false)
        
        # Store new selection
        selected_username = username
        # Find and store the newly selected button
        for child in friends_container.get_children():
            if child.has_method("set_username") and child.username == username:
                selected_button = child
                break
        
        # Enable send friend request button
        send_friend_request_button.disabled = false
    else:
        # User deselected by clicking again
        if username == selected_username:
            selected_username = ""
            selected_button = null
            send_friend_request_button.disabled = true

func _on_add_new_friends_button_pressed() -> void:
    # Show the add friends popup
    add_friends_popup.visible = true

func _on_back_button_pressed() -> void:
    # Clear name input
    name_input.text = ""
    
    # Clear search results
    for child in friends_container.get_children():
        child.queue_free()
    
    # Clear selection state
    selected_username = ""
    selected_button = null
    
    # Disable send friend request button
    send_friend_request_button.disabled = true
    
    # Hide popup
    add_friends_popup.visible = false

func _on_send_friend_request_button_pressed() -> void:
    # Check if a user is selected
    if selected_username.is_empty():
        return
    
    # Check if user is signed in
    if not UserDatabase.is_signed_in():
        push_error("Cannot send friend request: user not signed in")
        return
    
    # Create notification data for friend request
    var notification_data: Dictionary = {
        "recipient_username": selected_username,
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
    
    # Provide user feedback
    print("Friend request sent to %s" % selected_username)
    
    # Clear selection and disable button
    if selected_button != null:
        selected_button.set_highlighted(false)
    selected_username = ""
    selected_button = null
    send_friend_request_button.disabled = true

func _on_share_button_pressed() -> void:
    # TODO: Implement native share menu integration for mobile
    print("Share button pressed - feature not yet implemented")
