# uid://cc1ahmri317sm
extends Node

## Firebase-backed User Database Service
##
## Provides registration, authentication, profiles, notifications, friendships,
## matches and statistics on top of Firebase Authentication, Cloud Firestore and
## Cloud Functions (GodotFirebase plugin). In development and test runs the plugin
## talks to the Firebase Local Emulator Suite only.
##
## Almost every method talks to the network and must be awaited. Failures are returned
## as {success: false, error_code: String, message: String}; no failure is replaced by
## local or cached data.

## Minimum username length
const MIN_USERNAME_LENGTH := 5

## Maximum username length
const MAX_USERNAME_LENGTH := 15

## Default avatar path for new users
const DEFAULT_AVATAR_PATH := "res://assets/profile_pictures/man_standard.png"

## Notifications older than this are hidden and cleaned up (3 days)
const NOTIFICATION_EXPIRY_SECONDS: float = 259200.0

## Maximum number of username search results
const SEARCH_LIMIT := 20

## Cloud Function that applies the statistics of a finished match
const STATISTICS_FUNCTION := "processMatchStatistics"

const AUTH_TIMEOUT_SECONDS := 20.0

## Currently logged-in user: {uid, username, email, avatar_path} (empty if not signed in)
var current_user: Dictionary = {}

var _uid_cache: Dictionary = {}
var _fs_busy: bool = false
var _last_error: Dictionary = {}

signal _fs_released


class AuthWait extends RefCounted:
    signal finished
    var result: Array = []

    func on_result(code: Variant, content: Variant) -> void:
        result = [code, content]
        finished.emit()

    func on_timeout() -> void:
        finished.emit()


func _ready() -> void:
    Firebase.Firestore.error.connect(_on_firestore_error)
    GlobalSignalBus.notification_received.connect(_on_notification_received_global)
    GlobalSignalBus.notification_action_taken.connect(_on_notification_action_taken)


func _on_firestore_error(error: Variant = {}, _status: Variant = null, _message: Variant = null) -> void:
    if error is Dictionary:
        _last_error = error
    else:
        _last_error = {"code": error, "status": str(_status), "message": str(_message)}


## ============================================================================
## Firestore primitives (serialized so error reporting cannot be mixed up)
## ============================================================================

func _lock() -> void:
    while _fs_busy:
        await _fs_released
    _fs_busy = true
    _last_error = {}


func _unlock() -> void:
    _fs_busy = false
    _fs_released.emit()


func _result(ok: bool, data: Variant = null) -> Dictionary:
    return {
        "ok": ok,
        "data": data,
        "status": str(_last_error.get("status", "")),
        "message": str(_last_error.get("message", "Backend request failed"))
    }


func _doc_data(doc: FirestoreDocument) -> Dictionary:
    return Utilities.fields2dict({"fields": doc.document})


## Username-derived document IDs are percent-encoded so any character is URL safe.
func _doc_id(normalized_username: String) -> String:
    return normalized_username.uri_encode()


func _fs_get(collection: String, doc_id: String) -> Dictionary:
    await _lock()
    var doc: Variant = await Firebase.Firestore.collection(collection).get_doc(doc_id)
    var ok: bool = doc != null and _last_error.is_empty()
    var res: Dictionary = _result(ok, _doc_data(doc) if ok else {})
    _unlock()
    return res


func _fs_create(collection: String, doc_id: String, data: Dictionary) -> Dictionary:
    await _lock()
    var doc: Variant = await Firebase.Firestore.collection(collection).add(doc_id, data)
    var res: Dictionary = _result(doc != null and _last_error.is_empty())
    _unlock()
    return res


func _fs_set(collection: String, doc_id: String, data: Dictionary) -> Dictionary:
    await _lock()
    await Firebase.Firestore.collection(collection).set_doc(doc_id, data)
    var res: Dictionary = _result(_last_error.is_empty())
    _unlock()
    return res


