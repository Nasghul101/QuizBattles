# Tasks: Add Socials Page Popup Animation

**Change ID:** `add-socials-page-popup-animation`

## Implementation Checklist

- [x] **Task 1:** Review design.md and understand animation specifications
- [x] **Task 2:** Add Overlay ColorRect node to socials_page.tscn scene
- [x] **Task 3:** Configure Overlay node properties (color, anchors, mouse filter)
- [x] **Task 4:** Implement open_popup() function in socials_page.gd
- [x] **Task 5:** Implement close_popup() function in socials_page.gd
- [x] **Task 6:** Implement toggle_popup() function in socials_page.gd
- [x] **Task 7:** Connect AddNewFriendButton signal to toggle_popup()
- [x] **Task 8:** Test open animation - verify smooth slide-up and overlay fade
- [x] **Task 9:** Test close animation - verify smooth slide-down and overlay fade
- [x] **Task 10:** Test button toggle behavior - open/close multiple times
- [x] **Task 11:** Test overlay blocking - verify background UI is not interactive when popup visible
- [x] **Task 12:** Test animation interruption - verify no conflicts if button clicked during animation
- [x] **Task 13:** Verify animation performance on target mobile resolutions
- [x] **Task 14:** Update tasks.md checklist to mark all complete

## Task Details

### Task 1: Review design.md and understand animation specifications
- Read design.md thoroughly
- Understand animation duration, easing, and overlay behavior
- Note performance considerations

### Task 2: Add Overlay ColorRect node to socials_page.tscn scene
- Create new ColorRect node as child of root SocialsPage
- Position it before AddFriendsPopup in node tree (so popup appears on top)
- Set name to "PopupOverlay"

### Task 3: Configure Overlay node properties
- Set anchors_preset to 15 (full rect)
- Set color to Color.BLACK with 0.0 alpha initially
- Set mouse_filter to MOUSE_FILTER_STOP
- Set visible to false initially

### Task 4: Implement open_popup() function
- Create function `func open_popup() -> void:`
- Check if animation already in progress; return early if true
- Set `animation_in_progress = true`
- Create Tween that:
  - Animates AddFriendsPopup.position.y from viewport.size.y to 0 over 0.3 seconds
  - Animates PopupOverlay.color to Color(0, 0, 0, 0.4) over same duration
  - Uses EASE_IN_OUT easing with TRANS_QUAD
- On tween complete: set `is_popup_open = true`, `animation_in_progress = false`
- Make PopupOverlay visible before animation starts

### Task 5: Implement close_popup() function
- Create function `func close_popup() -> void:`
- Check if animation already in progress; return early if true
- Set `animation_in_progress = true`
- Create Tween that:
  - Animates AddFriendsPopup.position.y from 0 to viewport.size.y over 0.3 seconds
  - Animates PopupOverlay.color to Color(0, 0, 0, 0.0) over same duration
  - Uses EASE_IN_OUT easing with TRANS_QUAD
- On tween complete: set `is_popup_open = false`, `animation_in_progress = false`, hide PopupOverlay and AddFriendsPopup

### Task 6: Implement toggle_popup() function
- Create function `func toggle_popup() -> void:`
- If `is_popup_open` is true, call `close_popup()`
- Otherwise call `open_popup()`

### Task 7: Connect AddNewFriendButton signal
- In `_ready()` function, connect AddNewFriendButton.pressed signal to toggle_popup()
- Example: `$VBoxContainer/AddNewFriendButton.pressed.connect(toggle_popup)`

### Task 8: Test open animation
- Launch scene in editor
- Click AddNewFriendButton
- Verify popup slides smoothly from bottom to top
- Verify overlay fades in smoothly
- Verify animation takes approximately 0.3 seconds

### Task 9: Test close animation
- With popup open, click AddNewFriendButton again
- Verify popup slides smoothly from top to bottom and off-screen
- Verify overlay fades out smoothly
- Verify animation takes approximately 0.3 seconds

### Task 10: Test button toggle behavior
- Click button multiple times in rapid succession
- Verify consistent open/close behavior
- Verify no animation conflicts

### Task 11: Test overlay blocking
- Open popup
- Attempt to click elements behind the overlay (AddNewFriendButton, FriendsList)
- Verify clicks are blocked by overlay

### Task 12: Test animation interruption
- Open popup midway, click button again before animation completes
- Verify graceful handling - should either:
  - Immediately start close animation, OR
  - Queue the close and start after open completes
- Verify no visual glitches

### Task 13: Verify animation performance
- Run on mobile device or mobile emulator
- Monitor for frame drops or stuttering
- Verify smooth 60fps animation (or device native framerate)

### Task 14: Update checklist
- After all implementation and testing complete
- Check all boxes to mark complete

## Dependencies
None - all work is contained within socials_page scene and script.

## Parallelizable Work
- Tasks 2 & 3 can be done together (setting up overlay node)
- Tasks 4, 5, 6 can be done in sequence (they build on state management)
- Task 7 depends on tasks 4, 5, 6 being complete
- Tasks 8-13 are testing and should be done sequentially

## Validation Criteria
✓ Popup slides from bottom to top when opening  
✓ Popup slides from top to bottom when closing  
✓ Overlay appears and disappears with popup  
✓ Animation takes 0.3 seconds ± 50ms  
✓ Easing is smooth (not linear)  
✓ Button toggle works multiple times without issues  
✓ Overlay prevents interaction with background  
✓ No frame drops on target mobile devices  
