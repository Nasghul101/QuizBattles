## ADDED Requirements

### Requirement: Match mode marker
A match SHALL carry a `mode` field. Matches created from a friend invite use `friend`; matches created by random matchmaking use `random`. Matches without the field SHALL be treated as `friend`.

#### Scenario: Random match mode
- **WHEN** a match is created by random matchmaking
- **THEN** the stored match has `mode` set to `random`

#### Scenario: Legacy match
- **WHEN** a stored match has no `mode` field
- **THEN** it is treated as a `friend` match

### Requirement: Random matches stay out of the friend list
Matches with `mode` `random` SHALL NOT be listed on the friendly battle page. They are shown on the challenge page.

#### Scenario: Friendly battle page listing
- **WHEN** the friendly battle page loads the player's matches
- **THEN** matches with `mode` `random` are not listed

### Requirement: Random match starting player
For a match created by random matchmaking, `current_turn` and `inviter` SHALL be the player who pressed last, and the first round's category chooser SHALL be that player.

#### Scenario: Last presser starts
- **WHEN** a random match is created from player A's waiting search and player B's request
- **THEN** `current_turn` is player B
- **AND** `inviter` is player B
