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
    
    # Load color codes from JSON
    var file = FileAccess.open('res://data/color_codes.json', FileAccess.READ)
    if file:
        var json = JSON.new()
        var parse_result = json.parse(file.get_as_text())
        if parse_result == OK:
            var colors = json.data
            if colors.has("category_colors") and colors["category_colors"].has(category):
                var color_string = colors["category_colors"][category]
                if color_string != null:
                    set_bg_color(Color(color_string))
                else:
                    # Use a default color if category color is not defined
                    set_bg_color(Color("#808080"))
            else:
                # Use a default color if category not found
                set_bg_color(Color("#808080"))
        file.close()

func set_bg_color(color: Color) -> void:
    # Duplicate the gradient texture to make it modifiable
    var new_texture = bg.texture.duplicate()
    var new_gradient = new_texture.gradient.duplicate()
    new_gradient.colors[0] = color
    new_gradient.colors[1] = Color(color, 0.5)
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
