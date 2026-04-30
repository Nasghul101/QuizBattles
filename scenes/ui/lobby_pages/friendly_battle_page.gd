extends Control

const FRIENDLY_DUEL_BUTTON_L = preload("res://scenes/ui/components/friendly_duel_button_l.tscn")
const FRIENDLY_DUEL_BUTTON_R = preload("res://scenes/ui/components/friendly_duel_button_r.tscn")

@onready var friend_list_l : VBoxContainer = %FriendsListL
@onready var friend_list_r : VBoxContainer = %FriendsListR


func _ready() -> void:
    _populate_active_matches()
    
    # Listen for new matches being created
    GlobalSignalBus.match_created.connect(_on_match_created)


func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED:
        if visible and is_inside_tree():
            _populate_active_matches()


## Populate friend lists with friendly_duel_button components for active multiplayer matches
## Buttons alternate between left (friend_list_l) and right (friend_list_r) containers
func _populate_active_matches() -> void:
    # Return early if nodes aren't ready yet
    if not is_node_ready() or friend_list_l == null or friend_list_r == null:
        return
    
    # Clear existing children
    for child in friend_list_l.get_children():
        child.queue_free()
    for child in friend_list_r.get_children():
        child.queue_free()
    
    # Return early if user is not signed in
    if not UserDatabase.is_signed_in():
        return
    
    # Get all matches for current user
    var all_matches: Array = UserDatabase.get_all_matches_for_player(
        UserDatabase.current_user.username
    )
    
    # Filter out matches that current user has dismissed and finished matches
    var matches: Array = []
    for match in all_matches:
        var dismissed_by = match.get("dismissed_by", [])
        var is_finished = match.get("status") == "finished"
        if UserDatabase.current_user.username not in dismissed_by and not is_finished:
            matches.append(match)
    
    # Show/hide empty state message if it exists
    var no_matches_label = get_node_or_null("%NoMatchesLabel")
    if no_matches_label:
        no_matches_label.visible = matches.is_empty()
    
    # Create buttons for each match, alternating between left and right
    var match_index = 0
    for match in matches:
        var opponent_username = _get_opponent_username(match)
        
        # Determine target container and button scene
        var target_list = friend_list_l if match_index % 2 == 0 else friend_list_r
        var button_scene = FRIENDLY_DUEL_BUTTON_L if match_index % 2 == 0 else FRIENDLY_DUEL_BUTTON_R
        
        # Instantiate and add button
        var button = button_scene.instantiate()
        target_list.add_child(button)
        
        # Calculate scores
        var player_score = _calculate_player_score(match, UserDatabase.current_user.username)
        var opponent_score = _calculate_player_score(match, opponent_username)
        
        # Set button properties
        button.set_player_points(player_score)
        button.set_opponents_points(opponent_score)
        button.set_round_count(match.current_round)
        button.set_opponent_name(opponent_username)
        
        # Set highlight based on turn
        if match.current_turn == UserDatabase.current_user.username:
            button.highlight()
        else:
            button.un_highlight()
        
        # Connect button pressed signal
        button.pressed.connect(_on_button_pressed.bind(match.match_id))
        
        match_index += 1


## Calculate cumulative score for a player across all rounds
##
## @param match: Match Dictionary containing rounds_data
## @param username: Player's username to calculate score for
## @return int: Total number of correct answers across all rounds
func _calculate_player_score(match: Dictionary, username: String) -> int:
    var score = 0
    for round_data in match.rounds_data:
        if round_data.player_answers.has(username):
            var player_answer = round_data.player_answers[username]
            if player_answer.answered:
                for result in player_answer.results:
                    if result.was_correct:
                        score += 1
    return score


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


## Handle button press to navigate to gameplay screen
##
## @param match_id: Match identifier passed from button
func _on_button_pressed(match_id: String) -> void:
    # Validate match exists before navigating
    var match = UserDatabase.get_match(match_id)
    if match.is_empty():
        push_warning("Cannot navigate: match not found %s" % match_id)
        _populate_active_matches()  # Refresh list
        return
    
    var params = {"match_id": match_id}
    TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
