# uid://b11jdqaf8o7sv
extends Control
## Main Lobby Screen
##
## Entry point screen that provides access to game features and account management.
## Conditionally navigates to account screens based on user login state.
## Supports multi-page navigation with swipe gestures and bottom navigation buttons.
## Displays and manages notifications with visual indicators.

## Preload notification component for instantiation
const NOTIFICATION_COMPONENT = preload("res://scenes/ui/components/notification_component.tscn")

## Color to apply to notifications button when unread notifications exist
@export var notification_indicator_color: Color = Color(1.0, 0.8, 0.0)  # Yellow

## Reference to the container holding page content
@onready var page_clip_container: PageClipContainer = %PageClipContainer
@onready var navigation_bar: PanelContainer = %NavigationBar
@onready var notifications_button: TextureButton = %NotificationsButton
@onready var notifications_popup: MarginContainer = %NotificationsPopUp
@onready var notification_list_container: VBoxContainer = %NotificationListContainer
@onready var no_notifications_label: Label = %NoNotificationsLabel

## Current page tracking
var current_page: int = 0

## Track instantiated notification components
var notification_components: Array[Control] = []


func _ready() -> void:
	# Connect to GlobalSignalBus for notifications
	GlobalSignalBus.notification_received.connect(_on_notification_received)
	
	# Load existing notifications for current user
	_load_existing_notifications()
	
	# Update notification indicator
	_update_notification_indicator()
	
	await page_clip_container.initialized
	current_page = Utils.last_lobby_page
	page_clip_container.current_page = current_page
	page_clip_container.animate_to_page(current_page)
	_update_page_indicator(current_page)


func _on_page_clip_container_swipe_requested(target_page: int) -> void:
	current_page = target_page
	Utils.last_lobby_page = current_page
	page_clip_container.current_page = current_page
	_update_page_indicator(current_page)


## Update bottom navigation buttons to reflect current page
func _update_page_indicator(page_index: int) -> void:
	navigation_bar.set_active_button(page_index)


## Handle NavigationBar page change
func _on_navigation_bar_page_changed(index: int) -> void:
	current_page = index
	Utils.last_lobby_page = current_page
	page_clip_container.current_page = current_page
	page_clip_container.animate_to_page(current_page)
	_update_page_indicator(current_page)


## Handle AccountButton press with conditional navigation based on login state
func _on_account_button_pressed() -> void:
	if UserDatabase.is_signed_in():
		# User is logged in - navigate to account management
		Utils.navigate_to_scene("account_management")
	else:
		# User is not logged in - navigate to register/login
		Utils.navigate_to_scene("register_login")

## Load existing notifications from database and display them
func _load_existing_notifications() -> void:
	# Only load if user is signed in
	if not UserDatabase.is_signed_in():
		return
	
	var notifications: Array = UserDatabase.get_notifications(UserDatabase.current_user.username)
	
	# Instantiate a component for each notification
	for notification: Dictionary in notifications:
		_instantiate_notification_component(notification)


## Handle notification received signal
func _on_notification_received(notification_data: Dictionary) -> void:
	# Check if notification is for current user
	if not UserDatabase.is_signed_in():
		return
	
	var recipient: String = notification_data.get("recipient_username", "")
	if recipient != UserDatabase.current_user.username:
		return
	
	# Note: Notification is already added to database by UserDatabase autoload
	# We just need to display it if the recipient is currently logged in
	
	# Instantiate component to display notification
	_instantiate_notification_component(notification_data)
	
	# Update indicator
	_update_notification_indicator()


## Instantiate a notification component and add to list
func _instantiate_notification_component(notification_data: Dictionary) -> void:
	var component: Control = NOTIFICATION_COMPONENT.instantiate()
	
	# Add to list container first so @onready variables are initialized
	notification_list_container.add_child(component)
	notification_components.append(component)
	
	# Set notification data after component is in tree
	if component.has_method("set_notification_data"):
		component.set_notification_data(notification_data)
	
	# Connect action_taken signal
	if component.has_signal("action_taken"):
		component.action_taken.connect(_on_notification_action)


## Handle notification action (accept/deny)
func _on_notification_action(notification_id: String, action: String) -> void:
	# Only handle if user is signed in
	if not UserDatabase.is_signed_in():
		return
	
	# Find component and handle friend request BEFORE emitting signal
	for i in range(notification_components.size()):
		var component: Control = notification_components[i]
		
		# Check if this component matches the notification_id
		if component.has_method("set_notification_data"):
			# Access notification_data if available
			if component.get("notification_data") is Dictionary:
				var data: Dictionary = component.get("notification_data")
				if data.get("id") == notification_id:
					# Handle friend request acceptance FIRST
					if data.has("action_data") and action == "accept":
						var action_data: Dictionary = data.action_data
						if action_data.get("type") == "friend_request":
							# Call UserDatabase directly to add friend
							var sender: String = data.get("sender", "")
							if not sender.is_empty():
								UserDatabase.add_friend(UserDatabase.current_user.username, sender)
						
						# Handle game invite acceptance
						if action_data.get("type") == "game_invite":
							var inviter_id: String = action_data.get("inviter_id", "")
							if inviter_id.is_empty():
								push_warning("Game invite missing inviter_id")
							else:
								# Emit signal for future multiplayer integration
								GlobalSignalBus.game_invite_accepted.emit(inviter_id, UserDatabase.current_user.username)
								print("Game invite accepted: %s vs %s" % [inviter_id, UserDatabase.current_user.username])
								# TODO: Connect multiplayer game initialization to GlobalSignalBus.game_invite_accepted signal
					
					# Remove from array and free
					notification_components.remove_at(i)
					component.queue_free()
					break
	
	# Remove from database
	UserDatabase.remove_notification(UserDatabase.current_user.username, notification_id)
	
	# Emit global signal AFTER friend is added so listeners see updated state
	GlobalSignalBus.notification_action_taken.emit(notification_id, action)
	
	# Update indicator
	_update_notification_indicator()


## Update visual indicator on notifications button based on unread count
func _update_notification_indicator() -> void:
	no_notifications_label.visible = notification_components.is_empty()

	if not UserDatabase.is_signed_in():
		notifications_button.modulate = Color.WHITE
		return
	
	var unread_count: int = UserDatabase.get_unread_count(UserDatabase.current_user.username)
	
	if unread_count > 0:
		notifications_button.modulate = notification_indicator_color
	else:
		notifications_button.modulate = Color.WHITE
