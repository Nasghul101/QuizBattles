# Spec: Socials Page Popup Animation

**Capability ID:** `socials-page-popup-animation`  
**Last Updated:** 2026-01-24  
**Status:** Proposed

## Overview
Animated popup system for the Socials Page that displays an AddFriendsPopup panel with smooth slide-up/slide-down transitions and a semi-transparent overlay for visual focus.

---

## ADDED Requirements

### Requirement: Popup Open Animation
The system SHALL provide a smooth animation that slides the AddFriendsPopup from below the screen upwards to fill the entire screen, with a semi-transparent overlay fading in simultaneously when the user presses the AddNewFriendButton.

#### Scenario: User presses AddNewFriendButton to open popup
- **Given:** The Socials Page is displayed with AddFriendsPopup initially invisible and positioned off-screen below
- **When:** The user presses the AddNewFriendButton
- **Then:** 
  - The PopupOverlay fades in to 40% black opacity over 0.3 seconds
  - The AddFriendsPopup slides upward from below the screen to fill the entire screen over 0.3 seconds
  - The animation uses ease-in-out quadratic easing for smooth motion
  - The popup becomes fully visible and interactive after animation completes
  - The overlay blocks touch input from reaching background UI elements

#### Scenario: AddFriendsPopup preserves input fields during animation
- **Given:** The AddFriendsPopup contains a NameInput TextEdit field
- **When:** The popup is animating open
- **Then:**
  - The input field state is preserved (not cleared)
  - Any previous text remains in the field
  - The field becomes interactive once animation completes

---

### Requirement: Popup Close Animation
The system SHALL animate the AddFriendsPopup closed by sliding it downward off-screen with the overlay fading out when the user presses the AddNewFriendButton to close the popup.

#### Scenario: User presses AddNewFriendButton to close open popup
- **Given:** The Socials Page is displayed with AddFriendsPopup currently visible and animated open
- **When:** The user presses the AddNewFriendButton again
- **Then:**
  - The PopupOverlay fades out from 40% to 0% black opacity over 0.3 seconds
  - The AddFriendsPopup slides downward off-screen over 0.3 seconds
  - The animation uses ease-in-out quadratic easing for smooth motion
  - The popup becomes invisible and non-interactive after animation completes
  - The overlay is hidden and no longer blocks input

#### Scenario: Multiple open-close cycles maintain consistent animation
- **Given:** The popup has been opened and closed previously
- **When:** The user presses AddNewFriendButton to open/close multiple times in sequence
- **Then:**
  - Each animation cycle takes exactly 0.3 seconds
  - No animation stuttering or visual glitches occur
  - The popup returns to the exact same off-screen position each time

---

### Requirement: Animation Interruption Handling
The system SHALL handle animation interruption gracefully. If the user presses AddNewFriendButton while an animation is already in progress, the system MUST cancel the ongoing animation and begin the opposite animation (open→close or close→open) without visual glitches.

#### Scenario: User clicks button during open animation
- **Given:** The popup is currently animating open
- **When:** The user presses the AddNewFriendButton before the open animation completes
- **Then:**
  - The ongoing animation is cancelled smoothly
  - The close animation begins immediately or queues appropriately
  - No visual glitches or janky transitions occur
  - The popup smoothly reverses direction or transitions without artifacts

---

### Requirement: Overlay Input Blocking
The system SHALL use a PopupOverlay to prevent user interaction with any UI elements behind the popup (FriendsList, other VBoxContainer children) while the popup is visible and animating. The overlay MUST block all input events from reaching background UI elements.

#### Scenario: Overlay blocks background input while popup is open
- **Given:** The AddFriendsPopup is currently visible with PopupOverlay active
- **When:** The user attempts to click on the AddNewFriendButton or any FriendsList element behind the overlay
- **Then:**
  - The click event is consumed by the PopupOverlay
  - The background UI elements do not receive the input event
  - The overlay's mouse filter is set to STOP

#### Scenario: Overlay is transparent when popup is closed
- **Given:** The popup is closed and PopupOverlay is hidden
- **When:** The user attempts to click on the AddNewFriendButton or FriendsList
- **Then:**
  - The click events pass through to the underlying UI elements
  - The AddNewFriendButton responds normally to clicks
  - The overlay is either hidden or has mouse filter set to IGNORE when inactive

---

### Requirement: Popup Initial State
The system SHALL initialize the AddFriendsPopup and PopupOverlay in the correct hidden state on scene load. The popup MUST be positioned off-screen below the visible area, and the overlay MUST have 0% opacity and be hidden.

#### Scenario: Popup is invisible on scene load
- **Given:** The Socials Page scene is loaded
- **When:** The scene finishes loading and _ready() is called
- **Then:**
  - The AddFriendsPopup is positioned off-screen (below the visible area)
  - The PopupOverlay is hidden with 0% opacity
  - No animation plays on load
  - The AddNewFriendButton is clickable and functional

---

## Cross-References
- **Related to:** `socials-page` (parent screen)
- **Depends on:** None (uses only Godot built-in Tween system)
- **Future capability:** `socials-page-friend-search` (popup content will be implemented in separate spec)

---

## Implementation Notes
- Use Godot 4.5+ Tween system for all animations
- All animations must complete within 0.3 seconds ± 50ms tolerance
- Easing function: `Tween.EASE_IN_OUT` with `Tween.TRANS_QUAD`
- PopupOverlay color: `Color(0, 0, 0, 0.4)` when visible (black at 40% opacity)
- Maintain animation performance for mobile devices (target 60 FPS)
