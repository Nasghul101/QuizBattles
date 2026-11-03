extends SceneTree

## Emulator-backed test of the Firebase UserDatabase service.
## Run through `npm run test:user-database` (starts the Auth, Firestore and Functions emulators).

const PASSWORD := "Test-password-123!"

var _db: Node
var _suffix := str(Time.get_ticks_usec())
var _alice_name := "Alice%s" % str(Time.get_ticks_usec()).right(5)
var _bob_name := "Bobby%s" % str(Time.get_ticks_usec()).right(5)
var _alice_email: String
var _bob_email: String


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var firebase: Node = root.get_node("Firebase")
    if not _expect(firebase.emulating, "The test must use the Firebase emulators."):
        return
    var local_cache: Node = root.get_node("LocalCache")
    if not local_cache.session_restore_done:
        await local_cache.session_restore_finished
    _db = root.get_node("UserDatabase")
    _alice_email = "alice-%s@example.invalid" % _suffix
    _bob_email = "bob-%s@example.invalid" % _suffix

    if not _expect(not "data" in _db and not "DATABASE_PATH" in _db, "UserDatabase still exposes the local JSON database."):
        return

    # Registration
    var result: Dictionary = await _db.create_user("abc", PASSWORD, "short@example.invalid")
    if not _expect(not result.success and result.error_code == "USERNAME_TOO_SHORT", "Short username accepted: %s" % str(result)):
        return
    result = await _db.create_user("bad.name1", PASSWORD, "dot@example.invalid")
    if not _expect(not result.success and result.error_code == "USERNAME_INVALID", "Username with a dot accepted: %s" % str(result)):
        return
    result = await _db.create_user(_alice_name, PASSWORD, _alice_email)
    if not _expect(result.success and result.user.username == _alice_name and not result.user.has("password"), "Alice registration failed: %s" % str(result)):
        return
    result = await _db.create_user(_bob_name, PASSWORD, _bob_email)
    if not _expect(result.success, "Bob registration failed: %s" % str(result)):
        return
    if not _expect(not _db.is_signed_in(), "Registration must not set the current user."):
        return

    var other_email := "other-%s@example.invalid" % _suffix
    result = await _db.create_user(_alice_name.to_upper(), PASSWORD, other_email)
    if not _expect(not result.success and result.error_code == "USERNAME_EXISTS", "Duplicate username accepted: %s" % str(result)):
        return
    result = await _db.sign_in(other_email, PASSWORD)
    if not _expect(not result.success, "Auth account of a failed registration was not rolled back."):
        return
    result = await _db.create_user("Charlie%s" % str(Time.get_ticks_usec()).right(4), PASSWORD, _alice_email)
    if not _expect(not result.success and result.error_code == "EMAIL_EXISTS", "Duplicate email accepted: %s" % str(result)):
        return

    # Sign-in
    result = await _db.sign_in(_alice_email, "wrong-password")
    if not _expect(not result.success and not _db.is_signed_in(), "Wrong password signed in: %s" % str(result)):
        return
    result = await _db.sign_in("nobody-%s@example.invalid" % _suffix, PASSWORD)
    if not _expect(not result.success and not _db.is_signed_in(), "Unknown email signed in: %s" % str(result)):
        return
    result = await _db.sign_in(_alice_email, PASSWORD)
    if not _expect(result.success and result.user.username == _alice_name and result.user.email == _alice_email, "Alice sign-in failed: %s" % str(result)):
        return

    # Email verification and password recovery
    var firebase_auth: Node = root.get_node("Firebase").get_node("Auth")
    var original_uid: String = str(firebase_auth.auth.get("localid", ""))
    var verification_status: Dictionary = await _db.refresh_email_verification_status()
    if not _expect(
        verification_status.success and not verification_status.email_verified and verification_status.provider_id == "password",
        "New account verification status was wrong: %s" % str(verification_status)
    ):
        return

    result = await _db.send_email_verification()
    if not _expect(result.success, "Verification email request failed: %s" % str(result)):
        return
    if not _expect(firebase_auth.auth.get("localid", "") == original_uid, "Verification request replaced the active Auth session."):
        return
    result = await _db.send_email_verification()
    if not _expect(result.success, "Resending verification email failed: %s" % str(result)):
        return

    var reset_result: Dictionary = await _db.request_password_reset_email(_alice_email)
    if not _expect(reset_result.success, "Password reset request failed: %s" % str(reset_result)):
        return
    reset_result = await _db.request_password_reset_email("unknown-%s@example.invalid" % _suffix)
    if not _expect(reset_result.success, "Unknown-email reset request exposed account existence: %s" % str(reset_result)):
        return
    reset_result = await _db.request_password_reset_email("")
    if not _expect(not reset_result.success and reset_result.error_code == "INVALID_EMAIL", "Empty reset email was accepted: %s" % str(reset_result)):
        return
    reset_result = await _db.request_password_reset_email("not-an-email")
    if not _expect(not reset_result.success and reset_result.error_code == "INVALID_EMAIL", "Malformed reset email was accepted: %s" % str(reset_result)):
        return

    firebase_auth.is_busy = true
    reset_result = await _db.request_password_reset_email(_alice_email)
    firebase_auth.is_busy = false
    if not _expect(not reset_result.success and reset_result.error_code == "AUTH_BUSY", "Busy Auth service did not fail explicitly: %s" % str(reset_result)):
        return
    var timeout_result: Dictionary = await _db._auth_request(func() -> void: pass)
    if not _expect(
        not timeout_result.success and timeout_result.error_code == "SERVICE_UNAVAILABLE",
        "Auth request timeout did not return a service failure: %s" % str(timeout_result)
    ):
        return

    var oob_response: Dictionary = await _request_json(
        "http://127.0.0.1:9099/emulator/v1/projects/%s/oobCodes" % str(root.get_node("Firebase")._config.get("projectId", "")),
        HTTPClient.METHOD_GET
    )
    if not _expect(oob_response.get("response_code", 0) == 200, "Could not read Auth Emulator email actions: %s" % str(oob_response)):
        return
    var verification_code: String = ""
    for action: Variant in oob_response.get("body", {}).get("oobCodes", []):
        if action.get("email", "") == _alice_email and action.get("requestType", "") == "VERIFY_EMAIL":
            verification_code = str(action.get("oobCode", ""))
    if not _expect(not verification_code.is_empty(), "Auth Emulator did not expose the verification action code."):
        return

    var apply_code_response: Dictionary = await _request_json(
        str(firebase_auth._base_url) + "accounts:update?key=" + str(firebase_auth._config.get("apiKey", "")),
        HTTPClient.METHOD_POST,
        {"oobCode": verification_code}
    )
    if not _expect(apply_code_response.get("response_code", 0) == 200, "Could not apply Auth Emulator verification code: %s" % str(apply_code_response)):
        return
    verification_status = await _db.refresh_email_verification_status()
    if not _expect(
        verification_status.success and verification_status.email_verified,
        "Verified email status was not refreshed: %s" % str(verification_status)
    ):
        return
    var auth_base_url: String = str(firebase_auth._base_url)
    firebase_auth._base_url = "http://127.0.0.1:1/"
    verification_status = await _db.refresh_email_verification_status()
    firebase_auth._base_url = auth_base_url
    if not _expect(
        not verification_status.success and verification_status.error_code == "SERVICE_UNAVAILABLE",
        "Verification status refresh failure was not reported: %s" % str(verification_status)
    ):
        return

    # A verification-send failure does not roll back an already created account/profile.
    var retry_email: String = "retry-%s@example.invalid" % _suffix
    result = await _db.create_user("Retry%s" % str(Time.get_ticks_usec()).right(5), PASSWORD, retry_email)
    if not _expect(result.success, "Could not create verification retry account: %s" % str(result)):
        return
    auth_base_url = str(firebase_auth._base_url)
    firebase_auth._base_url = "http://127.0.0.1:1/"
    var failed_verification: Dictionary = await _db.send_email_verification()
    firebase_auth._base_url = auth_base_url
    if not _expect(not failed_verification.success, "Verification request unexpectedly succeeded against an unavailable endpoint."):
        return
    result = await _db.sign_in(retry_email, PASSWORD)
    if not _expect(result.success, "Verification email failure removed the account/profile: %s" % str(result)):
        return
    _db.sign_out()
    result = await _db.sign_in(_alice_email, PASSWORD)
    if not _expect(result.success, "Could not restore Alice's test session: %s" % str(result)):
        return

    # Lookup and prefix search
    if not _expect(await _db.user_exists(_bob_name.to_upper()), "Existing user not found."):
        return
    if not _expect(not await _db.user_exists("Nobody%s" % _suffix), "Missing user reported as existing."):
        return
    var display: Dictionary = await _db.get_user_data_for_display(_bob_name)
    if not _expect(display.username == _bob_name and display.wins == 0 and not display.has("email"), "Display data wrong: %s" % str(display)):
        return
    var found: Array = await _db.search_users_by_username(_bob_name.left(4).to_lower())
    if not _expect(found.size() == 1 and found[0].username == _bob_name and not found[0].has("email"), "Prefix search wrong: %s" % str(found)):
        return
    found = await _db.search_users_by_username(_bob_name.substr(1, 4))
    if not _expect(found.is_empty(), "Substring search matched: %s" % str(found)):
        return
    found = await _db.search_users_by_username(_alice_name)
    if not _expect(found.is_empty(), "Search returned the signed-in user."):
        return

    # Notifications
    var request := {
        "message": "Friend request",
        "sender": _alice_name,
        "has_actions": true,
        "action_data": {"type": "friend_request", "sender_id": _alice_name}
    }
    result = await _db.add_notification(_bob_name, request)
    if not _expect(result.success, "Notification not stored: %s" % str(result)):
        return
    result = await _db.add_notification(_bob_name, request)
    if not _expect(not result.success and result.error_code == "ALREADY_PENDING", "Duplicate friend request accepted: %s" % str(result)):
        return
    result = await _db.add_notification("Nobody%s" % _suffix, request)
    if not _expect(not result.success and result.error_code == "USER_NOT_FOUND", "Notification for missing user accepted: %s" % str(result)):
        return
    var notifications: Array = await _db.get_notifications(_bob_name)
    if not _expect(notifications.is_empty(), "Alice could read Bob's notifications."):
        return

    # Bob's session
    result = await _db.sign_in(_bob_email, PASSWORD)
    if not _expect(result.success, "Bob sign-in failed: %s" % str(result)):
        return
    notifications = await _db.get_notifications(_bob_name)
    if not _expect(notifications.size() == 1 and notifications[0].sender == _alice_name and notifications[0].action_data.type == "friend_request", "Bob's notifications wrong: %s" % str(notifications)):
        return
    if not _expect(await _db.get_unread_count(_bob_name) == 1, "Unread count wrong."):
        return
    result = await _db.mark_notification_read(_bob_name, notifications[0].id)
    if not _expect(result.success and await _db.get_unread_count(_bob_name) == 0, "Marking as read failed: %s" % str(result)):
        return
    result = await _db.mark_all_notifications_read(_bob_name)
    if not _expect(result.success and await _db.get_unread_count(_bob_name) == 0, "Marking all as read failed: %s" % str(result)):
        return

    # Friendship
    if not _expect(not await _db.are_friends(_bob_name, _alice_name), "Users were friends before accepting."):
        return
    result = await _db.add_friend(_bob_name, _alice_name)
    if not _expect(result.success, "Friendship not stored: %s" % str(result)):
        return
    result = await _db.add_friend(_alice_name, _bob_name)
    if not _expect(not result.success and result.error_code == "ALREADY_FRIENDS", "Duplicate friendship accepted: %s" % str(result)):
        return
    if not _expect(await _db.are_friends(_alice_name, _bob_name), "Friendship not found."):
        return
    var friends: Array = await _db.get_friends(_bob_name)
    if not _expect(friends.size() == 1 and friends[0].username == _alice_name, "Friends wrong: %s" % str(friends)):
        return

    result = await _db.remove_notification(_bob_name, notifications[0].id)
    if not _expect(result.success and (await _db.get_notifications(_bob_name)).is_empty(), "Notification not removed."):
        return

    # Matches and statistics
    var match_id: String = await _db.create_match(_alice_name, _bob_name, 2, 2)
    if not _expect(not match_id.is_empty(), "Match not created."):
        return
    var match_data: Dictionary = await _db.get_match(match_id)
    if not _expect(match_data.players == [_alice_name, _bob_name] and match_data.config.rounds == 2 and match_data.rounds_data.size() == 2, "Match data wrong: %s" % str(match_data)):
        return
    match_data.rounds_data[0].category = "Science"
    match_data.rounds_data[0].player_answers[_bob_name] = {"answered": true, "results": [{"was_correct": true}, {"was_correct": true}]}
    match_data.rounds_data[0].player_answers[_alice_name] = {"answered": true, "results": [{"was_correct": false}, {"was_correct": true}]}
    match_data.status = "finished"
    result = await _db.update_match(match_data)
    if not _expect(result.success, "Match update failed: %s" % str(result)):
        return
    var matches: Array = await _db.get_all_matches_for_player(_bob_name)
    if not _expect(matches.size() == 1 and matches[0].status == "finished", "Player matches wrong: %s" % str(matches)):
        return
    if not _expect((await _db.get_active_matches_for_player(_bob_name)).is_empty(), "Finished match listed as active."):
        return

    result = await _db.update_player_statistics(match_data)
    if not _expect(result.success and not result.already_processed and match_data.stats_processed, "Statistics failed: %s" % str(result)):
        return
    var bob_stats: Dictionary = await _db.get_user_data_for_display(_bob_name)
    var alice_stats: Dictionary = await _db.get_user_data_for_display(_alice_name)
    if not _expect(bob_stats.wins == 1 and bob_stats.total_games == 1 and bob_stats.friend_wins.get(_alice_name, 0) == 1, "Winner statistics wrong: %s" % str(bob_stats)):
        return
    if not _expect(alice_stats.losses == 1 and alice_stats.total_games == 1, "Loser statistics wrong: %s" % str(alice_stats)):
        return
    var stored: Dictionary = await _db.get_match(match_id)
    if not _expect(stored.stats_processed, "Match was not marked as processed."):
        return
    stored.stats_processed = false
    result = await _db.update_player_statistics(stored)
    if not _expect(not result.success or result.already_processed, "Statistics were applied twice: %s" % str(result)):
        return
    bob_stats = await _db.get_user_data_for_display(_bob_name)
    if not _expect(bob_stats.wins == 1, "Statistics were applied twice."):
        return
    if not _expect(await _db.delete_match(match_id), "Match not deleted."):
        return
    if not _expect((await _db.get_match(match_id)).is_empty(), "Deleted match still readable."):
        return

    # Avatar and friendship removal
    result = await _db.update_avatar("res://assets/profile_pictures/other.png")
    if not _expect(result.success and (await _db.get_user_data_for_display(_bob_name)).avatar_path.ends_with("other.png"), "Avatar update failed: %s" % str(result)):
        return
    result = await _db.remove_friend(_bob_name, _alice_name)
    if not _expect(result.success and not await _db.are_friends(_bob_name, _alice_name), "Friendship not removed: %s" % str(result)):
        return

    # Session persistence
    if not _expect(_db.remember_session(), "Session could not be stored."):
        return
    _db.current_user = {}
    root.get_node("Firebase").Auth.auth = {}
    result = await _db.restore_session()
    if not _expect(result.success and _db.current_user.username == _bob_name and _db.current_user.email == _bob_email, "Session restore failed: %s" % str(result)):
        return

    _db.sign_out()
    if not _expect(not _db.is_signed_in() and not FileAccess.file_exists("user://user.auth"), "Sign-out did not clear the session."):
        return
    if not _expect(root.get_node("Firebase").Auth.save_auth({
        "localid": "invalid-session-user",
        "refreshtoken": "invalid-session-refresh-token"
    }), "Could not store invalid session test data."):
        return
    result = await _db.restore_session()
    if not _expect(not result.success and not _db.is_signed_in() and not FileAccess.file_exists("user://user.auth"), "Invalid stored session was not cleared: %s" % str(result)):
        return

    print("UserDatabase Firebase integration passed.")
    quit()


func _expect(condition: bool, message: String) -> bool:
    if condition:
        return true
    push_error(message)
    quit(1)
    return false


func _request_json(url: String, method: HTTPClient.Method, data: Dictionary = {}) -> Dictionary:
    var http_request := HTTPRequest.new()
    root.add_child(http_request)
    var request_body: String = JSON.stringify(data) if method != HTTPClient.METHOD_GET else ""
    var request_error: int = http_request.request(
        url,
        PackedStringArray(["Content-Type: application/json"]),
        method,
        request_body
    )
    if request_error != OK:
        http_request.queue_free()
        return {"request_error": request_error}

    var response: Array = await http_request.request_completed
    http_request.queue_free()
    var parsed_body: Variant = JSON.parse_string(response[3].get_string_from_utf8())
    return {
        "response_code": int(response[1]),
        "body": parsed_body if parsed_body is Dictionary else {}
    }
