extends Control
## Gameplay screen for quiz game
##
## Receives and stores game configuration (rounds and questions) from setup screen.
## This configuration will be used by future game logic implementation.

## Number of rounds to play
var num_rounds: int = 0

## Number of questions per round
var num_questions: int = 0


func _ready() -> void:
    # Display current configuration for debugging
    if num_rounds > 0 and num_questions > 0:
        print("Game initialized: %d rounds, %d questions" % [num_rounds, num_questions])


## Initializes the gameplay screen with game configuration
##
## Called by TransitionManager when transitioning from setup screen.
## Stores configuration for use by future game logic.
##
## @param rounds: Number of rounds to play
## @param questions: Number of questions per round
func initialize(rounds: int, questions: int) -> void:
    num_rounds = rounds
    num_questions = questions