func _fs_patch(collection: String, doc_id: String, partial: Dictionary) -> Dictionary:
    await _lock()
    var doc := FirestoreDocument.new({"name": doc_id, "fields": Utilities.dict2fields(partial).fields})
    doc.collection_name = collection
    var updated: Variant = await Firebase.Firestore.collection(collection).update(doc)
    doc.free()
    var res: Dictionary = _result(updated != null and _last_error.is_empty())
    _unlock()
    return res


func _fs_delete(collection: String, doc_id: String) -> Dictionary:
    await _lock()
    var doc := FirestoreDocument.new({"name": doc_id})
    doc.collection_name = collection
    var deleted: Variant = await Firebase.Firestore.collection(collection).delete(doc)
    doc.free()
    var res: Dictionary = _result(bool(deleted) and _last_error.is_empty())
    _unlock()
    return res


## Returns {ok, data: Array[{id, data}], ...}
func _fs_query(query: FirestoreQuery) -> Dictionary:
    await _lock()
    var docs: Array = await Firebase.Firestore.query(query)
    var items: Array = []
    for doc: FirestoreDocument in docs:
        items.append({"id": doc.doc_name, "data": _doc_data(doc)})
        doc.free()
    var res: Dictionary = _result(_last_error.is_empty(), items)
    _unlock()
    return res


func _fail(error_code: String, message: String) -> Dictionary:
    return {"success": false, "error_code": error_code, "message": message}


func _backend_fail(res: Dictionary) -> Dictionary:
    var code: String = res.get("status", "")
    return _fail(code if not code.is_empty() else "BACKEND_ERROR", res.get("message", "Backend request failed"))


## ============================================================================
## Firebase Authentication helpers
## ============================================================================

## Starts a Firebase Auth request and waits for its auth_request signal.
## Returns {success: true, auth: Dictionary} or a failure dictionary.
func _auth_request(starter: Callable) -> Dictionary:
    if Firebase.Auth.is_busy:
        return _fail("AUTH_BUSY", "Authentication service is busy")

    var wait := AuthWait.new()
    Firebase.Auth.auth_request.connect(wait.on_result, CONNECT_ONE_SHOT)
    starter.call()
    if wait.result.is_empty():
        get_tree().create_timer(AUTH_TIMEOUT_SECONDS).timeout.connect(wait.on_timeout)
        await wait.finished
    if Firebase.Auth.auth_request.is_connected(wait.on_result):
        Firebase.Auth.auth_request.disconnect(wait.on_result)

    if wait.result.is_empty():
        return _fail("SERVICE_UNAVAILABLE", "Authentication service did not respond")

    var code: Variant = wait.result[0]
    var content: Variant = wait.result[1]
    if typeof(code) == TYPE_INT and code == 1:
        return {"success": true, "auth": content}

    var message: String = str(content)
    if message.contains("Error connecting"):
        return _fail("SERVICE_UNAVAILABLE", message)
    # Firebase messages look like "WEAK_PASSWORD : Password should be ..."
    var error_code: String = message.split(" ")[0] if not message.is_empty() else "AUTH_ERROR"
    return _fail(error_code, message)


func _current_uid() -> String:
    return str(Firebase.Auth.auth.get("localid", ""))


## ============================================================================
## Registration, sign-in and session
## ============================================================================

