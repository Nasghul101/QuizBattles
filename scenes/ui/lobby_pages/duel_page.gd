# uid://cvey2h22svmcj
extends Control

const TEST_PLAYER_1 := "robin"
const TEST_PLAYER_2 := "linus"
const TEST_ROUNDS := 3
const TEST_QUESTIONS := 5
const TEST_PASSWORD := "test1234"

var _starting: bool = false


# Debug fixture: only ever creates test accounts and matches in the Firebase emulators.
func _on_play_button_pressed() -> void:
    if _starting:
        return
    if not Firebase.emulating:
        push_error("Test duel is only available while using the Firebase emulators")
        return
    _starting = true
    var match_id: String = await _start_test_match()
    _starting = false
    if match_id.is_empty():
        push_error("Could not start the test duel; are the Firebase emulators running?")
        return
    TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", {"match_id": match_id})


func _start_test_match() -> String:
    if not await _ensure_test_account(TEST_PLAYER_2):
        return ""
    UserDatabase.sign_out()
    if not await _ensure_test_account(TEST_PLAYER_1):
        return ""
    await _clean_up_test_matches()
    return await UserDatabase.create_match(TEST_PLAYER_1, TEST_PLAYER_2, TEST_ROUNDS, TEST_QUESTIONS)


# Leaves the account signed in.
func _ensure_test_account(username: String) -> bool:
    var email: String = "%s@test.com" % username
    var result: Dictionary = await UserDatabase.sign_in(email, TEST_PASSWORD)
    if result.get("success", false):
        return true
    var created: Dictionary = await UserDatabase.create_user(username, TEST_PASSWORD, email)
    if not created.get("success", false):
        return false
    result = await UserDatabase.sign_in(email, TEST_PASSWORD)
    return result.get("success", false)


func _clean_up_test_matches() -> void:
    for existing: Dictionary in await UserDatabase.get_all_matches_for_player(TEST_PLAYER_1):
        if TEST_PLAYER_2 in existing.players:
            await UserDatabase.delete_match(existing.match_id)

