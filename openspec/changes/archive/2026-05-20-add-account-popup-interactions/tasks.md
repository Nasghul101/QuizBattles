# Implementation Tasks: Account Popup Interactions

## Task 1: Expose pressed signal in FriendDisplayComponent
- [x] Add `signal pressed` at the top of the script (after `class_name`)
- [x] Connect `%FriendDisplayButton.pressed` to a private handler in `_ready()`
- [x] In the handler, emit `pressed`

---

## Task 2: Attach account_popup.gd to the inline AccountPopup in socials_page.tscn
- [x] Script already attached in account_popup.tscn (`script = ExtResource("1_p8j0m")`) — no editor action required

---

## Task 3: Implement open_for_friend() and handler stubs in account_popup.gd
- [x] Add `var _displayed_friend_username: String = ""` field
- [x] Add `signal friend_removed`
- [x] Implement `open_for_friend(friend_username)`
- [x] Implement `_on_account_back_button_pressed()`
- [x] Implement `_on_unfried_buton_pressed()`
- [x] Implement `_on_no_button_pressed()`
- [x] Implement `_on_yes_button_pressed()`
- [x] Implement `_on_invite_to_duel_button_pressed()`

---

## Task 4: Wire AccountPopup into SocialsPage
- [x] Add `@onready var account_popup: AccountPopup = %AccountPopup`
- [x] Connect `account_popup.friend_removed` to `_populate_friends_list` in `_ready()`
- [x] Connect `display.pressed` to `_on_friend_display_pressed.bind(friend_username)` in `_populate_friends_list()`
- [x] Implement `_on_friend_display_pressed(friend_username: String)`

---

## Implementation Checklist

- [ ] Task 1: FriendDisplayComponent pressed signal
- [ ] Task 2: Attach script to inline AccountPopup in socials_page.tscn
- [ ] Task 3: Implement account_popup.gd logic
- [ ] Task 4: Wire AccountPopup into SocialsPage

## Parallelizable Work
- Tasks 1 and 2 are independent and can be done in parallel.
- Task 3 depends on Task 2.
- Task 4 depends on Tasks 1 and 3.
