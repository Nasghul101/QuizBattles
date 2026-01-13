# result-component Specification

## Purpose
A reusable UI component that displays a single round's results with a category icon and dynamically generated question result indicators. Players can click question circles to review their answered quiz screens.

## ADDED Requirements

### Requirement: The component SHALL use a Panel container as root node
The component SHALL have a PanelContainer as its root node to enable parent-controlled sizing and consistent visual boundaries.

#### Scenario: Root node structure
**Given** the result component scene is opened in the editor  
**When** inspecting the scene tree  
**Then** the root node is a PanelContainer

#### Scenario: Children resize with panel
**Given** a result component with resized panel dimensions  
**When** the panel size changes  
**Then** all child nodes scale proportionally to fill the panel

---

### Requirement: The component SHALL arrange nodes in horizontal layout
The component SHALL use an HBoxContainer inside the panel to arrange the category circle and question container horizontally.

#### Scenario: HBox layout structure
**Given** the result component scene structure  
**When** inspecting the PanelContainer children  
**Then** an HBoxContainer is the direct child of the panel

#### Scenario: HBox contains category and question container
**Given** the HBoxContainer in result component  
**When** inspecting its children  
**Then** it contains a TextureRect (category) and a VBoxContainer (questions)

---

### Requirement: The component SHALL display category icon as non-interactive circle
The component SHALL show the category icon in a TextureRect node that is circular and decorative only.

#### Scenario: Category circle node type
**Given** the result component scene structure  
**When** inspecting the category display node  
**Then** it is a TextureRect node

#### Scenario: Category texture can be set
**Given** a result component instance  
**When** `set_category_texture(texture: Texture2D)` is called  
**Then** the category TextureRect displays the provided texture

---

### Requirement: The component SHALL arrange question circles vertically
The component SHALL use a VBoxContainer to stack question circle buttons vertically.

#### Scenario: VBox for questions
**Given** the result component scene structure  
**When** inspecting the question container  
**Then** it is a VBoxContainer inside the HBoxContainer

#### Scenario: VBox contains question buttons
**Given** a result component with questions loaded  
**When** inspecting the VBoxContainer children  
**Then** it contains dynamically generated Button nodes

---

### Requirement: The component SHALL generate question circles dynamically
The component SHALL create question circle buttons at runtime based on configurable question count.

#### Scenario: Dynamic button creation
**Given** a result component with question_count = 3  
**When** `load_result_data()` is called  
**Then** exactly 3 Button nodes are created in the VBoxContainer

#### Scenario: Configurable question count
**Given** a result component in the editor  
**When** viewing inspector properties  
**Then** an exported `question_count` property is visible and editable

#### Scenario: Different question counts
**Given** a result component with question_count = 5  
**When** `load_result_data()` is called  
**Then** exactly 5 Button nodes are created in the VBoxContainer

---

### Requirement: The component SHALL store quiz screen references
The component SHALL maintain references to quiz_screen node instances from completed questions.

#### Scenario: Store quiz screens
**Given** a result component instance  
**When** `load_result_data(category_texture, quiz_screens: Array)` is called with 3 quiz_screen nodes  
**Then** the component internally stores all 3 quiz_screen references

#### Scenario: Access stored quiz screens
**Given** a result component with stored quiz screens  
**When** a question circle button at index 1 is clicked  
**Then** the component retrieves the quiz_screen at index 1

---

### Requirement: The component SHALL support texture assignment for question circles
The component SHALL allow textures to be set on question circle buttons.

#### Scenario: Set question textures individually
**Given** a result component with 3 question buttons  
**When** `set_question_texture(index: int, texture: Texture2D)` is called with index 1  
**Then** the button at index 1 displays the provided texture

#### Scenario: Load all question textures at once
**Given** a result component instance  
**When** `load_result_data(category_texture, quiz_screens, question_textures: Array)` is called  
**Then** each question button displays its corresponding texture from the array

---

### Requirement: The component SHALL emit signal when question circle is clicked
The component SHALL notify listeners when a question circle button is pressed.

#### Scenario: Question button clicked
**Given** a result component with 3 question buttons  
**When** the user clicks the button at index 2  
**Then** the component emits `question_clicked(index: int)` signal with value 2

---

### Requirement: The component SHALL display quiz screen in internal container when clicked
The component SHALL show the corresponding quiz_screen node when a question circle is clicked.

#### Scenario: Internal display container exists
**Given** the result component scene structure  
**When** inspecting the component nodes  
**Then** a Control or Panel node exists for displaying quiz screens

#### Scenario: Show quiz screen on click
**Given** a result component with quiz_screens loaded  
**When** question button at index 1 is clicked  
**Then** the quiz_screen at index 1 becomes visible in the internal container

#### Scenario: Quiz screen fills display area
**Given** a quiz_screen displayed in the result component  
**When** the internal container is visible  
**Then** the quiz_screen scales to fill the available display area

---

### Requirement: The component SHALL hide quiz screen display container initially
The component SHALL keep the quiz screen display container hidden by default.

#### Scenario: Container hidden on load
**Given** a result component just instantiated  
**When** the component is ready  
**Then** the internal quiz screen container is not visible

#### Scenario: Container visible when showing quiz
**Given** a result component with hidden quiz container  
**When** a question circle is clicked  
**Then** the internal container becomes visible

---

### Requirement: The component SHALL support closing displayed quiz screen
The component SHALL allow users to hide the displayed quiz screen and return to the result view.

#### Scenario: Close button or mechanism exists
**Given** a quiz screen displayed in the result component  
**When** the internal container is visible  
**Then** a close button or back mechanism is available

#### Scenario: Close quiz screen
**Given** a result component showing a quiz screen  
**When** the close mechanism is activated  
**Then** the internal container becomes hidden

#### Scenario: Emit close signal
**Given** a result component showing a quiz screen  
**When** the quiz screen is closed  
**Then** the component emits `quiz_review_closed()` signal

---

### Requirement: The component SHALL provide cleanup method for quiz screen references
The component SHALL offer a method to properly release quiz_screen node references.

#### Scenario: Clear references
**Given** a result component with stored quiz screens  
**When** `clear_data()` is called  
**Then** all quiz_screen references are cleared from internal storage

#### Scenario: Safe reuse after clear
**Given** a result component that has been cleared  
**When** `load_result_data()` is called with new data  
**Then** the component loads the new data without errors

---
