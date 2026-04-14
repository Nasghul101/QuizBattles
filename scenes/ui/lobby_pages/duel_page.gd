extends Control

const TEST_PLAYER_1 := "robin"
const TEST_PLAYER_2 := "linus"
const TEST_ROUNDS := 3
const TEST_QUESTIONS := 5

func _on_play_button_pressed() -> void:
    _setup_test_users()
    _clean_up_test_matches()
    UserDatabase.current_user = {
        "username": TEST_PLAYER_1,
        "email": "robin@test.com",
        "avatar_path": UserDatabase.DEFAULT_AVATAR_PATH
    }
    var match_id: String = UserDatabase.create_match(TEST_PLAYER_1, TEST_PLAYER_2, TEST_ROUNDS, TEST_QUESTIONS)
    TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", {"match_id": match_id})


func _setup_test_users() -> void:
    if not UserDatabase.user_exists(TEST_PLAYER_1):
        UserDatabase.create_user(TEST_PLAYER_1, "test1234", "robin@test.com")
    if not UserDatabase.user_exists(TEST_PLAYER_2):
        UserDatabase.create_user(TEST_PLAYER_2, "test1234", "linus@test.com")


func _clean_up_test_matches() -> void:
    var to_delete: Array[String] = []
    for match in UserDatabase.data.multiplayer_matches:
        if TEST_PLAYER_1 in match.players and TEST_PLAYER_2 in match.players:
            to_delete.append(match.match_id)
    for match_id in to_delete:
        UserDatabase.delete_match(match_id)
