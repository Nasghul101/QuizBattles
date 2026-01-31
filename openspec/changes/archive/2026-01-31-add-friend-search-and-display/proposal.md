# Proposal: Add Friend Search and Display

## Change ID
`add-friend-search-and-display`

## Overview
Enable users to search for other registered players by username in the AddFriendsPopup and display matching results as avatar components. This provides the foundation for the friend system by implementing search and display functionality without yet adding friend relationships or persistence.

## Problem Statement
The Socials Page currently has an AddFriendsPopup with a NameInput field but no functionality to search for users or display search results. Users need a way to discover other players in the system before they can add them as friends.

## Proposed Solution
Implement real-time username search in the AddFriendsPopup that:
- Triggers automatically as the user types in the NameInput TextEdit field
- Performs case-insensitive partial matching against usernames in UserDatabase
- Displays matching users as avatar_component instances in the SearchResults GridContainer
- Excludes the currently logged-in user from search results
- Provides a foundation for future friend relationship management (placeholder for excluding already-befriended users)

## Scope
**In Scope:**
- Real-time search triggering on text input changes
- Case-insensitive partial username matching
- Display of search results using avatar_component instances
- Current user exclusion from results
- Enhancement of UserDatabase.get_user_by_username() to return avatar_path

**Out of Scope:**
- Adding friends (persisting friend relationships)
- Friend list management
- Removing friends
- Friend-specific UI updates beyond search results
- Exact-match-only search (implementing partial matching instead)

## Impact Analysis
**Affected Components:**
- `scenes/ui/lobby_pages/socials_page.gd` - Add search logic and result display
- `autoload/user_database.gd` - Enhance get_user_by_username() to include avatar_path
- `openspec/specs/socials-page-popup-animation/spec.md` - New capability within existing socials page

**Dependencies:**
- Requires existing UserDatabase service
- Requires existing avatar_component scene
- Requires SearchResults GridContainer in AddFriendsPopup (already exists)

**Breaking Changes:** None

## User-Facing Changes
- Users can now type in the NameInput field and see matching usernames appear as avatar components in real-time
- Search results update dynamically as the user types
- The current user is never shown in their own search results

## Technical Considerations
- Search is performed in-memory against UserDatabase._users dictionary
- No debouncing implemented initially (can be added later if performance becomes an issue)
- Avatar components are dynamically instantiated and freed to reflect search results
- Partial matching uses String.to_lower().contains() for case-insensitive substring matching

## Alternatives Considered
1. **Search button instead of real-time search**: Rejected in favor of better UX with automatic search
2. **Exact match only**: Rejected to improve discoverability
3. **Case-sensitive search**: Rejected to prevent user frustration

## Open Questions
None - all clarifications received from user.

## Related Changes
None - This is a new capability.

## Implementation Notes
- The SearchResults GridContainer already exists in the scene
- Avatar components should be cleared and recreated on each search to reflect current results
- Empty search (no text) should clear all results
- No results found (text entered but no matches) should also clear all results