## Create a Firebase Auth account and its Firestore profile.
##
## Success is reported only after the Auth account, the unique username claim and the
## profile exist. If a later step fails, earlier steps are rolled back.
##
## @return {success: true, user: {username, email, avatar_path}} or a failure dictionary
func create_user(username: String, password: String, email: String) -> Dictionary:
    var username_validation: Dictionary = _validate_username(username)
    if not username_validation.success:
        return username_validation

    if email.strip_edges().is_empty():
        return _fail("INVALID_EMAIL", "Email is required")

    var signup: Dictionary = await _auth_request(
        func() -> void: Firebase.Auth.signup_with_email_and_password(email, password)
    )
    if not signup.success:
        return signup

    var uid: String = _current_uid()
    var normalized: String = username.to_lower()
    var claim: Dictionary = await _fs_create("usernames", _doc_id(normalized), {
        "uid": uid,
        "username": username,
        "username_normalized": normalized
    })
    if not claim.ok:
        await _discard_new_account("")
        if claim.status == "ALREADY_EXISTS":
            return _fail("USERNAME_EXISTS", "Username already exists")
        return _backend_fail(claim)

    var profile: Dictionary = await _fs_create("users", uid, {
        "uid": uid,
        "username": username,
        "username_normalized": normalized,
        "avatar_path": DEFAULT_AVATAR_PATH,
        "wins": 0,
        "losses": 0,
        "total_games": 0,
        "current_streak": 0,
        "friend_wins": {},
        "category_stats": {}
    })
    if not profile.ok:
        await _discard_new_account(_doc_id(normalized))
        return _backend_fail(profile)

    return {
        "success": true,
        "user": {
            "username": username,
            "email": email,
            "avatar_path": DEFAULT_AVATAR_PATH
        }
    }


## Rolls back a partially created registration (username claim first, then the Auth account).
func _discard_new_account(claim_id: String) -> void:
    if not claim_id.is_empty():
        var released: Dictionary = await _fs_delete("usernames", claim_id)
        if not released.ok:
            push_error("Could not release username claim after failed registration: %s" % released.message)
    var removed: Dictionary = await _auth_request(func() -> void: Firebase.Auth.delete_user_account())
    if not removed.success:
        push_error("Could not delete Auth account after failed registration: %s" % removed.message)
    Firebase.Auth.logout()


## Authenticate with email and password and load the Firestore profile.
##
## The current user session is set only after both steps succeed.
##
## @return {success: true, user: {username, email, avatar_path}} or a failure dictionary
func sign_in(email: String, password: String) -> Dictionary:
    var login: Dictionary = await _auth_request(
        func() -> void: Firebase.Auth.login_with_email_and_password(email, password)
    )
    if not login.success:
        return login
    return await _finish_sign_in(str(login.auth.get("email", email)))


## Restore the session stored in the encrypted GodotFirebase auth file.
func restore_session() -> Dictionary:
    if not FileAccess.file_exists("user://user.auth"):
        return _fail("NO_SESSION", "No stored session")

    var refreshed: Dictionary = await _auth_request(func() -> void: Firebase.Auth.load_auth())
    if not refreshed.success:
        Firebase.Auth.logout()
        return refreshed

    var holder: Dictionary = {"email": ""}
    var on_userdata: Callable = func(userdata: Variant) -> void: holder.email = str(userdata.email)
    Firebase.Auth.userdata_received.connect(on_userdata, CONNECT_ONE_SHOT)
    var userdata_request: Dictionary = await _auth_request(func() -> void: Firebase.Auth.get_user_data())
    if Firebase.Auth.userdata_received.is_connected(on_userdata):
        Firebase.Auth.userdata_received.disconnect(on_userdata)
    if not userdata_request.success:
        Firebase.Auth.logout()
        return userdata_request

    return await _finish_sign_in(holder.email)


func _finish_sign_in(email: String) -> Dictionary:
    var uid: String = _current_uid()
    var profile: Dictionary = await _fs_get("users", uid)
    if not profile.ok:
        Firebase.Auth.logout()
        if profile.status == "NOT_FOUND":
            return _fail("PROFILE_NOT_FOUND", "No user profile exists for this account")
        return _backend_fail(profile)

    current_user = {
        "uid": uid,
        "username": profile.data.get("username", ""),
        "email": email,
        "avatar_path": profile.data.get("avatar_path", DEFAULT_AVATAR_PATH)
    }
    return {"success": true, "user": get_current_user()}


## Persist the Firebase session in the encrypted GodotFirebase auth file.
func remember_session() -> bool:
    return Firebase.Auth.save_auth(Firebase.Auth.auth)


