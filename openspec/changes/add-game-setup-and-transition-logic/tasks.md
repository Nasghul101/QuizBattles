# Implementation Tasks

**Change ID:** `add-game-setup-and-transition-logic`  
**Order:** Sequential (dependencies between tasks)

---

## Tasks

### 1. Create TransitionManager autoload
- [ ] Create `autoload/transition_manager.gd` file
- [ ] Extend Node class
- [ ] Add CanvasLayer with ColorRect overlay (black, full viewport size)
- [ ] Set CanvasLayer layer to 100 (ensures overlay on top)
- [ ] Initialize ColorRect modulate alpha to 0 (transparent initially)
- [ ] Implement `change_scene(scene_path: String, params: Dictionary = {})` method
- [ ] Use Tween for fade-out animation (0.5s, alpha 0→1)
- [ ] Free current scene after fade-out completes
- [ ] Load and instantiate new scene
- [ ] Call `initialize()` on new scene if params dictionary is not empty
- [ ] Add new scene to tree
- [ ] Use Tween for fade-in animation (0.5s, alpha 1→0)
- [ ] Add static typing to all variables and parameters
- [ ] Add documentation comments (`##`) for class and method
- [ ] **Validation:** Test by calling `TransitionManager.change_scene()` from script

### 2. Register TransitionManager in project settings
- [ ] Open `project.godot` file
- [ ] Add TransitionManager to autoload section:
  ```
  [autoload]
  TransitionManager="*res://autoload/transition_manager.gd"
  ```
- [ ] Save file
- [ ] **Validation:** Verify TransitionManager is accessible in editor autoload list

### 3. Create setup_screen.gd script
- [ ] Create `scenes/ui/setup_screen.gd` file
- [ ] Extend Control (or appropriate base class matching .tscn root)
- [ ] Add `@onready` references to nodes:
  - `rounds_slider: HSlider` → `$VBoxContainer/MarginContainer/HBoxContainer/HSlider`
  - `rounds_amount: Label` → `$VBoxContainer/MarginContainer/HBoxContainer/Amount`
  - `questions_slider: HSlider` → `$VBoxContainer/MarginContainer2/HBoxContainer/HSlider`
  - `questions_amount: Label` → `$VBoxContainer/MarginContainer2/HBoxContainer/Amount`
  - `start_button: Button` → `$VBoxContainer/StartGameButton`
- [ ] Implement `_ready()` method:
  - Set slider default values (rounds=5, questions=3)
  - Set slider step to 1.0 (integer-only values)
  - Update amount labels to show defaults
  - Connect slider `value_changed` signals to update methods
  - Connect button `pressed` signal to start game method
- [ ] Implement `_on_rounds_slider_changed(value: float) -> void`:
  - Update rounds_amount label text to `str(int(value))`
- [ ] Implement `_on_questions_slider_changed(value: float) -> void`:
  - Update questions_amount label text to `str(int(value))`
- [ ] Implement `_on_start_button_pressed() -> void`:
  - Get current slider values as integers
  - Create params dictionary: `{"rounds": rounds_value, "questions": questions_value}`
  - Call `TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)`
- [ ] Add static typing throughout
- [ ] Add documentation comments for class and methods
- [ ] **Validation:** Verify node paths match exact hierarchy in setup_screen.tscn

### 4. Attach setup_screen.gd to setup_screen.tscn
- [ ] Open `scenes/ui/setup_screen.tscn` in Godot editor
- [ ] Select root node
- [ ] Attach `scenes/ui/setup_screen.gd` script to root node
- [ ] Save scene
- [ ] **Validation:** Script icon appears on root node in scene tree

### 5. Create gameplay_screen.gd script
- [ ] Create `scenes/ui/gameplay_screen.gd` file
- [ ] Extend Control (or appropriate base class matching .tscn root)
- [ ] Add properties with static typing:
  - `var num_rounds: int = 0`
  - `var num_questions: int = 0`
- [ ] Implement `initialize(rounds: int, questions: int) -> void`:
  - Store rounds in num_rounds
  - Store questions in num_questions
  - (Optional) Print values for debugging: `print("Game initialized: %d rounds, %d questions" % [rounds, questions])`
- [ ] Implement `_ready()` method (can be empty or print debug info)
- [ ] Add documentation comments for class and methods
- [ ] **Validation:** Verify parameter types are enforced

### 6. Attach gameplay_screen.gd to gameplay_screen.tscn
- [ ] Open `scenes/ui/gameplay_screen.tscn` in Godot editor
- [ ] Select root node
- [ ] Attach `scenes/ui/gameplay_screen.gd` script to root node
- [ ] Save scene
- [ ] **Validation:** Script icon appears on root node in scene tree

### 7. End-to-end integration testing
- [ ] Run game from setup_screen.tscn (set as main scene if needed)
- [ ] Verify default values appear in amount labels (5 and 3)
- [ ] Drag sliders and verify labels update in real-time
- [ ] Click "Start Game" button
- [ ] Verify smooth fade transition occurs (black overlay, ~1s total)
- [ ] Verify gameplay_screen.tscn loads successfully
- [ ] Check console output for initialization debug message (if added)
- [ ] Test with different slider combinations
- [ ] **Validation:** Complete user flow works without errors

### 8. Code review and cleanup
- [ ] Review all scripts for GDScript style guide compliance
- [ ] Ensure all functions have documentation comments (`##`)
- [ ] Verify static typing is used consistently
- [ ] Remove debug print statements if not needed
- [ ] Check for any hardcoded values that should be configurable
- [ ] **Validation:** Code passes internal review checklist

---

## Notes

- Tasks must be completed in order due to dependencies
- Node paths in task 3 must exactly match the scene structure
- Slider min/max values are configured via inspector - not hardcoded
- Debug print statements in task 5 can be kept or removed based on preference
- Main scene in project.godot should point to setup_screen.tscn for testing
