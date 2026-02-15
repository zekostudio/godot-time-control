# Godot Timeflow Plugin

Lightweight, scene-friendly time scaling for Godot 4.5+. Define clocks, route them to timelines, and slow / speed parts of your game independently.

![Godot Timeflow](./addons/timeflow/icons/logo.png)

## Contents
- Features
- Compatibility
- Installation
- Quick Start
- Core Concepts
- Tween Integration
- Customization
- Demo

## Features
- Multiple named clocks with parent blending (world, player, enemy, environment by default).
- Drop-in `TimeflowTimeline` node exposes a clock's effective `time_scale` to your scripts.
- Global `Timeflow` autoload to fetch or edit clocks from anywhere.
- Works with 2D or 3D; deterministic blending (additive or multiplicative).

## Compatibility
Godot 4.2+.

## Installation
1) Download the latest release: https://github.com/zekostudio/godot-timeflow/releases  
2) Copy `addons/timeflow` into your project's `addons` folder.  
3) In the editor: **Project > Project Settings > Plugins** and enable **Timeflow**.

## Quick Start
1) **Use the provided autoload**
   - The plugin registers `res://addons/timeflow/timeflow.tscn` as an autoload named `Timeflow`.
   - It contains four clocks: `WORLD` (root), `PLAYER`, `ENEMY`, `ENVIRONMENT` (children of `WORLD`).

2) **Add a TimeflowTimeline to a scene**
   - Add a `TimeflowTimeline` node.
   - Assign a `TimeflowClockConfig` resource to `clock_configuration` (for example `player_clock.tres` for the player).

3) **Consume the time scale in code**
   ```gdscript
   extends CharacterBody2D

   const TimeflowTimeline = preload("res://addons/timeflow/scripts/timeflow_timeline.gd")
   const SPEED: float = 300.0

   @export var timeline: TimeflowTimeline

   func _physics_process(delta: float) -> void:
       var input: Vector2 = Vector2(
           Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
           Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
       )
       velocity = input.normalized() * SPEED * timeline.time_scale
       move_and_slide()
   ```

4) **Change time from anywhere**
   ```gdscript
   const TimeflowClockConfig = preload("res://addons/timeflow/scripts/timeflow_clock_config.gd")
   @export var clock_configuration: TimeflowClockConfig

   func _process(_delta: float) -> void:
       Timeflow.get_clock(clock_configuration).local_time_scale = 0.5
       # or by key
       # Timeflow.get_clock_by_key("PLAYER").local_time_scale = 0.5
   ```

## Core Concepts
### TimeflowClockConfig (Resource)
Defines a clock identity, defaults, and parent relationship.

Properties:
- `key: String` — Identifier used to fetch the clock.
- `default_local_time_scale: float` — Default local scale applied at clock initialization.
- `default_paused: bool` — Default paused state.
- `parent_key: String` — Optional parent clock key (`""` means no parent).
- `parent_blend_mode: TimeflowBlendMode` — `MULTIPLICATIVE` (default) or `ADDITIVE`.
- `min_time_scale: float` / `max_time_scale: float` — Clamp range for runtime local scale changes.

### TimeflowClock (Node)
Computes an independent `time_scale`, optionally blended with a parent clock.

Properties:
- `configuration: TimeflowClockConfig` — Which clock this node represents.
- `local_time_scale: float` — Runtime local multiplier (initialized from config).
- `paused: bool` — Runtime paused state (initialized from config).
- `parent_blend_mode: TimeflowBlendMode` — Runtime blend mode (initialized from config).
- Runtime behavior: changing `local_time_scale` affects this clock and all clocks that depend on it through the parent hierarchy.

Method:
- `get_time_scale() -> float` — Returns the blended time scale.

### TimeflowTimeline (Node)
Bridge node that exposes the effective time scale of a chosen clock.

Properties:
- `mode: TimeflowTimelineMode` — `GLOBAL` (default) uses `clock_configuration`; `LOCAL` uses `local_clock`.
- `time_scale: float` — The resolved time scale of the targeted clock.
- `local_clock: TimeflowClock` — Used when mode is `LOCAL`.
- `clock_configuration: TimeflowClockConfig` — Used when mode is `GLOBAL`.

### Timeflow (Singleton / Autoload)
Registry for all clocks; available globally.

Methods:
- `has_clock(configuration: TimeflowClockConfig) -> bool`
- `get_clock(configuration: TimeflowClockConfig) -> TimeflowClock`
- `get_clock_by_key(key: String) -> TimeflowClock`
- `add_clock(configuration: TimeflowClockConfig) -> TimeflowClock`
- `remove_clock(configuration: TimeflowClockConfig) -> void`

## TimeflowTimeline-aware helper nodes
Drop these glue scripts next to existing nodes to keep their playback in sync with a `TimeflowTimeline` without rewriting their logic.

