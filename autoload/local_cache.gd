extends Node

## Local Device Cache Service
##
## Stores per-device settings that should persist across launches and restores the
## Firebase Auth session of the previous launch. Unlike UserDatabase (the shared
## Firebase backend of all accounts), this autoload only concerns this device.
##
## Settings are a single JSON dictionary written to user:// with Godot's built-in
## encrypted FileAccess API (obfuscation only, not secret storage). Login sessions
## are stored by the GodotFirebase plugin in its own encrypted auth file
## (user://user.auth); no password is ever stored on the device.
##
## IMPORTANT: This autoload must be registered after Firebase and UserDatabase in
## project.godot so both are ready before the session restore below runs.
##
## This cache is permanently device-local: it is never synced to a server.

## Emitted once the startup session restore has finished (success or not)
signal session_restore_finished(success: bool)

## Path to the encrypted cache file
const DATABASE_PATH := "user://local_cache.dat"

## Passphrase used to encrypt/decrypt the cache file (obfuscation only)
const PASSPHRASE := "quizduell_local_cache_v1"

## Default settings applied to a freshly created cache
## "locale" is empty until the player explicitly picks one; empty means
## "not chosen yet" so startup falls back to OS locale detection.
const DEFAULT_SETTINGS := {
    "music_volume": 1.0,
    "sfx_volume": 1.0,
    "notifications_enabled": true,
    "locale": ""
}

## In-memory cache state
var data: Dictionary = {
    "settings": DEFAULT_SETTINGS.duplicate()
}

## True once the startup session restore has finished
var session_restore_done: bool = false


func _ready() -> void:
    _load_cache()
    _restore_session()


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
    data.settings = DEFAULT_SETTINGS.duplicate()
    data.settings.merge(loaded.get("settings", {}), true)

    # Discard credentials remembered by earlier versions; they are not migrated to Firebase.
    if loaded.has("remembered_login"):
        _save_cache()


## Reset in-memory state to defaults and persist it, overwriting a corrupt file.
func _reset_to_defaults() -> void:
    data = {
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


## Silently restore the Firebase Auth session of the previous launch, if any.
func _restore_session() -> void:
    var result: Dictionary = await UserDatabase.restore_session()
    if result.success:
        print("LocalCache: Restored session for %s" % UserDatabase.current_user.username)
    elif result.get("error_code") != "NO_SESSION":
        push_warning("LocalCache: Stored session could not be restored (%s): %s" % [
            result.get("error_code", "UNKNOWN"),
            result.get("message", "No error details returned")
        ])
        forget_session()
    session_restore_done = true
    session_restore_finished.emit(result.success)


## Remember the current Firebase session for auto sign-in on future launches.
func remember_session() -> bool:
    return UserDatabase.remember_session()


## Forget the stored Firebase session.
func forget_session() -> void:
    if FileAccess.file_exists("user://user.auth"):
        Firebase.Auth.remove_auth()


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
