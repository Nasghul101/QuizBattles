# uid://b11jdqaf8o7sv
extends Control
## Main Lobby Screen
##
## Entry point screen that provides access to game features and account management.
## Conditionally navigates to account screens based on user login state.
## Supports multi-page navigation with swipe gestures and bottom navigation buttons.
## Displays and manages notifications with visual indicators.

## Color to apply to notifications button when unread notifications exist
@export var notification_indicator_color: Color = Color(1.0, 0.8, 0.0)  # Yellow

## Reference to the container holding page content
@onready var page_clip_container: PageClipContainer = %PageClipContainer
@onready var navigation_bar: PanelContainer = %NavigationBar
@onready var notifications_button: TextureButton = %NotificationsButton
@onready var notifications_popup: NotificationsPopUp = %NotificationsPopUp
@onready var page_name: Label = %PageName

## Current page tracking
var current_page: int = 0


func _ready() -> void:
    if not LocalCache.session_restore_done:
        await LocalCache.session_restore_finished

    # The lobby wires the notification sources to the pop-up, which manages the list itself
    notifications_popup.unread_changed.connect(_on_notifications_unread_changed)
    GlobalSignalBus.notification_received.connect(notifications_popup.add_received_notification)
    GlobalSignalBus.notifications_changed.connect(notifications_popup.apply_notification_changes)

    await notifications_popup.load_notifications()
    await notifications_popup.update_unread_state()

    # Set initial page name
    _update_page_name(current_page)
    
    if not page_clip_container.is_initialized:
        await page_clip_container.initialized
    current_page = Utils.last_lobby_page
    page_clip_container.current_page = current_page
    page_clip_container.animate_to_page(current_page)
    _update_page_indicator(current_page)
    _update_page_name(current_page)

    await notifications_popup.refresh_email_reminder()


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
            page_name.text = tr("MAIN_LOBBY_PAGE_NAME_CHALLENGE")
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


## Highlight the notifications button while something is unread
func _on_notifications_unread_changed(has_unread: bool) -> void:
    notifications_button.modulate = notification_indicator_color if has_unread else Color.WHITE
