# uid://cvey2h22svmcj
extends Control

const CARD_SCENE: PackedScene = preload("res://scenes/ui/components/face_random_opponent_display_component.tscn")
const GAMEPLAY_SCENE: String = "res://scenes/ui/gameplay_screen.tscn"

@onready var match_container: VBoxContainer = %MatchContainer
@onready var search_card: Control = %FaceRandomOpponent

## Match cards of the active random-opponent matches, keyed by match_id.
var _match_cards: Dictionary = {}
var _refreshing: bool = false
var _refresh_again: bool = false


func _ready() -> void:
    search_card.pressed.connect(_on_search_card_pressed)
    GlobalSignalBus.matches_changed.connect(_refresh)
    _refresh()


func _notification(what: int) -> void:
    if what == NOTIFICATION_VISIBILITY_CHANGED and visible and is_node_ready():
        _refresh()


## Rebuild the cards from the backend state: the search card is idle or searching,
## and every active random-opponent match has exactly one match card.
func _refresh() -> void:
    if _refreshing:
        _refresh_again = true
        return
    _refreshing = true

    if not UserDatabase.is_signed_in():
        _remove_match_cards(_match_cards.keys())
        search_card.set_idle()
        _refreshing = false
        return

    var matches: Array = await UserDatabase.get_all_matches_for_player(UserDatabase.current_user.username)
    var searching: bool = await UserDatabase.has_random_search()
    if not is_inside_tree():
        _refreshing = false
        return

    var active: Dictionary = {}
    for match_data: Dictionary in matches:
        if UserDatabase.get_match_mode(match_data) == UserDatabase.MODE_RANDOM \
                and match_data.get("status") == "active":
            active[match_data.match_id] = match_data

    var finished_ids: Array = []
    for match_id: String in _match_cards:
        if not active.has(match_id):
            finished_ids.append(match_id)
    _remove_match_cards(finished_ids)

    for match_id: String in active:
        var card: Control = _match_cards.get(match_id)
        if card == null:
            card = CARD_SCENE.instantiate()
            match_container.add_child(card)
            card.pressed.connect(_on_match_card_pressed.bind(match_id))
            _match_cards[match_id] = card
        card.set_match(active[match_id])

    match_container.move_child(search_card, 0)
    if searching:
        search_card.set_searching()
    else:
        search_card.set_idle()

    _refreshing = false
    if _refresh_again:
        _refresh_again = false
        _refresh()


func _remove_match_cards(match_ids: Array) -> void:
    for match_id: String in match_ids:
        _match_cards[match_id].queue_free()
        _match_cards.erase(match_id)


func _on_search_card_pressed() -> void:
    search_card.set_searching()
    var result: Dictionary = await UserDatabase.find_random_opponent()
    if not result.success:
        push_warning("Random opponent search failed: %s" % result.get("message", ""))
    _refresh()


func _on_match_card_pressed(match_id: String) -> void:
    var match_data: Dictionary = await UserDatabase.get_match(match_id)
    if match_data.is_empty():
        push_warning("Cannot navigate: match not found %s" % match_id)
        _refresh()
        return
    TransitionManager.change_scene(GAMEPLAY_SCENE, {"match_id": match_id})