## Sign out the current user and clear the session.
func sign_out() -> void:
    current_user = {}
    _uid_cache.clear()
    Firebase.Auth.logout()


## Get the currently logged-in user (without uid), or an empty Dictionary.
func get_current_user() -> Dictionary:
    if current_user.is_empty():
        return {}
    var user: Dictionary = current_user.duplicate()
    user.erase("uid")
    return user


func is_signed_in() -> bool:
    return not current_user.is_empty()


## Update the avatar path of the signed-in user.
func update_avatar(avatar_path: String) -> Dictionary:
    if not is_signed_in():
        return _fail("NOT_SIGNED_IN", "No user is currently signed in")

    var res: Dictionary = await _fs_patch("users", current_user.uid, {"avatar_path": avatar_path})
    if not res.ok:
        return _backend_fail(res)

    current_user.avatar_path = avatar_path
    return {"success": true, "avatar_path": avatar_path}


## ============================================================================
## Profiles and search
## ============================================================================

## Resolve a username to its uid through the public username claim.
## Returns {ok, found, uid, username}; ok is false when the backend failed.
func _resolve_user(username: String) -> Dictionary:
    var normalized: String = username.to_lower()
    if is_signed_in() and current_user.username.to_lower() == normalized:
        return {"ok": true, "found": true, "uid": current_user.uid, "username": current_user.username}
    if _uid_cache.has(normalized):
        return _uid_cache[normalized]
    if normalized.is_empty():
        return {"ok": true, "found": false}

    var claim: Dictionary = await _fs_get("usernames", _doc_id(normalized))
    if claim.ok:
        var found: Dictionary = {
            "ok": true,
            "found": true,
            "uid": str(claim.data.get("uid", "")),
            "username": str(claim.data.get("username", username))
        }
        _uid_cache[normalized] = found
        return found
    if claim.status == "NOT_FOUND":
        return {"ok": true, "found": false}
    push_error("Could not resolve user '%s': %s" % [username, claim.message])
    return {"ok": false, "found": false, "message": claim.message, "status": claim.status}


func _public_profile(profile: Dictionary) -> Dictionary:
    return {
        "username": profile.get("username", ""),
        "avatar_path": profile.get("avatar_path", DEFAULT_AVATAR_PATH)
    }


func user_exists(username: String) -> bool:
    var user: Dictionary = await _resolve_user(username)
    return user.found


## Get public profile data (username, avatar_path) of a user, or an empty Dictionary.
func get_user_by_username(username: String) -> Dictionary:
    var profile: Dictionary = await _load_profile_by_username(username)
    if profile.is_empty():
        return {}
    return _public_profile(profile)


func _load_profile_by_username(username: String) -> Dictionary:
    var user: Dictionary = await _resolve_user(username)
    if not user.found:
        return {}
    var profile: Dictionary = await _fs_get("users", user.uid)
    if not profile.ok:
        push_error("Could not load profile of '%s': %s" % [username, profile.message])
        return {}
    return profile.data


## Get user data safe for display in UI (no email or credentials).
func get_user_data_for_display(username: String) -> Dictionary:
    var profile: Dictionary = await _load_profile_by_username(username)
    if profile.is_empty():
        return {}
    return {
        "username": profile.get("username", ""),
        "avatar_path": profile.get("avatar_path", DEFAULT_AVATAR_PATH),
        "wins": profile.get("wins", 0),
        "losses": profile.get("losses", 0),
        "total_games": profile.get("total_games", 0),
        "current_streak": profile.get("current_streak", 0),
        "friend_wins": profile.get("friend_wins", {}),
        "category_stats": profile.get("category_stats", {})
    }