- `helpers/timeflow_animation_player_sync.gd` — Drives `AnimationPlayer.speed_scale` from a bound `TimeflowTimeline`.
- `helpers/timeflow_gpu_particles_2d_sync.gd` / `timeflow_gpu_particles_3d_sync.gd` — Drive particle `speed_scale` in 2D or 3D.
- `helpers/timeflow_area_2d.gd` / `timeflow_area_3d.gd` — Apply `timescale_multiplier` to bodies entering an `Area2D` or `Area3D`.

Area timeline integration fallback order (first match wins):
1) Method: `set_area_timescale_multiplier(multiplier: float)`
2) Property: `area_timescale_multiplier: float`

Minimal body integration (recommended):
```gdscript
var area_timescale_multiplier: float = 1.0

func _physics_process(_delta: float) -> void:
	velocity = input_dir * speed * timeline.time_scale * area_timescale_multiplier
	move_and_slide()
```

Usage pattern (example for 2D particles):
1) Add a plain `Node` as a sibling or parent, attach `timeflow_gpu_particles_2d_sync.gd`.
2) Assign `gpu_particles_2d` to your particles node and `timeline` to the relevant `TimeflowTimeline` (e.g., player or enemy).
3) Press play — particle playback automatically speeds up / slows down with the clock.
4) For rewind setups, keep `use_absolute_time_scale = true` (default) so particles simulate forward while rewind helpers invert emission direction.

## Rewind
This plugin includes a rewind recorder based on timeline direction:

- `scripts/rewind/timeflow_recorder.gd` (`TimeflowRecorder`) — records snapshots and applies them while time is reversed.
- `scripts/rewind/timeflow_rewindable.gd` (`TimeflowRewindable`) — base rewind contract for all rewindable adapters.
- `helpers/timeflow_rewindable_2d.gd` (`TimeflowRewindable2D`) — captures/restores a `Node2D` transform.
- `helpers/timeflow_rewindable_path_follow_2d.gd` (`TimeflowRewindablePathFollow2D`) — captures/restores `PathFollow2D.progress`.
- `helpers/timeflow_rewindable_gpu_particles_2d.gd` / `timeflow_rewindable_gpu_particles_3d.gd` — invert GPU particle initial velocity while rewinding.

Quick setup:
1) Add a rewindable adapter node (`TimeflowRewindable2D` or `TimeflowRewindablePathFollow2D`) and assign its target.
2) Add `TimeflowRecorder` to the same scene and assign:
   - `timeline` to your `TimeflowTimeline`
   - `rewindables` to one or more `TimeflowRewindable` nodes
3) Set the clock scale negative (for example `Timeflow.get_clock_by_key("PLAYER").local_time_scale = -1.0`) to rewind.
4) Return the clock to positive to resume forward simulation and recording.

Recorder tuning:
- `recording_duration` controls max rewind window (seconds).
- `recording_interval` controls snapshot frequency (higher frequency = smoother rewind, more memory).
- `record_when_paused` controls whether snapshots are captured while `time_scale == 0`.
- `TimeflowRewindable2D.disable_target_processing_while_rewinding` prevents gameplay scripts on that node from fighting restored rewind states.
- `TimeflowRewindableGPUParticles2D` / `TimeflowRewindableGPUParticles3D` require a `ParticleProcessMaterial` and can optionally duplicate it per-node before rewinding.
- When rewind stops (or reaches the recorded history limit), `TimeflowRecorder` clears history and starts recording from the current state again.
- `TimeflowRewindablePathFollow2D.snap_on_discontinuity` and `discontinuity_ratio` reduce jitter from large progress jumps (for example loop/reset boundaries).

## Tween Integration
Use this pattern to keep a Godot `Tween` synchronized with a `TimeflowTimeline`.

```gdscript
extends Node2D

const TimeflowTimeline = preload("res://addons/timeflow/scripts/timeflow_timeline.gd")

@export var timeline: TimeflowTimeline
@export var mover: Node2D
@export var duration: float = 1.5

var _tween: Tween

func _ready() -> void:
    _tween = get_tree().create_tween()
    _tween.set_loops()
    _tween.tween_property(mover, "position:x", 500.0, duration)
    _tween.tween_property(mover, "position:x", 100.0, duration)

func _process(_delta: float) -> void:
    if _tween != null:
        _tween.set_speed_scale(timeline.time_scale)
```

## Customization
**Swap the autoload scene**
1) Duplicate `res://addons/timeflow/timeflow.tscn` to another path.  
2) Edit the copy (add/remove global clocks, change hierarchy).  
3) In **Project > Project Settings > Addons > Timeflow**, set `autoload_path` to your scene (e.g., `res://scenes/timeflow.tscn`).  
4) Disable and re-enable the plugin (or restart the editor) to reload.

## Demo
Open `res://addons/timeflow/demo/demo.tscn` for a runnable example showing multiple clocks.
The scene includes an automatic showcase loop that demonstrates slow motion, acceleration, and rewind on different timelines.
It also includes preset buttons in the HUD to trigger each demo mode on demand.
