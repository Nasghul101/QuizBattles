# Change: Implement Socials Page Interactions

## Why
The socials_page was recently rebuilt with new UI but lacks all interactive functionality. Players cannot view friend statistics, search for new players, send friend requests, or see category preferences. Without these features, the social aspects of the quiz duel game are non-functional.

## What Changes
- Extend friend_display_component instantiation to populate with user statistics (wins, losses, category preferences)
- Add category statistics tracking to user database (`category_stats: Dictionary` mapping category names to play counts)
- Implement search-as-you-type functionality in AddFriendsPopup with name_display_button instantiation
- Create name_display_button script with radio-button highlight behavior
- Implement friend request sending with button state management (enabled only when selection exists)
- Add popup cleanup behavior (clear name input on close)
- Use existing GlobalSignalBus.notification_action_taken signal for friend list updates
- Use placeholder data for category statistics until real tracking is implemented

**Breaking Changes**: None

## Impact

**Affected Specs:**
- `socials-page-friend-display` (MODIFIED - add friend stats display)
- `local-user-database` (MODIFIED - add category stats tracking)
- `socials-page-search-interaction` (ADDED - new search and friend request flow)
- `name-display-button-component` (ADDED - new highlightable button component)

**Affected Code:**
- `scenes/ui/lobby_pages/socials_page.gd` - Main interaction logic
- `scenes/ui/components/friend_display_component.gd` - Already has setters, use them
- `scenes/ui/components/name_display_button.tscn` - Add script for highlight behavior
- `autoload/user_database.gd` - Add category_stats field and placeholder data
- `data/user_database.json` - Schema migration for category_stats

**Database Schema Changes:**
- User records: Add `category_stats: Dictionary` mapping category names to integers (play counts)
- Migration: Auto-add empty `category_stats: {}` for existing users with comment noting placeholder data

**Dependencies:**
- Requires existing friend_display_component.tscn and .gd
- Requires existing name_display_button.tscn
- Uses existing GlobalSignalBus.notification_action_taken signal
- Uses existing UserDatabase.search_users_by_username() method
