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
@onready var correct_answers_amount : AutoSizeLabel = %CorrectAnswersAmount
@onready var total_answers_amount : AutoSizeLabel = %TotalAnswersAmount
@onready var accuracy : AutoSizeLabel = %Accuracy

func _ready() -> void:
    # Set the title to the translated category name
    title.text = Utils.translate_category(category)
    
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
    
func set_correct_answers_amount(amount: int) -> void:
    correct_answers_amount.text = str(amount)

func set_total_answers_amount(amount: int) -> void:
    total_answers_amount.text = str(amount)

func set_accuracy() -> void:
    var rate: int = 0
    var total_answers: int = total_answers_amount.text.to_int()
    if total_answers > 0:
        var correct_answers: int = correct_answers_amount.text.to_int()
        rate = int(float(correct_answers) / float(total_answers) * 100.0)
    accuracy.text = "%d%%" % rate
