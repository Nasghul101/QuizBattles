# Design: Code Deduplication Strategy

## Overview

This document outlines the technical approach for consolidating duplicated code across the codebase while maintaining complete behavioral compatibility.

## Architecture Decisions

### 1. NavigationUtils Autoload Pattern

**Decision:** Create a new autoload singleton for scene navigation utilities.

**Rationale:**
- Navigation logic is used across 4+ different UI screens
- Autoload provides global access without coupling between screens
- Maintains consistency with existing autoload pattern (TransitionManager, UserDatabase, TriviaQuestionService)
- Single source of truth for scene path definitions

**Implementation:**
```gdscript
# autoload/navigation_utils.gd
extends Node

const SCENES: Dictionary = {
    "main_lobby": "res://scenes/ui/main_lobby_screen.tscn",
    "register_login": "res://scenes/ui/account_ui/register_login_screen.tscn",
    "account_management": "res://scenes/ui/account_ui/account_management_screen.tscn",
    "account_registration": "res://scenes/ui/account_ui/account_registration_screen.tscn"
}

func navigate_to_scene(scene_key: String, fallback_key: String = "") -> void:
    # Validates path, handles errors, calls TransitionManager
```

**Benefits:**
- Eliminates ~80 lines of duplicated navigation code
- Centralizes scene path definitions (easier to refactor paths later)
- Consistent error handling across all navigation
- Type-safe scene key lookup prevents typos

**Trade-offs:**
- Adds one new autoload (acceptable given project already uses pattern)
- Requires all navigation to go through this utility (improves consistency)

### 2. Internal Deduplication Strategy

**Decision:** Extract local helper methods for duplicated patterns within individual scripts.

**Rationale:**
- answer_button.gd has duplicated StyleBoxFlat border configuration code
- This pattern only appears in one script, so doesn't warrant a shared utility
- Local helper method reduces duplication without adding complexity

**Implementation:**
```gdscript
## Configure border properties for style box
func _configure_style_box_border(width: int, border_color: Color) -> void:
    _style_box.border_width_left = width
    _style_box.border_width_right = width
    _style_box.border_width_top = width
    _style_box.border_width_bottom = width
    if width > 0:
        _style_box.border_color = border_color
```

**Benefits:**
- Eliminates ~15 lines of duplicated border configuration
- Improves readability of public methods
- Easier to modify border styling in future

### 3. Scene Key Design

**Decision:** Use string keys instead of constants for scene references.

**Rationale:**
- Provides flexibility for runtime scene loading
- Avoids circular dependencies between NavigationUtils and scene scripts
- Allows easy extension for additional scenes
- Fallback key parameter enables graceful degradation

**Example Usage:**
```gdscript
# Navigate to account management with fallback to register/login
NavigationUtils.navigate_to_scene("account_management", "register_login")

# Navigate to main lobby (no fallback needed, it's the root)
NavigationUtils.navigate_to_scene("main_lobby")
```

## Error Handling Strategy

**Consistency:** Preserve existing error message patterns
- All invalid path errors log with push_error()
- Console output maintains same format for debugging
- Fallback behavior unchanged (some screens fall back to lobby, others to login)

**Enhancement:** Add validation for scene keys
- Unknown scene keys log error and attempt fallback
- If both primary and fallback fail, log error and stay on current scene

## Testing Strategy

**Manual Testing Required:**
1. Complete navigation flow: lobby → registration → login → management → back
2. Error case: invalid scene path (verify console error and fallback)
3. Quiz gameplay: verify answer button styling during question flow
4. All navigation paths from each screen

**Regression Prevention:**
- No changes to TransitionManager or scene lifecycle
- No changes to button interaction behavior
- All existing console log messages preserved

## Code Reduction Metrics

**Expected Savings:**
- NavigationUtils consolidation: ~80 lines removed
- Answer button helper method: ~15 lines removed
- Total: ~95-100 lines removed
- Net increase: ~40 lines (new NavigationUtils file)
- **Net reduction: 55-60 lines**

## Future Extensibility

This refactoring enables future improvements:
- Scene preloading in NavigationUtils
- Navigation history stack for back button behavior
- Scene parameter validation
- Analytics/logging hooks for scene transitions

## Risks and Mitigation

**Risk:** Breaking existing navigation flows
- **Mitigation:** Preserve exact same TransitionManager call patterns
- **Mitigation:** Keep all error messages identical for debugging continuity

**Risk:** Introducing autoload ordering issues
- **Mitigation:** NavigationUtils only depends on TransitionManager (already registered)
- **Mitigation:** No other autoloads depend on NavigationUtils

**Risk:** Scene key typos
- **Mitigation:** Centralized dictionary catches typos at runtime
- **Mitigation:** Future type safety possible with enum/constants

## Dependencies

**Required Before Implementation:**
- None - all dependencies already exist (TransitionManager, ResourceLoader)

**Registration Order:**
1. TransitionManager (existing)
2. NavigationUtils (new) - order doesn't matter since no cross-dependencies

## Alternative Patterns Considered

**1. Scene path constants in each screen**
- **Rejected:** Still requires duplication of validation + error handling logic

**2. Navigation manager with scene stack**
- **Rejected:** Too complex for current needs; would be future enhancement

**3. Extract to non-autoload utility script**
- **Rejected:** Would require `preload()` or passing references; autoload is simpler
