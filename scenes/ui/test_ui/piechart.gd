extends Control

@export_range(0,1) var label_offset: float = 0.6

@onready var chart: Panel = %Chart
@onready var win_label: Label = %Win_Label
@onready var draw_label: Label = %Draw_Label
@onready var loss_label: Label = %Loss_Label

var total_games: int
var win_percent : int
var draw_percent: int
var loose_percent: int

func _ready() -> void:
    set_chart(30, 5, 100)

func set_chart(total_wins : int, total_draws: int, total_games_played: int) -> void:
        # Get values from text fields
    var wins = total_wins
    var draws = total_draws
    total_games = total_games_played
    # Calculate total losses
    var losses = 100 - (wins + draws)
       
    if total_games > 0:
        # Calculate percentages (rounded to int)
        win_percent = roundi((wins / float(total_games)) * 100)
        draw_percent = roundi((draws / float(total_games)) * 100)
        loose_percent = 100 - win_percent - draw_percent  # Ensures all add up to 100
        
        # Get the shader material
        var shader_material = chart.material as ShaderMaterial
        
        if shader_material:
            # Set shader value to 100 - win
            shader_material.set_shader_parameter("value", 100 - wins)
            
            # Get the foreground gradient texture
            var fg_texture = shader_material.get_shader_parameter("fg") as GradientTexture1D
            
            if fg_texture and fg_texture.gradient:
                var gradient = fg_texture.gradient
                
                # Set gradient offsets
                # Offset 1 to loose/100
                # Offset 2 to (loose/100) + 0.01
                if gradient.offsets.size() >= 3:
                    gradient.offsets[1] = losses / 100.0
                    gradient.offsets[2] = (losses / 100.0) + 0.01
                
        # Position labels
        position_label(win_label, 0, wins, label_offset)
        win_label.text = "%d%%" % win_percent
        
        position_label(draw_label, wins, wins + draws, label_offset)
        draw_label.text = "%d%%" % draw_percent
        
        position_label(loss_label, wins + draws, total_games, label_offset)
        loss_label.text = "%d%%" % loose_percent

func position_label(label: Label, start_value: float, end_value: float, radius_offset: float):
    # Calculate the middle angle of this section
    var middle_value = (start_value + end_value) / 2.0
    var angle_degrees = (middle_value / total_games) * 360.0  # Convert to degrees based on total_games
    var angle_radians = deg_to_rad(angle_degrees - 90)  # -90 to start from top
    
    # Get chart center and radius
    var center = chart.size / 2.0
    var radius = min(center.x, center.y) * radius_offset
    
    # Convert polar to Cartesian coordinates
    var offset_x = -cos(angle_radians) * radius  # Negated to mirror x
    var offset_y = sin(angle_radians) * radius
    
    # Position the label
    label.position = center + Vector2(offset_x, offset_y)
    label.position -= label.size / 2.0
