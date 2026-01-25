# Proposal: Add Socials Page Popup Animation

**Change ID:** `add-socials-page-popup-animation`  
**Status:** Draft  
**Created:** 2026-01-24

## Why
Mobile app users expect smooth, animated UI transitions when popups appear or disappear. Static visibility changes create a jarring experience. Implementing a slide-up popup animation with an overlay establishes a professional, responsive feel that aligns with mobile app standards and improves user engagement on the Socials page.

## Problem Statement

The Socials Page features an `AddFriendsPopup` panel designed to allow users to add new friends. Currently, the popup is a static Control node that simply becomes visible/invisible without any animation or visual feedback. This creates a jarring user experience where the popup instantly appears on screen.

The feature needs a smooth, animated transition to enhance mobile UX and provide clear visual feedback when the popup is opened or closed.

## Proposed Solution

Implement a slide-up animation system for the AddFriendsPopup that:

1. **Opens with a smooth slide-up animation** - The popup slides from below the screen upwards to fill the full screen with `ease_in_out` easing
2. **Includes a semi-transparent overlay** - A darkened overlay appears behind the popup to focus user attention and prevent interaction with content behind it
3. **Closes with a slide-down animation** - The popup slides back down off-screen with mirrored animation behavior
4. **Multiple close triggers** - Users can close the popup by either:
   - Pressing the AddNewFriendButton again (toggle behavior)
   - Sliding the popup back down manually (if swiping is implemented in future)
5. **Non-blocking interaction** - The overlay blocks touch events from reaching underlying UI elements while the popup is visible

## Impact Assessment

### Benefits
- **Improved user experience** with smooth, professional animations
- **Clear visual hierarchy** via overlay preventing accidental interaction with background
- **Mobile-friendly** slide-from-bottom pattern aligns with mobile app standards
- **Foundation for future expansion** - establishes reusable animation patterns for other popups

### Risks
- **Animation performance** on older mobile devices; mitigation through optimization and Godot 4.5's efficient 2D rendering
- **No breaking changes** - existing popup structure is preserved, only animation behavior added

### Affected Components
- `socials_page.tscn` - AddFriendsPopup node structure (no changes needed)
- `socials_page.gd` - Implementation of popup open/close logic with animation

### Non-Affected Components
- FriendsList GridContainer (not implemented yet, future feature)
- Friend system backend (no implementation in this proposal)
- Other lobby pages (isolated to socials page only)

## Dependencies
None - uses built-in Godot Tween system for animations.

## Alternatives Considered

1. **Fade-in animation only** - Simple opacity change
   - **Rejected:** Less engaging than slide animation; doesn't leverage vertical screen space

2. **Slide-in from side** - Slide from left or right
   - **Rejected:** Mobile apps typically use bottom-sheet pattern for this use case

3. **Scale animation** - Grow from center of screen
   - **Rejected:** Less intuitive on mobile; bottom-sheet slide is more natural

## Timeline Estimate
2-3 hours for implementation and testing.

## Next Steps
1. Approval of this proposal
2. Proceed to implementation phase with tasks.md and design.md
