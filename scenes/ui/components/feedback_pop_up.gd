class_name FeedbackPopUp
extends PopUp

const FEEDBACK_FUNCTION := "sendFeedback"

@onready var feedback_type : OptionButton = %FeedbackType
@onready var feedback_edit : TextEdit = %FeedbackEdit
@onready var send_button : Button = %SendFeedbackButton

var _question: String = ""
var _answers: Array = []
var _correct_answer: String = ""
var _player_answer: String = ""
var _sending: bool = false


func set_context(question: String, answers: Array, correct_answer: String, player_answer: String) -> void:
    _question = question
    _answers = answers.duplicate()
    _correct_answer = correct_answer
    _player_answer = player_answer


func _on_send_feedback_button_pressed() -> void:
    var text: String = feedback_edit.text.strip_edges()
    if text.is_empty() or _sending:
        return

    _sending = true
    send_button.disabled = true
    var payload := {
        "question": _question,
        "answers": _answers,
        "correct_answer": _correct_answer,
        "player_answer": _player_answer,
        "feedback_type": feedback_type.get_selected_id(),
        "feedback": text,
    }
    var task: FunctionTask = Firebase.Functions.execute(FEEDBACK_FUNCTION, HTTPClient.METHOD_POST, {}, payload)
    var response: Variant = await task.task_finished
    _sending = false
    send_button.disabled = false

    if not task.error.is_empty() or not response is Dictionary:
        push_warning("Feedback could not be sent: %s" % str(task.error))
        return

    feedback_edit.text = ""
    play_animation.emit()
