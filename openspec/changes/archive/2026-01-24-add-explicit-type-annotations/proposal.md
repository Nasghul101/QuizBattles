# Proposal: Add Explicit Type Annotations

**Change ID:** `add-explicit-type-annotations`  
**Status:** Draft  
**Created:** 2026-01-21

## Problem Statement

The current codebase uses GDScript's inferred typing operator (`:=`) extensively, which reduces code clarity and makes type information less explicit. While type inference is convenient during development, explicit types provide:

1. **Better IDE support** - Explicit types enable more accurate code completion and error detection
2. **Improved readability** - Types document variable intent without needing to trace initialization
3. **Earlier error detection** - Type mismatches caught at parse time rather than runtime
4. **Self-documenting code** - Types serve as inline documentation for variable purpose

The project conventions document states: "Static typing: Use static typing where possible for better performance and error checking," but the codebase currently uses `:=` in 100+ locations.

## Proposed Solution

Replace all inferred type operators (`:=`) with explicit type annotations throughout the codebase:

1. **Variable declarations** - Convert `var name := value` to `var name: Type = value`
2. **Function return types** - Add explicit return type annotations to all functions without them
3. **Function parameters** - Ensure all function parameters have explicit types (already mostly complete)
4. **Loop variables** - Add explicit types to `for` loop iteration variables
5. **Class members** - Ensure all class member variables have explicit types

## Impact Assessment

### Benefits
- **Enhanced type safety** - Compiler catches type errors earlier in development
- **Better tooling support** - IDEs provide more accurate completions and warnings
- **Improved maintainability** - Types document variable purpose and constraints
- **Performance potential** - Explicit types enable potential compiler optimizations
- **Consistency** - Aligns with project conventions stated in openspec/project.md

### Risks
- **Minimal risk** - This is purely a type annotation change with no logic modifications
- **Verbose code** - Slightly increases code length (acceptable trade-off for clarity)
- **Refactoring effort** - Requires touching many files (but changes are straightforward)

### Affected Components
- All 15 .gd files in the project (excluding test_ui folder)
- No changes to .tscn files or other assets
- No changes to external APIs or interfaces

## Dependencies
**Prerequisite:** `refactor-codebase-deduplication` should be completed first to minimize merge conflicts and simplify type annotations in utility functions.

## Alternatives Considered

1. **Gradual migration** - Only add types to new code going forward
   - **Rejected:** Results in inconsistent codebase; better to standardize now

2. **Keep type inference** - Continue using `:=` throughout
   - **Rejected:** Contradicts project conventions and reduces code quality

3. **Selective annotation** - Only add types where ambiguous
   - **Rejected:** Partial solution doesn't achieve consistency goal

## Success Criteria

- Zero occurrences of `:=` operator in non-test .gd files
- All functions have explicit return type annotations
- All variables have explicit type annotations
- Project builds without new errors or warnings
- No behavioral changes in gameplay or UI
