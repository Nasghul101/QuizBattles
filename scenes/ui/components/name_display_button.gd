extends Button
## Interactive button component for displaying and selecting usernames in the search results.
##
## Provides radio-button style selection behavior where only one button can be highlighted
## at a time. Emits signals when selection state changes to allow parent components to
## manage the overall selection state.

## Emitted when the highlight state of this button changes.
## @param username: The username associated with this button
## @param is_highlighted: Whether this button is now highlighted (selected)
signal selection_changed(username: String, is_highlighted: bool)

## Username associated with this button
var username: String = ""

## Whether this button is currently highlighted (selected)
var is_highlighted: bool = false:
    set(value):
        is_highlighted = value
        _update_appearance()


func _ready() -> void:
    # Connect button press to toggle highlight state
    pressed.connect(_on_pressed)
    _update_appearance()


## Handle button press to toggle highlight state
func _on_pressed() -> void:
    set_highlighted(not is_highlighted)
    selection_changed.emit(username, is_highlighted)


## Update the highlighted state and visual appearance.
## @param value: New highlight state
func set_highlighted(value: bool) -> void:
    is_highlighted = value
    _update_appearance()


## Update visual appearance based on highlight state
func _update_appearance() -> void:
    if is_highlighted:
        # Highlighted state - use accent color
        add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))  # Yellow/gold color
        add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.0))
        add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.2))
    else:
        # Normal state - remove color overrides to use theme defaults
        remove_theme_color_override("font_color")
        remove_theme_color_override("font_pressed_color")
        remove_theme_color_override("font_hover_color")


## Set the username for this button and update the display text.
## @param new_username: Username to display and associate with this button
func set_username(new_username: String) -> void:
    username = new_username
    text = new_username
