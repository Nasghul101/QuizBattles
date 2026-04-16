# gradient-label-component Specification

## Purpose
A reusable `Label`-derived UI component that overlays a two-stop gradient texture on its text, used as the category header on the quiz screen. Exposes an `set_accent_color()` method so callers can theme the gradient's first color stop at runtime without touching the second stop.

## Requirements

### Requirement: The component SHALL declare a named class for static typing
The `gradient_label.gd` script SHALL include `class_name GradientLabel` so other scripts can reference it with a typed annotation without requiring a preload path.

#### Scenario: Type annotation in a referencing script
**Given** `gradient_label.gd` declares `class_name GradientLabel`  
**When** another script declares `var label: GradientLabel`  
**Then** Godot's type system recognises the annotation without a preload  
**And** calling `label.set_accent_color(color)` is statically valid

---

### Requirement: The component SHALL expose a method to set its accent color
The `GradientLabel` component SHALL provide a `set_accent_color(color: Color)` method that updates the first color (index 0) of the gradient texture applied to the label, leaving all other gradient stops unchanged.

#### Scenario: Set accent color to a valid color
**Given** a `GradientLabel` instance with a two-stop gradient  
**When** `set_accent_color(Color("#00B8E8"))` is called  
**Then** `gradient.texture.gradient.colors[0]` equals `Color("#00B8E8")`  
**And** `gradient.texture.gradient.colors[1]` remains unchanged

#### Scenario: Set accent color to white (fallback)
**Given** a `GradientLabel` instance  
**When** `set_accent_color(Color.WHITE)` is called  
**Then** `gradient.texture.gradient.colors[0]` equals `Color(1, 1, 1, 1)`

#### Scenario: Graceful no-op when texture is missing
**Given** a `GradientLabel` instance whose gradient child lacks a `GradientTexture2D`  
**When** `set_accent_color(color)` is called  
**Then** a warning is pushed via `push_warning()`  
**And** no crash or error occurs

---
