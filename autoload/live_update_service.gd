# uid://crrh4ygbv7emx
extends Node
## LiveUpdateService
##
## Polls the signed-in user's notifications, friends and matches and publishes
## GlobalSignalBus change signals when remote data differs from the last snapshot.
## Kept separate from UserDatabase, which stays a pure data-access layer.

## Seconds between polls while signed in and focused.
const POLL_INTERVAL: float = 5.0
## Upper bound for the backed-off interval after consecutive failures.
const MAX_BACKOFF_INTERVAL: float = 30.0

var _timer: Timer
var _polling: bool = false
var _poll_failed: bool = false
var _failures: int = 0
var _has_focus: bool = true
var _snapshot_user: String = ""
var _baseline_ready: bool = false
var _notification_ids: Dictionary = {}
var _friend_names: Dictionary = {}
var _match_hashes: Dictionary = {}
var _was_searching: bool = false


func _ready() -> void:
    Firebase.Firestore.error.connect(_on_firestore_error)
    _timer = Timer.new()
    _timer.wait_time = POLL_INTERVAL
    _timer.one_shot = true
    _timer.timeout.connect(_on_timer_timeout)
    add_child(_timer)
    _timer.start()


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _has_focus = false
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        _has_focus = true
        _timer.stop()
        _on_timer_timeout()


func _on_firestore_error(_error: Variant = null, _status: Variant = null, _message: Variant = null) -> void:
    if _polling:
        _poll_failed = true


func _on_timer_timeout() -> void:
    await poll_now()
    var interval: float = minf(POLL_INTERVAL * pow(2.0, _failures), MAX_BACKOFF_INTERVAL)
    _timer.start(interval)


## Run one poll cycle. Skipped when signed out, unfocused or already polling.
func poll_now() -> void:
    if _polling or not _has_focus or not UserDatabase.is_signed_in():
        return
    _polling = true
    _poll_failed = false
    var username: String = UserDatabase.current_user.username
    if username != _snapshot_user:
        _snapshot_user = username
        _baseline_ready = false

    var notifications: Array = await UserDatabase.get_notifications(username)
    var friends: Array = await UserDatabase.get_friends(username)
    var matches: Array = await UserDatabase.get_all_matches_for_player(username)
    var searching: bool = await UserDatabase.has_random_search()
    _polling = false

    # Query helpers return [] on errors, so a failed poll must be discarded.
    if _poll_failed or not UserDatabase.is_signed_in() or UserDatabase.current_user.username != username:
        _failures += 1
        return
    _failures = 0
    _apply_results(notifications, friends, matches, searching)


func _apply_results(notifications: Array, friends: Array, matches: Array, searching: bool = false) -> void:
    var notification_map: Dictionary = {}
    for item: Dictionary in notifications:
        notification_map[str(item.get("id", ""))] = item
    var friend_map: Dictionary = {}
    for item: Dictionary in friends:
        friend_map[str(item.get("username", ""))] = true
    var match_map: Dictionary = {}
    for item: Dictionary in matches:
        match_map[str(item.get("match_id", ""))] = item.hash()

    if _baseline_ready:
        var notif_diff: Dictionary = diff_notifications(_notification_ids, notification_map)
        if not notif_diff.added.is_empty() or not notif_diff.removed.is_empty():
            GlobalSignalBus.notifications_changed.emit(notif_diff.added, notif_diff.removed)
        if not _same_keys(_friend_names, friend_map):
            GlobalSignalBus.friends_changed.emit()
        if match_map != _match_hashes or searching != _was_searching:
            GlobalSignalBus.matches_changed.emit()

    _notification_ids = notification_map
    _friend_names = friend_map
    _match_hashes = match_map
    _was_searching = searching
    _baseline_ready = true


func _same_keys(a: Dictionary, b: Dictionary) -> bool:
    for key: Variant in a:
        if not b.has(key):
            return false
    return a.size() == b.size()


## Compare two id -> notification maps.
## [param old_map] Previous snapshot; values are ignored.
## [param new_map] Current snapshot keyed by notification id.
## [return] {added: Array[Dictionary], removed: Array[String]}
static func diff_notifications(old_map: Dictionary, new_map: Dictionary) -> Dictionary:
    var added: Array = []
    var removed: Array = []
    for id: Variant in new_map:
        if not old_map.has(id):
            added.append(new_map[id])
    for id: Variant in old_map:
        if not new_map.has(id):
            removed.append(str(id))
    return {"added": added, "removed": removed}
