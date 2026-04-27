extends Node

## Local User Database Service
##
## Provides in-memory user registration, authentication, and session management.
## Designed as a temporary replacement for Firebase Authentication with a compatible
## API surface to minimize future migration effort.
##
## This service stores user data only in memory - all data is lost when the game closes.
## Passwords are hashed using SHA-256 for security even in temporary storage.
##
## Error codes follow Firebase Auth naming conventions (uppercase with underscores).

## Valid top-level domains for email validation
const VALID_TLDS := [".com", ".de", ".org", ".net", ".edu", ".gov", ".co", ".uk", ".io", ".app", ".dev", ".tech"]

## Minimum username length
const MIN_USERNAME_LENGTH := 5

## Maximum username length
const MAX_USERNAME_LENGTH := 15

## Default avatar path for new users
const DEFAULT_AVATAR_PATH := "res://assets/profile_pictures/man_standard.png"

## Path to the JSON file where user data is stored
const DATABASE_PATH := "res://data/user_database.json"

## Main database structure containing users and matches
var data: Dictionary = {
    "users": {},
    "multiplayer_matches": []
}

## Shortcut reference to users dictionary for backward compatibility
var _users: Dictionary:
    get:
        return data.users
    set(value):
        data.users = value

## Currently logged-in user (empty Dictionary if not signed in)
var current_user: Dictionary = {}


func _ready() -> void:
    _load_database()
    # Connect to GlobalSignalBus to handle incoming notifications
    GlobalSignalBus.notification_received.connect(_on_notification_received_global)
    # Connect to notification actions for handling denial logic
    GlobalSignalBus.notification_action_taken.connect(_on_notification_action_taken)
    # Connect to game invite acceptance for match creation
    GlobalSignalBus.game_invite_accepted.connect(_on_game_invite_accepted)


## Handle notification received from GlobalSignalBus
## Adds notification to recipient's database regardless of who is currently logged in
func _on_notification_received_global(notification_data: Dictionary) -> void:
    var recipient: String = notification_data.get("recipient_username", "")
    if recipient.is_empty():
        push_error("Cannot add notification: recipient_username is missing")
        return
    
    # Check for duplicate friend requests
    if notification_data.has("action_data"):
        var action_data: Dictionary = notification_data.action_data
        if action_data.get("type") == "friend_request":
            var sender: String = notification_data.get("sender", "")
            if _has_pending_friend_request(recipient, sender):
                push_warning("Friend request already sent to %s from %s" % [recipient, sender])
                return
        
        # Check for duplicate game invites
        if action_data.get("type") == "game_invite":
            var sender: String = notification_data.get("sender", "")
            if _has_pending_game_invite(recipient, sender):
                push_warning("Game invite already sent to %s from %s" % [recipient, sender])
                return
    
    # Add notification to recipient's account
    add_notification(recipient, notification_data)


## Check if a pending friend request already exists from sender to recipient
func _has_pending_friend_request(recipient: String, sender: String) -> bool:
    if not user_exists(recipient):
        return false
    
    var notifications: Array = get_notifications(recipient)
    
    for notif_data: Dictionary in notifications:
        if notif_data.has("action_data") and notif_data.action_data is Dictionary:
            var action_data: Dictionary = notif_data.action_data
            if action_data.get("type") == "friend_request" and notif_data.get("sender") == sender:
                return true
    
    return false


## Check if a pending game invite already exists from sender to recipient
func _has_pending_game_invite(recipient: String, sender: String) -> bool:
    if not user_exists(recipient):
        return false
    
    var notifications: Array = get_notifications(recipient)
    
    for notif_data: Dictionary in notifications:
        if notif_data.has("action_data") and notif_data.action_data is Dictionary:
            var action_data: Dictionary = notif_data.action_data
            if action_data.get("type") == "game_invite" and notif_data.get("sender") == sender:
                return true
    
    return false


