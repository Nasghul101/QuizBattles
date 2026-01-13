# Tasks: add-result-component

## Implementation Tasks

### 1. Create result_component.gd script
- [ ] Create `scenes/ui/components/result_component.gd`
- [ ] Define data structure for question results (question_data, was_correct, player_answer)
- [ ] Define signal `question_review_requested(question_index: int, question_data: Dictionary)`
- [ ] Implement `load_result_data(category_texture: Texture2D, results: Array)` method
- [ ] Store category texture and question results internally
- [ ] Validate that results array contains exactly 3 entries
- [ ] Add documentation comments

**Validation**: Script compiles without errors, follows GDScript style guide

### 2. Update result_component.tscn scene
- [ ] Add script reference to result_component.gd
- [ ] Verify CategorySymbol (TextureRect) node exists
- [ ] Verify HBoxContainer with 3 answer indicator buttons exists
- [ ] Get node references in script using @onready
- [ ] Ensure buttons have appropriate minimum sizes

**Validation**: Scene loads in editor, all nodes are accessible

### 3. Implement button icon display logic
- [ ] Create method `_update_button_icons()` to set button icons based on correctness
- [ ] Load icon_right.png from `res://assets/icon_right.png`
- [ ] Load icon_wrong.png from `res://assets/icon_wrong.png`
- [ ] Set button icons based on was_correct field in results data
- [ ] Call icon update when `load_result_data()` is invoked

**Validation**: Buttons display correct icons for correct/incorrect answers

### 4. Implement button click handling
- [ ] Connect all 3 button pressed signals to handler method
- [ ] Create `_on_answer_button_pressed(button_index: int)` handler
- [ ] Emit `question_review_requested` signal with question index and stored data
- [ ] Ensure signal includes all necessary data for popup display

**Validation**: Clicking buttons emits correct signals with proper data

### 5. Manual testing
- [ ] Create test scene that instantiates result component
- [ ] Test with all-correct scenario (3 correct answers)
- [ ] Test with all-incorrect scenario (3 incorrect answers)
- [ ] Test with mixed scenario (1-2 correct, rest incorrect)
- [ ] Verify button signals contain correct question data
- [ ] Test with different category textures

**Validation**: Component behaves correctly in all scenarios

## Validation Checklist
- [ ] Script follows GDScript style guide conventions
- [ ] Documentation comments follow Godot conventions (## for docs, # for inline)
- [ ] All public methods have documentation
- [ ] Scene structure matches component requirements
- [ ] Icons display correctly for all answer states
- [ ] Signals emit with complete question data
- [ ] No errors in Godot console when using component

## Dependencies
- Sequential: Tasks 1-2 must complete before task 3
- Sequential: Task 3 must complete before task 4
- Sequential: Tasks 1-4 must complete before task 5
