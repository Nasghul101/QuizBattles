# uid://c4ntbjatf22a6
extends PanelContainer

signal page_changed(index: int)

@onready var challenge_button: Button = %ChallengeButton
@onready var shop_button: Button = %ShopButton
@onready var vs_button: Button = %VSButton
@onready var sozial_button: Button = %SocialButton
@onready var highlight_shine: Panel = %HighlightShine

var _nav_buttons: Array[Button]


func _ready() -> void:
    _nav_buttons = [challenge_button, shop_button, vs_button, sozial_button]

    await get_tree().process_frame
    await get_tree().process_frame
    
    highlight_shine.size.x = challenge_button.size.x
    highlight_shine.size.y = challenge_button.size.y

## Set the pressed (active) navigation button by page index
func set_active_button(index: int) -> void:
    for i: int in range(_nav_buttons.size()):
        if i == index:
            change_highlight(_nav_buttons[i].position)


func change_highlight(new_position: Vector2) -> void:
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(highlight_shine, "position", new_position, 0.3)


func _on_challenge_button_pressed() -> void:
    page_changed.emit(0)


func _on_shop_button_pressed() -> void:
    page_changed.emit(1)


func _on_vs_button_pressed() -> void:
    page_changed.emit(2)


func _on_social_button_pressed() -> void:
    page_changed.emit(3)
