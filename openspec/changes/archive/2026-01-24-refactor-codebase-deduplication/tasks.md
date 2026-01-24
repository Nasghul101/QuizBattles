# Implementation Tasks

This document outlines the step-by-step implementation plan for code deduplication.

## Task Checklist

- [x] Create NavigationUtils autoload singleton
  - [x] Create `autoload/navigation_utils.gd` file
  - [x] Add navigate_to_scene() utility function
  - [x] Register in project.godot as autoload
  
- [x] Refactor main_lobby_screen.gd navigation
  - [x] Replace _navigate_to_register_login() with NavigationUtils call
  - [x] Replace _navigate_to_account_management() with NavigationUtils call
  - [x] Remove private navigation helper functions
  - [x] Test account button navigation flow

- [x] Refactor register_login_screen.gd navigation
  - [x] Replace _navigate_to_main_lobby() with NavigationUtils call
  - [x] Replace _navigate_to_account_registration() with NavigationUtils call
  - [x] Replace _navigate_to_account_management_after_login() with NavigationUtils call
  - [x] Remove private navigation helper functions
  - [x] Test all navigation paths (back, new account, login success)

- [x] Refactor account_registration_screen.gd navigation
  - [x] Replace _navigate_to_register_login() with NavigationUtils call
  - [x] Replace _navigate_to_account_management() with NavigationUtils call
  - [x] Remove private navigation helper functions
  - [x] Test registration flow and navigation

- [x] Refactor account_management_screen.gd navigation
  - [x] Replace _navigate_to_main_lobby() with NavigationUtils call
  - [x] Replace _navigate_to_register_login() with NavigationUtils call
  - [x] Remove private navigation helper functions
  - [x] Test back button and log off navigation

- [x] Refactor answer_button.gd internal duplication
  - [x] Extract _configure_style_box_border() helper method
  - [x] Update _on_button_pressed() to use helper
  - [x] Update reset() to use helper
  - [x] Test button state changes in quiz gameplay

- [ ] Final validation
  - [ ] Manually test complete navigation flow: lobby → registration → login → management → lobby
  - [ ] Verify quiz gameplay with answer button interactions
  - [ ] Confirm no console errors or warnings
  - [ ] Validate code reduction metrics (target: 100+ lines removed)

## Notes

- Each script refactoring should be tested independently before moving to the next
- NavigationUtils must be registered as autoload before refactoring any screens
- All navigation functions follow the same pattern: path validation + TransitionManager.change_scene()
- Preserve all error messages and console output for debugging consistency
