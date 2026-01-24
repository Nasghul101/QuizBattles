# Proposal: Refactor Codebase for Code Deduplication

**Change ID:** `refactor-codebase-deduplication`  
**Status:** Draft  
**Created:** 2026-01-21

## Problem Statement

The current codebase contains duplicated code patterns across multiple scripts, which increases maintenance burden, introduces potential for inconsistency, and violates the DRY (Don't Repeat Yourself) principle. Specifically:

1. **Scene navigation logic** is duplicated across 4 different scripts with identical patterns for scene path validation and TransitionManager calls
2. **Input validation patterns** for enabling/disabling buttons based on field content are duplicated in registration and login screens
3. **Style box configuration** is duplicated in answer_button and answer_review_screen for button styling

## Proposed Solution

Create utility functions to consolidate duplicated code while maintaining existing functionality:

1. **Create `NavigationUtils.gd` autoload** to centralize scene navigation logic used across multiple screens
2. **Extract local helper methods** within individual scripts to reduce internal duplication (e.g., style box configuration in answer buttons)
3. **Preserve all existing behavior** - this is a pure refactoring change with no functional modifications

## Impact Assessment

### Benefits
- **Reduced code volume** by eliminating ~150 lines of duplicated code
- **Improved maintainability** through single source of truth for common patterns
- **Easier future changes** - scene path updates only need to change in one place
- **Better testability** - utility functions can be tested independently

### Risks
- **Minimal risk** - all changes are internal refactorings with identical external behavior
- **Regression potential** mitigated by careful testing of navigation flows

### Affected Components
- Multiple UI screens (navigation refactoring)
- Answer button components (internal deduplication)
- No changes to core game logic or data services

## Dependencies
None - this is a standalone refactoring change.

## Alternatives Considered

1. **Status quo** - Keep duplicated code
   - **Rejected:** Increases maintenance burden and inconsistency risk

2. **More aggressive utility extraction** - Extract additional patterns like button state management
   - **Rejected:** Would require more significant architectural changes; prefer minimal scope

## Success Criteria

- All duplicated navigation code consolidated into NavigationUtils
- All scripts pass existing functionality tests
- No observable change in user-facing behavior
- Code volume reduced by at least 100 lines
