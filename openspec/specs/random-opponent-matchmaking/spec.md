## Purpose
Pairs signed-in players who want to face a random opponent. It manages the waiting search, the pairing into a match, and the automatic expiry of searches nobody answered.

## Requirements

### Requirement: Start or join a random-opponent search
The system SHALL let a signed-in player request a random opponent. If no other player's search is waiting, a search for the player is stored. If another player's search is waiting, the two players are paired.

#### Scenario: No search waiting
- **WHEN** a player requests a random opponent and no other player has a waiting search
- **THEN** a waiting search is stored for that player
- **AND** no match is created

#### Scenario: Another search is waiting
- **WHEN** a player requests a random opponent and another player has a waiting search
- **THEN** a match is created between the two players
- **AND** the waiting search is removed

#### Scenario: Concurrent requests
- **WHEN** several players request a random opponent at the same time
- **THEN** each waiting search is paired with at most one player
- **AND** a player is never paired with themself

#### Scenario: Player already searching
- **WHEN** a player who already has a waiting search requests a random opponent again
- **THEN** no second search is created
- **AND** no match is created

### Requirement: Search while matches are active
A player SHALL be able to start a new random-opponent search while they have active random-opponent matches, and SHALL be able to have several random-opponent matches at the same time.

#### Scenario: Search with active match
- **WHEN** a player with an active random-opponent match requests a random opponent
- **THEN** a waiting search is stored or a pairing is made as usual

### Requirement: Exclude current opponents
A player SHALL NOT be paired with another player they already have an active match with. Such players are excluded from each other's searches until that match is over, but both can still be paired with other players.

#### Scenario: Waiting search of a current opponent
- **WHEN** player B requests a random opponent, the only waiting search is player A's, and A and B have an active match
- **THEN** no match is created
- **AND** a waiting search is stored for player B

#### Scenario: Other waiting search available
- **WHEN** player B requests a random opponent, and player A (a current opponent) and player C both have waiting searches
- **THEN** B is paired with C
- **AND** A's search stays waiting

#### Scenario: Match is over
- **WHEN** the active match between A and B has finished
- **THEN** A and B can be paired with each other again, creating a separate match

### Requirement: Random-opponent match configuration
A match created by random matchmaking SHALL have 5 rounds with 3 questions per round, and SHALL be marked as a random-opponent match.

#### Scenario: Fixed configuration
- **WHEN** a random-opponent match is created
- **THEN** its configuration is 5 rounds and 3 questions per round

### Requirement: Last player to search plays first
In a random-opponent match, the player who pressed the button last (the one who completed the pairing) SHALL take the first turn.

#### Scenario: First turn assignment
- **WHEN** player A has a waiting search and player B then requests a random opponent
- **THEN** the match's current turn is player B
- **AND** player B is the first category chooser

### Requirement: Search expiry after 24 hours
A waiting search SHALL be cancelled automatically once it has waited more than 24 hours. Players cannot cancel a search manually.

#### Scenario: Search expires
- **WHEN** a search has been waiting for more than 24 hours
- **THEN** the search is removed
- **AND** the player may start a new search

#### Scenario: Expired search is not paired
- **WHEN** a player requests a random opponent and the only waiting search is older than 24 hours
- **THEN** that search is not used for pairing
- **AND** a new waiting search is stored for the requesting player

### Requirement: Search access control
A client SHALL only be able to read the searches that belong to the signed-in player. A client SHALL NOT be able to create a match for another player directly.

#### Scenario: Reading another player's search
- **WHEN** a signed-in player tries to read another player's search
- **THEN** the request is denied

### Requirement: Client search status
The client SHALL be able to tell whether the signed-in player currently has a waiting search.

#### Scenario: Waiting search exists
- **WHEN** the signed-in player has a waiting search
- **THEN** the status reports that the player is searching

#### Scenario: Search ended
- **WHEN** the waiting search is paired or expires
- **THEN** the status reports that the player is no longer searching
