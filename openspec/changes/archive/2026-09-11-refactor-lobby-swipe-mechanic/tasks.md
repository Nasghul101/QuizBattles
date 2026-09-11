## 1. PageClipContainer swipe component
- [x] 1.1 Create `scenes/ui/page_clip_container.gd` with `# uid://...` first line, extending `Control`
- [x] 1.2 Add `@export` vars: `swipe_threshold`, `animation_duration`, `animation_transition`, `animation_ease`
- [x] 1.3 Add `current_page: int` and `signal swipe_requested(target_page: int)`
- [x] 1.4 Implement `_gui_input(event)` handling press/drag/release for touch, mouse button, and mouse motion drag, replacing the manual rect hit-test
- [x] 1.5 Implement drag-following of `PagesContainer.position.x` with clamping to first/last page bounds
- [x] 1.6 Implement swipe-end handling that computes the clamped target page from swipe distance/threshold, emits `swipe_requested(target_page)`, and calls `animate_to_page(target_page)`
- [x] 1.7 Implement isolated `_animate_pages_to(target_x: float) -> void` containing only the `Tween` setup/playback (duration/trans/ease from exported vars)
- [x] 1.8 Implement public `animate_to_page(page_index: int) -> void` that computes target x from `page_width`/`page_separation` and calls `_animate_pages_to`
- [x] 1.9 Compute and cache `page_width`/`page_separation` and set each page's `custom_minimum_size.x` (moved from `main_lobby_screen.gd`)

## 2. main_lobby_screen.gd simplification
- [x] 2.1 Remove swipe state vars (`swipe_start_pos`, `is_swiping`, `swipe_threshold`, `drag_start_container_pos`, `page_width`, `page_separation`), `_input()`, `_handle_swipe_end()`, `_set_page_position()`
- [x] 2.2 Keep `current_page` in `main_lobby_screen.gd`; connect to `page_clip_container.swipe_requested` to update `current_page` and call `_update_page_indicator()`
- [x] 2.3 Update `_on_navigation_bar_page_changed(index)` to set `current_page` and call `page_clip_container.animate_to_page(index)` directly (remove old `_navigate_to_page()` clamping duplication, reuse `_get_total_pages()` only where still needed)
- [x] 2.4 Update `_ready()` to no longer read `page_width`/`page_separation`/set page min sizes itself (now handled by `page_clip_container.gd`), just wait for it to initialize before calling `_update_page_indicator(0)`

## 3. Scene wiring
- [x] 3.1 Attach `page_clip_container.gd` to the `PageClipContainer` node in `main_lobby_screen.tscn`

## 4. Validation
- [x] 4.1 Manually test swipe left/right, threshold-under-swipe snap-back, and boundary clamping on first/last page in the editor
- [x] 4.2 Manually test `NavigationBar` button presses still animate to the correct page and update the active indicator