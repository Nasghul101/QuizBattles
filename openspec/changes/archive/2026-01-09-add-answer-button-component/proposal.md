# Proposal: Add Answer Button Component

## Why
The quiz game needs a reusable UI component for answer selection that provides immediate visual feedback (correct/wrong states) and enables consistent interaction across all question screens.

## What Changes
- Add new scene-based component: `scenes/ui/components/answer_button.tscn` with accompanying script
- Component displays answer text, emits selection signals, and reveals correct/wrong states
- Exported color properties enable customization for future theming/monetization
- Self-contained behavior: disables after press, handles state transitions with animations

## Impact
- **Affected specs**: New capability `answer-button-component`
- **Affected code**: New files in `scenes/ui/components/`
- **Dependencies**: None - standalone component

## Summary
Create a reusable scene-based answer button component for the quiz interface that displays answer text, handles user interaction, and visually indicates correctness through color states.

## Motivation
The quiz game requires a consistent, reusable UI element for displaying and selecting answers. This component will serve as the foundation for the question answering interface, supporting the core gameplay loop of selecting answers and receiving immediate visual feedback.

## Goals
- Create a single, reusable answer button component that can be instantiated 4 times per question
- Support visual state changes (neutral, selected, correct, wrong)
- Enable flexible styling through exported properties for future theming/monetization
- Follow composition-based architecture principles for modularity

## Non-Goals
- Timer integration (handled separately)
- Question validation logic (parent scene responsibility)
- Layout of multiple buttons (handled by parent question screen)
- Complex animations or effects beyond color transitions

## Scope
This change adds one new capability:
- **answer-button-component**: A scene-based UI component for quiz answer selection

## User Impact
Developers using this component will be able to:
- Quickly build question screens by instantiating 4 button components
- Customize colors and styling through the inspector
- Receive signals when answers are selected
- Programmatically reveal correct/wrong states after validation

## Dependencies
- Godot 4.5+ Button node
- No external dependencies

## Risks & Mitigations
- **Risk**: Component might need refactoring if game mode requirements change
  - **Mitigation**: Keep component simple and focused on single responsibility
- **Risk**: Color choices might not work for all themes
  - **Mitigation**: Use exported properties for easy customization

## Alternatives Considered
1. **Script-based component**: Rejected in favor of scene-based for visual editing
2. **Parent-controlled states**: Rejected in favor of self-disabling for cleaner API
3. **Hardcoded colors**: Rejected in favor of exported properties for flexibility
