# Trailing Progress Bar Shader Setup

This guide explains how to apply the trailing fade shader to any ProgressBar in the project.

## Shader Asset

- Shader path: `res://shaders/trailing_progress_bar.gdshader`
- Primary target: `TimeLimitBar` in `res://scenes/ui/quiz_screen.tscn`

## Step-by-Step Setup

1. Select the target `ProgressBar` node in the Godot editor.
2. In the Inspector, set `material` to a new `ShaderMaterial`.
3. Assign `res://shaders/trailing_progress_bar.gdshader` to the material's `shader` property.
4. Set the default uniforms:
   - `progress = 1.0`
   - `previous_progress = 1.0`
   - `fade_strength = 0.5`
   - `fade_softness = 0.5`
   - `softness = 0.5`
   - `glow_intensity = 0.3`
   - `trail_fade_duration = 0.5`
   - `last_change_time = 0.0`
5. Update `progress`, `previous_progress`, and `last_change_time` from script when the bar value changes.

## Uniform Reference

| Uniform | Range | Effect |
|---|---|---|
| `progress` | `0.0-1.0` | Current normalized fill amount |
| `previous_progress` | `0.0-1.0` | Previous normalized fill amount |
| `fade_strength` | `0.0-1.0` | Overall intensity of the trail treatment |
| `fade_softness` | `0.1-1.0` | Softness of trail boundaries |
| `softness` | `0.1-1.0` | Falloff softness near the receding edge |
| `glow_intensity` | `0.0-1.0` | Adds subtle highlight to the trail region |
| `trail_fade_duration` | `0.2-2.0` | Time in seconds for complete fade-out |
| `last_change_time` | `>= 0.0` | Timestamp used for time-based decay |

## Recommended Presets

### Health Bar (responsive and readable)
- `fade_strength = 0.7`
- `fade_softness = 0.45`
- `softness = 0.4`
- `glow_intensity = 0.25`
- `trail_fade_duration = 0.45`

### Mana Bar (soft and fluid)
- `fade_strength = 0.5`
- `fade_softness = 0.65`
- `softness = 0.7`
- `glow_intensity = 0.35`
- `trail_fade_duration = 0.7`

### Cooldown Bar (snappy feedback)
- `fade_strength = 0.6`
- `fade_softness = 0.35`
- `softness = 0.3`
- `glow_intensity = 0.2`
- `trail_fade_duration = 0.3`

## Troubleshooting

- No visible trail:
  - Ensure `previous_progress > progress` when values decrease.
  - Ensure `last_change_time` is updated to current `TIME` when progress changes.
  - Increase `fade_strength` and `glow_intensity` temporarily to verify effect.

- Trail never disappears:
  - Verify `trail_fade_duration` is non-zero.
  - Verify `last_change_time` is not continuously reset every frame.

- Effect looks too hard or aliased:
  - Increase `fade_softness` and `softness`.

## Script Update Example

```gdscript
var max_value_safe := max(time_limit_bar.max_value, 0.0001)
var current_norm := clamp(time_limit_bar.value / max_value_safe, 0.0, 1.0)
var previous_norm := clamp(previous_value / max_value_safe, 0.0, 1.0)

material.set_shader_parameter("previous_progress", previous_norm)
material.set_shader_parameter("progress", current_norm)
material.set_shader_parameter("last_change_time", Time.get_ticks_msec() / 1000.0)
```

Note: The example above uses engine time in seconds. Use a consistent time source for all updates.
