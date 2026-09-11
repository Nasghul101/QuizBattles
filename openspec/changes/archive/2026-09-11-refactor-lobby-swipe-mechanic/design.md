## Context
`main_lobby_screen.gd` currently owns a hand-rolled swipe/paging system: a global `_input()` handler manually checks whether touch/mouse presses land inside `PageClipContainer`'s rect, tracks drag deltas, clamps `PagesContainer.position.x`, and on release computes a target page and tweens to it. Page state (`current_page`), navigation bar sync, and animation are all interleaved in the same script.

## Goals / Non-Goals
- Goals:
  - Move all gesture detection (press/drag/release) and drag-following visuals onto `PageClipContainer` via `_gui_input()`.
  - Isolate the tween/animation code in one function with editable `@export` parameters.
  - Simplify `main_lobby_screen.gd` to a thin coordinator: it still tracks `current_page` and syncs `NavigationBar`.
- Non-Goals:
  - No visual/style changes to pages or navigation bar.
  - No change to page count, page order, or `NavigationBar` behavior.
  - No change to notification logic in `main_lobby_screen.gd`.

## Decisions

### Decision: New `page_clip_container.gd` script owns gesture + animation, `main_lobby_screen.gd` stays source of truth for `current_page`
- `PageClipContainer` gets its own script with:
  - `@export var swipe_threshold: float = 100.0`
  - `@export var animation_duration: float = 0.3`
  - `@export var animation_transition: Tween.TransitionType = Tween.TRANS_CUBIC`
  - `@export var animation_ease: Tween.EaseType = Tween.EASE_OUT`
  - `var current_page: int = 0` — kept in sync by `main_lobby_screen.gd` (set whenever it changes `current_page` there, e.g. via a setter call), used only for drag clamping/target computation.
  - `signal swipe_requested(target_page: int)` — emitted once a completed drag/swipe determines a new (already clamped) target page index.
  - `func animate_to_page(page_index: int) -> void` — public method that computes the target x and calls the isolated animation function. Used both internally (after a swipe) and externally (when `main_lobby_screen.gd` reacts to `NavigationBar` presses).
  - `func _animate_pages_to(target_x: float) -> void` — the only function that touches the `Tween`; contains no gesture/page-index logic.
- `main_lobby_screen.gd` keeps `current_page`, connects to `page_clip_container.swipe_requested`, updates `current_page` + `NavigationBar` indicator, and forwards `NavigationBar` presses to `page_clip_container.animate_to_page(index)`.
- Alternative considered: Let `PageClipContainer` fully own `current_page` and have `main_lobby_screen.gd` just read it. Rejected per explicit requirement to keep `main_lobby_screen.gd` as the source of truth (keeps `NavigationBar` coordination centralized in one place).

### Decision: Use `_gui_input()` instead of global `_input()`
- `PageClipContainer` is a `Control`; setting `mouse_filter = MOUSE_FILTER_STOP` (or `PASS` if children still need clicks) lets Godot route only input events that land inside its rect to `_gui_input()`, eliminating the manual `get_global_rect().has_point()` check and the need to filter out clicks on the nav bar/header.
- Drag/release events outside the control's rect (e.g. finger moves fast) are still delivered to the control that received the initial press as long as it has grabbed input via `accept_event()` / Godot's built-in touch capture behavior for `_gui_input`; if edge cases appear during implementation, fall back to connecting to `gui_input` signal plus tracking press capture manually.

## Risks / Trade-offs
- Splitting state between two scripts (`current_page` mirrored in both) could drift if not updated consistently → Mitigated by routing all page changes through a single public method (`animate_to_page`) and the `swipe_requested` signal, with no other place mutating `PagesContainer.position.x`.
- `_gui_input()` scoping could behave differently for drag events that start inside the control but end outside its bounds → validate manually on mobile touch during implementation; keep `swipe_threshold` and clamping logic defensive regardless of where the release occurs.

## Migration Plan
- Direct refactor, no data migration. Update `main_lobby_screen.tscn` to attach the new script to the `PageClipContainer` node and re-wire the `NavigationBar` `page_changed` signal handler to call `page_clip_container.animate_to_page()`.

## Open Questions
None — resolved via clarifying questions before drafting this proposal.