## Handle notification action taken (for denial logic)
## Sends rejection notification to inviter when game invite is denied
func _on_notification_action_taken(notification_id: String, action: String) -> void:
    # Only handle deny actions
    if action != "deny":
        return
    
    # Get current user
    if not is_signed_in():
        return
    
    var current_username: String = current_user.username
    
    # Find the notification being denied
    var notifications: Array = get_notifications(current_username)
    var denied_notification: Dictionary = {}
    
    for notif_data: Dictionary in notifications:
        if notif_data.get("id") == notification_id:
            denied_notification = notif_data
            break
    
    # Check if it's a game invite
    if denied_notification.has("action_data"):
        var action_data: Dictionary = denied_notification.action_data
        if action_data.get("type") == "game_invite":
            # Send rejection notification to original sender
            var inviter: String = denied_notification.get("sender", "")
            if not inviter.is_empty():
                var rejection_data: Dictionary = {
                    "recipient_username": inviter,
                    "message": "%s rejected your duel" % current_username,
                    "sender": "System",
                    "has_actions": false,
                    "action_data": {
                        "type": "game_invite_rejection"
                    }
                }
                # Emit through signal bus to trigger notification creation
                GlobalSignalBus.notification_received.emit(rejection_data)
                print("Rejection notification sent to %s" % inviter)


## Create a new user account with username, password, and email.
## 
## Validates input, checks for duplicates, hashes the password, and stores the user.
##
## @param username: Username for the new account (5-15 characters)
## @param password: Password for the new account (will be hashed)
## @param email: Email address for the new account (must be valid format)
## @return Dictionary with success status, error info, and user data:
##   - {success: true, user: {username: String, email: String}} on success
##   - {success: false, error_code: String, message: String} on failure
func create_user(username: String, password: String, email: String) -> Dictionary:
    # Validate username length
    var username_validation: Dictionary = _validate_username(username)
    if not username_validation.success:
        return username_validation
    
    # Validate email format
    var email_validation: Dictionary = _validate_email(email)
    if not email_validation.success:
        return email_validation
    
    # Check for duplicate username
    if user_exists(username):
        return {
            "success": false,
            "error_code": "USERNAME_EXISTS",
            "message": "Username already exists"
        }
    
    # Check for duplicate email
    if email_exists(email):
        return {
            "success": false,
            "error_code": "EMAIL_EXISTS",
            "message": "Email already registered"
        }
    
    # Hash password and store user
    var password_hash: String = _hash_password(password)
    var user_data: Dictionary = {
        "username": username,
        "password_hash": password_hash,
        "email": email,
        "avatar_path": DEFAULT_AVATAR_PATH,
        "notifications": [],
        "friends": [],
        "wins": 0,
        "losses": 0,
        "current_streak": 0,
        "friend_wins": {},
        "category_stats": {}
    }
    _users[username] = user_data
    _save_database()
    # Return success with public user data (no password hash)
    return {
        "success": true,
        "user": {
            "username": username,
            "email": email,
            "avatar_path": DEFAULT_AVATAR_PATH
        }
    }


## Authenticate a user with username and password credentials.
##
## Verifies credentials and sets the current user session on success.
##
## @param username: Username to authenticate
## @param password: Password to verify
## @return Dictionary with success status, error info, and user data:
##   - {success: true, user: {username: String, email: String}} on success
##   - {success: false, error_code: String, message: String} on failure
func sign_in(username: String, password: String) -> Dictionary:
    # Check if user exists
    if not user_exists(username):
        return {
            "success": false,
            "error_code": "USER_NOT_FOUND",
            "message": "No user found with this username"
        }
    
    # Get stored user data
    var user_data: Dictionary = _users[username]
    var stored_hash: String = user_data.password_hash
    
    # Verify password hash
    var provided_hash: String = _hash_password(password)
    if provided_hash != stored_hash:
        return {
            "success": false,
            "error_code": "INVALID_PASSWORD",
            "message": "Password is incorrect"
        }
    
    # Set current user (without password hash)
    current_user = {
        "username": user_data.username,
        "email": user_data.email,
        "avatar_path": user_data.avatar_path
    }
    
    # Return success with user data
    return {
        "success": true,
        "user": current_user.duplicate()
    }


## Sign out the current user and clear the session.
func sign_out() -> void:
    current_user = {}


## Get the currently logged-in user.
##
## @return Dictionary with user data {username: String, email: String} if signed in,
##         or empty Dictionary if not signed in
func get_current_user() -> Dictionary:
    return current_user.duplicate()


## Check if a user is currently signed in.
##
## @return true if a user is signed in, false otherwise
func is_signed_in() -> bool:
    return not current_user.is_empty()


