# Proposal: add-result-component

## Overview
Add a reusable result component that displays a category icon and question results for a single round. The component will show one large category circle and dynamically generated question circles that can be clicked to review the answered quiz screens.

## Problem Statement
Players need a way to review their performance after answering questions in a category. Currently, there is no component to display:
- Which category was played
- Which questions were answered correctly or incorrectly
- A way to review the actual quiz screens from completed questions

## Proposed Solution
Create a `result_component` scene that:
- Displays a non-interactive category circle (TextureRect) showing the category icon
- Dynamically generates clickable question circle buttons based on configurable question count
- Stores references to quiz_screen instances from completed questions
- Shows the corresponding quiz screen in an internal panel when a question circle is clicked
- Uses a Panel > HBox > (Category + VBox) structure for proper scaling and layout
- Supports texture loading for both category and question circles

## Scope
This change introduces a new UI component following the same reusable pattern as `answer-button-component`. 

### In Scope
- New `result_component` scene and script
- Node structure: Panel > HBox > (TextureRect for category + VBox with dynamic Button children)
- Method to load category data and quiz screen references
- Dynamic generation of question buttons based on count
- Internal panel/container to display quiz screens when question buttons are clicked
- Signal emission when quiz screens are shown/hidden
- Texture support for category and question circles
- Expand/collapse functionality for quiz screen review

### Out of Scope
- Result screen layout and composition (will be implemented separately)
- Color modulation (textures contain colors)
- Score calculation or display
- Animation between result states
- Persistence of result data

## Changes to Specifications

### New Specifications
- `result-component`: A reusable component for displaying category and question results with review capability

### Modified Specifications
None

## Dependencies
- Requires `quiz-screen-component` spec (already exists)
- No blocking dependencies

## Risks & Mitigations
- **Risk**: Dynamic button generation could impact performance with many questions
  - **Mitigation**: Follow Godot best practices for node pooling if needed; start with simple instantiation
  
- **Risk**: Storing quiz_screen node references could cause memory issues if not managed properly
  - **Mitigation**: Implement proper cleanup methods; document lifecycle expectations

- **Risk**: Scaling behavior might not work as expected across different screen sizes
  - **Mitigation**: Use container expand/fill flags properly; test on mobile portrait orientation

## Alternatives Considered
1. **Static question count**: Hardcode 3 question circles
   - Rejected: Need flexibility for future game modes with different question counts
   
2. **Recreate quiz screens from data**: Store question data and rebuild quiz screens on demand
   - Rejected: More complex and loses original state (user selections, timing, etc.)

3. **External quiz screen display**: Emit signal and let parent handle showing quiz screen
   - Rejected: Makes component less self-contained and harder to reuse

## Success Criteria
- Result component scene exists at `scenes/ui/components/result_component.tscn`
- Component can be instantiated and configured in any parent scene
- Question circles are generated dynamically based on configurable count
- Clicking a question circle displays the corresponding quiz screen
- Category texture can be loaded via method or _ready function
- Component follows project conventions for composition and reusability
- All requirements pass validation with `openspec validate`