## Search users whose username starts with the query (case-insensitive).
## Firestore has no substring queries, so only prefixes are matched.
## The signed-in user is excluded.
##
## @return Array of {username, avatar_path}
func search_users_by_username(query: String) -> Array:
    var results: Array = []
    if query.is_empty():
        return results

    var prefix: String = query.to_lower()
    var firestore_query: FirestoreQuery = FirestoreQuery.new() \
        .from("users") \
        .order_by("username_normalized") \
        .limit(SEARCH_LIMIT + 1)
    # FirestoreQuery.where() drops the first filter when chaining AND onto a single filter
    firestore_query.query["where"] = firestore_query.create_composite_filter(FirestoreQuery.OPERATOR.AND, [
        firestore_query.create_field_filter("username_normalized", FirestoreQuery.OPERATOR.GREATER_THAN_OR_EQUAL, prefix),
        firestore_query.create_field_filter("username_normalized", FirestoreQuery.OPERATOR.LESS_THAN, prefix + "\uf8ff")
    ])
    var res: Dictionary = await _fs_query(firestore_query)
    if not res.ok:
        push_error("User search failed: %s" % res.message)
        return results

    for item: Dictionary in res.data:
        if is_signed_in() and item.id == current_user.uid:
            continue
        if results.size() >= SEARCH_LIMIT:
            break
        results.append(_public_profile(item.data))
    return results


func _validate_username(username: String) -> Dictionary:
    var length: int = username.length()
    if length < MIN_USERNAME_LENGTH:
        return _fail("USERNAME_TOO_SHORT", "Username must be at least %d characters" % MIN_USERNAME_LENGTH)
    if length > MAX_USERNAME_LENGTH:
        return _fail("USERNAME_TOO_LONG", "Username must be at most %d characters" % MAX_USERNAME_LENGTH)
    # "/" is not allowed in document IDs and "." would split Firestore field paths
    if username.contains("/") or username.contains("."):
        return _fail("USERNAME_INVALID", "Username must not contain '/' or '.'")
    return {"success": true}


## ============================================================================
## Notifications
## ============================================================================

## Create a notification for a user in Firestore.
##
## @param username: Username of the recipient
## @param notification_data: message, sender, has_actions, action_data and optionally
##   id, timestamp (unix seconds). Friend requests and game invites use a deterministic
##   id so the same sender cannot create duplicates while one is still pending.
## @return {success: true, id: String} or a failure dictionary
func add_notification(username: String, notification_data: Dictionary) -> Dictionary:
    if not is_signed_in():
        return _fail("NOT_SIGNED_IN", "No user is currently signed in")

    var recipient: Dictionary = await _resolve_user(username)
    if not recipient.ok:
        return _fail(str(recipient.get("status", "")), str(recipient.get("message", "Backend request failed")))
    if not recipient.found:
        return _fail("USER_NOT_FOUND", "User '%s' does not exist" % username)

    var action_data: Dictionary = notification_data.get("action_data", {})
    var id: String = str(notification_data.get("id", ""))
    if id.is_empty():
        var type: String = str(action_data.get("type", ""))
        if type == "friend_request" or type == "game_invite":
            id = "%s_%s_%s" % [type, current_user.uid, recipient.uid]
        else:
            id = _generate_notification_id()

    var created_at: float = float(notification_data.get("timestamp", Time.get_unix_time_from_system()))
    var res: Dictionary = await _fs_create("notifications", id, {
        "recipient_uid": recipient.uid,
        "sender_uid": current_user.uid,
        "sender": str(notification_data.get("sender", current_user.username)),
        "message": str(notification_data.get("message", "")),
        "has_actions": bool(notification_data.get("has_actions", false)),
        "action_data": action_data,
        "is_read": false,
        "created_at": created_at
    })
    if not res.ok:
        if res.status == "ALREADY_EXISTS":
            return _fail("ALREADY_PENDING", "A matching notification is already pending")
        return _backend_fail(res)
    return {"success": true, "id": id}


func _generate_notification_id() -> String:
    return "%d_%d" % [int(Time.get_unix_time_from_system() * 1000.0), randi() % 1000000]