## Update the avatar path for the currently signed-in user.
##
## @param avatar_path: New avatar path to set
## @return Dictionary with success status and error info:
##   - {success: true, avatar_path: String} on success
##   - {success: false, error_code: String, message: String} on failure
func update_avatar(avatar_path: String) -> Dictionary:
    # Check if user is signed in
    if not is_signed_in():
        return {
            "success": false,
            "error_code": "NOT_SIGNED_IN",
            "message": "No user is currently signed in"
        }
    
    # Get current username
    var username: String = current_user.username
    
    # Update avatar_path in stored user data
    if _users.has(username):
        _users[username].avatar_path = avatar_path
        _save_database()
    
    # Update current_user session to reflect the change
    current_user.avatar_path = avatar_path
    
    # Return success
    return {
        "success": true,
        "avatar_path": avatar_path
    }


## Check if a username is already registered.
##
## @param username: Username to check
## @return true if username exists, false otherwise
func user_exists(username: String) -> bool:
    return _users.has(username)


## Check if an email is already registered.
##
## @param email: Email address to check
## @return true if email exists, false otherwise
func email_exists(email: String) -> bool:
    for user_data: Dictionary in _users.values():
        if user_data.email == email:
            return true
    return false


## Get user data by username (for internal use).
##
## @param username: Username to look up
## @return Dictionary with user data if found, empty Dictionary otherwise
func get_user_by_username(username: String) -> Dictionary:
    if user_exists(username):
        var user_data : Dictionary = _users[username]
        return {
            "username": user_data.username,
            "email": user_data.email,
            "avatar_path": user_data.avatar_path
        }
    return {}


## Get user data safe for display in UI (excludes sensitive data).
##
## Returns username, avatar_path, wins, losses, current_streak, friend_wins.
## Explicitly excludes password_hash and email for security.
##
## @param username: Username to look up
## @return Dictionary with display-safe user data, or empty Dictionary if user doesn't exist
func get_user_data_for_display(username: String) -> Dictionary:
    if not user_exists(username):
        return {}
    
    var user_data: Dictionary = _users[username]
    return {
        "username": user_data.username,
        "avatar_path": user_data.get("avatar_path", DEFAULT_AVATAR_PATH),
        "wins": user_data.get("wins", 0),
        "losses": user_data.get("losses", 0),
        "current_streak": user_data.get("current_streak", 0),
        "friend_wins": user_data.get("friend_wins", {}),
        "category_stats": user_data.get("category_stats", {})
    }


## Search for users by username with case-insensitive partial matching.
##
## Performs partial substring matching (case-insensitive) and excludes
## the currently logged-in user from results.
##
## @param query: Search string to match against usernames
## @return Array of user dictionaries with username, email, and avatar_path
func search_users_by_username(query: String) -> Array:
    var results: Array = []
    
    # Return empty array if query is empty
    if query.is_empty():
        return results
    
    # Convert query to lowercase for case-insensitive matching
    var query_lower: String = query.to_lower()
    
    # Search through all users
    for username: String in _users.keys():
        # Exclude current user from results
        if is_signed_in() and username == current_user.username:
            continue
        
        # Check if username contains query (case-insensitive)
        if username.to_lower().contains(query_lower):
            var user_data: Dictionary = _users[username]
            results.append({
                "username": user_data.username,
                "email": user_data.email,
                "avatar_path": user_data.avatar_path
            })
    
    return results


## Validate email format.
##
## Checks for @ symbol and valid top-level domain.
##
## @param email: Email address to validate
## @return Dictionary with success status and error info:
##   - {success: true} if valid
##   - {success: false, error_code: String, message: String} if invalid
func _validate_email(email: String) -> Dictionary:
    # Check for @ symbol
    if not email.contains("@"):
        return {
            "success": false,
            "error_code": "INVALID_EMAIL",
            "message": "Email format is invalid"
        }
    
    # Check for valid TLD
    var has_valid_tld: bool = false
    for tld: String in VALID_TLDS:
        if email.ends_with(tld):
            has_valid_tld = true
            break
    
    if not has_valid_tld:
        return {
            "success": false,
            "error_code": "INVALID_EMAIL",
            "message": "Email format is invalid"
        }
    
    return {"success": true}


## Validate username length.
##
## Username must be between 5 and 15 characters inclusive.
##
## @param username: Username to validate
## @return Dictionary with success status and error info:
##   - {success: true} if valid
##   - {success: false, error_code: String, message: String} if invalid
func _validate_username(username: String) -> Dictionary:
    var length: int = username.length()
    
    if length < MIN_USERNAME_LENGTH:
        return {
            "success": false,
            "error_code": "USERNAME_TOO_SHORT",
            "message": "Username must be at least %d characters" % MIN_USERNAME_LENGTH
        }
    
    if length > MAX_USERNAME_LENGTH:
        return {
            "success": false,
            "error_code": "USERNAME_TOO_LONG",
            "message": "Username must be at most %d characters" % MAX_USERNAME_LENGTH
        }
    
    return {"success": true}


