# Implementation Tasks

**NOTE**: All editor changes (scene modifications, node additions, property settings) must be performed manually by the developer in the Godot editor. This document provides detailed step-by-step instructions for what to do in the editor.

## 1. Scene Structure Setup (Editor Work)
- [x] 1.1 Open `main_lobby_screen.tscn` in Godot editor
- [x] 1.2 Locate the VBoxContainer node that contains the header, middle content, and bottom panel
- [x] 1.3 Select the middle section (currently `MarginContainer` with TextureRect and `MarginContainer2` with PlayButton)
- [x] 1.4 Delete or remove these middle MarginContainer nodes
- [x] 1.5 Add a new `TabContainer` node as a child of the VBoxContainer (between header PanelContainer and bottom PanelContainer3)
- [x] 1.6 Name the TabContainer node: `PageContainer`
- [x] 1.7 Set TabContainer properties in Inspector:
  - `layout_mode` = 2
  - `size_flags_vertical` = 3 (Expand)
  - `tabs_visible` = false (hide default tab bar)
  - `use_hidden_tabs_for_min_size` = false

## 2. Create Page Content Scenes (Editor Work)
- [x] 2.1 Create new directory: `scenes/ui/lobby_pages/`
- [x] 2.2 Create new scene `duel_page.tscn`:
  - Root node: Control (name: "DuelPage")
  - Add MarginContainer child with margins (left: 40, right: 40, top: 20, bottom: 20)
  - Inside MarginContainer, add VBoxContainer
  - Add Label with text "Duel Page Content" and TextureRect placeholder
  - Add Button with text "Play" (migrate from old PlayButton)
  - Save scene
- [x] 2.3 Create new scene `page2.tscn`:
  - Root node: Control (name: "Page2")
  - Add MarginContainer child with margins (left: 40, right: 40, top: 20, bottom: 20)
  - Inside MarginContainer, add Label with text "Page 2 - Coming Soon"
  - Add placeholder content (TextureRect or ColorRect)
  - Save scene
- [x] 2.4 Create new scene `socials_page.tscn`:
  - Root node: Control (name: "SocialsPage")
  - Add MarginContainer child with margins (left: 40, right: 40, top: 20, bottom: 20)
  - Inside MarginContainer, add Label with text "Socials Page - Coming Soon"
  - Add placeholder content for future social features
  - Save scene

## 3. Instance Pages in TabContainer (Editor Work)
- [x] 3.1 Open `main_lobby_screen.tscn` in editor
- [x] 3.2 Select the PageContainer (TabContainer) node
- [x] 3.3 Right-click PageContainer → "Instance Child Scene"
- [x] 3.4 Select `lobby_pages/duel_page.tscn` and instance it
- [x] 3.5 Right-click PageContainer → "Instance Child Scene"
- [x] 3.6 Select `lobby_pages/page2.tscn` and instance it
- [x] 3.7 Right-click PageContainer → "Instance Child Scene"
- [x] 3.8 Select `lobby_pages/socials_page.tscn` and instance it
- [x] 3.9 Verify the order: DuelPage (tab 0), Page2 (tab 1), SocialsPage (tab 2)
- [x] 3.10 Save the scene

## 4. Script: Add Swipe Detection Logic
- [x] 4.1 Open `main_lobby_screen.gd` in script editor
- [x] 4.2 Add member variables at the top of the script
- [x] 4.3 Add swipe detection in `_ready()` function
- [x] 4.4 Add input handling function
- [x] 4.5 Add swipe handling function
- [x] 4.6 Add page navigation function

## 5. Script: Connect Bottom Navigation Buttons
- [x] 5.1 In `main_lobby_screen.gd`, add page indicator update function
- [x] 5.2 Add signal connection functions

## 6. Editor: Connect Bottom Button Signals (Editor Work)
- [x] 6.1 Open `main_lobby_screen.tscn` in editor
- [x] 6.2 Select the DuelPage button node (in VBoxContainer/PanelContainer3/HBoxContainer)
- [x] 6.3 In Inspector, go to "Node" tab → "Signals"
- [x] 6.4 Double-click "pressed()" signal
- [x] 6.5 Connect to main_lobby_screen node, method: `_on_duel_page_pressed`
- [x] 6.6 Repeat for Page2 button → connect to `_on_page2_pressed`
- [x] 6.7 Repeat for SocialPage button → connect to `_on_social_page_pressed`
- [x] 6.8 Optional: Set button "toggle_mode" = true for visual pressed state
- [x] 6.9 Save the scene

## 7. Migrate Existing Functionality (Editor & Script Work)
- [x] 7.1 DuelPage kept as-is per user request
- [x] 7.2-7.5 Skipped - no migration needed

## 8. Polish and Testing
- [ ] 8.1 Test swipe gestures in different directions
- [ ] 8.2 Test bottom navigation button clicks
- [ ] 8.3 Verify header and bottom panel stay static during transitions
- [ ] 8.4 Adjust swipe_threshold and animation duration for feel
- [ ] 8.5 Test on mobile device or touch simulator
- [ ] 8.6 Verify page bounds (can't swipe beyond first/last page)
- [ ] 8.7 Add visual polish (optional): 
  - Page transition effects
  - Active page indicator styling
  - Drag preview while swiping

## 9. Documentation
- [x] 9.1 Add GDScript documentation comments to all new functions
- [x] 9.2 Document the page system architecture in code comments
- [ ] 9.3 Update any relevant project documentation
