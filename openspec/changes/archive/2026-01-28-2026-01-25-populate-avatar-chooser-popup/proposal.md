# Proposal: Populate Avatar Chooser Popup

**Change ID**: `2026-01-25-populate-avatar-chooser-popup`  
**Date**: January 25, 2026  
**Status**: Proposal

## Overview

Implement popup behavior to dynamically populate the `ChooseAvatarPopup` with avatar selection options when the user presses the `UserAvatar` button on the Account Management Screen. Each avatar option will be represented as an `AvatarComponent` displaying a profile picture from the `profile_pictures` folder along with its filename as a label.

## Why

Users need a visual way to select their profile avatar. The Account Management Screen already has a `UserAvatar` button and `ChooseAvatarPopup` UI structure, but they are not yet connected or populated with actual avatar options. This change bridges that gap by dynamically loading available avatars and displaying them in a modal popup.

## What Changes

- `account_management_screen.gd` will handle the `UserAvatar` button press signal and show the `ChooseAvatarPopup`
- `account_management_screen.gd` will scan `res://assets/profile_pictures/` and instantiate `AvatarComponent` instances for each PNG
- `avatar_component.gd` will expose `set_avatar_picture()` and `set_avatar_name()` utility functions
- `ChooseAvatarPopup` will be configured as modal

## Goals

1. Populate `AvatarContainer` with `AvatarComponent` instances for each PNG in `assets/profile_pictures/`
2. Display the popup as modal when `UserAvatar` button is pressed
3. Ensure `AvatarComponent` has utility functions to set its picture and name dynamically
4. Create clean separation of concerns: popup shows avatars, components manage their own state

## Scope

- Modify `account_management_screen.gd` to handle `UserAvatar` button press and show popup
- Add utility functions to `avatar_component.gd` to set picture and name
- Modify `account_management_screen.gd` to scan `profile_pictures` folder and instantiate avatar components
- Configure `ChooseAvatarPopup` to be modal

## Non-Scope

- Database storage or persistence of avatar selection
- Avatar selection click handling (will be handled in follow-up work)
- Popup dismiss behavior beyond being modal

## Related Specs

- [Avatar Component](../../specs/result-button-component/) (closest related component pattern)
- [Account Management Screen](../../specs/account-management-screen/spec.md)

## Risks & Open Questions

None identified at this stage.
