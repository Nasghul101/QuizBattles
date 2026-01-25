# Design Document: Socials Page Popup Animation System

## Architecture Overview

The popup animation system uses Godot's built-in `Tween` system for smooth, performance-optimized animations. The system consists of:

1. **Overlay Node** - ColorRect that blocks input and provides visual focus
2. **PopupPanel** - The AddFriendsPopup Control node that slides in/out
3. **Animation Controller** - Logic in socials_page.gd that orchestrates animation sequences
4. **State Management** - Tracks popup open/closed state to prevent conflicting animations

## Animation Specifications

### Slide-Up Animation (Open)
- **Duration:** 0.3 seconds
- **Easing:** `Tween.EASE_IN_OUT` with `Tween.TRANS_QUAD`
- **Movement:** Y position from `get_viewport_rect().size.y` (off-screen) to 0 (full visible)
- **Parallel animation:** Overlay opacity from 0 to 0.5 (40% opacity)

### Slide-Down Animation (Close)
- **Duration:** 0.3 seconds
- **Easing:** `Tween.EASE_IN_OUT` with `Tween.TRANS_QUAD` (mirrored)
- **Movement:** Y position from 0 to `get_viewport_rect().size.y` (off-screen)
- **Parallel animation:** Overlay opacity from 0.5 to 0

### Overlay Behavior
- **Node Type:** ColorRect (transparent background, only visible when popup is open/animating)
- **Color:** Black with 0% opacity initially, 40% opacity when popup is fully visible
- **Input blocking:** Mouse filter set to STOP to prevent interaction with background
- **Parent:** Root of socials_page scene (so it sits behind the popup)

## Technical Implementation Strategy

### State Tracking
```gdscript
var is_popup_open: bool = false
var animation_in_progress: bool = false
```

Prevents simultaneous animations and ensures button state is accurate.

### Animation Sequence
1. Check if animation is already in progress; if so, return early
2. Set `animation_in_progress = true`
3. Create Tween for popup position and overlay opacity
4. On animation complete, update `is_popup_open` and set `animation_in_progress = false`

### Button Signal Handlers
- `AddNewFriendButton.pressed()` → Toggle popup (open if closed, close if open)
- `AddFriendsPopup.visibility_changed()` → Not used; rely on explicit animation control instead

## Godot Node Structure
The existing node structure in socials_page.tscn already supports this:
- AddFriendsPopup (Panel) → needs `margin_top` modified during animation
- AddNewFriendButton → signal already connected, handler to be implemented

**New Node Required:**
- Overlay (ColorRect) → Create programmatically or add to scene file before implementation

## Future Extensibility

This animation system establishes patterns for:
- Other popup animations (future friend search results, friend requests, etc.)
- Reusable tween library functions if multiple popups are added
- Potential overlay utility for modal dialogs

## Performance Considerations

- **Tweens:** Godot's built-in Tween system is highly optimized for 2D transforms
- **Target devices:** Works smoothly on Android 8+ and iOS 12+ (tested scope)
- **No continuous updates:** Animation runs only during transition, minimal per-frame cost during static state
