# Tasks: add-result-component

## Implementation Tasks

### 1. Create result_component scene structure
- Create new scene at `scenes/ui/components/result_component.tscn`
- Add PanelContainer as root node
- Add HBoxContainer as child of PanelContainer
- Add TextureRect (for category circle) as first child of HBoxContainer
- Add VBoxContainer as second child of HBoxContainer
- Configure container properties (expand, fill, sizing flags)
- Configure TextureRect to be circular or square (will hold circular texture)

**Validation**: Scene file exists and node structure matches requirement

---

### 2. Create result_component script with basic structure
- Create `scenes/ui/components/result_component.gd`
- Attach script to root PanelContainer
- Add class documentation comment
- Define exported property `@export var question_count: int = 3`
- Create node references (@onready variables) for category TextureRect, question VBoxContainer, and quiz display container
- Add signal definitions: `question_clicked(index: int)`, `quiz_review_closed()`
- Implement `_ready()` function with basic initialization

**Validation**: Script compiles without errors, exported properties visible in editor

---

### 3. Implement quiz screen display container
- Add Control or Panel node to scene for displaying quiz screens
- Position and size it appropriately (overlay or separate panel)
- Set initial visibility to hidden
- Add close Button to the container
- Connect close button pressed signal to close handler
- Implement `_show_quiz_screen(quiz_screen: Node)` method
- Implement `_hide_quiz_screen()` method
- Emit `quiz_review_closed()` signal when closed

**Validation**: Container exists, can be shown/hidden programmatically

---

### 4. Implement dynamic question button generation
- Create `_generate_question_buttons()` private method
- Clear any existing buttons in VBoxContainer
- Loop based on `question_count` and instantiate Button nodes
- Configure each button (size, expand flags)
- Add texture support to buttons (icon or custom texture property)
- Store button references in array or access via get_children()
- Connect each button's pressed signal to handler with index parameter

**Validation**: Changing question_count in editor creates correct number of buttons at runtime

---

### 5. Implement load_result_data method
- Create `load_result_data(category_texture: Texture2D, quiz_screens: Array, question_textures: Array = [])` method
- Validate input parameters (array sizes match question_count)
- Store quiz_screens array in member variable
- Set category texture on TextureRect
- Call `_generate_question_buttons()` if not already generated
- Apply textures to question buttons from question_textures array
- Add documentation comment explaining parameters

**Validation**: Method accepts data and displays category texture, creates buttons

---

### 6. Implement question button click handler
- Create `_on_question_button_pressed(index: int)` method
- Emit `question_clicked(index)` signal
- Retrieve quiz_screen from stored array at given index
- Reparent or add quiz_screen to display container
- Call `_show_quiz_screen(quiz_screen)`
- Handle error cases (invalid index, null quiz_screen)

**Validation**: Clicking question button displays corresponding quiz screen

---

### 7. Implement set_category_texture method
- Create public `set_category_texture(texture: Texture2D)` method
- Apply texture to category TextureRect node
- Add null check
- Add documentation comment

**Validation**: Method successfully updates category texture

---

### 8. Implement set_question_texture method
- Create public `set_question_texture(index: int, texture: Texture2D)` method
- Validate index is within bounds
- Get button at index from VBoxContainer children
- Apply texture to button (icon property or custom)
- Add null checks and error handling
- Add documentation comment

**Validation**: Method successfully updates individual question button textures

---

### 9. Implement clear_data method
- Create public `clear_data()` method
- Clear quiz_screens array
- Remove quiz_screen from display container if currently showing
- Hide display container
- Clear textures from all buttons
- Clear category texture
- Add documentation comment

**Validation**: Component can be cleared and reloaded with new data without errors

---

### 10. Create test scene for result_component
- Create `scenes/ui/result_component_test.tscn`
- Add result_component instance
- Create test script `scenes/ui/result_component_test.gd`
- Load sample category texture
- Create or mock 3 quiz_screen instances with test data
- Call `load_result_data()` in `_ready()`
- Add UI to test different question counts
- Test button clicks and quiz screen display

**Validation**: Test scene runs, displays component, buttons work, quiz screens appear

---

### 11. Add UID files for new scripts
- Ensure `.uid` files are generated for `result_component.gd`
- Ensure `.uid` files are generated for `result_component_test.gd`

**Validation**: UID files exist alongside script files

---

### 12. Verify layout and scaling behavior
- Test component with different panel sizes
- Verify children expand/fill properly
- Test with different question_counts (3, 5, 1)
- Test on mobile portrait resolution (if possible)
- Adjust container flags if needed for proper scaling

**Validation**: Component scales properly, maintains layout with different configurations

---

## Testing Tasks

### Manual Testing Checklist
- [ ] Component instantiates without errors
- [ ] Category texture displays correctly
- [ ] Question buttons generate dynamically based on count
- [ ] Question button textures display correctly
- [ ] Clicking question button shows quiz screen
- [ ] Quiz screen display fills container properly
- [ ] Close button hides quiz screen
- [ ] Signals emit at correct times
- [ ] clear_data() properly resets component
- [ ] Component works with different question_counts
- [ ] Layout scales with panel resizing

---

## Dependencies
- Task 1 must complete before Task 2
- Task 3 can be done in parallel with Task 2
- Tasks 4-9 depend on Task 2 completion
- Task 10 depends on Tasks 1-9 completion
- Task 11 can be done after file creation
- Task 12 should be done after Task 10

---

## Notes
- Follow GDScript style guide for all code
- Use static typing throughout
- Add documentation comments (##) for all public methods
- Keep component simple and reusable like answer_button component
- Question button styling (circular shape, borders) can be refined later via themes or custom drawing
