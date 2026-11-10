# uid://b4k7m2xq9ndwa
class_name MatchHelper
extends RefCounted
## Read-only helpers for match Dictionaries shared by the friendly battle page and match cards.


## Cumulative number of correct answers of a player across all rounds.
static func calculate_player_score(match_data: Dictionary, username: String) -> int:
    var score: int = 0
    for round_data: Dictionary in match_data.rounds_data:
        if round_data.player_answers.has(username):
            var player_answer: Dictionary = round_data.player_answers[username]
            if player_answer.answered:
                for result: Dictionary in player_answer.results:
                    if result.was_correct:
                        score += 1
    return score


## Username of the other player, or an empty String if there is none.
static func get_opponent_username(match_data: Dictionary, own_username: String) -> String:
    for player: String in match_data.players:
        if player != own_username:
            return player
    return ""
