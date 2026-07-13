# uid://du2is7604h5ib
extends Control
## Category selection popup component
##
## Modal popup that displays 3 random categories for the player to choose from.
## Manages loading state with progress bar animation while questions are being fetched.
##
## Usage:
##   1. Instance the category_popup_component.tscn scene
##   2. Connect to the category_selected signal
##   3. Call show_categories(categories) to display category options
##   4. Call show_loading() when fetching questions
##   5. Call hide_popup() to close the popup
##
## Signals:
##   category_selected(category_name: String) - Emitted when player selects a category

# Signals
signal category_selected(category_name: String)

# Node references
@onready var headline: Label = %Headline
@onready var category1: Button = %Category1
@onready var category2: Button = %Category2
@onready var category3: Button = %Category3
@onready var bg1: TextureRect = %BG1
@onready var bg2: TextureRect = %BG2
@onready var bg3: TextureRect = %BG3
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var category_container: HBoxContainer = %HBoxContainer

# Internal state
var is_loading: bool = false
var progress_tween: Tween


func _ready() -> void:
    # Connect category button signals
    category1.pressed.connect(_on_category_selected.bind(category1))
    category2.pressed.connect(_on_category_selected.bind(category2))
    category3.pressed.connect(_on_category_selected.bind(category3))
    
    # Initially hide the popup
    visible = false
    progress_bar.visible = false


## Display category selection with 3 random categories
##
## Args:
##   categories: Array of 3 category name strings to display
func show_categories(categories: Array) -> void:
    if categories.size() != 3:
        push_error("show_categories requires exactly 3 categories, got %d" % categories.size())
        return
    
    # Reset to selection state
    is_loading = false
    headline.text = "Choose a Category"
    category_container.visible = true
    progress_bar.visible = false
    
    # Populate category buttons
    category1.text = categories[0]
    category2.text = categories[1]
    category3.text = categories[2]
    
    # Color category buttons
    set_bg_color(bg1, Utils.resolve_category_color(categories[0]))
    set_bg_color(bg2, Utils.resolve_category_color(categories[1]))
    set_bg_color(bg3, Utils.resolve_category_color(categories[2]))

    # Show the popup
    visible = true

func set_bg_color(bg: TextureRect, color: Color) -> void:
    # Duplicate the gradient texture to make it modifiable
    var new_texture = bg.texture.duplicate(true)
    var new_gradient = new_texture.gradient.duplicate(true)
    var new_colors = new_gradient.colors
    new_colors[0] = color
    new_colors[1] = Color(color.r, color.g, color.b, 0.5)
    new_gradient.colors = new_colors
    new_texture.gradient = new_gradient
    bg.texture = new_texture

## Switch to loading state with animated progress bar
func show_loading() -> void:
    is_loading = true
    headline.text = "Loading..."
    category_container.visible = false
    progress_bar.visible = true
    progress_bar.value = 0
    
    # Animate progress bar from 0 to 100 over 1.5 seconds
    if progress_tween:
        progress_tween.kill()
    
    progress_tween = create_tween()
    progress_tween.tween_property(progress_bar, "value", 100, 1.5)


## Hide the popup
func hide_popup() -> void:
    visible = false
    
    # Stop any ongoing animation
    if progress_tween:
        progress_tween.kill()


## Handle category button press
##
## Args:
##   button: The button that was pressed
func _on_category_selected(button: Button) -> void:
    if is_loading:
        return  # Ignore clicks during loading
    
    print("[CategoryPopup] Category selected: ", button.text)
    
    var category_name: String = button.text
    category_selected.emit(category_name)