## Hash a password using SHA-256.
##
## Uses Godot's built-in HashingContext to generate a secure hash.
##
## @param password: Plain-text password to hash
## @return Hex-encoded SHA-256 hash of the password
func _hash_password(password: String) -> String:
    var ctx: HashingContext = HashingContext.new()
    ctx.start(HashingContext.HASH_SHA256)
    ctx.update(password.to_utf8_buffer())
    var hash_bytes: PackedByteArray = ctx.finish()
    return hash_bytes.hex_encode()


## Add a notification to a user's notification list.
##
## Automatically generates unique ID and timestamp if not provided.
## Stores notification in user's record and persists to database.
##
## @param username: Username of recipient
## @param notification_data: Dictionary containing notification details:
##   - message: String - The notification text
##   - sender: String - Username or "System"
##   - has_actions: bool - Whether to show accept/deny buttons
##   - action_data: Dictionary - Custom data for handling actions
##   - id (optional): String - Auto-generated if not provided
##   - timestamp (optional): String - Auto-generated if not provided (ISO 8601)
##   - is_read (optional): bool - Defaults to false
func add_notification(username: String, notification_data: Dictionary) -> void:
    # Validate user exists
    if not user_exists(username):
        push_error("Cannot add notification: user '%s' does not exist" % username)
        return
    
    # Ensure user has notifications array
    if not _users[username].has("notifications"):
        _users[username].notifications = []
    
    # Auto-generate ID if not provided
    if not notification_data.has("id"):
        notification_data.id = _generate_notification_id()
    
    # Auto-generate timestamp if not provided (Unix timestamp for expiry logic)
    if not notification_data.has("timestamp"):
        notification_data.timestamp = Time.get_unix_time_from_system()
    
    # Default is_read to false
    if not notification_data.has("is_read"):
        notification_data.is_read = false
    
    # Append notification to user's list
    _users[username].notifications.append(notification_data)
    
    # Persist to disk
    _save_database()


## Remove a notification from a user's notification list by ID.
##
## @param username: Username of the user
## @param notification_id: Unique ID of the notification to remove
func remove_notification(username: String, notification_id: String) -> void:
    # Validate user exists
    if not user_exists(username):
        push_error("Cannot remove notification: user '%s' does not exist" % username)
        return
    
    # Check if user has notifications array
    if not _users[username].has("notifications"):
        return
    
    var notifications: Array = _users[username].notifications
    
    # Find and remove notification by ID
    for i in range(notifications.size()):
        if notifications[i].has("id") and notifications[i].id == notification_id:
            notifications.remove_at(i)
            _save_database()
            return


## Get all notifications for a specific user.
## Automatically filters out notifications older than 3 days.
##
## @param username: Username to get notifications for
## @return Array of notification dictionaries (excluding expired), or empty array if user doesn't exist
func get_notifications(username: String) -> Array:
    if not user_exists(username):
        return []
    
    if not _users[username].has("notifications"):
        return []
    
    # Filter out expired notifications (older than 3 days)
    const NOTIFICATION_EXPIRY_SECONDS: int = 259200  # 3 days in seconds
    var current_time: float = Time.get_unix_time_from_system()
    var filtered_notifications: Array = []
    
    for notif_data: Dictionary in _users[username].notifications:
        var notification_time: float = 0.0
        var timestamp_value: Variant = notif_data.get("timestamp", 0.0)
        
        # Handle both float (Unix timestamp) and String (ISO 8601) formats for backwards compatibility
        if timestamp_value is float:
            notification_time = timestamp_value
        elif timestamp_value is String:
            # Parse ISO 8601 string to Unix timestamp
            var datetime: Dictionary = Time.get_datetime_dict_from_datetime_string(timestamp_value, false)
            notification_time = Time.get_unix_time_from_datetime_dict(datetime)
        
        # Keep notification if not expired
        if current_time - notification_time <= NOTIFICATION_EXPIRY_SECONDS:
            filtered_notifications.append(notif_data)
    
    return filtered_notifications


