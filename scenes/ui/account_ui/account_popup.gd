# uid://cuag73iw3g4do
class_name AccountPopup
extends MarginContainer

signal friend_removed

@onready var friend_name_label: Label = %FriendName
@onready var friend_total_games_amount: Label = %TotalGamesAmount
@onready var friend_win_amount: Label = %WinsAmount
@onready var friend_draw_amount: Label = %DrawsAmount
@onready var friend_loss_amount: Label = %LossAmount
@onready var piechart: Control = %Piechart
@onready var unfriend_popup: MarginContainer = %UnfriendPopup
@onready var invite_button: Button = %InviteToDuelButton

var _displayed_friend_username: String = ""

func _ready():
	unfriend_popup.visible = false


func open_for_friend(friend_username: String) -> void:
	_displayed_friend_username = friend_username
	friend_name_label.text = friend_username

	var friend_data: Dictionary = UserDatabase.get_user_data_for_display(friend_username)
	var wins: int = friend_data.get("wins", 0)
	var losses: int = friend_data.get("losses", 0)
	var total_games: int = friend_data.get("total_games", 0)
	var draws: int = total_games - wins - losses

	friend_total_games_amount.text = str(total_games)
	friend_win_amount.text = str(wins)
	friend_draw_amount.text = str(draws)
	friend_loss_amount.text = str(losses)

	piechart.set_chart(wins, draws, total_games)

	invite_button.disabled = false
	unfriend_popup.visible = false
	visible = true


func _on_account_back_button_pressed():
	visible = false


func _on_invite_to_duel_button_pressed():
	if not UserDatabase.is_signed_in():
		return
	var notification_data: Dictionary = {
		"recipient_username": _displayed_friend_username,
		"message": "%s invites you to a duel" % [UserDatabase.current_user.username],
		"sender": UserDatabase.current_user.username,
		"has_actions": true,
		"action_data": {
			"type": "game_invite",
			"inviter_id": UserDatabase.current_user.username
		}
	}
	GlobalSignalBus.notification_received.emit(notification_data)
	invite_button.disabled = true


func _on_unfried_buton_pressed():
	unfriend_popup.visible = true


func _on_yes_button_pressed():
	if not UserDatabase.is_signed_in():
		push_error("Cannot unfriend: no user signed in")
		unfriend_popup.visible = false
		visible = false
		return
	UserDatabase.remove_friend(UserDatabase.current_user.username, _displayed_friend_username)
	unfriend_popup.visible = false
	visible = false
	friend_removed.emit()


func _on_no_button_pressed():
	unfriend_popup.visible = false
