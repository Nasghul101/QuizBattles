# main-lobby-screen Specification Delta
# Change: add-navigation-bar-scene

## MODIFIED Requirements

### Requirement: Multi-Page Container Structure
*Previously: 3 child page scenes. Now: 4 child page scenes.*

The main lobby screen SHALL use a page container to manage four content pages.

**Changes from previous version:**
- Page count increases from 3 to 4.
- A Shop dummy page is added at index 1.
- New page order: DuelPage (0), ShopPage (1), FriendlyBattlePage (2), SocialsPage (3).

#### Scenario: Display four pages
**GIVEN** the main lobby screen is loaded  
**WHEN** the scene initializes  
**THEN** the `PagesContainer` HBoxContainer SHALL contain exactly 4 child page scenes  
**AND** they SHALL appear in order: DuelPage, ShopPage, FriendlyBattlePage, SocialsPage

#### Scenario: Shop dummy page content
**GIVEN** the main lobby screen is loaded  
**WHEN** the ShopPage is visible  
**THEN** a centered label SHALL display the text `"Shop (Coming Soon)"`

---

### Requirement: Bottom Navigation Component
*Previously: inline PanelContainer3 with plain Button nodes. Now: NavigationBar scene instance.*

The main lobby screen SHALL use an instance of `res://scenes/ui/navigation_bar.tscn` as its bottom navigation control.

**Changes from previous version:**
- `PanelContainer3` and its plain `DuelPage`, `Page2`, `SocialPage` buttons are removed.
- The `NavigationBar` scene instance is added as the last child of `VBoxContainer`.
- Signal connections to `_on_duel_page_pressed`, `_on_page_2_pressed`, `_on_social_page_pressed` are replaced by a single connection to `navigation_bar.page_changed`.

#### Scenario: NavigationBar instance present in scene
**GIVEN** the main lobby screen scene file  
**WHEN** the scene tree is inspected  
**THEN** a `NavigationBar` node SHALL exist as the last child of `VBoxContainer`  
**AND** it SHALL be an instance of `res://scenes/ui/navigation_bar.tscn`

#### Scenario: Button press navigates to correct page
**GIVEN** the user is on any page of the main lobby  
**WHEN** the user taps a navigation button  
**THEN** the `NavigationBar` emits `page_changed(index)`  
**AND** the main lobby screen SHALL navigate to the page at that index  
**AND** `set_active_button(index)` SHALL be called on the NavigationBar

---

### Requirement: Active Page Indicator Synchronization
*Previously: `button.disabled = true` for active button. Now: `grab_focus()` via `NavigationBar.set_active_button(index)`.*

The NavigationBar SHALL visually indicate the currently active page using the focus style of the active button.

**Changes from previous version:**
- Indicator mechanism changes from `disabled = true` to `grab_focus()`.
- `_update_page_indicator` in `main_lobby_screen.gd` calls `navigation_bar.set_active_button(page_index)`.

#### Scenario: Update indicator after swipe navigation
**GIVEN** the user is on page 0 (Challenge)  
**WHEN** the user swipes left to navigate to page 1 (Shop)  
**THEN** `navigation_bar.set_active_button(1)` SHALL be called  
**AND** the Shop button SHALL have focus (purple glow)  
**AND** all other buttons SHALL NOT have focus

#### Scenario: Update indicator after button press
**GIVEN** the user is on page 0  
**WHEN** the user taps the Social button (index 3)  
**THEN** `navigation_bar.set_active_button(3)` SHALL be called  
**AND** the Social button SHALL have focus  
**AND** all other buttons SHALL NOT have focus

#### Scenario: Initialize indicator on scene load
**GIVEN** the main lobby screen is loading  
**WHEN** `_ready()` runs and `_update_page_indicator(0)` is called  
**THEN** `navigation_bar.set_active_button(0)` SHALL be called  
**AND** the Challenge button SHALL have focus on initial display
