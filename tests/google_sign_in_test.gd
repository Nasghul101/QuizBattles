extends SceneTree

## Emulator-backed test of Google ID-token registration in UserDatabase.
## Run through `npm run test:google-sign-in` (starts the Auth, Firestore and Functions emulators).
## The Auth emulator accepts unsigned fake ID tokens, so no Google credentials are needed.

var _db: Node
var _suffix := str(Time.get_ticks_usec())


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

    # Username generation bounds
    var samples: Array = ["Max Mustermann", "Al", "", "A very long display name indeed", "李小龍", "a_b-c.d"]
    for sample: String in samples:
        for attempt in range(6):
            var generated: String = _db._generate_username(sample, attempt)
            if not _expect(generated.length() >= 5 and generated.length() <= 15, "Bad length for '%s' (attempt %d): '%s'" % [sample, attempt, generated]):
                return
            if not _expect(_is_valid(generated), "Invalid characters for '%s': '%s'" % [sample, generated]):
                return
    if not _expect(_db._generate_username("Max Mustermann", 0) == "MaxMustermann", "Plain name was altered unexpectedly."):
        return

    # New Google user
    var display := "Gina%s" % _suffix.right(5)
    var email := "gina-%s@example.invalid" % _suffix
    var token := _fake_id_token("google-sub-%s" % _suffix, email)
    var result: Dictionary = await _db.register_with_google(token, display, email)
    if not _expect(result.success and result.user.username == display, "New Google user registration failed: %s" % str(result)):
        return
    if not _expect(_db.is_signed_in(), "Google registration did not sign the user in."):
        return
    var uid: String = _db.current_user.uid
    _db.sign_out()

    # Returning Google user keeps the same profile and creates no second one
    result = await _db.register_with_google(token, "Different Name", email)
    if not _expect(result.success and result.user.username == display, "Returning Google user was not signed in: %s" % str(result)):
        return
    if not _expect(_db.current_user.uid == uid, "Returning Google user got a different uid."):
        return
    _db.sign_out()

    # Username collision: another Google account with the same display name gets a suffix
    var email2 := "gina2-%s@example.invalid" % _suffix
    result = await _db.register_with_google(_fake_id_token("google-sub-2-%s" % _suffix, email2), display, email2)
    if not _expect(result.success and result.user.username != display and result.user.username.begins_with(display.left(5)), "Collision was not resolved with a suffix: %s" % str(result)):
        return
    if not _expect(result.user.username.length() <= 15, "Suffixed username too long."):
        return
    _db.sign_out()

    # Invalid token fails without creating anything
    result = await _db.register_with_google("not-a-token", "Nobody", "")
    if not _expect(not result.success, "Invalid ID token was accepted."):
        return
    if not _expect(not _db.is_signed_in(), "Invalid ID token signed a user in."):
        return

    print("Google sign-in registration checks passed.")
    quit()


func _is_valid(username: String) -> bool:
    var rx := RegEx.new()
    rx.compile("^[A-Za-z0-9_]+$")
    return rx.search(username) != null


func _b64url(text: String) -> String:
    return Marshalls.raw_to_base64(text.to_utf8_buffer()).replace("+", "-").replace("/", "_").replace("=", "")


## Unsigned JWT in the format the Auth emulator accepts for the google.com provider.
func _fake_id_token(sub: String, email: String) -> String:
    var header := _b64url(JSON.stringify({"alg": "none", "typ": "JWT"}))
    var payload := _b64url(JSON.stringify({
        "sub": sub,
        "email": email,
        "email_verified": true,
        "iss": "https://accounts.google.com",
        "aud": "demo-quizbattles"
    }))
    return "%s.%s." % [header, payload]


func _expect(condition: bool, message: String) -> bool:
    if condition:
        return true
    push_error(message)
    quit(1)
    return false
