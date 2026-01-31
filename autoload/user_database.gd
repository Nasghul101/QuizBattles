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

## In-memory user storage: Dictionary mapping username -> user data
var _users: Dictionary = {}

## Currently logged-in user (empty Dictionary if not signed in)
var current_user: Dictionary = {}


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
        "avatar_path": DEFAULT_AVATAR_PATH
    }
    _users[username] = user_data
    
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
    
    # Update avatar_path in current session
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
