extends TextureButton

@onready var player_points: Label = %PlayerPoints
@onready var opponent_points: Label = %OpponentPoints
@onready var round_count: AutoSizeLabel = %RoundLabel
@onready var opponent_name: AutoSizeLabel = %OpponentName
@onready var highlight_texture: TextureRect = %HighlightTexture

func _ready() -> void:
    un_highlight()

func set_player_points(points: int) -> void:
    player_points.text = str(points)
    
func set_opponents_points(points: int) -> void:
    opponent_points.text = str(points)
    
func set_round_count(count: int) -> void:
    round_count.text = "Round: " + str(count)
    
func set_opponent_name(opp_name: String) -> void:
    opponent_name.text = opp_name

func highlight() -> void:
    highlight_texture.visible = true
 
func un_highlight() -> void:
    highlight_texture.visible = false
