# Proposal: Add Trivia Question Service

**Change ID**: `add-trivia-question-service`  
**Date**: 2026-01-14  
**Status**: Proposed

## Problem Statement

The game currently lacks a way to fetch and manage trivia questions from the Open Trivia Database API. Quiz screens expect question data but have no source to provide it. The project needs:

1. Integration with Open Trivia Database API to fetch questions by category
2. Local caching of fetched questions for offline gameplay
3. Fallback to a local question database when API requests fail
4. Category mapping to consolidate Entertainment and Science subcategories
5. A data layer service that provides questions without coupling to game logic

Without this service, the gameplay screens cannot function with real trivia content.

## Proposed Solution

Create a **Trivia Question Service** as an autoload singleton that:

- Fetches questions from Open Trivia Database API per-round (3 questions at a time)
- Caches fetched questions locally in memory for the current session
- Consolidates Open Trivia DB categories (merge Entertainment/* → Entertainment, Science/* → Science)
- Falls back to a local JSON file (`res://data/fallback_questions.json`) when API fails
- Returns questions in the existing Open Trivia DB format (no transformation needed)
- Uses Godot's HTTPRequest node for async API calls
- Provides clear error states for "no internet" vs "API failure"

### Architecture Decision

**Storage**: Autoload service (`res://autoload/trivia_question_service.gd`)
- **Why autoload**: Global access pattern, single instance, survives scene transitions
- **Why not game logic**: Questions are data, not gameplay rules
- **Why not UI**: Keeps data fetching separate from presentation

**Memory Strategy**: Session-based cache
- Store fetched questions in a Dictionary keyed by category
- Clear cache only on app restart or explicit flush
- No persistent disk storage (rely on API + fallback JSON)

### Category Mapping

Open Trivia DB has 24 categories. We will:
- Merge `Entertainment: Film`, `Entertainment: Music`, etc. → `"Entertainment"`
- Merge `Science: Computers`, `Science: Mathematics`, etc. → `"Science"`
- Keep other categories as-is (History, Geography, Sports, etc.)

Mapping will be hardcoded in the service (simple dictionary lookup).

### Error Handling Strategy

| Scenario | Behavior |
|----------|----------|
| API request fails (500, timeout) | Fall back to local JSON |
| No internet connection | Emit error signal, UI shows "Please connect to internet" |
| Local JSON missing/corrupt | Push error, return empty array |
| Invalid API response | Push warning, fall back to local JSON |
| Rate limit (assumed won't happen) | Not explicitly handled |

### Data Flow

```
GameplayScreen
    ↓ (requests questions for category)
TriviaQuestionService
    ↓ (check cache)
    ├─ [Cache Hit] → Return cached questions
    └─ [Cache Miss] → Fetch from API
        ↓
        ├─ [Success] → Cache + Return
        └─ [Failure] → Load from fallback JSON
```

## Design Decisions

### 1. Per-Round Fetching vs Bulk Fetching
**Decision**: Fetch 3 questions per round when category is selected  
**Rationale**: Categories are chosen dynamically by players during gameplay. Pre-fetching all categories would waste bandwidth and memory. Per-round fetching aligns with the Classic Duel flow.

### 2. Caching Strategy
**Decision**: In-memory session cache, no disk persistence  
**Rationale**: 
- Keeps questions fresh on each app launch
- Avoids disk I/O overhead on mobile
- Simplifies implementation (no save/load logic)
- Fallback JSON provides offline support

### 3. Format Preservation
**Decision**: Keep Open Trivia DB format as-is  
**Rationale**: Quiz screen already expects this format. No need to introduce transformation layer.

### 4. Fallback JSON Structure
**Decision**: JSON file with array of question objects, organized by category  
**Rationale**: 
- Easy to edit manually
- Developer can add custom questions
- Simple to parse with Godot's JSON API

### 5. No HTML Entity Decoding Initially
**Decision**: Return raw question text from API (may contain HTML entities like `&quot;`)  
**Rationale**: Open Trivia DB often returns encoded text. We could decode it, but:
- Adds complexity (regex or additional library)
- Can be added later if needed
- Developer may want to handle it in UI layer

**Note**: If HTML entities become problematic, we can add decoding in a future change.

## Affected Components

### New Components
- `TriviaQuestionService` (autoload service)
- `fallback_questions.json` (data file)

### Modified Components
None (this is a new capability - existing screens will integrate in future changes)

## Alternatives Considered

### 1. Scene Node vs Autoload
**Rejected**: Scene node approach would require passing the service reference around, adding complexity.

### 2. Fetch Entire Match Worth of Questions (18 questions)
**Rejected**: Categories are chosen dynamically per round. Can't predict which categories to fetch.

### 3. Transform API Data to Custom Format
**Rejected**: Unnecessary - quiz screen already expects Open Trivia DB format.

### 4. Persistent Disk Cache
**Rejected**: Adds complexity, disk I/O overhead, cache invalidation logic. Session cache + fallback JSON is simpler.

## Dependencies

None. This is a foundational data layer service.

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Open Trivia DB API changes format | Validate response structure, fallback on invalid data |
| API rate limiting | Assume won't happen per user requirement |
| Large question cache consuming memory | Only cache questions for current session, limit to ~50 questions max |
| Network latency on mobile | Use async HTTPRequest, show loading indicator in UI |

## Success Criteria

- [ ] Service fetches 3 questions from Open Trivia DB API for a given category
- [ ] Questions are cached in memory and reused if same category requested again
- [ ] API failures automatically fall back to local JSON questions
- [ ] Entertainment and Science subcategories are correctly mapped
- [ ] Service returns questions in Open Trivia DB format
- [ ] "No internet" scenario is distinguishable from "API failure"
- [ ] Fallback JSON contains at least 3 example questions per major category

## Open Questions

None - all clarifications received from user.
