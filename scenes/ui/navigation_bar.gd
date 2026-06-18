extends PanelContainer

signal page_changed(index: int)

@onready var challenge_button: Button = %ChallengeButton
@onready var shop_button: Button = %ShopButton
@onready var vs_button: Button = %VSButton
@onready var sozial_button: Button = %SocialButton

var _nav_buttons: Array[Button]


func _ready() -> void:
    _nav_buttons = [challenge_button, shop_button, vs_button, sozial_button]


## Set the pressed (active) navigation button by page index
func set_active_button(index: int) -> void:
    for i: int in range(_nav_buttons.size()):
        _nav_buttons[i].button_pressed = (i == index)


func _on_challenge_button_pressed() -> void:
    page_changed.emit(0)


func _on_shop_button_pressed() -> void:
    page_changed.emit(1)


func _on_vs_button_pressed() -> void:
    page_changed.emit(2)


func _on_social_button_pressed() -> void:
    page_changed.emit(3)
