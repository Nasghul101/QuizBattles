# Specification: Setup Screen Logic

**Capability ID:** `setup-screen-logic`  
**Type:** Component  
**Status:** Draft

## Purpose

Provides interactive configuration interface for players to customize game settings (rounds and questions) before starting gameplay, with real-time UI feedback and scene transition triggering.

---

## ADDED Requirements

### Requirement: Setup screen MUST synchronize slider values with amount labels
The setup screen SHALL synchronize slider values with their corresponding amount labels in real-time so players can see their current selections.

#### Scenario: Player adjusts rounds slider
**Given** the setup screen is displayed  
**And** the rounds slider is at value 3  
**When** the player drags the slider to value 5  
**Then** the rounds amount label must immediately display "5"

#### Scenario: Player adjusts questions slider
**Given** the setup screen is displayed  
**And** the questions slider is at value 2  
**When** the player drags the slider to value 4  
**Then** the questions amount label must immediately display "4"

---

### Requirement: Setup screen MUST initialize with default configuration values
The setup screen SHALL initialize with sensible default values when loaded.

#### Scenario: Setup screen loads for the first time
**Given** no previous game configuration exists  
**When** the setup screen loads  
**Then** the rounds slider must be set to 5  
**And** the rounds amount label must display "5"  
**And** the questions slider must be set to 3  
**And** the questions amount label must display "3"

---

### Requirement: Sliders MUST only allow integer values
The sliders SHALL only allow integer values to ensure whole numbers for rounds and questions.

#### Scenario: Player moves slider between integer positions
**Given** the setup screen is displayed  
**When** the player drags a slider to a position between integers  
**Then** the slider must snap to the nearest integer value  
**And** the amount label must display only integer values

---

### Requirement: Start game button MUST trigger scene transition with configured values
The start game button SHALL trigger scene transition with configured values when pressed.

#### Scenario: Player starts game with custom settings
**Given** the setup screen is displayed  
**And** the rounds slider is set to 6  
**And** the questions slider is set to 4  
**When** the player presses the "Start Game" button  
**Then** the scene transition must be initiated with fade effect  
**And** the gameplay screen must receive rounds=6 and questions=4

#### Scenario: Player starts game with default settings
**Given** the setup screen is displayed  
**And** the sliders are at default values (5 rounds, 3 questions)  
**When** the player presses the "Start Game" button  
**Then** the scene transition must be initiated with fade effect  
**And** the gameplay screen must receive rounds=5 and questions=3

---

### Requirement: Setup screen script MUST correctly reference nodes from scene tree
The setup screen script SHALL correctly reference nodes from the scene tree for proper functionality.

#### Scenario: Script accesses slider nodes
**Given** the setup screen script is attached to setup_screen.tscn  
**When** the script initializes  
**Then** it must successfully reference both HSlider nodes  
**And** it must successfully reference both Amount label nodes  
**And** it must successfully reference the StartGameButton node

---

### Requirement: Setup screen MUST connect to node signals for event-driven updates
The setup screen SHALL connect to node signals for event-driven updates.

#### Scenario: Slider value changes trigger updates
**Given** the setup screen has initialized  
**When** a slider value changes  
**Then** the corresponding amount label must update via signal connection  
**And** no manual polling or timer-based updates are used

#### Scenario: Button press triggers transition
**Given** the setup screen has initialized  
**When** the start button is pressed  
**Then** the button pressed signal must trigger the scene transition logic

---

## Dependencies

- `scene-transition-manager` - For fade transition functionality
- `gameplay-screen-initialization` - For receiving configuration values
- Node structure in `setup_screen.tscn`:
  - `VBoxContainer/MarginContainer/HBoxContainer/HSlider` (rounds)
  - `VBoxContainer/MarginContainer/HBoxContainer/Amount` (rounds label)
  - `VBoxContainer/MarginContainer2/HBoxContainer/HSlider` (questions)
  - `VBoxContainer/MarginContainer2/HBoxContainer/Amount` (questions label)
  - `VBoxContainer/StartGameButton` (start button)

---

## Technical Notes

- Uses GDScript static typing for performance
- Follows Godot signal-based event handling patterns
- Node paths must match exact hierarchy in .tscn file
- Slider min/max values configured via inspector (not hardcoded)
- Script file: `scenes/ui/setup_screen.gd`
