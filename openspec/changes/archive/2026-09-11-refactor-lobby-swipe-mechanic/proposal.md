# Change: Rework Main Lobby Swipe Mechanic

## Why
The swipe/paging logic in `main_lobby_screen.gd` is currently spread across a global `_input()` handler, manual rect hit-testing against `PageClipContainer`, and inline tween code mixed with page-index bookkeeping. This makes the swipe behavior hard to read, hard to tune, and not reusable. We want the swipe gesture handling to live directly on `PageClipContainer`, be simpler to follow, and have the swipe transition animation isolated in its own function so it can be edited independently.

## What Changes
- **BREAKING**: Move all swipe/drag detection and page-following logic out of `main_lobby_screen.gd` into a new script `page_clip_container.gd` attached to the `PageClipContainer` node.
- Replace the global `_input()` + manual rect hit-test with `_gui_input()` on `PageClipContainer` (Control's built-in scoped input), removing the need for manual `get_global_rect().has_point()` checks.
- `PageClipContainer` becomes responsible for: tracking drag state, clamping the drag position, determining the swipe target page on release, and animating `PagesContainer` to a target page.
- Isolate the tween/animation code into a single dedicated function (e.g. `_animate_pages_to(target_x: float)`) that only plays the transition, with `@export` tween parameters (duration, transition type, ease type) so the animation can be edited without touching gesture logic.
- `main_lobby_screen.gd` remains the source of truth for `current_page` and continues to drive `NavigationBar`. It listens to a new signal from `PageClipContainer` (emitted when a swipe determines a target page) to update its own `current_page` and the navigation indicator, and calls a public method on `PageClipContainer` to animate to a page when navigation buttons are pressed.
- Simplify `main_lobby_screen.gd` by removing the swipe state variables, `_input()`, `_handle_swipe_end()`, and `_set_page_position()` now that this logic lives on `PageClipContainer`.

## Impact
- Affected specs: `main-lobby-screen`
- Affected code:
  - [scenes/ui/main_lobby_screen.gd](scenes/ui/main_lobby_screen.gd)
  - [scenes/ui/main_lobby_screen.tscn](scenes/ui/main_lobby_screen.tscn) (new script attached to `PageClipContainer` node)
  - New file: `scenes/ui/page_clip_container.gd`
