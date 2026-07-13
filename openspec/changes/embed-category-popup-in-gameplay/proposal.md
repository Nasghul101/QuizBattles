# Proposal: Embed Category Popup in Gameplay Screen

## Summary
Refactor the category popup from a dynamically instantiated separate scene to an embedded component within the gameplay_screen.tscn scene file. This change simplifies the scene structure by following the same pattern used for other popups in the project (e.g., NotificationsPopUp in main_lobby_screen).

## Motivation
Currently, the category popup is:
- Defined as a separate scene (`category_popup_component.tscn`)
- Preloaded and instantiated dynamically in `gameplay_screen.gd` during `_ready()`
- Added as a child at runtime

This approach adds unnecessary complexity when a simpler embedded pattern already exists in the codebase. The NotificationsPopUp in main_lobby_screen demonstrates an embedded popup that becomes visible/invisible as needed without dynamic instantiation.

**Benefits:**
- **Consistency**: Matches the pattern used by NotificationsPopUp and other embedded popups
- **Simplicity**: Eliminates runtime instantiation code
- **Editor visibility**: Popup structure is visible and editable directly in the scene editor
- **Reduced code**: Removes preload and instantiation logic from gameplay_screen.gd

## Proposed Changes

### Scene Structure
Transform category_popup_component from a separate scene to an embedded node tree within gameplay_screen.tscn:

```
GameplayScreen (Control)
├── ... (existing nodes)
└── CategoryPopup (MarginContainer) [script: category_popup_component.gd]
    └── Panel
        └── VBoxContainer
            ├── Headline (Label)
            ├── HBoxContainer
            │   ├── Category1 (Button)
            │   ├── Category2 (Button)
            │   └── Category3 (Button)
            └── ProgressBar
```

The MarginContainer will have the `category_popup_component.gd` script attached and will be initially set to `visible = false`.

### Code Changes

**gameplay_screen.gd:**
- Remove the preload of `category_popup_component.tscn`
- Remove dynamic instantiation code in `_ready()`
- Change `category_popup` from a runtime variable to an @onready reference
- Remove `add_child()` call for category popup
- Retain all signal connections and visibility management (no functional changes)

**category_popup_component.gd:**
- No changes required (remains a separate reusable script)
- Script continues to handle `show_categories()`, `show_loading()`, `hide_popup()` as before

**category_popup_component.tscn:**
- Delete this file (no longer needed as a separate scene)

### Behavior Preservation
The category popup will function identically to before:
- Initially invisible
- Made visible via `category_popup.show_categories(categories)`
- Hidden via `category_popup.hide_popup()`
- Same signal emissions (`category_selected`)
- Same loading state animation

## Affected Specifications
- **gameplay-screen-initialization**: Requirements related to category popup instantiation will be modified to reflect embedded rather than dynamic instantiation

## Alternatives Considered
1. **Keep current approach**: Maintains status quo but leaves inconsistency with other popups
2. **Inline the script**: Would lose reusability if category popup is needed elsewhere
3. **Create a base popup class**: Over-engineered for this simple use case

## Risks and Mitigations
- **Risk**: Accidentally breaking signal connections or visibility logic
  - **Mitigation**: Careful code review, test all category selection flows
- **Risk**: Layout/positioning differences from embedded approach
  - **Mitigation**: User indicated layout is not a concern for this change

## Implementation Notes
- The MarginContainer (root of embedded popup) will hold the script reference
- Panel child provides the background styling container
- All existing unique node names (`%Headline`, `%Category1`, etc.) are preserved
- No changes to popup behavior, signals, or public API
