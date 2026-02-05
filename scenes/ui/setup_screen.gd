extends Control
## Setup screen for configuring game settings
##
## Allows players to configure the number of rounds and questions per round
## using interactive sliders, then transitions to the gameplay screen.

## Reference to rounds slider
@onready var rounds_slider: HSlider = %RoundsSlider

## Reference to rounds amount label
@onready var rounds_amount: Label = %RoundsAmount

## Reference to questions slider
@onready var questions_slider: HSlider = %QuestionsSlider

## Reference to questions amount label
@onready var questions_amount: Label = %QuestionsAmount

## Username of player being invited to a multiplayer game (empty for single-player)
var pending_invite_player: String = ""



func _ready() -> void:
    # Set default values
    rounds_slider.value = 5.0
    questions_slider.value = 3.0
    
    # Configure sliders for integer-only values
    rounds_slider.step = 1.0
    questions_slider.step = 1.0
    
    # Update labels to show default values
    rounds_amount.text = str(int(rounds_slider.value))
    questions_amount.text = str(int(questions_slider.value))
    
    # Connect signals
    rounds_slider.value_changed.connect(_on_rounds_slider_changed)
    questions_slider.value_changed.connect(_on_questions_slider_changed)


## Updates rounds amount label when slider changes
func _on_rounds_slider_changed(value: float) -> void:
    rounds_amount.text = str(int(value))


## Updates questions amount label when slider changes
func _on_questions_slider_changed(value: float) -> void:
    questions_amount.text = str(int(value))


## Initialize setup screen with optional parameters
##
## @param params: Dictionary with optional "invited_player" key
func initialize(params: Dictionary) -> void:
    if params.has("invited_player"):
        pending_invite_player = params["invited_player"]
        print("[SetupScreen] Initialized with invited player: %s" % pending_invite_player)


## Starts the game with selected configuration
func _on_start_game_button_pressed() -> void:
    var rounds_value: int = int(rounds_slider.value)
    var questions_value: int = int(questions_slider.value)
    
    print("[SetupScreen] Start game pressed. pending_invite_player: '%s'" % pending_invite_player)
    
    if pending_invite_player.is_empty():
        # Single-player mode - kept for testing purposes
        # TODO: Remove this path once multiplayer is stable
        var params: Dictionary = {
            "rounds": rounds_value,
            "questions": questions_value
        }
        TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)
    else:
        # Multiplayer invite mode
        var notification_data: Dictionary = {
            "recipient_username": pending_invite_player,
            "message": "%s invites you to a duel (%d rounds, %d questions)" % [
                UserDatabase.current_user.username, rounds_value, questions_value
            ],
            "sender": UserDatabase.current_user.username,
            "has_actions": true,
            "action_data": {
                "type": "game_invite",
                "inviter_id": UserDatabase.current_user.username,
                "rounds": rounds_value,
                "questions": questions_value
            }
        }
        
        GlobalSignalBus.notification_received.emit(notification_data)
        
        # Clear pending invite
        pending_invite_player = ""
        
        # Return to main lobby
        TransitionManager.change_scene("res://scenes/ui/main_lobby_screen.tscn")
    
