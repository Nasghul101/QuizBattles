# Tasks: add-navigation-bar-scene

## Implementation Checklist

- [x] **T1** — Create `scenes/ui/lobby_pages/shop_page.tscn`  
  Minimal `Control` scene with a centered `Label` whose text is `"Shop (Coming Soon)"`. No script required.  
  _Validation: Scene opens in Godot without errors; label is centered on screen._

- [x] **T2** — Update `navigation_bar.gd`  
  - Declare signal `page_changed(index: int)`.  
  - Add `set_active_button(index: int)` method that calls `grab_focus()` on the button at the given index and releases focus from all others.  
  - Implement the four button-press handlers to emit `page_changed` with the corresponding index (Challenge=0, Shop=1, VS=2, Social=3).  
  _Validation: Pressing each button emits the correct index (manual test or print statement)._

- [x] **T3** — Update `main_lobby_screen.tscn`  
  - Remove the `PanelContainer3` node and its children (`HBoxContainer`, `DuelPage`, `Page2`, `SocialPage`) and their signal connections.  
  - Add an instance of `res://scenes/ui/navigation_bar.tscn` as the last child of `VBoxContainer` (after `MarginContainer`).  
  - Add a new `shop_page.tscn` instance into `PagesContainer` at index 1 (after `duel_page`, before `friendly_battle_page`).  
  _Validation: Scene tree matches the new page-mapping table; no orphan connections._

- [x] **T4** — Update `main_lobby_screen.gd`  
  - Add `@onready var navigation_bar` reference to the new nav bar node.  
  - In `_ready()`, connect `navigation_bar.page_changed` to a new handler `_on_navigation_bar_page_changed(index)`.  
  - Add `_on_navigation_bar_page_changed(index: int)` that calls `_navigate_to_page(index)`.  
  - Update `_update_page_indicator(page_index: int)` to call `navigation_bar.set_active_button(page_index)` instead of iterating `PanelContainer3/HBoxContainer`.  
  - Remove the now-unused `_on_duel_page_pressed`, `_on_page_2_pressed`, `_on_social_page_pressed` handlers.  
  _Validation: Button press navigates to correct page; swipe updates the focused button._

- [ ] **T5** — Manual smoke test  
  - Launch the main lobby; Challenge button has focus on start.  
  - Tap each nav button; correct page appears and focus moves to that button.  
  - Swipe left/right; pages change and focused button updates.  
  - Shop page displays "Shop (Coming Soon)".  

## Dependencies
- T1 has no dependencies.  
- T2 has no dependencies.  
- T3 depends on T1 (shop_page.tscn must exist before being instanced).  
- T4 depends on T2 and T3.  
- T5 depends on T1–T4.

## Parallelizable Work
T1 and T2 can be done in parallel before T3/T4.
