extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _expect(root.has_node("Firebase"), "Firebase autoload is missing."):
		return

	var firebase = root.get_node("Firebase")
	if not _expect(firebase.configuration_ready, "Firebase emulator configuration did not initialize."):
		return
	if not _expect(firebase.emulating, "The integration test must use the Firebase emulators."):
		return

	var auth = firebase.get_node("Auth")
	var email := "firestore-rules-%s@example.invalid" % Time.get_ticks_usec()
	auth.signup_with_email_and_password(email, "Test-password-123!")
	var auth_result: Array = await auth.auth_request
	if not _expect(auth_result[0] == 1, "Auth Emulator sign-up failed: %s" % str(auth_result[1])):
		return

	var user_id := str(auth.auth.get("localid", ""))
	if not _expect(not user_id.is_empty(), "Auth Emulator did not return a user ID."):
		return
	if not _expect(firebase.Firestore.auth.get("idtoken", "") == auth.auth.get("idtoken", ""), "Firestore did not receive the Auth ID token."):
		return

	var username_claim = await firebase.Firestore.collection("usernames").add(
		"tokenproof",
		{
			"uid": user_id,
			"username": "TokenProof",
			"username_normalized": "tokenproof"
		}
	)
	if not _expect(username_claim != null, "Could not create a username claim for the authenticated user."):
		return

	var own_profile = await firebase.Firestore.collection("users").add(
		user_id,
		{
			"uid": user_id,
			"username": "TokenProof",
			"username_normalized": "tokenproof",
			"avatar_path": "res://assets/avatars/default.png",
			"wins": 0,
			"losses": 0,
			"total_games": 0,
			"current_streak": 0,
			"friend_wins": {},
			"category_stats": {}
		}
	)
	if not _expect(own_profile != null, "Firestore denied creating the authenticated user's profile."):
		return

	var foreign_profile = await firebase.Firestore.collection("users").add(
		"other-user-id",
		{
			"uid": "other-user-id",
			"username": "ForeignUser",
			"username_normalized": "foreignuser",
			"avatar_path": "res://assets/avatars/default.png",
			"wins": 0,
			"losses": 0,
			"total_games": 0,
			"current_streak": 0,
			"friend_wins": {},
			"category_stats": {}
		}
	)
	if not _expect(foreign_profile == null, "Firestore rules allowed creating another user's profile."):
		return

	print("Auth Emulator token reached Firestore and user ownership rules enforced the authenticated UID.")
	quit()


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