## Mark a notification as read for a user.
##
## @param username: Username of the user
## @param notification_id: Unique ID of the notification to mark as read
func mark_notification_read(username: String, notification_id: String) -> void:
    # Validate user exists
    if not user_exists(username):
        push_error("Cannot mark notification as read: user '%s' does not exist" % username)
        return
    
    # Check if user has notifications array
    if not _users[username].has("notifications"):
        return
    
    var notifications: Array = _users[username].notifications
    
    # Find and update notification
    for notif_data: Dictionary in notifications:
        if notif_data.has("id") and notif_data.id == notification_id:
            notif_data.is_read = true
            _save_database()
            return


## Get the count of unread notifications for a user.
##
## @param username: Username to check
## @return Number of unread notifications (is_read == false)
func get_unread_count(username: String) -> int:
    if not user_exists(username):
        return 0
    
    if not _users[username].has("notifications"):
        return 0
    
    var unread_count: int = 0
    for notif_data: Dictionary in _users[username].notifications:
        if notif_data.has("is_read") and not notif_data.is_read:
            unread_count += 1
    
    return unread_count


## Generate a unique notification ID.
##
## Combines current time in milliseconds with a random component.
##
## @return Unique ID string
func _generate_notification_id() -> String:
    var time_ms: int = Time.get_ticks_msec()
    var random_part: int = randi() % 10000
    return "%d_%d" % [time_ms, random_part]


## Check if two users are friends.
##
## @param username1: First user's username
## @param username2: Second user's username
## @return true if users are friends, false otherwise
func are_friends(username1: String, username2: String) -> bool:
    # Check if first user exists
    if not user_exists(username1):
        return false
    
    # Check if user has friends array
    if not _users[username1].has("friends"):
        return false
    
    # Check if username2 is in username1's friends array
    return username2 in _users[username1].friends


## Add a bidirectional friendship between two users.
##
## Creates friendship in both directions and prevents duplicates and self-friending.
##
## @param username: First user's username
## @param friend_username: Second user's username to befriend
func add_friend(username: String, friend_username: String) -> void:
    # Validate both users exist
    if not user_exists(username):
        push_error("Cannot add friend: user '%s' does not exist" % username)
        return
    
    if not user_exists(friend_username):
        push_error("Cannot add friend: user '%s' does not exist" % friend_username)
        return
    
    # Prevent self-friending
    if username == friend_username:
        push_error("Cannot add friend: users cannot friend themselves")
        return
    
    # Check if already friends
    if are_friends(username, friend_username):
        push_warning("Users '%s' and '%s' are already friends" % [username, friend_username])
        return
    
    # Ensure both users have friends array
    if not _users[username].has("friends"):
        _users[username].friends = []
    
    if not _users[friend_username].has("friends"):
        _users[friend_username].friends = []
    
    # Add bidirectional friendship
    _users[username].friends.append(friend_username)
    _users[friend_username].friends.append(username)
    
    # Save to database
    _save_database()
    
    print("Friendship created: %s <-> %s" % [username, friend_username])


## Remove a bidirectional friendship between two users.
##
## Removes friendship from both users' friends arrays.
##
## @param username: First user's username
## @param friend_username: Second user's username to unfriend
func remove_friend(username: String, friend_username: String) -> void:
    # Validate both users exist (silent return if not)
    if not user_exists(username) or not user_exists(friend_username):
        return
    
    # Ensure both users have friends array
    if not _users[username].has("friends"):
        _users[username].friends = []
    
    if not _users[friend_username].has("friends"):
        _users[friend_username].friends = []
    
    # Remove from both sides
    if friend_username in _users[username].friends:
        _users[username].friends.erase(friend_username)
    
    if username in _users[friend_username].friends:
        _users[friend_username].friends.erase(username)
    
    # Save to database
    _save_database()
    
    print("Friendship removed: %s <-> %s" % [username, friend_username])


## Get list of friends with full user data.
##
## Returns array of friend dictionaries containing username, email, and avatar_path.
## Skips friends who no longer exist in the database.
##
## @param username: Username to get friends for
## @return Array of friend data dictionaries, or empty array if user doesn't exist
func get_friends(username: String) -> Array:
    # Validate user exists
    if not user_exists(username):
        push_error("Cannot get friends: user '%s' does not exist" % username)
        return []
    
    # Check if user has friends array
    if not _users[username].has("friends"):
        return []
    
    var results: Array = []
    var friends_list: Array = _users[username].friends
    
    # Get full data for each friend
    for friend_username: String in friends_list:
        var friend_data: Dictionary = get_user_by_username(friend_username)
        
        # Skip if friend no longer exists (deleted user)
        if friend_data.is_empty():
            continue
        
        results.append(friend_data)
    
    return results


