extends Node

## Local Device Cache Service
##
## Stores per-device state that should persist across launches: the last
## remembered login (for auto sign-in) and in-game settings. Unlike
## UserDatabase (which simulates a shared backend of all accounts), this
## autoload only ever concerns itself with this specific device.
##
## Storage is a single JSON dictionary written to user:// with Godot's
## built-in encrypted FileAccess API. The passphrase is embedded in the
## binary, so this only obfuscates the file from casual inspection - it is
## not real secret storage, matching UserDatabase's temporary, pre-Firebase
## security posture.
##
## IMPORTANT: This autoload must be registered after UserDatabase in
## project.godot so UserDatabase has already loaded its user records before
## the automatic sign-in attempt below runs.
##
## This cache is permanently device-local: it is never synced to a server
## or database and is out of scope for the future Firebase migration. It is
## not shipped with the app - the file only ever exists once created at
## runtime on the player's device. On a new device, players start with no
## remembered login and default settings by design.

## Path to the encrypted cache file
const DATABASE_PATH := "user://local_cache.dat"

## Passphrase used to encrypt/decrypt the cache file (obfuscation only)
const PASSPHRASE := "quizduell_local_cache_v1"

## Default settings applied to a freshly created cache
const DEFAULT_SETTINGS := {
    "music_volume": 1.0,
    "sfx_volume": 1.0,
    "notifications_enabled": true
}

## In-memory cache state
var data: Dictionary = {
    "remembered_login": {},
    "settings": DEFAULT_SETTINGS.duplicate()
}


func _ready() -> void:
    _load_cache()
    _attempt_auto_sign_in()


## Load the cache file from disk, or create a fresh default one if missing/corrupt.
func _load_cache() -> void:
    if not FileAccess.file_exists(DATABASE_PATH):
        _save_cache()
        return

    var file: FileAccess = FileAccess.open_encrypted_with_pass(DATABASE_PATH, FileAccess.READ, PASSPHRASE)
    if file == null:
        push_warning("LocalCache: Failed to open cache file, recreating defaults: %s" % str(FileAccess.get_open_error()))
        _reset_to_defaults()
        return

    var json_string: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(json_string) != OK:
        push_warning("LocalCache: Failed to parse cache file, recreating defaults: %s" % json.get_error_message())
        _reset_to_defaults()
        return

    if typeof(json.data) != TYPE_DICTIONARY:
        push_warning("LocalCache: Cache file did not contain a dictionary, recreating defaults")
        _reset_to_defaults()
        return

    var loaded: Dictionary = json.data
    data.remembered_login = loaded.get("remembered_login", {})
    data.settings = DEFAULT_SETTINGS.duplicate()
    data.settings.merge(loaded.get("settings", {}), true)


## Reset in-memory state to defaults and persist it, overwriting a corrupt file.
func _reset_to_defaults() -> void:
    data = {
        "remembered_login": {},
        "settings": DEFAULT_SETTINGS.duplicate()
    }
    _save_cache()


## Persist the current in-memory state to the encrypted cache file.
func _save_cache() -> void:
    var file: FileAccess = FileAccess.open_encrypted_with_pass(DATABASE_PATH, FileAccess.WRITE, PASSPHRASE)
    if file == null:
        push_error("LocalCache: Failed to save cache file: %s" % str(FileAccess.get_open_error()))
        return

    file.store_string(JSON.stringify(data))
    file.close()


## Attempt to silently sign in the remembered user, if any, via UserDatabase.
##
## Reuses UserDatabase.sign_in() so a password change since the credentials
## were cached naturally invalidates auto sign-in (the stored password will
## no longer match the account's current password hash).
func _attempt_auto_sign_in() -> void:
    var remembered: Dictionary = data.remembered_login
    if remembered.is_empty():
        return

    var username: String = remembered.get("username", "")
    var password: String = remembered.get("password", "")

    var result: Dictionary = UserDatabase.sign_in(username, password)
    if result.success:
        print("LocalCache: Auto signed in as %s" % username)
    else:
        print("LocalCache: Remembered login is no longer valid, forgetting it (%s)" % result.get("error_code", ""))
        forget_login()


## Remember login credentials for auto sign-in on future launches.
##
## @param username: Username that was just signed in/registered
## @param password: Password used for that sign-in/registration
func remember_login(username: String, password: String) -> void:
    data.remembered_login = {
        "username": username,
        "password": password
    }
    _save_cache()


## Clear any remembered login credentials.
func forget_login() -> void:
    data.remembered_login = {}
    _save_cache()


## Get a settings value, falling back to the provided default if not set.
##
## @param key: Settings key to look up
## @param default: Value to return if the key does not exist
func get_setting(key: String, default: Variant) -> Variant:
    return data.settings.get(key, default)


## Set a settings value and persist it immediately.
##
## @param key: Settings key to set
## @param value: New value to store
func set_setting(key: String, value: Variant) -> void:
    data.settings[key] = value
    _save_cache()
