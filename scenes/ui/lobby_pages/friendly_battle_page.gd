extends Control

const AVATAR_COMPONENT = preload("res://scenes/ui/components/avatar_component.tscn")

@onready var friend_list: GridContainer = %FriendsList


func _ready() -> void:
    _populate_active_matches()
    
    # Listen for new matches being created
    GlobalSignalBus.match_created.connect(_on_match_created)


func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        if visible and is_inside_tree():
            _populate_active_matches()


## Populate friend_list with avatar_components for active multiplayer matches
func _populate_active_matches() -> void:
    # Return early if nodes aren't ready yet
    if not is_node_ready() or friend_list == null:
        return
    
    # Clear existing children
    for child in friend_list.get_children():
        child.queue_free()
    
    # Return early if user is not signed in
    if not UserDatabase.is_signed_in():
        return
    
    # Get all matches for current user
    var all_matches: Array = UserDatabase.get_all_matches_for_player(
        UserDatabase.current_user.username
    )
    
    # Filter out matches that current user has dismissed
    var matches: Array = []
    for match in all_matches:
        var dismissed_by = match.get("dismissed_by", [])
        if UserDatabase.current_user.username not in dismissed_by:
            matches.append(match)
    
    # Show/hide empty state message if it exists
    var no_matches_label = get_node_or_null("%NoMatchesLabel")
    if no_matches_label:
        no_matches_label.visible = matches.is_empty()
    
    # Create avatar_component for each match
    for match in matches:
        var opponent_username = _get_opponent_username(match)
        var opponent_data = UserDatabase.get_user_data_for_display(opponent_username)
        
        if opponent_data.is_empty():
            continue  # Skip if opponent data not found
        
        var avatar: Button = AVATAR_COMPONENT.instantiate()
        friend_list.add_child(avatar)
        
        # Set avatar picture to opponent's profile
        avatar.set_avatar_picture(opponent_data.avatar_path)
        
        # Set match ID for navigation context
        avatar.set_match_id(match.match_id)
        
        # Set turn status label
        var label_text = ""
        if match.status == "finished":
            label_text = "Game Finished"
        elif match.current_turn == UserDatabase.current_user.username:
            label_text = "Your Turn"
        else:
            label_text = "%s Turn" % opponent_username
        avatar.set_avatar_name(label_text)
        
        # Connect click signal
        avatar.avatar_clicked.connect(_on_avatar_clicked)


## Get opponent's username from match data
##
## @param match: Match Dictionary
## @return String: Opponent's username
func _get_opponent_username(match: Dictionary) -> String:
    var current_username = UserDatabase.current_user.username
    for player in match.players:
        if player != current_username:
            return player
    return ""


## Handle new match creation by refreshing the match list
##
## @param _match_id: Match identifier (unused, needed for signal signature)
## @param player1: Username of first player
## @param player2: Username of second player
func _on_match_created(_match_id: String, player1: String, player2: String) -> void:
    # Only refresh if current user is involved in the match
    if UserDatabase.is_signed_in():
        var current_username = UserDatabase.current_user.username
        if current_username == player1 or current_username == player2:
            _populate_active_matches()


## Handle avatar click to navigate to gameplay screen
##
## @param match_id: Match identifier passed from avatar component
func _on_avatar_clicked(match_id: String) -> void:
    # Validate match exists before navigating
    var match = UserDatabase.get_match(match_id)
    if match.is_empty():
        push_warning("Cannot navigate: match not found %s" % match_id)
        _populate_active_matches()  # Refresh list
        return
    
    var params = {"match_id": match_id}
    TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
