class_name NotificationsPopUp extends PopUp
## Notifications pop-up
##
## Owns the notification list: instantiates notification components, handles their
## accept/deny actions, the "mark all as read" button and the local unverified-email reminder.
## The main lobby screen drives it (load, live updates, reminder refresh) and reacts to
## [signal unread_changed] to highlight the notifications button.

## Emitted whenever the unread state may have changed.
signal unread_changed(has_unread: bool)

## Id of the local (not stored in Firestore) unverified-email reminder notification
const EMAIL_REMINDER_ID := "local_email_verification_reminder"

const NOTIFICATION_COMPONENT = preload("res://scenes/ui/components/notification_component.tscn")

@onready var notification_list_container: VBoxContainer = %NotificationListContainer
@onready var no_notifications_label: Label = %NoNotificationsLabel

var notification_components: Array[Control] = []

var _email_reminder_component: Control
var _email_reminder_busy: bool = false


## Load the stored notifications of the signed-in user.
func load_notifications() -> void:
    if not UserDatabase.is_signed_in():
        return

    var notifications: Array = await UserDatabase.get_notifications(UserDatabase.current_user.username)
    for notif_data: Dictionary in notifications:
        _instantiate_notification_component(notif_data)
    await update_unread_state()


## Show a notification that was just received, if it is meant for the signed-in user.
func add_received_notification(notification_data: Dictionary) -> void:
    if not UserDatabase.is_signed_in():
        return
    if notification_data.get("recipient_username", "") != UserDatabase.current_user.username:
        return

    _instantiate_notification_component(notification_data)
    await update_unread_state()


## Apply remotely detected notification changes without a screen switch.
func apply_notification_changes(added: Array, removed: Array) -> void:
    for removed_id: String in removed:
        var component: Control = _find_component(removed_id)
        if component != null:
            _remove_component(component)

    for notif_data: Dictionary in added:
        if _find_component(str(notif_data.get("id", ""))) == null:
            _instantiate_notification_component(notif_data)

    await update_unread_state()


## Recompute the empty label and tell the lobby whether anything is unread.
func update_unread_state() -> void:
    no_notifications_label.visible = notification_components.is_empty()

    if not UserDatabase.is_signed_in():
        unread_changed.emit(false)
        return

    var unread_count: int = await UserDatabase.get_unread_count(UserDatabase.current_user.username)
    var reminder_unread: bool = is_instance_valid(_email_reminder_component) and not UserDatabase.email_reminder_read
    unread_changed.emit(unread_count > 0 or reminder_unread)


## Check the verification status and show or remove the reminder notification accordingly.
## A failed status check leaves an existing reminder in place and never treats the email as verified.
func refresh_email_reminder() -> void:
    if _email_reminder_busy or not UserDatabase.is_signed_in():
        return

    _email_reminder_busy = true
    var result: Dictionary = await UserDatabase.refresh_email_verification_status()
    _email_reminder_busy = false
    if not UserDatabase.is_signed_in():
        return

    if not result.get("success", false):
        push_warning("Could not refresh email verification status (%s): %s" % [
            result.get("error_code", "UNKNOWN"),
            result.get("message", "No error details returned")
        ])
        _set_email_reminder_message("ACCOUNT_MANAGEMENT_EMAIL_STATUS_FAILED")
        return

    if result.get("provider_id", "") != "password" or result.get("email_verified", false):
        _remove_email_reminder()
    else:
        _show_email_reminder("ACCOUNT_MANAGEMENT_EMAIL_VERIFICATION_REMINDER")
    await update_unread_state()


## Mark all notifications as read. The email reminder stays listed but stops highlighting the icon.
func _on_mark_as_read_button_pressed() -> void:
    if not UserDatabase.is_signed_in():
        return

    var result: Dictionary = await UserDatabase.mark_all_notifications_read(UserDatabase.current_user.username)
    if not result.get("success", false):
        push_error("Could not mark notifications as read: %s" % result.get("message", "Unknown error"))
    UserDatabase.email_reminder_read = true
    await update_unread_state()


func _find_component(notification_id: String) -> Control:
    for component: Control in notification_components:
        if not is_instance_valid(component):
            continue
        var data: Variant = component.get("notification_data")
        if data is Dictionary and data.get("id") == notification_id:
            return component
    return null


func _remove_component(component: Control) -> void:
    notification_components.erase(component)
    component.queue_free()


func _instantiate_notification_component(notification_data: Dictionary) -> Control:
    var component: Variant = NOTIFICATION_COMPONENT.instantiate()

    # Add to the tree first so the component's @onready variables are initialized
    notification_list_container.add_child(component)
    notification_components.append(component)
    component.set_notification_data(notification_data)
    component.action_taken.connect(_on_notification_action)
    return component


## Handle notification action (accept/deny)
func _on_notification_action(notification_id: String, action: String) -> void:
    if not UserDatabase.is_signed_in():
        return

    if notification_id == EMAIL_REMINDER_ID:
        # The reminder reuses the two action buttons: accept = resend, deny = refresh status
        if action == "accept":
            await _resend_email_verification()
        else:
            await refresh_email_reminder()
        return

    var matching_component: Control = _find_component(notification_id)
    if matching_component == null:
        push_warning("Notification action ignored because notification %s is no longer displayed" % notification_id)
        return
    var notification_data: Dictionary = matching_component.get("notification_data")

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
        _remove_component(matching_component)

    GlobalSignalBus.notification_action_taken.emit(notification_data, action)
    await update_unread_state()


func _resend_email_verification() -> void:
    if _email_reminder_busy:
        return

    _email_reminder_busy = true
    var result: Dictionary = await UserDatabase.send_email_verification()
    _email_reminder_busy = false
    if result.get("success", false):
        _set_email_reminder_message("ACCOUNT_MANAGEMENT_EMAIL_VERIFICATION_SENT")
    else:
        push_warning("Verification email request failed (%s): %s" % [
            result.get("error_code", "UNKNOWN"),
            result.get("message", "No error details returned")
        ])
        _set_email_reminder_message("ACCOUNT_MANAGEMENT_EMAIL_VERIFICATION_SEND_FAILED")


func _show_email_reminder(message_key: String) -> void:
    if is_instance_valid(_email_reminder_component):
        _set_email_reminder_message(message_key)
        return

    _email_reminder_component = _instantiate_notification_component(_email_reminder_data(message_key))
    notification_list_container.move_child(_email_reminder_component, 0)


func _set_email_reminder_message(message_key: String) -> void:
    if is_instance_valid(_email_reminder_component):
        _email_reminder_component.set_notification_data(_email_reminder_data(message_key))


func _remove_email_reminder() -> void:
    if not is_instance_valid(_email_reminder_component):
        return
    _remove_component(_email_reminder_component)
    _email_reminder_component = null


func _email_reminder_data(message_key: String) -> Dictionary:
    return {
        "id": EMAIL_REMINDER_ID,
        "message": message_key,
        "has_actions": true,
        "accept_label": "ACCOUNT_MANAGEMENT_RESEND_VERIFICATION_BUTTON",
        "deny_label": "ACCOUNT_MANAGEMENT_REFRESH_VERIFICATION_BUTTON"
    }
