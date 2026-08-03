extends Control

@onready var visibility_test : Button = %VisibilityTest

func _on_switch_visible_button_pressed() -> void:
    visibility_test.visible = not visibility_test.visible
