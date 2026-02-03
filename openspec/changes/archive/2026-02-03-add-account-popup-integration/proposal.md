# Change Proposal: Add Account Popup Integration

## Change ID
`add-account-popup-integration`

## Context
The game currently has an account_popup scene created at `scenes/ui/account_ui/account_popup.tscn` with a basic structure (NameLabel, PlayerAvatar, BackButton) but no functionality. Friends are displayed in the socials page using avatar components, but clicking on a friend avatar does nothing. The application needs a reusable way to display user account information across multiple scenes without tight coupling to any specific page.

## Problem
- The account_popup scene exists but has no data-binding or display logic
- Avatar components in the FriendsList (and potentially other locations) need to trigger the account popup when clicked
- The popup needs to fetch and display user data from UserDatabase without hardcoding scene-specific logic
- User statistics (wins, losses, current_streak) are planned features but don't yet exist in the database schema
- The popup should be reusable across multiple scenes (socials page, match results, leaderboards, etc.)
- No mechanism exists to close the popup via overlay click or back button

## Proposed Solution
Implement a complete account popup system with three interconnected components:

1. **Account Popup Component** (new capability)
   - Create display logic in `account_popup.gd` to accept a user_id and fetch data from UserDatabase
   - Display username, avatar, and user statistics (wins, losses, current_streak)
   - Implement modal overlay behavior with click-outside-to-close functionality
   - Handle back button to close popup
   - Position centered with responsive margins
   - Explicitly exclude sensitive data (password, email) from being displayed

2. **Avatar Component** (modify existing)
   - Add signal `avatar_clicked(user_id: String)` emitted when the button is pressed
   - Add method to store and retrieve user_id: `set_user_id(id: String)` and `get_user_id() -> String`
   - Maintain existing functionality (set_avatar_picture, set_avatar_name)

3. **Local User Database** (modify existing)
   - Extend user data schema to include: `wins: int`, `losses: int`, `current_streak: int`
   - Initialize new fields with default value `0` for new and existing users
   - Add method `get_user_data_for_display(username: String) -> Dictionary` that returns user data safe for UI display (excludes password_hash, email)
   - Ensure backward compatibility by adding migration logic for existing users in database

## Goals
- Enable clicking on any friend avatar to view their account details
- Create a reusable account popup that any scene can integrate
- Lay the groundwork for future gameplay statistics display
- Maintain separation of concerns (popup doesn't know about specific parent scenes)
- Ensure security by explicitly filtering sensitive user data

## Non-Goals
- Implementing actual win/loss/streak tracking gameplay logic (future work)
- Adding animated transitions to the popup (explicitly no animation)
- Implementing drag-to-dismiss behavior (stays fixed center)
- Adding edit/settings functionality to the popup
- Implementing friend management actions from within the popup

## Dependencies
- Existing: UserDatabase autoload service
- Existing: GlobalSignalBus (optional, for future decoupled communication)
- Existing: avatar_component scene and script
- New: account_popup scene and script

## Impact
- **Modified capabilities**: avatar-component, local-user-database
- **New capabilities**: account-popup-component
- **Affected scenes**: socials_page (needs to wire avatar clicks to popup)
- **Schema change**: UserDatabase adds three integer fields to user records

## Testing Strategy
- Manual testing: Click friend avatar in socials page → popup opens with correct data
- Manual testing: Click overlay → popup closes
- Manual testing: Click back button → popup closes
- Manual testing: Verify sensitive data (password, email) not accessible to popup
- Unit testing: UserDatabase migration of existing users to new schema
- Integration testing: Multiple scenes using the same popup instance correctly
