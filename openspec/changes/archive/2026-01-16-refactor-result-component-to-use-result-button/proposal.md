# Refactor Result Component to Use Result Button Component

**Change ID:** `refactor-result-component-to-use-result-button`  
**Status:** Proposed  
**Created:** 2026-01-16  

## Problem Statement

Currently, the `result_component` directly manages all UI concerns for answer indicator buttons, including:
- Setting button sizes, modulation, and visual properties
- Loading and managing icon assets (icon_right, icon_wrong)
- Instantiating raw Button nodes
- Hardcoding three AnswerButton nodes in the scene file

This creates tight coupling between the result component's logic and UI implementation details, making it harder to:
- Reuse answer indicator button styling elsewhere
- Maintain consistent visual appearance
- Modify button behavior without touching result_component
- Scale to variable numbers of questions

## Proposed Solution

Refactor `result_component` to delegate all button UI concerns to a new `ResultButtonComponent`:

1. **Create ResultButtonComponent script** (`result_button_component.gd`) that:
   - Manages its own UI properties (size, colors, modulation)
   - Loads icon assets internally
   - Exposes methods to set correct/incorrect state
   - Emits a signal when clicked
   - Stores associated question data

2. **Simplify result_component** to:
   - Dynamically instantiate ResultButtonComponent instances based on question count
   - Remove all button UI setup code
   - Connect to ResultButtonComponent signals
   - Only handle data loading and signal forwarding

3. **Remove hardcoded buttons** from `result_component.tscn`

## Impact

### Changed Components
- **result-button-component** (NEW): New capability with scene + script
- **result-component** (MODIFIED): Simplified logic, delegates UI to child component

### Benefits
- Separation of concerns: UI details isolated to ResultButtonComponent
- Reusability: ResultButtonComponent can be used elsewhere
- Maintainability: Changes to button appearance happen in one place
- Flexibility: Easily supports variable number of questions

### Breaking Changes
None - external API remains unchanged:
- `load_result_data(texture, results)` signature stays the same
- `question_review_requested` signal remains unchanged
- Component behavior from external perspective is identical

## Acceptance Criteria

- [x] ResultButtonComponent scene and script created
- [x] ResultButtonComponent manages all button UI properties internally
- [x] result_component dynamically instantiates ResultButtonComponent instances
- [x] All button UI setup code removed from result_component.gd
- [x] Hardcoded AnswerButton nodes removed from result_component.tscn
- [x] Signal flow works: ResultButtonComponent → result_component → external listeners
- [x] `initialize_empty()` and `load_result_data()` work as before
- [x] Variable question counts supported (not just 3)

## Dependencies

None - self-contained refactoring of existing components.

## Rollout Plan

1. Create ResultButtonComponent spec and implementation
2. Update result-component spec to reflect new architecture
3. Refactor result_component implementation
4. Test with existing gameplay flows
5. Archive change after validation
