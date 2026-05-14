class_name FriendDisplayComponent
extends Control

@onready var base_texture: TextureButton = %FriendDisplayButton
@onready var first_category: Panel = %FirstPlayedCategory
@onready var second_category: Panel = %SecondPlayedCategory
@onready var third_category: Panel = %ThirdPlayedCategory
@onready var player_name: AutoSizeLabel = %Name
@onready var win_count: Label = %WinCount
@onready var loss_count: Label = %LossCount

func set_new_texture(new_texture: CompressedTexture2D) -> void:
    base_texture.texture_normal = new_texture
    
func set_first_category(color: Color) -> void:
    var stylebox: StyleBoxFlat = first_category.get_theme_stylebox("panel").duplicate()
    stylebox.bg_color = color
    stylebox.border_color = Color.from_hsv(color.h, 0.4, 1.0, 1.0)
    stylebox.shadow_color = Color.from_hsv(color.h, 0.4, 1.0, 0.5)
    first_category.add_theme_stylebox_override("panel", stylebox)
    
func set_second_category(color: Color) -> void:
    var stylebox: StyleBoxFlat = second_category.get_theme_stylebox("panel").duplicate()
    stylebox.bg_color = color
    stylebox.border_color = Color.from_hsv(color.h, 0.4, 1.0, 1.0)
    stylebox.shadow_color = Color.from_hsv(color.h, 0.4, 1.0, 0.5)
    second_category.add_theme_stylebox_override("panel", stylebox)
    
func set_third_category(color: Color) -> void:
    var stylebox: StyleBoxFlat = third_category.get_theme_stylebox("panel").duplicate()
    stylebox.bg_color = color
    stylebox.border_color = Color.from_hsv(color.h, 0.4, 1.0, 1.0)
    stylebox.shadow_color = Color.from_hsv(color.h, 0.4, 1.0, 0.5)
    third_category.add_theme_stylebox_override("panel", stylebox)
    
func set_player_name(p_name: String) -> void:
    player_name.text = p_name

func set_win_count(wins: int) -> void:
    win_count.text = str(wins)
    
func set_loss_count(losses: int) -> void:
    loss_count.text = str(losses)
