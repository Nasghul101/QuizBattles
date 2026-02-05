extends Panel

## NotificationComponent
##
## Reusable UI component for displaying notifications with optional action buttons.
## Emits action_taken signal when user accepts or denies the notification.
## Notifications are automatically filtered by the database to remove expired items (>3 days old).
## The timestamp field is managed automatically by UserDatabase.

## Emitted when user interacts with notification (accepts or denies).
## [param notification_id] Unique ID of the notification
## [param action] Action taken by user ("accept" or "deny")
signal action_taken(notification_id: String, action: String)

## Color indicator for future customization (e.g., visual effects)
@export var indicator_color: Color = Color.WHITE

@onready var notification_text: Label = %NotificationText
@onready var action_buttons_container: HBoxContainer = %ActionButtonsContainer

## Current notification data
var notification_data: Dictionary = {}


## Set the notification data and update UI.
##
## @param data: Dictionary containing:
##   - id: String - Unique notification ID
##   - message: String - Notification text to display
##   - has_actions: bool - Whether to show accept/deny buttons
##   - (other fields preserved for action handling)
func set_notification_data(data: Dictionary) -> void:
    notification_data = data
    
    # Update message label
    if data.has("message"):
        notification_text.text = data.message
    
    # Show/hide action buttons based on has_actions flag
    if data.has("has_actions"):
        action_buttons_container.visible = data.has_actions
    else:
        action_buttons_container.visible = false


func _on_accept_pressed() -> void:
    if notification_data.has("id"):
        action_taken.emit(notification_data.id, "accept")


func _on_deny_pressed() -> void:
    if notification_data.has("id"):
        action_taken.emit(notification_data.id, "deny")
