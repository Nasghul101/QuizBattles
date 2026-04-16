# quiz-screen-component Specification Delta
# Change: add-category-color-theming

## ADDED Requirements

### Requirement: The component SHALL apply a category accent color when loading a question
When `load_question(data)` is called, the quiz screen SHALL resolve the accent color for the question's category from `Utils.get_color_codes()["category_colors"]` and apply it to the `GradientLabel` category header and all four `AnswerButton` components.

#### Scenario: Known category with defined color
**Given** `color_codes.json` defines `"Science": "#00B8E8"`  
**When** `load_question({"category": "Science", ...})` is called  
**Then** `category_label.set_accent_color(Color("#00B8E8"))` is called  
**And** `set_pulsating_color(Color("#00B8E8"))` is called on all four answer buttons

#### Scenario: Known category with null color
**Given** `color_codes.json` defines `"General Knowledge": null`  
**When** `load_question({"category": "General Knowledge", ...})` is called  
**Then** `category_label.set_accent_color(Color.WHITE)` is called  
**And** `set_pulsating_color(Color.WHITE)` is called on all four answer buttons

#### Scenario: Category key absent from question data
**Given** question data that has no `"category"` key  
**When** `load_question(data)` is called  
**Then** `set_accent_color(Color.WHITE)` and `set_pulsating_color(Color.WHITE)` are called (white fallback)

#### Scenario: Category name not present in color_codes.json
**Given** question data with `"category": "UnknownCategory"`  
**When** `load_question(data)` is called  
**Then** `set_accent_color(Color.WHITE)` and `set_pulsating_color(Color.WHITE)` are called (white fallback)

---

### Requirement: The component SHALL use GradientLabel typed reference for the category label
The `%CategoryLabel` onready reference SHALL be typed as `GradientLabel` (not plain `Label`) so `set_accent_color()` is callable with static typing.

#### Scenario: Static type annotation
**Given** `gradient_label.gd` declares `class_name GradientLabel`  
**When** `quiz_screen.gd` declares `@onready var category_label: GradientLabel = %CategoryLabel`  
**Then** no type error occurs at scene load  
**And** `category_label.set_accent_color(color)` is statically valid
