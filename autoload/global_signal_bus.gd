extends Node

## GlobalSignalBus
##
## Central hub for application-wide signals to enable decoupled communication
## between systems. Used primarily for notifications but extensible for other
## global events.

## Emitted when any system creates a notification for a user.
## [param notification_data] Dictionary containing:
## - recipient_username: String - Target user's username
## - message: String - Notification text to display
## - sender: String - Username or "System" indicating source
## - has_actions: bool - Whether notification shows accept/deny buttons
## - action_data: Dictionary - Custom data for handling notification actions (e.g., {"type": "friend_request", "sender_id": "username"})
signal notification_received(notification_data: Dictionary)

## Emitted when a user interacts with a notification (accepts or denies).
## [param notification_id] Unique ID of the notification
## [param action] Action taken by user ("accept" or "deny")
## Systems interested in specific notification types should listen to this signal
## and check action_data to handle their notification types appropriately.
signal notification_action_taken(notification_id: String, action: String)
