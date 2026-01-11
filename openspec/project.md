# Project Context

## Purpose
A fully 2D, mobile-first quiz duel game inspired by Quizduell for phone apps. Players compete head-to-head by answering trivia questions in structured rounds. The game emphasizes competitive fairness, simple modern UX, and cosmetic-only monetization with no ads or subscriptions.

## Tech Stack
- **Engine**: Godot 4.5+ (2D only)
- **Target Platform**: Mobile (Android/iOS) - Portrait orientation
- **Rendering**: 2D rendering only (no 3D nodes)
- **Programming Language**: GDScript
- **Backend**: Firebase (authentication, database, cloud functions)
- **Question Source**: Open Trivia Database (JSON-based)
- **Architecture**: Scene-based with clear separation of logic, UI, and data

## Project Conventions

### Code Style
- Follow official GDScript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- Static typing: Use static typing where possible for better performance and error checking
- Mobile-performance optimizations
- No hardcoded art styles, colors, or themes in logic
- Avoid code assumptions about "only one game mode"

### Documentation Conventions
- Follow official GDScript documentation comments guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
- Use `##` for documentation comments (class descriptions, function descriptions)
- Use `#` for inline explanatory comments
- Example:
  ```gdscript
  extends Node2D
  ## Test scene for quiz screen component
  
  ## Calculate the final score based on correct answers and time bonus
  func calculate_score(correct: int, time_bonus: float) -> int:
      # Multiply by 100 to get base score
      return int(correct * 100 * time_bonus)
  ```

### Architecture Patterns
- **Scene-based architecture**: Each screen is a separate, reusable scene
- **Composition workflow**: Follow composition-based design as described in [Composition in Godot 4](https://www.gotut.net/composition-in-godot-4/)
  - Build complex objects by combining simpler, reusable components
  - Create modular components (scripts or scenes) that can be mixed and matched
  - Components should be independent and easily replaceable
  - Benefits: Reusability, modularity, flexibility, and consistency
  - Use both scene-based components (for shared visual/configuration defaults) and script-based components (for behavior logic)
- **Separation of concerns**:
  - Game logic layer (duel mechanics, scoring, turn management)
  - UI layer (visual presentation, input handling)
  - Data layer (questions, player state, match state)
- **Modular game modes**: Mode logic must be extendable for future additions
- **Decoupled systems**: Monetization features separate from gameplay logic
- **Replaceable components**: Question sources must be easily swappable
- **Placeholder-first UI**: Generic panels, buttons, labels - developer controls final design

### Testing Strategy
- **Framework**: GUT (Godot Unit Test)
- **Focus**: Core game logic (scoring, turn management, question validation)
- **UI Testing**: Manual testing for mobile UX
- **Integration**: Test question loading, state persistence, backend connectivity

### Git Workflow
- **Branching**: Simple feature branches merged to main
- **Commits**: Clear, descriptive messages
- **Pull Requests**: Optional for solo development, recommended for major features

## Domain Context

### Game Mode System
- **Current**: Classic Duel (only implemented mode)
- **Future**: Architecture supports multiple game modes
- **Design principle**: No hardcoded assumptions about single mode

### Classic Duel Structure
- **Match**: 6 rounds per duel
- **Round**: 1 category with 3 questions
- **Category Selection**: Players alternate choosing (A chooses → both answer, B chooses → both answer)
- **Scoring**: 1 point per correct answer, no speed bonus
- **Timer**: Per question - timeout = no point
- **Play Style**: Asynchronous play required, real-time optional

### Question Format
- Multiple choice with 4 answer options
- Each question includes:
  - Question text
  - Answer options (4 choices)
  - Correct answer index
  - Category
  - Difficulty level
- Local caching supported
- Manual custom questions supported

### Core UI Screens (Scene Structure)
1. Home / Duel Overview
2. Category Selection
3. Question Screen
4. Round Result
5. Match Result

Each screen must be a separate, reusable scene.

### Monetization Model (Future-Ready)
- **Cosmetic only**: Avatars, win animations, emotes, UI themes
- **No gameplay advantages** from purchases
- **No ads**
- **No subscriptions**
- Implementation can be stubbed/mocked initially

## Important Constraints

### Design Philosophy
- Build a clean foundation first
- Prioritize clarity over features
- Avoid feature creep
- Everything must be replaceable and extensible
- Developer has full control over visual design

### Mobile-First Requirements
- Portrait orientation only
- Large tap targets
- Clear typography
- One primary action per screen
- Touch input only (no mouse assumptions)
- UI scales to different phone resolutions

### Accessibility & Usability
- Avoid aggressive animations
- Visual effects must be optional
- No clutter in UI
- Performance-friendly for mobile devices

### Non-Negotiables
- ✅ Godot 4.5 or newer
- ✅ 2D only (no 3D nodes)
- ✅ Mobile-first design
- ✅ Expandable game mode architecture
- ✅ Developer-controlled design (no baked-in styling)
- ✅ Simple, modular, replaceable UI

## External Dependencies
- **Open Trivia Database**: JSON-based question source (https://opentdb.com/)
- **Firebase**: 
  - Authentication (player accounts)
  - Firestore (game state, match data, player profiles)
  - Cloud Functions (matchmaking logic, validation)
  - Free tier suitable for development and initial launch
- **Analytics**: Firebase Analytics (included in free tier)
- **Monetization Platform**: Google Play / App Store in-app purchases for cosmetics
