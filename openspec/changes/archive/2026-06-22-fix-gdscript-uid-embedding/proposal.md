# Proposal: fix-gdscript-uid-embedding

## Summary
Embedded UIDs directly into all GDScript (`.gd`) files as a `# uid://...` comment on the first line, resolving engine warnings caused by the Godot 4.4+ UID system change.

## Problem / Motivation
The project was originally developed on a Godot version that stored script UIDs in separate `.uid` sidecar files (e.g., `piechart.gd.uid`). Godot 4.4 changed this: UIDs for GDScript files are now expected to be embedded inline as a comment on the first line of the script. Running the project on Godot 4.7 produced warnings for every script:

```
W load: res://scenes/ui/components/piechart.tscn:4 - ext_resource, invalid UID: uid://caiyu3bea5dhy - using text path instead: res://scenes/ui/components/piechart.gd
```

Godot couldn't locate the UIDs in its registry (because it no longer reads sidecar files for GDScript), fell back to text-path resolution, and logged a warning per affected resource.

## What Changed
- Prepended `# uid://...` as the first line in **38 `.gd` files** across the entire project, using the UID values from their existing `.uid` sidecar files.
- The `.uid` sidecar files are left in place (Godot may still reference them for non-GDScript resources or older compatibility layers).

## Affected Files
All `.gd` files that had a corresponding `.uid` sidecar:
- `addons/font_auto_size_labels/*.gd` (4 files)
- `addons/Godot-PieChart-main/pie_chart.gd`
- `autoload/*.gd` (5 files)
- `scenes/ui/*.gd` (5 files)
- `scenes/ui/account_ui/*.gd` (4 files)
- `scenes/ui/components/*.gd` (14 files)
- `scenes/ui/lobby_pages/*.gd` (3 files)
- `scenes/ui/test_ui/*.gd` (2 files)

## Key Design Decisions
1. **Inline comment format** — `# uid://...` on line 1, matching the format Godot 4.4+ writes when it creates new scripts.
2. **Values sourced from sidecar files** — The UIDs are unchanged; only their storage location moves from `.uid` files into the scripts.
3. **Sidecar files retained** — Not deleted, as Godot may still use them for shader and other non-GDScript resource types.

## Out of Scope
- `.gdshader` files (Godot does not embed UIDs inline in shader files)
- Removing the `.uid` sidecar files
