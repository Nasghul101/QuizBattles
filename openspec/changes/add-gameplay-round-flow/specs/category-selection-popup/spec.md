# category-selection-popup Specification Delta

## Purpose
A modal popup component that displays 3 random trivia categories for player selection and shows loading progress while questions are being fetched from the API.

## ADDED Requirements

### Requirement: The component SHALL display 3 random category buttons
The category selection popup SHALL present exactly 3 buttons populated with random category names from the available categories pool.

#### Scenario: Display random categories
**Given** the TriviaQuestionService has 12 available categories  
**When** `show_categories(categories)` is called with 3 random category names  
**Then** each of the 3 category buttons displays one of the provided category names

#### Scenario: Category button interaction
**Given** the popup is showing 3 categories  
**When** the player presses one of the category buttons  
**Then** the component emits `category_selected(category_name)` signal with the selected category name

---

### Requirement: The component SHALL display loading state with progress indication
The popup SHALL switch from category selection to loading state when questions are being fetched, showing animated progress feedback.

#### Scenario: Transition to loading state
**Given** the popup is showing category buttons  
**When** `show_loading()` is called  
**Then** the category buttons are hidden  
**And** the progress bar becomes visible  
**And** the headline text changes to "Loading..."

#### Scenario: Progress bar animation
**Given** the popup is in loading state  
**When** the progress bar is visible  
**Then** the progress bar value animates from 0 to 100 over 1-2 seconds

---

### Requirement: The component SHALL function as a modal overlay
The popup SHALL block interaction with background elements when visible and be dismissible when hidden.

#### Scenario: Block background interaction
**Given** the gameplay_screen has interactive elements  
**When** the category popup is visible  
**Then** players cannot interact with gameplay_screen elements behind the popup

#### Scenario: Hide popup
**Given** the category popup is visible  
**When** `hide_popup()` is called or questions are ready  
**Then** the popup becomes invisible  
**And** background elements become interactable again

---

### Requirement: The component SHALL emit category selection signal
The popup SHALL communicate the selected category back to the parent controller via signal.

#### Scenario: Emit category selection
**Given** the popup is showing categories ["History", "Science", "Sports"]  
**When** the player presses the "History" button  
**Then** the component emits `category_selected("History")` signal

---

### Requirement: The component SHALL integrate with existing UI structure
The popup SHALL use the existing category_popup_component.tscn structure without requiring UI changes.

#### Scenario: Use existing tscn structure
**Given** category_popup_component.tscn has Category1, Category2, Category3 buttons, ProgressBar, and Headline label  
**When** the component script is attached  
**Then** all node references are accessible via unique name references (%Category1, %Category2, etc.)
