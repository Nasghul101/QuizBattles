# Change Proposal: Add User Avatar Persistence

**Change ID:** `add-user-avatar-persistence`  
**Date:** 2026-01-28  
**Status:** Proposed

## Summary

Add avatar image persistence to the user account system, enabling users to select and save profile pictures during registration and account management. The system will store avatar paths as string references in the database, not the actual image data.

## Background

The Account Management Screen already displays a `UserAvatar` button and has a `ChooseAvatarPopup` that shows available profile pictures. However, there is currently no way to:
1. Assign a default avatar when creating an account
2. Persist the user's avatar selection
3. Update the avatar when a user selects a new one from the popup

This change bridges that gap by extending the database schema and implementing selection/persistence logic.

## Motivation

- **User Personalization**: Players should be able to choose and save their preferred profile picture
- **Visual Identity**: Avatars provide a visual representation of user accounts throughout the app
- **Data Efficiency**: Store only file path references (strings) rather than large binary image data
- **Complete User Flow**: Registration → Selection → Persistence should work end-to-end

## Solution

### Core Changes

1. **Extend UserDatabase Schema**
   - Add `avatar_path` field to user records (String)
   - Default value: `"res://assets/profile_pictures/man_standard.png"`
   - Add `update_avatar()` method to change current user's avatar

2. **Update Account Registration**
   - Automatically assign default avatar path when creating new accounts

3. **Implement Avatar Selection Flow**
   - Connect `pressed` signals from `AvatarComponent` instances in the popup
   - When user clicks an avatar: update database, refresh UI, close popup
   - Load and display current user's avatar in `UserAvatar` button on screen load

4. **Add Avatar Display in Account Management**
   - Show current user's avatar image in the `UserAvatar` button
   - Refresh button texture when avatar changes

### Affected Capabilities

- **local-user-database**: Add avatar_path field and update methods
- **account-registration-screen**: Set default avatar on account creation
- **avatar-selection-popup**: Add selection behavior and persistence
- **account-management-screen**: Display and update user avatar

## Dependencies

- Existing `AvatarComponent` scene and utility functions
- Existing `ChooseAvatarPopup` UI structure and drag behavior
- Existing profile pictures in `assets/profile_pictures/`

## Risks & Considerations

- **Invalid Paths**: If avatar_path references a non-existent file, fallback to default
- **Backward Compatibility**: Existing user records (if any) don't have avatar_path → use default
- **Image Loading**: Use `load()` for resource paths; handle null textures gracefully

## Success Criteria

- [ ] New accounts automatically receive `man_standard.png` as default avatar
- [ ] `UserAvatar` button displays the user's current avatar image
- [ ] Clicking an avatar in the popup updates the database and UI
- [ ] Popup closes immediately after avatar selection
- [ ] Avatar persists across screen navigation (stays with user session)
- [ ] Invalid avatar paths fall back to `man_standard.png`

## Out of Scope

- Creating new avatar images or importing additional pictures
- Uploading custom user images (only pre-defined avatars)
- Avatar validation or file existence checking on database write
- UI notifications or confirmation messages on avatar change
