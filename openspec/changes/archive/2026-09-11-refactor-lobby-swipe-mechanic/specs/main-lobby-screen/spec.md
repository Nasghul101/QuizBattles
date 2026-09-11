## MODIFIED Requirements

### Requirement: Horizontal Swipe Gesture Detection
The `PageClipContainer` node SHALL own horizontal swipe gesture detection for page navigation, using its `_gui_input()` handler instead of a global input handler.

**Rationale:** Mobile-first UX requires touch-based navigation between pages. Scoping detection to `_gui_input()` on `PageClipContainer` removes the need for manual rect hit-testing and keeps gesture logic co-located with the pages it controls.

#### Scenario: Detect swipe left gesture
**GIVEN** the user is viewing a page in the main lobby
**AND** the current page is not the last page
**WHEN** the user touches `PageClipContainer` and drags left at least `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL emit `swipe_requested` with the next page index (current page + 1)
**AND** `PageClipContainer` SHALL animate `PagesContainer` to that page

#### Scenario: Detect swipe right gesture
**GIVEN** the user is viewing a page in the main lobby
**AND** the current page is not the first page
**WHEN** the user touches `PageClipContainer` and drags right at least `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL emit `swipe_requested` with the previous page index (current page - 1)
**AND** `PageClipContainer` SHALL animate `PagesContainer` to that page

#### Scenario: Ignore swipe below threshold
**GIVEN** the user is viewing a page in the main lobby
**WHEN** the user touches and drags less than `swipe_threshold` pixels
**AND** releases the touch
**THEN** `PageClipContainer` SHALL NOT emit `swipe_requested`
**AND** `PageClipContainer` SHALL animate `PagesContainer` back to the current page

#### Scenario: Prevent swipe beyond first page
**GIVEN** the user is on page 0 (first page)
**WHEN** the user swipes right on `PageClipContainer`
**THEN** `PageClipContainer` SHALL clamp the target page to 0
**AND** SHALL NOT emit `swipe_requested` with a negative index

#### Scenario: Prevent swipe beyond last page
**GIVEN** the user is on the last page
**WHEN** the user swipes left on `PageClipContainer`
**THEN** `PageClipContainer` SHALL clamp the target page to the last valid index
**AND** SHALL NOT emit `swipe_requested` with an out-of-range index

## ADDED Requirements

### Requirement: PageClipContainer Swipe Component Ownership
The `PageClipContainer` node SHALL be the sole owner of drag tracking, drag-following visuals, and swipe-to-page-index computation, implemented in a dedicated script attached to that node.

**Rationale:** Consolidating swipe mechanics on the node that visually clips/contains the pages removes duplicated bounds/position math from `main_lobby_screen.gd` and makes the pager reusable independent of the lobby screen.

#### Scenario: Drag follows finger within bounds
**GIVEN** the user is dragging on `PageClipContainer`
**WHEN** the drag position would move `PagesContainer` beyond the first or last page
**THEN** `PageClipContainer` SHALL clamp `PagesContainer.position.x` to stay within the first/last page bounds

#### Scenario: main_lobby_screen remains source of truth for current page
**GIVEN** `PageClipContainer` emits `swipe_requested(target_page)` after a completed swipe
**WHEN** `main_lobby_screen.gd` receives the signal
**THEN** `main_lobby_screen.gd` SHALL update its own `current_page` value
**AND** SHALL update the `NavigationBar` active indicator to match

#### Scenario: Navigation bar drives PageClipContainer
**GIVEN** the user presses a `NavigationBar` button for page index N
**WHEN** `main_lobby_screen.gd` handles the `page_changed` signal
**THEN** `main_lobby_screen.gd` SHALL update its own `current_page` to N
**AND** SHALL call `PageClipContainer.animate_to_page(N)` to perform the transition

### Requirement: Isolated Swipe Animation Function
The page transition animation SHALL be implemented in a single dedicated function on `PageClipContainer` that only plays the tween, separate from gesture-detection and page-index logic, with its duration, transition type, and ease type exposed as editable `@export` properties.

**Rationale:** Isolating the animation lets it be tuned or replaced without touching swipe detection logic, and exported parameters let the animation feel be adjusted in the editor Inspector without code changes.

#### Scenario: Animation function only plays the transition
**GIVEN** `PageClipContainer.animate_to_page(page_index)` is called
**WHEN** the target x position for `PagesContainer` has been computed
**THEN** a dedicated animation function SHALL be called with only that target x
**AND** that function SHALL contain no swipe-detection or page-index-computation logic

#### Scenario: Animation parameters are editable
**GIVEN** the `PageClipContainer` node is selected in the Godot editor
**WHEN** the Inspector is opened
**THEN** the animation duration, transition type, and ease type SHALL appear as editable exported properties
