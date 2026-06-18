# Proposal: add-navigation-bar-scene

## Summary
Replace the existing inline bottom navigation (`PanelContainer3` with plain `Button` nodes) in `main_lobby_screen.tscn` with the newly created `navigation_bar.tscn` scene. The new scene is a reusable `PanelContainer` with four styled `NavigationButton` components (Challenge, Shop, VS, Social). A Shop dummy page is added as the second lobby page so all four buttons map to a real page.

## Problem / Motivation
The current bottom navigation is an ad-hoc row of unstyled buttons embedded directly in `main_lobby_screen.tscn`. The new `navigation_bar.tscn` is a polished, self-contained component with custom `NavigationButton` instances that carry focus/hover/pressed styles. Integrating it removes the placeholder UI and aligns with the project's composition-based architecture.

## Scope
| Area | Change |
|---|---|
| `scenes/ui/navigation_bar.tscn` | Already created — no structural changes in this proposal |
| `scenes/ui/navigation_bar.gd` | Add `page_changed(index: int)` signal, `set_active_button(index)` method, and button-press handlers |
| `scenes/ui/main_lobby_screen.tscn` | Replace `PanelContainer3` block with an instance of `navigation_bar.tscn` |
| `scenes/ui/main_lobby_screen.gd` | Connect to `page_changed` signal; call `set_active_button` from swipe navigation; update `_update_page_indicator` |
| `scenes/ui/lobby_pages/shop_page.tscn` *(new)* | Minimal dummy Control with centered "Shop (Coming Soon)" label |
| `openspec/specs/navigation-bar-component/` *(new)* | New capability spec |
| `openspec/specs/main-lobby-screen/` | MODIFIED requirements for bottom nav structure, page count, indicator mechanism |

## Page Mapping
| Index | Button | Page |
|---|---|---|
| 0 | Challenge | `duel_page.tscn` |
| 1 | Shop | `shop_page.tscn` *(new dummy)* |
| 2 | VS | `friendly_battle_page.tscn` |
| 3 | Social | `socials_page.tscn` |

## Key Design Decisions
1. **Signal-based communication** — `navigation_bar.gd` emits `page_changed(index: int)` on button press. `main_lobby_screen.gd` connects to it. This keeps the nav bar decoupled from any specific screen.
2. **`grab_focus()` for active indicator** — The `NavigationButton` component already defines a purple glow `focus` StyleBox. Calling `grab_focus()` on the active button gives the visual feedback without extra state.
3. **Swipe stays in `main_lobby_screen.gd`** — Swipe gesture logic is screen-level behaviour and should not live inside a reusable navigation component. When swipe navigation changes the page, the screen calls `navigation_bar.set_active_button(index)` directly.
4. **Shop dummy as first stub** — A minimal scene prevents null-index errors and satisfies the 4-button layout.

## Out of Scope
- Actual shop functionality
- Transitions / animations for the nav bar itself
- Any changes to the header or notification system

## Related Specs
- `main-lobby-screen` — modified (page count, indicator mechanism, nav bar node path)
- `navigation-bar-component` — new capability
