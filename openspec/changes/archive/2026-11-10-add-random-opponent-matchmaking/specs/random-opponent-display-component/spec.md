## Purpose
Defines the `face_random_opponent_display_component` card and how the challenge page uses it: one search card to start a random-opponent search, and one card per active random-opponent match, so several matches can run at the same time.

## ADDED Requirements

### Requirement: Search card always present
The challenge page SHALL always show exactly one search card, a `face_random_opponent_display_component` in the idle or searching state.

#### Scenario: Page opened without a search
- **WHEN** the challenge page opens and the player has no waiting search
- **THEN** one card in the idle state is shown

#### Scenario: Page opened with a search
- **WHEN** the challenge page opens and the player has a waiting search
- **THEN** one card in the searching state is shown

### Requirement: Idle state
The idle card SHALL show only the player's name and the "face opponent" prompt.

#### Scenario: Idle display
- **WHEN** a card is in the idle state
- **THEN** `NameP1` shows the player's name
- **AND** `ScoreP1`, `NameP2`, `ScoreP2` and `RoundLabel` are invisible
- **AND** `FaceOpponentLabel` shows `CHALLENGE_SCREEN_FACE_OPPONENT`
- **AND** `ButtonBGHighlighted` is invisible
- **AND** `FaceRandomOpponentButton` is enabled

### Requirement: Searching state
After the player presses `FaceRandomOpponentButton` on the idle card and no opponent is found yet, the card SHALL show the searching state.

#### Scenario: Search started
- **WHEN** the player presses `FaceRandomOpponentButton` on the idle card and no opponent is available
- **THEN** the card looks like the idle state, except that `FaceOpponentLabel` shows `CHALLENGE_SCREEN_SEARCH_OPPONENT`
- **AND** `FaceRandomOpponentButton` is disabled

### Requirement: Opponent's turn state
A match card SHALL show the match with the opponent's turn when the opponent is to play.

#### Scenario: Opponent's turn display
- **WHEN** a match card is shown and the match's current turn belongs to the opponent
- **THEN** `NameP1`, `ScoreP1`, `NameP2`, `ScoreP2` and `RoundLabel` are visible and show the correct names, scores and round
- **AND** `FaceOpponentLabel` shows `CHALLENGE_SCREEN_OPPONENT_TURN`
- **AND** `ButtonBGHighlighted` is invisible
- **AND** `FaceRandomOpponentButton` is enabled

### Requirement: Player's turn state
A match card SHALL show the match highlighted when it is the player's turn.

#### Scenario: Player's turn display
- **WHEN** a match card is shown and the match's current turn belongs to the player
- **THEN** `NameP1`, `ScoreP1`, `NameP2`, `ScoreP2` and `RoundLabel` are visible and show the correct names, scores and round
- **AND** `FaceOpponentLabel` shows `CHALLENGE_SCREEN_YOUR_TURN`
- **AND** `ButtonBGHighlighted` is visible
- **AND** `FaceRandomOpponentButton` is enabled

### Requirement: One match card per active random match
The challenge page SHALL show one match card for each active random-opponent match of the player, in addition to the search card.

#### Scenario: Opponent found
- **WHEN** the player's search is paired with another player
- **THEN** a new match card is instantiated for the new match
- **AND** the search card returns to the idle state so the player can search again

#### Scenario: Several matches
- **WHEN** the player has three active random-opponent matches
- **THEN** three match cards and one search card are shown

#### Scenario: Match finished
- **WHEN** a random-opponent match finishes
- **THEN** its match card is removed from the challenge page
- **AND** the other cards are unchanged

#### Scenario: Matches restored on open
- **WHEN** the challenge page opens
- **THEN** a match card exists for every active random-opponent match of the player, with the state for its current turn

### Requirement: Opening the match
Pressing `FaceRandomOpponentButton` on a match card SHALL open that card's match.

#### Scenario: Press on a match card
- **WHEN** the player presses `FaceRandomOpponentButton` on a match card
- **THEN** the gameplay screen opens for that card's match and no other match

### Requirement: Live state updates
Cards SHALL update without a manual refresh when a search is paired or expires, or when a match changes or finishes.

#### Scenario: Opponent found while page is open
- **WHEN** the player is in the searching state and another player's request pairs with them
- **THEN** a match card appears and the search card returns to idle

#### Scenario: Search expired while page is open
- **WHEN** the player's waiting search is removed without a match
- **THEN** the search card returns to the idle state

#### Scenario: Turn changes
- **WHEN** the current turn of a shown match changes
- **THEN** that match card switches between the opponent's turn and player's turn states
