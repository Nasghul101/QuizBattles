# Change: Add Swipeable Lobby Pages

## Why
The main lobby currently displays only a single static content area. To provide better navigation and organize different features (Duel, Page2, Socials), we need a swipeable multi-page interface where users can swipe left/right to access different sections while keeping the header and bottom navigation bar consistent across pages.

## What Changes
- Add TabContainer-based page system to main lobby middle section
- Implement custom swipe gesture detection for horizontal page navigation
- Create 3 separate page content scenes (Duel page, Page2, Page3/Socials page)
- Sync bottom navigation buttons with current page state
- Maintain static header and bottom navigation during page transitions
- Add smooth animated transitions between pages

## Impact
- Affected specs: main-lobby-screen
- Affected code: 
  - `scenes/ui/main_lobby_screen.tscn` - UI structure modifications
  - `scenes/ui/main_lobby_screen.gd` - Navigation and swipe logic
  - New scenes: `scenes/ui/lobby_pages/` directory with 3 page scenes
- UI/UX: Users gain swipe-based navigation, bottom buttons become page indicators/switchers
