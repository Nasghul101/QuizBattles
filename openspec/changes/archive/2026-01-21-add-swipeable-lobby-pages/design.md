# Design: Swipeable Lobby Pages

## Context
The main lobby screen currently has a static single-page layout with placeholder buttons in the bottom navigation. To support multiple feature sections (Duel, social features, future game modes), we need a multi-page interface that users can navigate by swiping or tapping bottom buttons.

**Constraints:**
- Must work smoothly on mobile devices (touch gestures)
- Must preserve existing header and bottom navigation visual structure
- Must be extensible for future pages
- Must maintain current functionality (account button, navigation)

**Stakeholders:**
- End users (mobile quiz game players)
- Developers (maintaining and extending page system)

## Goals / Non-Goals

### Goals
- Implement swipeable horizontal navigation between 3 pages
- Maintain static header and bottom navigation during page transitions
- Sync bottom navigation buttons with current page state
- Support both swipe gestures and button taps for navigation
- Smooth, mobile-friendly animations
- Create modular page system for easy future expansion

### Non-Goals
- Not implementing actual content for Page2 and Socials pages (placeholders only)
- Not adding vertical scrolling within pages (can be added per-page later)
- Not implementing page caching/lazy loading (all 3 pages loaded simultaneously)
- Not supporting diagonal or multi-touch gestures

## Decisions

### Decision 1: TabContainer as Page Container
**What:** Use Godot's built-in `TabContainer` with hidden tabs as the foundation for the page system.

**Why:**
- Built-in page/tab management (current tab tracking, content visibility)
- Easy to add/remove pages programmatically
- Supports keyboard/controller navigation automatically
- Simpler than custom viewport/scroll container approach

**Alternatives considered:**
1. **HBoxContainer with ScrollContainer:**
   - Pro: More visual control, can see page transitions
   - Con: More complex position management, need to handle visibility manually
   - Rejected: More implementation complexity for same result
   
2. **Manual scene swapping:**
   - Pro: Lower memory footprint (only 1 page loaded)
   - Con: No smooth transitions between pages, more state management
   - Rejected: Poor UX, more code complexity

3. **ViewportContainer approach:**
   - Pro: Could enable parallax or 3D effects
   - Con: Overkill for 2D UI, performance overhead
   - Rejected: Violates "2D only" project constraint

### Decision 2: Swipe Detection in _input()
**What:** Implement custom swipe detection using InputEventScreenTouch/Drag events.

**Why:**
- Full control over swipe threshold, direction, and sensitivity
- Can tune for mobile feel
- Simple state machine (start → dragging → end)

**Alternatives considered:**
1. **Use Control.gui_input():**
   - Pro: Scoped to specific control
   - Con: May not capture touches outside control bounds
   - Rejected: Could miss edge swipes
   
2. **Use Godot Gesture Recognizer (if exists in 4.5+):**
   - Pro: Built-in gesture handling
   - Con: May not exist or be too rigid
   - Rejected: More dependencies, less customization

### Decision 3: Separate Scene Files for Each Page
**What:** Create independent scene files under `scenes/ui/lobby_pages/` for each page content.

**Why:**
- Clear separation of concerns
- Easy to develop each page independently
- Can be worked on by different developers
- Follows project's scene-based architecture pattern

**Structure:**
```
scenes/ui/lobby_pages/
├── duel_page.tscn (main duel/play content)
├── page2.tscn (placeholder for future feature)
└── socials_page.tscn (placeholder for social features)
```

### Decision 4: Bottom Buttons as Page Indicators
**What:** Bottom navigation buttons become both indicators and direct navigation controls.

**Why:**
- Dual purpose: show current page + allow direct jumps
- Common mobile UX pattern (tab bars)
- Uses existing button nodes, minimal UI restructuring

**Implementation:**
- Set `toggle_mode = true` on buttons
- Use `button_pressed` property to show active state
- Connect to same `_navigate_to_page()` function as swipes

