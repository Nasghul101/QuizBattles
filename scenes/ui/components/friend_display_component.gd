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
    first_category.bg_color = color
    first_category.border_color = color.from_hsv(1.0, 0.4, 1.0, 1.0)
    first_category.shadow_color = color.from_hsv(1.0, 0.4, 1.0, 0.5)
    
func set_second_category(color: Color) -> void:
    second_category.bg_color = color
    second_category.border_color = color.from_hsv(1.0, 0.4, 1.0, 1.0)
    first_category.shadow_color = color.from_hsv(1.0, 0.4, 1.0, 0.5)
    
func set_third_category(color: Color) -> void:
    third_category.bg_color = color
    third_category.border_color = color.from_hsv(1.0, 0.4, 1.0, 1.0)
    first_category.shadow_color = color.from_hsv(1.0, 0.4, 1.0, 0.5)
    
func set_player_name(p_name: String) -> void:
    player_name.text = p_name

func set_win_count(wins: int) -> void:
    win_count.text = str(wins)
    
func set_loss_count(losses: int) -> void:
    loss_count.text = str(losses)
