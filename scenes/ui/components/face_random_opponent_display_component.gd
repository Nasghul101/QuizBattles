extends TextureRect
## Card of the challenge page. The search card cycles between idle and searching;
## a match card shows a random-opponent match with the opponent's or the player's turn.

## Emitted when the card's button is pressed.
signal pressed

enum State { IDLE, SEARCHING, OPPONENT_TURN, YOUR_TURN }

## Match shown by this card (empty for the search card).
var match_id: String = ""
var state: State = State.IDLE

@onready var button_bg_highlighted: TextureRect = %ButtonBGHighlighted
@onready var name_p_1: AutoSizeLabel = %NameP1
@onready var score_p_1: Label = %ScoreP1
@onready var round_label: Label = %RoundLabel
@onready var score_p_2: Label = %ScoreP2
@onready var name_p_2: AutoSizeLabel = %NameP2
@onready var face_opponent_label: Label = %FaceOpponentLabel
@onready var face_random_opponent_button: Button = $FaceRandomOpponentButton


func _ready() -> void:
    _apply_state(state)


## Idle search card: player name and the "face opponent" prompt.
func set_idle() -> void:
    match_id = ""
    _apply_state(State.IDLE)


## Search card while waiting for an opponent.
func set_searching() -> void:
    match_id = ""
    _apply_state(State.SEARCHING)


## Show a match; the state follows the match's current turn.
func set_match(match_data: Dictionary) -> void:
    match_id = str(match_data.match_id)
    var own_username: String = UserDatabase.current_user.username
    var opponent_username: String = MatchHelper.get_opponent_username(match_data, own_username)

    name_p_1.text = own_username
    name_p_2.text = opponent_username
    score_p_1.text = str(MatchHelper.calculate_player_score(match_data, own_username))
    score_p_2.text = str(MatchHelper.calculate_player_score(match_data, opponent_username))
    round_label.text = tr("FRIENDLY_DUEL_ROUND_LABEL") % int(match_data.current_round)

    var is_own_turn: bool = match_data.current_turn == own_username
    _apply_state(State.YOUR_TURN if is_own_turn else State.OPPONENT_TURN)


func _apply_state(new_state: State) -> void:
    state = new_state
    if not is_node_ready():
        return

    var shows_match: bool = state == State.OPPONENT_TURN or state == State.YOUR_TURN
    if UserDatabase.is_signed_in():
        name_p_1.text = UserDatabase.current_user.username
    score_p_1.visible = shows_match
    name_p_2.visible = shows_match
    score_p_2.visible = shows_match
    round_label.visible = shows_match
    button_bg_highlighted.visible = state == State.YOUR_TURN
    face_random_opponent_button.disabled = state == State.SEARCHING

    match state:
        State.IDLE:
            face_opponent_label.text = "CHALLENGE_SCREEN_FACE_OPPONENT"
        State.SEARCHING:
            face_opponent_label.text = "CHALLENGE_SCREEN_SEARCH_OPPONENT"
        State.OPPONENT_TURN:
            face_opponent_label.text = "CHALLENGE_SCREEN_OPPONENT_TURN"
        State.YOUR_TURN:
            face_opponent_label.text = "CHALLENGE_SCREEN_YOUR_TURN"


func _on_face_random_opponent_button_pressed() -> void:
    pressed.emit()
