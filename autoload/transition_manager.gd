extends Node
## Manages scene transitions with fade effects
##
## Provides centralized scene transition functionality with smooth fade-in/fade-out
## effects for consistent user experience across all scene changes.

## Fade overlay canvas layer
var _canvas_layer: CanvasLayer

## Black overlay for fade effect
var _overlay: ColorRect

## Active tween for animation
var _tween: Tween


func _ready() -> void:
    # Create canvas layer with high z-index to render above all content
    _canvas_layer = CanvasLayer.new()
    _canvas_layer.layer = 100
    add_child(_canvas_layer)
    
    # Create black fullscreen overlay
    _overlay = ColorRect.new()
    _overlay.color = Color.BLACK
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Start transparent
    _overlay.modulate.a = 0.0
    _canvas_layer.add_child(_overlay)


## Transitions to a new scene with fade effect
##
## Fades out current scene (0.5s), loads new scene, optionally initializes it
## with parameters, then fades in (0.5s) for ~1s total transition.
##
## @param scene_path: Path to target scene (e.g., "res://scenes/ui/gameplay_screen.tscn")
## @param params: Optional dictionary of parameters to pass to target scene's initialize() method
func change_scene(scene_path: String, params: Dictionary = {}) -> void:
    # Fade out
    _tween = create_tween()
    _tween.tween_property(_overlay, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    await _tween.finished
    
    # Clean up current scene
    var current_scene: Node = get_tree().current_scene
    if current_scene:
        current_scene.queue_free()
    
    # Load and instantiate new scene
    var new_scene: Node = load(scene_path).instantiate()
    
    # Initialize with parameters if provided
    if not params.is_empty() and new_scene.has_method("initialize"):
        new_scene.initialize(params)
    
    # Add to tree
    get_tree().root.add_child(new_scene)
    get_tree().current_scene = new_scene
    
    # Fade in
    _tween = create_tween()
    _tween.tween_property(_overlay, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
