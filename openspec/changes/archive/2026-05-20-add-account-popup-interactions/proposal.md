# Proposal: Add Account Popup Interactions

## Why
The `AccountPopup` exists in `socials_page.tscn` with all its UI nodes (FriendName label, piechart, statistics labels, UnfriendPopup) but none of the interactive behaviour is wired up. The `account_popup.gd` script has empty handler stubs. Pressing a `FriendDisplayComponent` does nothing, and the back/unfriend/invite buttons are non-functional.

## What Changes

### FriendDisplayComponent – expose pressed signal
`FriendDisplayComponent` must expose a `pressed` signal (forwarding the internal `%FriendDisplayButton.pressed`) so parent scenes can connect without reaching into its internals.

### SocialsPage – open AccountPopup on friend press
`socials_page.gd` connects to each `FriendDisplayComponent`'s `pressed` signal when it instantiates them. On press it calls `AccountPopup.open_for_friend(friend_username)` and makes the AccountPopup visible.

### AccountPopup – populate and handle all interactions
`account_popup.gd` gains a `open_for_friend(friend_username: String)` method that:
- Stores the displayed friend's username
- Populates `FriendName` label with the friend's username
- Reads the friend's global stats (`wins`, `losses`, `total_games`) from `UserDatabase.get_user_data_for_display()` and derives draws as `total_games - wins - losses`
- Calls `Piechart.set_chart(wins, draws, total_games)` to render the piechart
- Sets the `TotalGamesAmount`, `WinsAmount`, `DrawsAmount`, `LossAmount` labels
- Resets the InviteToDuelButton to enabled
- Shows the AccountPopup (sets `visible = true`)

**Back button**: hides the AccountPopup (sets `visible = false`).

**Invite to Duel button**: already specced; wires up the existing empty stub to emit a game invite notification via `GlobalSignalBus.notification_received`. No change to spec required — implementation only.

**Unfriend button**: shows `UnfriendPopup` by setting its `visible = true`.

**UnfriendPopup – No button**: hides `UnfriendPopup`.

**UnfriendPopup – Yes button**: calls `UserDatabase.remove_friend(current_user, friend_username)`, hides the AccountPopup (both inner and outer), and emits a signal so `SocialsPage` can refresh the friend list.

## Affected Specs
| Spec | Change type |
|---|---|
| `account-management-screen` | MODIFIED – new requirements for open/populate/close/unfriend |
| `socials-page-friend-display` | MODIFIED – FriendDisplayComponent pressed signal; SocialsPage popup wiring |

## User Experience Flow

### Opening the popup
1. Socials page is open showing a list of friends.
2. User taps a `FriendDisplayComponent`.
3. `AccountPopup` slides/appears over the socials page.
4. FriendName, statistics labels, and piechart are filled with the friend's data.

### Closing the popup
- User taps the back (✕) button → AccountPopup hides.

### Sending a duel invite (existing flow, needs wiring)
- User taps "Invite to duel" → game invite notification sent, button disabled for session.

### Unfriending
1. User taps "Unfriend" → `UnfriendPopup` appears.
2. User taps "No" → `UnfriendPopup` hides, AccountPopup remains visible.
3. User taps "Yes" → friendship removed bidirectionally, both popups close, friends list refreshes.

## Dependencies
- `UserDatabase.remove_friend()` – already implemented.
- `UserDatabase.get_user_data_for_display()` – already implemented (provides `wins`, `losses`, `total_games`).
- `Piechart.set_chart()` – already implemented.
- Game invite notification flow – already specced in `account-management-screen`.

## Success Criteria
1. Pressing any `FriendDisplayComponent` opens the `AccountPopup` with correct friend data.
2. The piechart and all four statistic labels show the friend's global wins/losses/draws/total.
3. Back button hides the popup without side effects.
4. Invite to Duel button wires up to the existing notification flow.
5. Unfriend button shows the confirmation popup.
6. Confirming unfriend removes friendship bidirectionally in the database and refreshes the friends list.
7. Cancelling unfriend leaves the friendship intact and returns to the AccountPopup.
