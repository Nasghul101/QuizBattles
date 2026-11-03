# uid://dg5ln3kx7q2ab
extends Node

## Google Sign-In Service
##
## Thin wrapper around the GodotGoogleSignIn Android plugin. Only available on Android
## builds that include the plugin; everywhere else is_available() returns false.
## Results use the same shape as UserDatabase: {success: bool, ...} or
## {success: false, error_code: String, message: String}.

const PLUGIN_NAME := "GodotGoogleSignIn"
const SETTING_WEB_CLIENT_ID := "google_sign_in/web_client_id"
const SIGN_IN_TIMEOUT_SECONDS := 120.0

var _plugin: Object = null
var _initialized: bool = false
var _pending: SignInWait = null


class SignInWait extends RefCounted:
    signal finished
    var result: Dictionary = {}

    func on_success(id_token: String, email: String, display_name: String) -> void:
        result = {"success": true, "id_token": id_token, "email": email, "display_name": display_name}
        finished.emit()

    func on_failed(error: String) -> void:
        result = {"success": false, "error_code": "GOOGLE_SIGN_IN_FAILED", "message": error}
        finished.emit()

    func on_timeout() -> void:
        finished.emit()


func _ready() -> void:
    if OS.get_name() == "Android" and Engine.has_singleton(PLUGIN_NAME):
        _plugin = Engine.get_singleton(PLUGIN_NAME)


## True only on Android with the GodotGoogleSignIn plugin loaded.
func is_available() -> bool:
    return _plugin != null


func get_web_client_id() -> String:
    return str(ProjectSettings.get_setting(SETTING_WEB_CLIENT_ID, "")).strip_edges()


## Shows the Google account chooser and returns {success, id_token, email, display_name}.
func sign_in() -> Dictionary:
    if not is_available():
        return _fail("GOOGLE_UNAVAILABLE", "Google Sign-In is not available on this platform")
    if _pending != null:
        return _fail("GOOGLE_BUSY", "A Google sign-in is already in progress")

    var web_client_id: String = get_web_client_id()
    if web_client_id.is_empty():
        push_error("Google Sign-In is not configured: set '%s' in the project settings" % SETTING_WEB_CLIENT_ID)
        return _fail("GOOGLE_NOT_CONFIGURED", "Google Sign-In is not configured")

    if not _initialized:
        _plugin.initialize(web_client_id)
        _initialized = true

    var wait := SignInWait.new()
    _pending = wait
    _plugin.connect("sign_in_success", wait.on_success, CONNECT_ONE_SHOT)
    _plugin.connect("sign_in_failed", wait.on_failed, CONNECT_ONE_SHOT)
    _plugin.signInWithGoogleButton()
    get_tree().create_timer(SIGN_IN_TIMEOUT_SECONDS).timeout.connect(wait.on_timeout)
    await wait.finished

    if _plugin.is_connected("sign_in_success", wait.on_success):
        _plugin.disconnect("sign_in_success", wait.on_success)
    if _plugin.is_connected("sign_in_failed", wait.on_failed):
        _plugin.disconnect("sign_in_failed", wait.on_failed)
    _pending = null

    if wait.result.is_empty():
        return _fail("GOOGLE_TIMEOUT", "Google sign-in did not respond")
    return wait.result


func _fail(error_code: String, message: String) -> Dictionary:
    return {"success": false, "error_code": error_code, "message": message}
