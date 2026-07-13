# gameplay-screen-initialization Spec Delta

## MODIFIED Requirements

### Requirement: Gameplay screen MUST instantiate child components on ready
The gameplay screen SHALL configure embedded components and instantiate remaining dynamic children during initialization.

#### Scenario: Configure embedded category popup
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** the embedded CategoryPopup MarginContainer node is accessed via `%CategoryPopup`  
**And** the category popup is already part of the scene tree (no instantiation needed)  
**And** the category popup's visibility is managed by toggling the `visible` property

#### Scenario: Instantiate quiz screen
**Given** the gameplay screen loads  
**When** `_ready()` executes  
**Then** a quiz_screen instance is created  
**And** added as a child of gameplay screen  
**And** set to invisible by default

---

## REMOVED Requirements

### ~~Requirement: Gameplay screen MUST instantiate child components on ready~~
~~The gameplay screen SHALL create and configure category popup and quiz screen as children during initialization.~~

#### ~~Scenario: Instantiate category popup~~
~~**Given** the gameplay screen loads~~  
~~**When** `_ready()` executes~~  
~~**Then** a category_popup_component instance is created~~  
~~**And** added as a child of gameplay screen~~  
~~**And** set to invisible by default~~

---

## Rationale

The category popup is now embedded directly in the gameplay_screen.tscn scene file as a `MarginContainer` node with the `category_popup_component.gd` script attached. This follows the same pattern used by other popups in the project (e.g., NotificationsPopUp in main_lobby_screen).

**What changed:**
- Category popup is no longer a separate `.tscn` scene
- No dynamic instantiation or `add_child()` call needed
- Accessed via `@onready var category_popup: MarginContainer = %CategoryPopup`
- Still uses the same script (`category_popup_component.gd`) for behavior
- Signal connections remain identical

**What stayed the same:**
- Quiz screen remains dynamically instantiated (unchanged)
- All signal connections work the same way
- Popup visibility management remains the same
- Public API of category popup unchanged (`show_categories()`, `hide_popup()`, etc.)
