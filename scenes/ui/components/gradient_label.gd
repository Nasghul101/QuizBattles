extends Label
class_name GradientLabel

@onready var gradient : TextureRect = %Gradient


## Set the accent color (index 0) of the gradient overlay
##
## Args:
##   color: The accent color to apply; index 1 remains unchanged
func set_accent_color(color: Color) -> void:
    var tex := gradient.texture as GradientTexture2D
    if tex == null:
        push_warning("GradientLabel: gradient texture is not a GradientTexture2D; set_accent_color is a no-op")
        return
    var grad := tex.gradient
    if grad == null:
        push_warning("GradientLabel: GradientTexture2D has no Gradient resource; set_accent_color is a no-op")
        return
    grad.set_color(0, color)
