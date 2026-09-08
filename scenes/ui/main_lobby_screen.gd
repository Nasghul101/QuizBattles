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
@onready var page_clip_container: Control = %PageClipContainer
@onready var pages_container: HBoxContainer = %PagesContainer
@onready var navigation_bar: PanelContainer = %NavigationBar
@onready var notifications_button: TextureButton = %NotificationsButton
@onready var notifications_popup: MarginContainer = %NotificationsPopUp
@onready var notification_list_container: VBoxContainer = %NotificationListContainer
@onready var no_notifications_label: Label = %NoNotificationsLabel

## Swipe detection state
var swipe_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var swipe_threshold: float = 100.0  # Minimum pixels to trigger page change
var drag_start_container_pos: float = 0.0
var page_width: float = 0.0
var page_separation: float = 0.0

## Current page tracking
var current_page: int = 0
var is_animating: bool = false

## Track instantiated notification components
var notification_components: Array[Control] = []


func _ready() -> void:
	# Connect to GlobalSignalBus for notifications
	GlobalSignalBus.notification_received.connect(_on_notification_received)
	
	# Load existing notifications for current user
	_load_existing_notifications()
	
	# Update notification indicator
	_update_notification_indicator()
	
	# Calculate page width from viewport
	await get_tree().process_frame  # Wait for layout
	page_width = page_clip_container.size.x
	
	# Get separation from HBoxContainer
	page_separation = pages_container.get_theme_constant("separation")
	
	# Set each page to take full width
	for page: Node in pages_container.get_children():
		if page is Control:
			(page as Control).custom_minimum_size.x = page_width
	
	# Force layout update
	pages_container.queue_sort()
	await get_tree().process_frame
	
	# Initialize page system - position at first page
	_set_page_position(0, false)
	_update_page_indicator(0)


## Get total number of pages dynamically
func _get_total_pages() -> int:
	return pages_container.get_child_count()


## Handle input events for swipe gestures
func _input(event: InputEvent) -> void:
	# Handle touch/mouse drag for swiping
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			# Only start a swipe when the press is inside the page content area,
			# not on the navigation bar or header, so nav button clicks are ignored.
			if page_clip_container.get_global_rect().has_point(event.position):
				swipe_start_pos = event.position
				drag_start_container_pos = pages_container.position.x
				is_swiping = true
		else:
			# Always clear swiping state on release, even during animation,
			# so is_swiping never leaks as true.
			if is_swiping and not is_animating:
				_handle_swipe_end(event.position)
			is_swiping = false
	
	elif event is InputEventScreenDrag:
		if is_swiping and not is_animating:
			# Follow finger - move container with drag
			var drag_offset: float = event.position.x - swipe_start_pos.x
			var target_pos: float = drag_start_container_pos + drag_offset
			
			# Clamp to prevent dragging beyond first/last page
			var min_pos: float = -((page_width + page_separation) * (_get_total_pages() - 1))
			var max_pos: float = 0.0
			pages_container.position.x = clampf(target_pos, min_pos, max_pos)
	
	elif event is InputEventMouseMotion:
		if is_swiping and not is_animating and event.button_mask != 0:
			# Follow mouse - move container with drag
			var drag_offset: float = event.position.x - swipe_start_pos.x
			var target_pos: float = drag_start_container_pos + drag_offset
			
			# Clamp to prevent dragging beyond first/last page
			var min_pos: float = -((page_width + page_separation) * (_get_total_pages() - 1))
			var max_pos: float = 0.0
			pages_container.position.x = clampf(target_pos, min_pos, max_pos)


## Process swipe gesture and change page if threshold met
func _handle_swipe_end(end_pos: Vector2) -> void:
	var swipe_vector: Vector2 = end_pos - swipe_start_pos
	var swipe_distance: float = swipe_vector.x
	
	# Determine target page based on swipe direction and distance
	var target_page: int = current_page
	
	if abs(swipe_distance) >= swipe_threshold:
		if swipe_distance > 0:  # Swipe right → go to previous page
			target_page = current_page - 1
		else:  # Swipe left → go to next page
			target_page = current_page + 1
	
	# Animate to target page (or snap back to current if threshold not met)
	_navigate_to_page(target_page)


## Navigate to specific page with bounds checking and animation
func _navigate_to_page(page_index: int) -> void:
	# Clamp to valid page range
	page_index = clampi(page_index, 0, _get_total_pages() - 1)
	
	if page_index == current_page and not is_swiping:
		# Already on target page, snap back if mid-drag
		_set_page_position(current_page, true)
		return
	
	current_page = page_index
	_set_page_position(current_page, true)
	_update_page_indicator(current_page)


## Set page position with optional animation
func _set_page_position(page_index: int, animate: bool = false) -> void:
	var target_x: float = -(page_width + page_separation) * page_index
	
	if animate:
		is_animating = true
		var tween: Tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(pages_container, "position:x", target_x, 0.3)
		tween.finished.connect(func() -> void: is_animating = false)
	else:
		pages_container.position.x = target_x


## Update bottom navigation buttons to reflect current page
func _update_page_indicator(page_index: int) -> void:
	navigation_bar.set_active_button(page_index)


## Handle NavigationBar page change
func _on_navigation_bar_page_changed(index: int) -> void:
	_navigate_to_page(index)


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
