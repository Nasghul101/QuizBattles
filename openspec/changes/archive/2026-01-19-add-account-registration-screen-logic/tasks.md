# Tasks: Add Account Registration Screen Logic

## Implementation Tasks

### 1. Create account_registration_screen.gd script
- [x] **Description**: Create the main controller script and attach it to the scene root node.

**Validation**: Script exists and is attached to `account_registration_screen.tscn`

**Dependencies**: None

---

### 2. Implement node references and initialization
- [x] **Description**: Add `@onready` references for all UI nodes (4 TextEdits and 2 Buttons) and initialize button state.

**Validation**: 
- All nodes are properly referenced
- CreateAccountButton starts disabled
- Scene loads without errors

**Dependencies**: Task 1

---

### 3. Implement field content monitoring
- [x] **Description**: Connect `text_changed` signals from all 4 TextEdit nodes to update CreateAccountButton enabled state.

**Validation**:
- Button is disabled when any field is empty
- Button becomes enabled when all 4 fields have content
- Button state updates in real-time as user types

**Dependencies**: Task 2

---

### 4. Implement Create Account button press handler
- [x] **Description**: Connect `pressed` signal and implement validation logic:
- Check password match
- Validate email format
- Check username uniqueness via UserDatabase
- Log appropriate console messages

**Validation**:
- Password mismatch prevents account creation and logs error
- Invalid email format prevents account creation and logs error
- Duplicate username prevents account creation and logs error
- Valid inputs create account and log success with user data

**Dependencies**: Task 3

---

### 5. Implement username field monitoring for duplicate error recovery
- [x] **Description**: After duplicate username error, monitor NameInput for changes to re-enable button.

**Validation**:
- After duplicate username error, button is disabled
- Editing NameInput re-enables button (if all fields still have content)
- Can attempt registration again with modified username

**Dependencies**: Task 4

---

### 6. Manual testing and polish
- [x] **Description**: Test all validation paths and edge cases:
- Empty fields
- Password mismatch
- Invalid email formats
- Duplicate username
- Successful registration
- Error recovery flows

**Validation**:
- All scenarios work as specified
- Console output is clear and correct
- No runtime errors

**Dependencies**: Task 5

---

## Notes
- All error handling uses console output only (`print()` or `push_error()`)
- BackButton intentionally left unimplemented per requirements
- No visual feedback beyond button enabled/disabled state
- All validation leverages existing UserDatabase methods