## ============================================================================
## Multiplayer Match Management
## ============================================================================

## Create a new multiplayer match between two players
##
## @param inviter: Username who sent the invitation
## @param invitee: Username who accepted the invitation
## @param rounds: Number of rounds to play
## @param questions: Number of questions per round
## @return match_id: Unique identifier for the created match
func create_match(inviter: String, invitee: String, rounds: int, questions: int) -> String:
    var match_id = "match_%d" % Time.get_unix_time_from_system()
    
    var match_data = {
        "match_id": match_id,
        "players": [inviter, invitee],
        "inviter": inviter,
        "config": {
            "rounds": rounds,
            "questions": questions
        },
        "current_turn": inviter,  # Inviter always starts
        "current_round": 1,
        "status": "active",
        "dismissed_by": [],  # Track which players have dismissed the finished match
        "stats_processed": false,  # Track if statistics have been updated
        "rounds_data": [],
        "created_at": Time.get_unix_time_from_system()
    }
    
    # Initialize rounds_data with empty structures
    for i in range(rounds):
        var round_data = {
            "round_number": i + 1,
            "category": "",
            "category_chooser": inviter if (i + 1) % 2 == 1 else invitee,
            "questions": [],
            "player_answers": {
                inviter: {
                    "answered": false,
                    "results": []
                },
                invitee: {
                    "answered": false,
                    "results": []
                }
            }
        }
        match_data.rounds_data.append(round_data)
    
    data.multiplayer_matches.append(match_data)
    _save_database()
    
    return match_id


## Retrieve a specific match by ID
##
## @param match_id: Unique identifier of the match
## @return Dictionary: Match data, or empty Dictionary if not found
func get_match(match_id: String) -> Dictionary:
    for match in data.multiplayer_matches:
        if match.match_id == match_id:
            return match
    
    push_warning("Match not found: %s" % match_id)
    return {}


## Get all active matches for a specific player
##
## @param username: Player's username
## @return Array[Dictionary]: List of active matches where player is participant
func get_active_matches_for_player(username: String) -> Array:
    var player_matches: Array = []
    
    for match in data.multiplayer_matches:
        if match.status == "active" and username in match.players:
            player_matches.append(match)
    
    return player_matches


## Get all matches (active and finished) for a specific player
##
## Unlike get_active_matches_for_player(), this returns matches regardless of status.
## Useful for displaying finished matches that haven't been dismissed yet.
##
## @param username: Player's username
## @return Array[Dictionary]: List of all matches where player is participant
func get_all_matches_for_player(username: String) -> Array:
    var player_matches: Array = []
    
    for match in data.multiplayer_matches:
        if username in match.players:
            player_matches.append(match)
    
    return player_matches


## Update an existing match with new data
##
## @param match_data: Complete match Dictionary with updated fields
func update_match(match_data: Dictionary) -> void:
    if not match_data.has("match_id"):
        push_error("Cannot update match: missing match_id")
        return
    
    for i in range(data.multiplayer_matches.size()):
        if data.multiplayer_matches[i].match_id == match_data.match_id:
            data.multiplayer_matches[i] = match_data
            _save_database()
            return
    
    push_warning("Match not found for update: %s" % match_data.match_id)


## Delete a match from the database
##
## @param match_id: Unique identifier of the match to delete
## @return bool: true if match was deleted, false if not found
func delete_match(match_id: String) -> bool:
    for i in range(data.multiplayer_matches.size()):
        if data.multiplayer_matches[i].match_id == match_id:
            data.multiplayer_matches.remove_at(i)
            _save_database()
            print("Match deleted: %s" % match_id)
            return true
    
    push_warning("Match not found for deletion: %s" % match_id)
    return false


