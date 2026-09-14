# uid://caiyu3bea5dhy
extends AspectRatioContainer

@export_range(0, 1) var label_offset: float = 0.6

@onready var chart: Panel = %Chart
@onready var win_label: Label = %Win_Label
@onready var draw_label: Label = %Draw_Label
@onready var loss_label: Label = %Loss_Label

var wins: int = 0
var draws: int = 0
var total_games: int = 0
var win_percent: int = 0
var draw_percent: int = 0
var loose_percent: int = 0

func _ready() -> void:
    chart.resized.connect(_on_chart_resized)
    _update_chart()

func _on_chart_resized() -> void:
    _update_labels()

func set_chart(total_wins: int, total_draws: int, total_games_played: int) -> void:
    wins = total_wins
    draws = total_draws
    total_games = total_games_played
    
    if not is_inside_tree():
        return
    
    _update_chart()

func _update_chart() -> void:
    if not chart:
        return
    
    if total_games > 0:
        win_percent = roundi((wins / float(total_games)) * 100.0)
        draw_percent = roundi((draws / float(total_games)) * 100.0)
        loose_percent = 100 - win_percent - draw_percent
        
        var shader_material = chart.material as ShaderMaterial
        if shader_material:
            shader_material.set_shader_parameter("value", 100.0 - float(win_percent))
            
            var fg_texture = shader_material.get_shader_parameter("fg") as GradientTexture1D
            if fg_texture and fg_texture.gradient:
                var gradient = fg_texture.gradient
                if gradient.offsets.size() >= 3:
                    gradient.offsets[1] = loose_percent / 100.0
                    gradient.offsets[2] = (loose_percent / 100.0) + 0.001
                    
        _update_labels()
    else:
        _update_labels()

func _update_labels() -> void:
    if not chart or not win_label or not draw_label or not loss_label:
        return
    
    if total_games > 0:
        win_label.text = "%d%%" % win_percent
        draw_label.text = "%d%%" % draw_percent
        loss_label.text = "%d%%" % loose_percent
        
        win_label.visible = win_percent > 0
        draw_label.visible = draw_percent > 0
        loss_label.visible = loose_percent > 0
        
        position_label(win_label, 0, wins, label_offset)
        position_label(draw_label, wins, wins + draws, label_offset)
        position_label(loss_label, wins + draws, total_games, label_offset)
    else:
        win_label.visible = false
        draw_label.visible = false
        loss_label.visible = false

func position_label(label: Label, start_value: float, end_value: float, radius_offset: float) -> void:
    if total_games <= 0 or chart.size.x <= 0 or chart.size.y <= 0:
        return
    
    var middle_value = (start_value + end_value) / 2.0
    var angle_degrees = (middle_value / float(total_games)) * 360.0
    var angle_radians = deg_to_rad(angle_degrees - 90.0)
    
    var center = chart.size / 2.0
    var radius = min(center.x, center.y) * radius_offset
    
    var offset_x = -cos(angle_radians) * radius
    var offset_y = sin(angle_radians) * radius
    
    label.position = center + Vector2(offset_x, offset_y) - (label.size / 2.0)
