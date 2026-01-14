# Implementation Tasks

**Change ID:** `add-game-setup-and-transition-logic`  
**Order:** Sequential (dependencies between tasks)

---

## Tasks

### 1. Create TransitionManager autoload
- [x] Create `autoload/transition_manager.gd` file
- [x] Extend Node class
- [x] Add CanvasLayer with ColorRect overlay (black, full viewport size)
- [x] Set CanvasLayer layer to 100 (ensures overlay on top)
- [x] Initialize ColorRect modulate alpha to 0 (transparent initially)
- [x] Implement `change_scene(scene_path: String, params: Dictionary = {})` method
- [x] Use Tween for fade-out animation (0.5s, alpha 0→1)
- [x] Free current scene after fade-out completes
- [x] Load and instantiate new scene
- [x] Call `initialize()` on new scene if params dictionary is not empty
- [x] Add new scene to tree
- [x] Use Tween for fade-in animation (0.5s, alpha 1→0)
- [x] Add static typing to all variables and parameters
- [x] Add documentation comments (`##`) for class and method
- [x] **Validation:** Test by calling `TransitionManager.change_scene()` from script

### 2. Register TransitionManager in project settings
- [x] Open `project.godot` file
- [x] Add TransitionManager to autoload section:
  ```
  [autoload]
  TransitionManager="*res://autoload/transition_manager.gd"
  ```
- [x] Save file
- [x] **Validation:** Verify TransitionManager is accessible in editor autoload list

### 3. Create setup_screen.gd script
- [x] Create `scenes/ui/setup_screen.gd` file
- [x] Extend Control (or appropriate base class matching .tscn root)
- [x] Add `@onready` references to nodes:
  - `rounds_slider: HSlider` → `$VBoxContainer/MarginContainer/HBoxContainer/HSlider`
  - `rounds_amount: Label` → `$VBoxContainer/MarginContainer/HBoxContainer/Amount`
  - `questions_slider: HSlider` → `$VBoxContainer/MarginContainer2/HBoxContainer/HSlider`
  - `questions_amount: Label` → `$VBoxContainer/MarginContainer2/HBoxContainer/Amount`
  - `start_button: Button` → `$VBoxContainer/StartGameButton`
- [x] Implement `_ready()` method:
  - Set slider default values (rounds=5, questions=3)
  - Set slider step to 1.0 (integer-only values)
  - Update amount labels to show defaults
  - Connect slider `value_changed` signals to update methods
  - Connect button `pressed` signal to start game method
- [x] Implement `_on_rounds_slider_changed(value: float) -> void`:
  - Update rounds_amount label text to `str(int(value))`
- [x] Implement `_on_questions_slider_changed(value: float) -> void`:
  - Update questions_amount label text to `str(int(value))`
- [x] Implement `_on_start_button_pressed() -> void`:
  - Get current slider values as integers
  - Create params dictionary: `{"rounds": rounds_value, "questions": questions_value}`
  - Call `TransitionManager.change_scene("res://scenes/ui/gameplay_screen.tscn", params)`
- [x] Add static typing throughout
- [x] Add documentation comments for class and methods
- [x] **Validation:** Verify node paths match exact hierarchy in setup_screen.tscn

### 4. Attach setup_screen.gd to setup_screen.tscn
- [x] Open `scenes/ui/setup_screen.tscn` in Godot editor
- [x] Select root node
- [x] Attach `scenes/ui/setup_screen.gd` script to root node
- [x] Save scene
- [x] **Validation:** Script icon appears on root node in scene tree

### 5. Create gameplay_screen.gd script
- [x] Create `scenes/ui/gameplay_screen.gd` file
- [x] Extend Control (or appropriate base class matching .tscn root)
- [x] Add properties with static typing:
  - `var num_rounds: int = 0`
  - `var num_questions: int = 0`
- [x] Implement `initialize(rounds: int, questions: int) -> void`:
  - Store rounds in num_rounds
  - Store questions in num_questions
  - (Optional) Print values for debugging: `print("Game initialized: %d rounds, %d questions" % [rounds, questions])`
- [x] Implement `_ready()` method (can be empty or print debug info)
- [x] Add documentation comments for class and methods
- [x] **Validation:** Verify parameter types are enforced

### 6. Attach gameplay_screen.gd to gameplay_screen.tscn
- [x] Open `scenes/ui/gameplay_screen.tscn` in Godot editor
- [x] Select root node
- [x] Attach `scenes/ui/gameplay_screen.gd` script to root node
- [x] Save scene
- [x] **Validation:** Script icon appears on root node in scene tree

### 7. End-to-end integration testing
- [x] Run game from setup_screen.tscn (set as main scene if needed)
- [x] Verify default values appear in amount labels (5 and 3)
- [x] Drag sliders and verify labels update in real-time
- [x] Click "Start Game" button
- [x] Verify smooth fade transition occurs (black overlay, ~1s total)
- [x] Verify gameplay_screen.tscn loads successfully
- [x] Check console output for initialization debug message (if added)
- [x] Test with different slider combinations
- [x] **Validation:** Complete user flow works without errors

### 8. Code review and cleanup
- [x] Review all scripts for GDScript style guide compliance
- [x] Ensure all functions have documentation comments (`##`)
- [x] Verify static typing is used consistently
- [x] Remove debug print statements if not needed
- [x] Check for any hardcoded values that should be configurable
- [x] **Validation:** Code passes internal review checklist

---

## Notes

- Tasks must be completed in order due to dependencies
- Node paths in task 3 must exactly match the scene structure
- Slider min/max values are configured via inspector - not hardcoded
- Debug print statements in task 5 can be kept or removed based on preference
- Main scene in project.godot should point to setup_screen.tscn for testing