## Handle game invite acceptance by creating a match
##
## Extracts rounds/questions from the most recent game invite notification
## for the invitee and creates a persistent match entry.
##
## @param inviter_username: Username who sent the invite
## @param invitee_username: Username who accepted the invite
func _on_game_invite_accepted(inviter_username: String, invitee_username: String) -> void:
    # Find the notification with game invite data
    var notifications = get_notifications(invitee_username)
    var rounds = 3  # Default fallback
    var questions = 2  # Default fallback
    
    for notification in notifications:
        if notification.has("action_data") and notification.action_data.get("type") == "game_invite":
            if notification.action_data.get("inviter_id") == inviter_username:
                rounds = notification.action_data.get("rounds", 3)
                questions = notification.action_data.get("questions", 2)
                break
    
    # Create the match
    var match_id = create_match(inviter_username, invitee_username, rounds, questions)
    print("Match created: %s between %s and %s (%d rounds, %d questions)" % [
        match_id, inviter_username, invitee_username, rounds, questions
    ])
    
    # Emit signal to notify UI of new match
    GlobalSignalBus.match_created.emit(match_id, inviter_username, invitee_username)


## ============================================================================
## Player Statistics Management
## ============================================================================

## Update player statistics after a multiplayer match completes.
##
## Calculates winner/loser based on correct answers, updates wins/losses/streaks,
## tracks friend-specific wins, and emits signals for UI updates.
## Uses stats_processed flag to ensure single execution per match.
##
## @param match_data: Complete match Dictionary with results for both players
func update_player_statistics(match_data: Dictionary) -> void:
    # Validate match data
    if not match_data.has("match_id"):
        push_error("Cannot update statistics: missing match_id")
        return
    
    if not match_data.has("players") or match_data.players.size() != 2:
        push_error("Cannot update statistics: invalid players array")
        return
    
    # Check if statistics already processed
    if match_data.get("stats_processed", false):
        push_warning("Statistics already processed for match %s" % match_data.match_id)
        return
    
    # Calculate winner
    var result: Dictionary = _calculate_match_winner(match_data)
    
    if result.is_draw:
        # Draw - no stats change, but mark as processed
        print("Match %s ended in draw - no statistics updated" % match_data.match_id)
        match_data.stats_processed = true
        update_match(match_data)
        return
    
    var winner: String = result.winner
    var loser: String = result.loser
    
    # Verify both users exist
    if not user_exists(winner):
        push_error("Cannot update statistics: winner '%s' not found" % winner)
        return
    
    if not user_exists(loser):
        push_error("Cannot update statistics: loser '%s' not found" % loser)
        return
    
    # Update winner statistics
    _users[winner].wins += 1
    _users[winner].current_streak += 1
    
    # Update loser statistics
    _users[loser].losses += 1
    _users[loser].current_streak = 0
    
    # Update friend wins if players are friends
    if are_friends(winner, loser):
        if not _users[winner].has("friend_wins"):
            _users[winner].friend_wins = {}
        
        var current_friend_wins: int = _users[winner].friend_wins.get(loser, 0)
        _users[winner].friend_wins[loser] = current_friend_wins + 1
        
        print("Friend win recorded: %s now has %d wins vs %s" % [winner, _users[winner].friend_wins[loser], loser])
    
    # Mark statistics as processed
    match_data.stats_processed = true
    
    # Save changes
    _save_database()
    update_match(match_data)
    
    # Emit signals for both players
    GlobalSignalBus.player_stats_updated.emit(winner)
    GlobalSignalBus.player_stats_updated.emit(loser)
    
    print("Statistics updated for match %s: %s won, %s lost" % [match_data.match_id, winner, loser])


## Calculate the winner of a completed match based on total correct answers.
##
## @param match_data: Complete match Dictionary with player answers
## @return Dictionary with winner, loser, and is_draw fields
func _calculate_match_winner(match_data: Dictionary) -> Dictionary:
    var players: Array = match_data.players
    var player1: String = players[0]
    var player2: String = players[1]
    
    var score1: int = 0
    var score2: int = 0
    
    # Count correct answers across all rounds
    for round_data: Dictionary in match_data.rounds_data:
        # Count player1 correct answers
        if round_data.player_answers.has(player1):
            var p1_results: Array = round_data.player_answers[player1].get("results", [])
            for result: Dictionary in p1_results:
                if result.get("was_correct", false):
                    score1 += 1
        
        # Count player2 correct answers
        if round_data.player_answers.has(player2):
            var p2_results: Array = round_data.player_answers[player2].get("results", [])
            for result: Dictionary in p2_results:
                if result.get("was_correct", false):
                    score2 += 1
    
    # Determine winner
    if score1 > score2:
        return {"winner": player1, "loser": player2, "is_draw": false}
    elif score2 > score1:
        return {"winner": player2, "loser": player1, "is_draw": false}
    else:
        return {"winner": "", "loser": "", "is_draw": true}