func _notification_from_doc(item: Dictionary) -> Dictionary:
    var data: Dictionary = item.data
    return {
        "id": item.id,
        "timestamp": float(data.get("created_at", 0.0)),
        "is_read": bool(data.get("is_read", false)),
        "message": data.get("message", ""),
        "sender": data.get("sender", ""),
        "sender_uid": data.get("sender_uid", ""),
        "has_actions": bool(data.get("has_actions", false)),
        "action_data": data.get("action_data", {})
    }


## Remove a notification by ID.
func remove_notification(username: String, notification_id: String) -> Dictionary:
    var res: Dictionary = await _fs_delete("notifications", notification_id)
    if not res.ok:
        return _backend_fail(res)
    return {"success": true}


## Get a user's notifications, oldest first. Expired notifications (older than 3 days)
## are hidden and deleted. Only the recipient may read them.
func get_notifications(username: String) -> Array:
    var user: Dictionary = await _resolve_user(username)
    if not user.found:
        return []

    var firestore_query: FirestoreQuery = FirestoreQuery.new() \
        .from("notifications") \
        .where("recipient_uid", FirestoreQuery.OPERATOR.EQUAL, user.uid)
    var res: Dictionary = await _fs_query(firestore_query)
    if not res.ok:
        push_error("Could not load notifications: %s" % res.message)
        return []

    var now: float = Time.get_unix_time_from_system()
    var notifications: Array = []
    for item: Dictionary in res.data:
        var notification: Dictionary = _notification_from_doc(item)
        if now - float(notification.timestamp) > NOTIFICATION_EXPIRY_SECONDS:
            await _fs_delete("notifications", item.id)
            continue
        notifications.append(notification)
    notifications.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.timestamp < b.timestamp)
    return notifications


func mark_notification_read(username: String, notification_id: String) -> Dictionary:
    var res: Dictionary = await _fs_patch("notifications", notification_id, {"is_read": true})
    if not res.ok:
        return _backend_fail(res)
    return {"success": true}


func get_unread_count(username: String) -> int:
    var unread_count: int = 0
    for notification: Dictionary in await get_notifications(username):
        if not notification.is_read:
            unread_count += 1
    return unread_count


## Handle notification received from GlobalSignalBus and store it for the recipient.
func _on_notification_received_global(notification_data: Dictionary) -> void:
    var recipient: String = notification_data.get("recipient_username", "")
    if recipient.is_empty():
        push_error("Cannot add notification: recipient_username is missing")
        return

    var result: Dictionary = await add_notification(recipient, notification_data)
    if result.success:
        return
    if result.error_code == "ALREADY_PENDING":
        push_warning("Notification to %s is already pending" % recipient)
    else:
        push_error("Could not send notification to %s: %s" % [recipient, result.message])


## Sends a rejection notification to the inviter when a game invite is denied.
func _on_notification_action_taken(denied_notification: Dictionary, action: String) -> void:
    if action != "deny" or not is_signed_in():
        return

    var action_data: Dictionary = denied_notification.get("action_data", {})
    if action_data.get("type") != "game_invite":
        return

    var inviter: String = denied_notification.get("sender", "")
    if inviter.is_empty():
        return
    GlobalSignalBus.notification_received.emit({
        "recipient_username": inviter,
        "message": "%s rejected your duel" % current_user.username,
        "sender": "System",
        "has_actions": false,
        "action_data": {"type": "game_invite_rejection"}
    })


## ============================================================================
## Friendships
## ============================================================================

func _friendship_id(uid_a: String, uid_b: String) -> String:
    return "%s_%s" % ([uid_a, uid_b] if uid_a < uid_b else [uid_b, uid_a])


func are_friends(username1: String, username2: String) -> bool:
    var user1: Dictionary = await _resolve_user(username1)
    var user2: Dictionary = await _resolve_user(username2)
    if not user1.found or not user2.found:
        return false
    var res: Dictionary = await _fs_get("friendships", _friendship_id(user1.uid, user2.uid))
    if res.ok:
        return true
    if res.status != "NOT_FOUND":
        push_error("Could not check friendship: %s" % res.message)
    return false


