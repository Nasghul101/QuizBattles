# uid://dqlxt3hoy3uwp
extends Control

@export_enum("General Knowledge",
             "Entertainment",
             "Science",
             "History",
             "Geography",
             "Sports",
             "Art",
             "Animals",
             "Mythology",
             "Politics",
             "Celebrities",
             "Vehicles") var category : String = "General Knowledge"
@onready var bg : TextureRect = %BG
@onready var title : AutoSizeLabel = %Title
@onready var win_amount : AutoSizeLabel = %WinAmount
@onready var played_amount : AutoSizeLabel = %PlayedAmount
@onready var win_rate : AutoSizeLabel = %WinRate

func _ready() -> void:
    # Set the title to the category name
    title.text = category
    
    set_bg_color(Utils.resolve_category_color(category))

func set_bg_color(color: Color) -> void:
    # Duplicate the gradient texture to make it modifiable
    var new_texture = bg.texture.duplicate()
    var new_gradient = new_texture.gradient.duplicate()
    var new_colors = new_gradient.colors
    new_colors[0] = color
    new_colors[1] = Color(color.r, color.g, color.b, 0.5)
    new_gradient.colors = new_colors
    new_texture.gradient = new_gradient
    bg.texture = new_texture
    
func set_win_amount(amount: int) -> void:
    win_amount.text = str(amount)

func set_played_amount(amount: int) -> void:
    played_amount.text = str(amount)

func set_win_rate() -> void:
    var rate = 0
    if played_amount.text.to_int() > 0:
        rate = int((win_amount.text.to_int() / played_amount.text.to_int()) * 100)
    win_rate.text = "%d%%" % rate
