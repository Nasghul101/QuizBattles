# Proposal: Document Absolute Node Path Usage

**Change ID:** `document-absolute-node-paths`  
**Status:** Draft  
**Created:** 2026-01-21

## Problem Statement

The codebase uses absolute node paths (accessing nodes via `get_tree().root`) in two locations:
1. `result_component.gd` - Adds answer_review_screen to viewport root for z-index control
2. `transition_manager.gd` - Manages scene lifecycle by adding/removing from root

While these absolute path usages are necessary and intentional, they represent special architectural patterns that should be documented for maintainability. Absolute paths can introduce tight coupling and make code harder to understand without context.

## Proposed Solution

**Document-only change** - Create comprehensive documentation of absolute node path usages without modifying code:

1. **Audit all scripts** to identify every usage of absolute node path patterns:
   - `get_tree().root.add_child()`
   - `get_tree().root.get_node()`
   - `get_node("/root/...")`
   
2. **Document findings** in this proposal for review, including:
   - File location and line number
   - Reason for absolute path usage
   - Whether the usage is appropriate or should be refactored
   - Alternative approaches if applicable

3. **No code changes** - This is purely a documentation and analysis change

## Impact Assessment

### Benefits
- **Increased awareness** of tight coupling points in the architecture
- **Better maintainability** through documented architectural decisions
- **Informed refactoring** decisions for future work
- **Code review aid** for understanding why absolute paths are used

### Risks
- **No risks** - This is a documentation-only change with no code modifications

### Affected Components
- No code changes
- Documentation only (this proposal file)

## Dependencies
None - This change is independent and can be completed any time.

## Alternatives Considered

1. **Immediate refactoring** - Convert absolute paths to relative/signal-based patterns
   - **Rejected per user requirement:** User explicitly requested to avoid changes that could affect game behavior

2. **No documentation** - Leave absolute paths undocumented
   - **Rejected:** Reduces maintainability and makes architectural decisions implicit

## Success Criteria

- Complete list of all absolute node path usages in non-test .gd files
- Documentation of why each usage exists and whether it's appropriate
- Recommendations for future refactoring (if applicable)
- No code changes made

## Findings

### Current Absolute Node Path Usages

#### 1. result_component.gd (Line 52)
```gdscript
get_tree().root.add_child(answer_review_screen)
```

**Purpose:** Adds the answer review modal overlay to the viewport root instead of as a child of the result component to ensure proper z-index layering above all other UI elements.

**Justification:** **Appropriate usage** - Modal overlays need to be at the root level to appear above all other content regardless of their parent's z-index. Alternative approaches (parenting to result component) would fail due to z-index inheritance.

**Recommendation:** Keep as-is. This is a standard Godot pattern for modal overlays. Consider future enhancement of adding to a dedicated "modal layer" CanvasLayer if the game grows more complex modals.

---

#### 2. transition_manager.gd (Line 59)
```gdscript
get_tree().root.add_child(new_scene)
```

**Purpose:** Adds the newly loaded scene to the viewport root as part of the scene transition lifecycle.

**Justification:** **Appropriate usage** - The TransitionManager is an autoload singleton responsible for managing the entire scene tree. It must operate at the root level to swap out scenes. This is the standard Godot pattern for scene management.

**Recommendation:** Keep as-is. This is a core architectural component and the usage is exactly as intended by Godot's design. Alternative approaches (scene stack, sub-viewports) would be over-engineered for current needs.

---

### Summary

**Total absolute path usages found:** 2  
**Appropriate usages:** 2  
**Usages requiring refactoring:** 0

**Architectural Analysis:**  
Both absolute path usages are intentional, well-justified, and follow Godot best practices for their respective use cases (modal overlay management and scene lifecycle management). No refactoring is recommended at this time.

**Future Considerations:**
- If the game adds more modal dialogs, consider creating a dedicated ModalManager autoload that provides a consistent z-index layer for all modals
- TransitionManager's scene management is already well-encapsulated and requires no changes