## Create a bidirectional friendship (one record shared by both users).
func add_friend(username: String, friend_username: String) -> Dictionary:
    if username.to_lower() == friend_username.to_lower():
        return _fail("SELF_FRIEND", "Users cannot friend themselves")

    var user: Dictionary = await _resolve_user(username)
    var friend: Dictionary = await _resolve_user(friend_username)
    if not user.found or not friend.found:
        return _fail("USER_NOT_FOUND", "Both users must exist")

    var uids: Array = [user.uid, friend.uid]
    uids.sort()
    var res: Dictionary = await _fs_create("friendships", _friendship_id(user.uid, friend.uid), {
        "participant_uids": uids,
        "created_at": Time.get_unix_time_from_system()
    })
    if not res.ok:
        if res.status == "ALREADY_EXISTS":
            return _fail("ALREADY_FRIENDS", "Users are already friends")
        return _backend_fail(res)
    return {"success": true}


func remove_friend(username: String, friend_username: String) -> Dictionary:
    var user: Dictionary = await _resolve_user(username)
    var friend: Dictionary = await _resolve_user(friend_username)
    if not user.found or not friend.found:
        return _fail("USER_NOT_FOUND", "Both users must exist")

    var res: Dictionary = await _fs_delete("friendships", _friendship_id(user.uid, friend.uid))
    if not res.ok:
        return _backend_fail(res)
    return {"success": true}


## Get the friends of the signed-in user.
##
## @return Array of {username, avatar_path}
func get_friends(username: String) -> Array:
    var user: Dictionary = await _resolve_user(username)
    if not user.found:
        push_error("Cannot get friends: user '%s' does not exist" % username)
        return []

    var firestore_query: FirestoreQuery = FirestoreQuery.new() \
        .from("friendships") \
        .where("participant_uids", FirestoreQuery.OPERATOR.ARRAY_CONTAINS, user.uid)
    var res: Dictionary = await _fs_query(firestore_query)
    if not res.ok:
        push_error("Could not load friends: %s" % res.message)
        return []

    var friends: Array = []
    for item: Dictionary in res.data:
        for friend_uid: String in item.data.get("participant_uids", []):
            if friend_uid == user.uid:
                continue
            var profile: Dictionary = await _fs_get("users", friend_uid)
            if profile.ok:
                friends.append(_public_profile(profile.data))
    return friends


## ============================================================================
## Multiplayer matches
## ============================================================================

## Create a new multiplayer match between two players.
##
## @return match_id, or an empty String if the match could not be created
func create_match(inviter: String, invitee: String, rounds: int, questions: int) -> String:
    var inviter_user: Dictionary = await _resolve_user(inviter)
    var invitee_user: Dictionary = await _resolve_user(invitee)
    if not inviter_user.found or not invitee_user.found:
        push_error("Cannot create match: both players must exist")
        return ""

    var match_id: String = "match_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 1000000]
    var match_data: Dictionary = {
        "match_id": match_id,
        "players": [inviter, invitee],
        "participant_uids": [inviter_user.uid, invitee_user.uid],
        "inviter": inviter,
        "config": {"rounds": rounds, "questions": questions},
        "current_turn": inviter,
        "current_round": 1,
        "status": "active",
        "dismissed_by": [],
        "stats_processed": false,
        "rounds_data": [],
        "created_at": Time.get_unix_time_from_system()
    }
    for i in range(rounds):
        match_data.rounds_data.append({
            "round_number": i + 1,
            "category": "",
            "category_chooser": inviter if (i + 1) % 2 == 1 else invitee,
            "questions": [],
            "player_answers": {
                inviter: {"answered": false, "results": []},
                invitee: {"answered": false, "results": []}
            }
        })

    var res: Dictionary = await _fs_create("matches", match_id, match_data)
    if not res.ok:
        push_error("Could not create match: %s" % res.message)
        return ""
    return match_id


