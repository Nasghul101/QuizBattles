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
@onready var page_name: Label = %PageName

## Current page tracking
var current_page: int = 0

## Track instantiated notification components
var notification_components: Array[Control] = []


func _ready() -> void:
    if not LocalCache.session_restore_done:
        await LocalCache.session_restore_finished

    # Connect to GlobalSignalBus for notifications
    GlobalSignalBus.notification_received.connect(_on_notification_received)
    
    # Load existing notifications for current user
    await _load_existing_notifications()
    
    # Update notification indicator
    await _update_notification_indicator()

    # Set initial page name
    _update_page_name(current_page)
    
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
    _update_page_name(current_page)


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
    _update_page_name(current_page)


## Handle AccountButton press with conditional navigation based on login state
func _update_page_name(page_index: int) -> void:
    match page_index:
        0:
            page_name.text = tr("MAIN_LOBBY_PAGE_NAME_DUEL")
        1:
            page_name.text = tr("MAIN_LOBBY_PAGE_NAME_SHOP")
        2:
            page_name.text = tr("MAIN_LOBBY_PAGE_NAME_FRIENDLY_BATTLE")
        3:
            page_name.text = tr("MAIN_LOBBY_PAGE_NAME_SOCIALS")
        _:
            page_name.text = ""

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
    
    var notifications: Array = await UserDatabase.get_notifications(UserDatabase.current_user.username)
    
    # Instantiate a component for each notification
    for notif_data: Dictionary in notifications:
        _instantiate_notification_component(notif_data)


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
    await _update_notification_indicator()


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
    
    var notification_data: Dictionary = {}
    var matching_component: Control
    for i in range(notification_components.size()):
        var component: Control = notification_components[i]
        
        # Check if this component matches the notification_id
        if component.has_method("set_notification_data"):
            # Access notification_data if available
            if component.get("notification_data") is Dictionary:
                var data: Dictionary = component.get("notification_data")
                if data.get("id") == notification_id:
                    notification_data = data
                    matching_component = component
                    break

    if notification_data.is_empty():
        push_warning("Notification action ignored because notification %s is no longer displayed" % notification_id)
        return

    var action_data: Dictionary = notification_data.get("action_data", {})
    if action == "accept":
        if action_data.get("type") == "friend_request":
            var sender: String = notification_data.get("sender", "")
            var friendship: Dictionary = await UserDatabase.add_friend(
                UserDatabase.current_user.username,
                sender
            )
            if not friendship.get("success", false):
                push_error("Could not accept friend request: %s" % friendship.get("message", "Unknown error"))
                return
        elif action_data.get("type") == "game_invite":
            var inviter: String = str(action_data.get("inviter_id", ""))
            if inviter.is_empty():
                push_error("Game invite is missing inviter_id")
                return
            var match_id: String = await UserDatabase.create_match(
                inviter,
                UserDatabase.current_user.username,
                int(action_data.get("rounds", 3)),
                int(action_data.get("questions", 2))
            )
            if match_id.is_empty():
                push_error("Could not create a match for the accepted game invite")
                return
            GlobalSignalBus.match_created.emit(
                match_id,
                inviter,
                UserDatabase.current_user.username
            )
            GlobalSignalBus.game_invite_accepted.emit(inviter, UserDatabase.current_user.username)

    var removed: Dictionary = await UserDatabase.remove_notification(
        UserDatabase.current_user.username,
        notification_id
    )
    if not removed.get("success", false):
        push_error("Could not remove notification: %s" % removed.get("message", "Unknown error"))
        return

    if is_instance_valid(matching_component):
        notification_components.erase(matching_component)
        matching_component.queue_free()

    GlobalSignalBus.notification_action_taken.emit(notification_data, action)
    await _update_notification_indicator()


## Update visual indicator on notifications button based on unread count
func _update_notification_indicator() -> void:
    no_notifications_label.visible = notification_components.is_empty()

    if not UserDatabase.is_signed_in():
        notifications_button.modulate = Color.WHITE
        return
    
    var unread_count: int = await UserDatabase.get_unread_count(UserDatabase.current_user.username)
    
    if unread_count > 0:
        notifications_button.modulate = notification_indicator_color
    else:
        notifications_button.modulate = Color.WHITE
