# result-component Specification Delta

## MODIFIED Requirements

### Requirement: The component SHALL store question data for review
The result component SHALL store complete question data and outcome information including the player's selected answer text to enable review functionality.

#### Scenario: Store player answer text
**Given** a result component receiving data via `load_result_data()`  
**When** the data contains "player_answer" field with the player's selected answer text  
**Then** the player_answer value is stored internally with question_data and was_correct

---

## ADDED Requirements

### Requirement: The component SHALL manage answer review screen lifecycle
The result component SHALL instantiate, configure, and manage the visibility of an answer_review_screen component for displaying detailed question reviews.

#### Scenario: Pre-instantiate review screen
**Given** the result_component.gd script  
**When** `_ready()` executes  
**Then** an answer_review_screen instance is created, added as a child, and initially hidden

#### Scenario: Review screen as popup layer
**Given** the instantiated answer_review_screen in result_component  
**When** adding it to the scene tree  
**Then** it is positioned to act as a modal overlay (via z_index or CanvasLayer configuration)

#### Scenario: Reuse review screen instance
**Given** a result component with an instantiated review screen  
**When** multiple result buttons are clicked in sequence  
**Then** the same review screen instance is reused (shown/hidden) rather than creating new instances

---

### Requirement: The component SHALL show review screen when result button is clicked
The result component SHALL respond to result button clicks by populating and displaying the answer review screen with the corresponding question data.

#### Scenario: Handle result button signal
**Given** a result component with loaded data and connected review screen  
**When** a result button emits the `result_clicked` signal with question_data  
**Then** the result component calls a method to show the review screen with that data

#### Scenario: Load data into review screen
**Given** a result button click with complete question data  
**When** the result component handles the signal  
**Then** it calls `answer_review_screen.load_review_data(question_data)` with the full dictionary

#### Scenario: Show review screen
**Given** the review screen has been populated with question data  
**When** displaying the review  
**Then** the result component calls `answer_review_screen.show_review()` to make it visible

---

### Requirement: The component SHALL ensure only one review screen is visible at a time
The result component SHALL manage review screen visibility to prevent multiple overlays from appearing simultaneously.

#### Scenario: Hide before showing new review
**Given** a review screen is currently visible  
**When** a different result button is clicked  
**Then** the current review screen is hidden before loading and showing the new question data

#### Scenario: Single review screen instance
**Given** multiple result buttons in the same result component  
**When** clicking different buttons in sequence  
**Then** only one review screen is ever visible at any given time

---

### Requirement: The component SHALL handle review screen dismissal
The result component SHALL respond to review screen close events and restore gameplay screen interactivity.

#### Scenario: Connect to review screen hide signal
**Given** the instantiated answer_review_screen  
**When** the review screen's back button is pressed  
**Then** the review screen calls its `hide_review()` method and becomes invisible

#### Scenario: Cleanup after review close
**Given** a visible review screen  
**When** the back button hides the review  
**Then** the gameplay screen remains interactive (no additional cleanup needed as review screen just hides)
