# Extract Drag Handle Component

## Change ID
`2026-01-28-extract-drag-handle-component`

## Status
Proposed

## Context
The AddFriendsPopup in the SocialsPage currently has drag-to-dismiss functionality implemented directly in the SocialsPage script. This dragging logic is useful for other popups in the application and should be extracted into a reusable DragHandle component that can be added to any popup.

The existing DragHandle scene (`scenes/ui/components/drag_handle_component.tscn`) is currently just a transparent Panel node with no script or functionality. This change will transform it into a fully functional, reusable component that encapsulates all drag interaction logic.

## Problem
Currently:
- Drag functionality is tightly coupled to `socials_page.gd`
- The DragHandle component scene exists but has no functionality
- Reusing drag-to-dismiss behavior in other popups requires duplicating code
- Drag direction, threshold, and behavior are hardcoded
- No centralized component for popup drag interaction

## Proposed Solution
Extract the dragging functionality from `socials_page.gd` into a new `drag_handle_component.gd` script that:

1. **Encapsulates drag interaction logic**: Handle all mouse input for drag detection, tracking, and release
2. **Emits signal-based events**: Send drag lifecycle signals (started, updated, ended) to let parent popups control positioning and overlay effects
3. **Supports configurable drag directions**: Allow single-axis dragging (up, down, left, right) selected via exported enum
4. **Provides configurable thresholds**: Export drag threshold distance for triggering dismissal actions
5. **Handles snap-back animation**: Internally animate return to original position when drag threshold isn't met
6. **Remains direction-agnostic**: Parent components control actual positioning based on drag signals

The SocialsPage will then use the DragHandle component by connecting to its signals rather than handling input directly.

## Impacted Specifications
- **NEW**: `drag-handle-component` - Define the reusable drag handle component behavior
- **MODIFIED**: `socials-page-popup-animation` - Update to use DragHandle component signals instead of direct input handling

## Dependencies
- Existing DragHandle scene at `scenes/ui/components/drag_handle_component.tscn`
- Existing socials page popup animation implementation

## Risks
- **Low**: Refactoring existing working drag code to new component
- **Low**: Ensuring signal-based approach maintains current smooth dragging behavior
- **Low**: Testing snap-back animation timing matches current implementation

## Out of Scope
- Creating instances of the DragHandle scene in other popups (only extracting to component)
- Modifying other popup implementations to use DragHandle
- Making the DragHandle scene "unique" or instanced (it remains a component scene)
- Multi-directional dragging (only single-axis per component instance)
- Touch gesture support beyond basic mouse/touch input events