## Risks / Trade-offs

### Risk 1: Touch Input Conflicts
**Risk:** Swipe detection may interfere with buttons or other interactive elements on pages.

**Mitigation:**
- Use `event.button_mask` check during drag to ensure primary touch
- Child controls consume input first (Godot's input event system)
- Add swipe threshold to avoid accidental triggers
- Test thoroughly with buttons, scrollable areas

### Risk 2: Animation Performance on Low-End Devices
**Risk:** Tween animations may stutter on older mobile devices.

**Trade-off:** 
- Current approach: TabContainer instant switching + optional tween for polish
- If performance issues arise, disable animation or reduce duration
- TabContainer already handles content visibility efficiently

**Mitigation:**
- Keep animations simple (no complex shaders or particles)
- Test on low-end device profile
- Provide option to disable animations in settings (future)

### Risk 3: Future Page Additions May Break Layout
**Risk:** Adding more than 3 pages could break bottom navigation visual design.

**Trade-off:**
- Current: Fixed 3-button bottom layout
- Future: May need pagination dots or scrolling tab bar

**Mitigation:**
- Document maximum recommended pages (3-4)
- If exceeding, refactor bottom navigation to use page indicators (dots)
- Keep `TOTAL_PAGES` constant easy to modify

## Implementation Notes

### Scene Hierarchy After Changes
```
MainLobbyScreen (Control)
└── VBoxContainer
    ├── PanelContainer (Header - UNCHANGED)
    │   └── HBoxContainer
    │       ├── Label ("Quiz Battles")
    │       └── AccountButton
    ├── PageContainer (TabContainer - NEW)
    │   ├── @DuelPage (instanced scene)
    │   ├── @Page2 (instanced scene)
    │   └── @SocialsPage (instanced scene)
    └── PanelContainer3 (Bottom Nav - MODIFIED behavior)
        └── HBoxContainer
            ├── DuelPage (Button - now page navigator)
            ├── Page2 (Button - now page navigator)
            └── SocialPage (Button - now page navigator)
```

### Swipe Detection State Machine
```
IDLE
  ↓ (touch/click press)
SWIPING (record start position)
  ↓ (touch/click release)
CHECK_THRESHOLD
  → if distance < threshold: IDLE (ignore)
  → if distance >= threshold: NAVIGATE (change page)
  ↓
IDLE
```

### Page Index Mapping
- Page 0: DuelPage (main/default)
- Page 1: Page2 (placeholder)
- Page 2: SocialsPage (placeholder)

## Migration Plan

### Step 1: Backup Current Scene
Before starting implementation:
1. Duplicate `main_lobby_screen.tscn` as `main_lobby_screen_backup.tscn`
2. Keep backup until new implementation is verified

### Step 2: Incremental Implementation
1. Add TabContainer without removing old content (test structure)
2. Create and instance page scenes (verify loading)
3. Add swipe detection without navigation (test gesture recognition)
4. Connect navigation logic (test page switching)
5. Hook up bottom buttons (test full integration)
6. Remove old middle content nodes

### Step 3: Testing Checkpoints
- After each major task, run scene in Godot
- Test on desktop with mouse (simulates touch)
- Use Godot's touch emulation mode
- Deploy to Android device for real touch testing

### Rollback Plan
If issues arise:
1. Restore from backup scene
2. Keep new page scene files (reusable)
3. Review design decisions
4. Adjust approach based on findings

## Open Questions
1. **Animation Duration:** What feels best? (Suggest: 0.3s, tune during testing)
2. **Swipe Threshold:** How many pixels for mobile? (Suggest: 100px, tune for device)
3. **Page2 Purpose:** What feature should this page eventually contain?
4. **Vertical Scrolling:** Will pages need scrollable content? (Not in initial scope, but pages should support it independently)
5. **Page Persistence:** Should the system remember last viewed page across sessions? (Not in initial scope, default to page 0)
