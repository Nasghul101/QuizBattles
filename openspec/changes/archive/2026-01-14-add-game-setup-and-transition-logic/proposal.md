# Proposal: Add Game Setup and Transition Logic

**Change ID:** `add-game-setup-and-transition-logic`  
**Status:** Proposal  
**Created:** 2026-01-14  
**Author:** AI Assistant

## Why

The game currently has visual setup and gameplay screens (`setup_screen.tscn` and `gameplay_screen.tscn`) but lacks the logic to allow players to configure game settings (rounds and questions), transition between screens with visual feedback, and pass configuration data to gameplay. Without this foundational logic, players cannot start a customized game session.

## What Changes

- Add `setup_screen.gd` script for slider interaction and value display
- Add `gameplay_screen.gd` script for configuration reception and storage
- Create `TransitionManager` autoload for reusable fade transitions (0.5s)
- Register TransitionManager in `project.godot` autoload section
- Connect UI elements (sliders, labels, button) via signals

## Impact

- **Affected specs**: Three new capabilities
  - `setup-screen-logic` - Player configuration interface
  - `scene-transition-manager` - Reusable fade transitions
  - `gameplay-screen-initialization` - Configuration reception
- **Affected code**: New files in `scenes/ui/` and `autoload/`
- **Dependencies**: None - standalone functionality

## Summary

Implement interactive game setup screen with configurable sliders (rounds/questions), real-time label updates, smooth fade transitions between scenes, and a reusable transition manager autoload for consistent scene changes throughout the game.

## Problem Statement

The game currently has visual setup and gameplay screens (`setup_screen.tscn` and `gameplay_screen.tscn`) but lacks the logic to:
1. Allow players to configure game settings (number of rounds and questions per round) via interactive sliders
2. Display current slider values in real-time to the player
3. Transition between setup and gameplay screens with visual feedback
4. Pass configuration data from setup to gameplay for future game logic implementation

Without this foundational logic, players cannot start a game or customize their gameplay experience.

## Goals

1. **Setup Screen Logic:** Enable player configuration of rounds and questions with real-time UI updates
2. **Scene Transition:** Provide smooth fade transition between setup and gameplay screens
3. **Data Passing:** Establish a pattern for passing game configuration to gameplay screen that can later integrate with Firebase persistence
4. **Reusable Transitions:** Create a transition manager for consistent scene changes across the entire game

## Proposed Solution

### Overview
Implement three core capabilities:

1. **Setup Screen Logic** (`setup_screen.gd`)
   - Connect sliders to amount labels for real-time value display
   - Handle start button press to initiate scene transition
   - Pass configuration values to gameplay screen

2. **Scene Transition Manager** (autoload singleton)
   - Provide reusable fade-in/fade-out functionality (0.5s duration)
   - Support scene switching with parameter passing
   - Enable future expansion for other transition effects

3. **Gameplay Screen Initialization** (`gameplay_screen.gd`)
   - Receive and store round/question configuration
   - Provide initialization method for external setup
   - Maintain state for future game logic integration

### Design Decisions

**Why autoload for transitions?**
- Ensures consistent visual experience across all scene changes
- Singleton pattern allows any scene to trigger transitions
- Fade overlay persists across scene changes

**Why initialization method over exports?**
- Supports dynamic configuration from code
- Compatible with future Firebase data loading
- Allows validation and processing of settings before storage

**Why store directly in gameplay_screen?**
- Temporary solution until Firebase integration
- Keeps configuration close to where it's used
- Easy to refactor when adding persistent storage

## Affected Capabilities

- **NEW:** `setup-screen-logic` - Player configuration interface
- **NEW:** `scene-transition-manager` - Reusable scene transitions with effects
- **NEW:** `gameplay-screen-initialization` - Game configuration reception and storage

## Non-Goals

- Implementing actual quiz gameplay logic (future work)
- Firebase integration or persistent storage (future work)
- Additional configuration options beyond rounds/questions (future work)
- Custom transition effects beyond fade (future work)

## Dependencies

- Godot 4.5+ engine features (tweens, autoload)
- Existing setup_screen.tscn and gameplay_screen.tscn scene files
- Node structure as currently defined in .tscn files

## Migration & Compatibility

**New Files:**
- `scenes/ui/setup_screen.gd` - Setup screen script
- `scenes/ui/gameplay_screen.gd` - Gameplay screen script
- `autoload/transition_manager.gd` - Scene transition autoload

**Modified Files:**
- `project.godot` - Add TransitionManager autoload registration

**Breaking Changes:** None (new functionality only)

## Future Considerations

- Firebase integration will replace direct property storage
- Additional game modes may require different configuration parameters
- Transition manager can be extended with additional effects (slide, zoom, etc.)
- Setup screen may gain more configuration options (difficulty, categories, etc.)

## Success Criteria

1. Sliders update amount labels in real-time
2. Start button triggers smooth 0.5s fade transition
3. Gameplay screen receives correct round/question values
4. Transition manager is reusable from any scene
5. Code follows GDScript style guide and project conventions
6. All requirements validated by OpenSpec
