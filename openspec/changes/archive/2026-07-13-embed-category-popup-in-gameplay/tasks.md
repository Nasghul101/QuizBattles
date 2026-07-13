# Implementation Tasks

## Overview
Embed the category popup component directly into gameplay_screen.tscn following the MarginContainer > Panel > VBoxContainer structure pattern.

## Task List

### 1. Scene Structure Changes
- [x] Open `gameplay_screen.tscn` in Godot editor or text editor
- [x] Add a new `MarginContainer` node as a child of `GameplayScreen` root
  - Set node name to `CategoryPopup`
  - Attach `category_popup_component.gd` script
  - Set `unique_name_in_owner = true`
  - Set `visible = false`
  - Configure anchors_preset = 15 (full rect)
  - Set grow_horizontal = 2, grow_vertical = 2
- [x] Add a `Panel` node as a child of `CategoryPopup` MarginContainer
  - Copy panel styling from NotificationsPopUp if needed (optional)
- [x] Add a `VBoxContainer` node as child of Panel
  - Set `unique_id` to match the one from category_popup_component.tscn
  - Configure `theme_override_constants/separation = 34`
- [x] Add `Headline` Label as child of VBoxContainer
  - Set `unique_name_in_owner = true`
  - Configure font size = 50
  - Set text = "Choose a Category"
  - Set horizontal_alignment = 1, vertical_alignment = 1
- [x] Add `HBoxContainer` as child of VBoxContainer
  - Set `unique_name_in_owner = true`
  - Set size_flags_vertical = 3
  - Configure `theme_override_constants/separation = 29`
- [x] Add three `Button` nodes as children of HBoxContainer
  - Names: `Category1`, `Category2`, `Category3`
  - Each with `unique_name_in_owner = true`
  - Each with size_flags_horizontal = 3
- [x] Add `ProgressBar` as child of VBoxContainer
  - Set `unique_name_in_owner = true`
  - Set custom_minimum_size = Vector2(0, 50)

### 2. Script Changes in gameplay_screen.gd
- [x] Remove line: `var category_popup_scene: PackedScene = preload("res://scenes/ui/components/category_popup_component.tscn")`
- [x] Change `var category_popup: Control` to `@onready var category_popup: MarginContainer = %CategoryPopup`
- [x] Remove from `_ready()`:
  - `category_popup = category_popup_scene.instantiate()`
  - `add_child(category_popup)`
  - `category_popup.visible = false`
  - `await get_tree().process_frame` (if it's only for category popup layout)
- [x] Verify signal connection remains: `category_popup.category_selected.connect(_on_category_selected)`
- [x] Verify all calls to `category_popup.show_categories()`, `category_popup.hide_popup()`, `category_popup.show_loading()` still work

### 3. File Cleanup
- [x] Delete `scenes/ui/components/category_popup_component.tscn`
- [x] Verify `scenes/ui/components/category_popup_component.gd` remains (DO NOT delete the script file)

### 4. Specification Updates
- [x] Update `gameplay-screen-initialization` spec delta to reflect embedded instantiation pattern

### 5. Validation
- [x] Run `openspec validate embed-category-popup-in-gameplay --strict`
- [x] Resolve any validation issues
- [x] Test in Godot:
  - Launch gameplay screen
  - Verify category popup appears when PlayButton is pressed (if first player)
  - Verify three category buttons are clickable
  - Verify loading animation plays after selection
  - Verify popup hides after questions load
  - Verify no console errors related to missing nodes or null references

## Dependencies
None - this is a standalone refactor

## Validation Criteria
- ✓ gameplay_screen.tscn contains embedded CategoryPopup node tree
- ✓ category_popup_component.tscn file is deleted
- ✓ category_popup_component.gd file still exists
- ✓ gameplay_screen.gd has no preload or instantiation code for category popup
- ✓ All signal connections work correctly
- ✓ Category selection flow works identically to before
- ✓ OpenSpec validation passes with --strict flag