## Retrieve a match by ID, or an empty Dictionary if it is missing or not accessible.
func get_match(match_id: String) -> Dictionary:
    var res: Dictionary = await _fs_get("matches", match_id)
    if not res.ok:
        push_warning("Match could not be loaded: %s (%s)" % [match_id, res.message])
        return {}
    return res.data


## Get all matches (active and finished) of the signed-in player.
func get_all_matches_for_player(username: String) -> Array:
    var user: Dictionary = await _resolve_user(username)
    if not user.found:
        return []

    var firestore_query: FirestoreQuery = FirestoreQuery.new() \
        .from("matches") \
        .where("participant_uids", FirestoreQuery.OPERATOR.ARRAY_CONTAINS, user.uid)
    var res: Dictionary = await _fs_query(firestore_query)
    if not res.ok:
        push_error("Could not load matches: %s" % res.message)
        return []

    var matches: Array = []
    for item: Dictionary in res.data:
        matches.append(item.data)
    return matches


func get_active_matches_for_player(username: String) -> Array:
    var active: Array = []
    for match_data: Dictionary in await get_all_matches_for_player(username):
        if match_data.get("status") == "active":
            active.append(match_data)
    return active


## Persist a complete match Dictionary.
func update_match(match_data: Dictionary) -> Dictionary:
    if not match_data.has("match_id") or not match_data.has("participant_uids"):
        return _fail("INVALID_MATCH", "Match data needs match_id and participant_uids")

    var res: Dictionary = await _fs_set("matches", match_data.match_id, match_data)
    if not res.ok:
        return _backend_fail(res)
    return {"success": true}


func delete_match(match_id: String) -> bool:
    var res: Dictionary = await _fs_delete("matches", match_id)
    if not res.ok:
        push_warning("Match could not be deleted: %s (%s)" % [match_id, res.message])
    return res.ok


## ============================================================================
## Player statistics
## ============================================================================

## Apply the statistics of a finished match through the Cloud Function.
##
## The latest match state is saved first because the function reads the match from
## Firestore. The function is idempotent per match (stats_processed).
func update_player_statistics(match_data: Dictionary) -> Dictionary:
    if not match_data.has("match_id"):
        return _fail("INVALID_MATCH", "Cannot update statistics: missing match_id")
    if not match_data.has("players") or match_data.players.size() != 2:
        return _fail("INVALID_MATCH", "Cannot update statistics: invalid players array")
    if match_data.get("stats_processed", false):
        return {"success": true, "already_processed": true}

    var saved: Dictionary = await update_match(match_data)
    if not saved.success:
        return saved

    var task: FunctionTask = Firebase.Functions.execute(
        STATISTICS_FUNCTION, HTTPClient.METHOD_POST, {}, {"match_id": match_data.match_id}
    )
    var response: Variant = await task.task_finished
    if not task.error.is_empty() or not response is Dictionary:
        return _fail("STATISTICS_FAILED", "Statistics update failed: %s" % str(task.error))

    match_data.stats_processed = true
    for player: String in match_data.players:
        GlobalSignalBus.player_stats_updated.emit(player)
    return {"success": true, "already_processed": bool(response.get("already_processed", false))}


## Placeholder category statistics used by the profile UI for display only (never stored).
func _generate_placeholder_category_stats() -> Dictionary:
    var categories: Array[String] = ["General Knowledge", "Entertainment", "Science", "History", "Geography", "Sports"]
    var stats: Dictionary = {}
    var selected_categories: Array[String] = categories.duplicate()
    selected_categories.shuffle()

    for i in range(3):
        if i < selected_categories.size():
            var category: String = selected_categories[i]
            var played: int = randi() % 20 + 1
            var wins: int = randi() % played
            stats[category] = {"played": played, "wins": wins}

    return stats
