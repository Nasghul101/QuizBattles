# Proposal: update-gameplay-screen-result-ui

## Summary
The `gameplay_screen.tscn` UI has been redesigned. A header with `NameP1`/`NameP2` labels was added,
and the two separate result containers (`ResultContainerL` / `ResultContainerR`) were consolidated into one
`ResultContainer`. The `result_component` was simultaneously updated to manage both players' answer buttons
internally. This proposal aligns `gameplay_screen.gd` and its spec with the new scene and component API.

## Problem
`gameplay_screen.gd` currently:
- References `result_container_l` and `result_container_r` `@onready` nodes that no longer exist in the scene.
- Calls `result_component.load_result_data(icon_placeholder, results)` with the old single-player signature,
  which is incompatible with the new `load_result_data(category_name, p1_results, p2_results)` API.
- Calculates scores by iterating `result_component.stored_results` (one array), which no longer matches the
  component's split `stored_results_p1` / `stored_results_p2` design.
- Does not populate the new `NameP1` and `NameP2` header labels.
- Does not call `set_round(i + 1)` when initialising each result component.

## Scope
- **`gameplay_screen.gd`** — adapt to new scene structure and new result-component API.
- **`gameplay-screen-initialization` spec** — update requirements to reflect the unified container, player
  name labels, and updated method signatures.
- **`result-component` spec** — capture already-implemented API changes (`load_result_data` new signature,
  `set_round`, `stored_results_p1`/`stored_results_p2`, `hide_results`).

Out of scope:
- Visual / theme changes to `gameplay_screen.tscn` or `result_component.tscn`.
- Changes to multiplayer match logic or turn management.
- Any other screen or service.

## Decisions
| Question | Decision |
|---|---|
| NameP2 in single-player | Left blank (empty string) |
| P2 buttons in single-player | Pass empty `[]` for p2_results, then call `hide_results()` |
| NameP1 source | Always `UserDatabase.current_user.username` |
| `set_round` call | Called during `_initialize_result_components()`, `set_round(i + 1)` |

## Affected Specs
- `gameplay-screen-initialization` (MODIFIED)
- `result-component` (MODIFIED)