## Save the user database to a JSON file.
func _save_database() -> void:
    # Convert data dictionary to JSON
    var json_string: String = JSON.stringify(data, "\t")
    
    # Open file for writing
    var file: FileAccess = FileAccess.open(DATABASE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Failed to save user database: " + str(FileAccess.get_open_error()))
        return
    
    # Write JSON data to file
    file.store_string(json_string)
    file.close()


## Load the user database from a JSON file.
## Creates a new empty database file if it doesn't exist.
func _load_database() -> void:
    # Check if file exists
    if not FileAccess.file_exists(DATABASE_PATH):
        print("User database not found, creating new database at: " + DATABASE_PATH)
        data = {
            "users": {},
            "multiplayer_matches": []
        }
        _save_database()
        return
    
    # Open file for reading
    var file: FileAccess = FileAccess.open(DATABASE_PATH, FileAccess.READ)
    if file == null:
        push_error("Failed to load user database: " + str(FileAccess.get_open_error()))
        data = {
            "users": {},
            "multiplayer_matches": []
        }
        return
    
    # Read and parse JSON data
    var json_string: String = file.get_as_text()
    file.close()
    
    # Parse JSON
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    
    if parse_result != OK:
        push_error("Failed to parse user database JSON: " + json.get_error_message())
        data = {
            "users": {},
            "multiplayer_matches": []
        }
        return
    
    # Load parsed data
    var loaded_data: Variant = json.data
    if loaded_data is Dictionary:
        # Check if this is old format (direct user dictionary) or new format
        if loaded_data.has("users") and loaded_data.has("multiplayer_matches"):
            # New format
            data = loaded_data
        else:
            # Old format - migrate
            print("Migrating database from old format to new format")
            data = {
                "users": loaded_data,
                "multiplayer_matches": []
            }
        _migrate_user_data()
        print("User database loaded successfully. Users: " + str(data.users.size()))
    else:
        push_error("User database JSON is not a valid dictionary")
        data = {
            "users": {},
            "multiplayer_matches": []
        }


## Migrate existing user data to include new fields.
##
## Adds wins, losses, current_streak, friend_wins, category_stats fields with default values 
## to existing users that don't have these fields. Ensures backward compatibility.
func _migrate_user_data() -> void:
    var migrated_count: int = 0
    
    for username: String in _users.keys():
        var user_data: Dictionary = _users[username]
        var needs_migration: bool = false
        
        # Add wins field if missing
        if not user_data.has("wins"):
            user_data.wins = 0
            needs_migration = true
        
        # Add losses field if missing
        if not user_data.has("losses"):
            user_data.losses = 0
            needs_migration = true
        
        # Add current_streak field if missing
        if not user_data.has("current_streak"):
            user_data.current_streak = 0
            needs_migration = true
        
        # Add friend_wins field if missing
        if not user_data.has("friend_wins"):
            user_data.friend_wins = {}
            needs_migration = true
        
        # Add category_stats field if missing
        # TODO: Replace placeholder data with real category tracking from gameplay_screen match completion
        if not user_data.has("category_stats"):
            user_data.category_stats = {}
            needs_migration = true
        
        if needs_migration:
            migrated_count += 1
    
    # Save if any users were migrated
    if migrated_count > 0:
        _save_database()
        print("Migrated %d users to include statistics fields" % migrated_count)


## Generate placeholder category statistics for testing.
##
## TODO: Replace with real category tracking from gameplay_screen match completion.
## This function generates random play counts for 3 random categories to allow UI testing
## before real gameplay tracking is implemented.
##
## @return Dictionary mapping category names to play counts (1-20)
func _generate_placeholder_category_stats() -> Dictionary:
    # TODO: Replace with real category tracking from gameplay_screen match completion
    var categories: Array[String] = ["General Knowledge", "Entertainment", "Science", "History", "Geography", "Sports"]
    var stats: Dictionary = {}
    
    # Pick 3 random categories with random play counts
    var selected_categories: Array[String] = categories.duplicate()
    selected_categories.shuffle()
    
    for i in range(3):
        if i < selected_categories.size():
            var category: String = selected_categories[i]
            stats[category] = randi() % 20 + 1  # Random count 1-20
    
    return stats

