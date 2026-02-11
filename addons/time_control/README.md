# Godot Time Control Plugin

Lightweight, scene-friendly time scaling for Godot 4.5+. Define clocks, route them to timelines, and slow / speed parts of your game independently.

![Godot Time Control](./addons/time_control/icons/logo.png)

## Contents
- Features
- Compatibility
- Installation
- Quick Start
- Core Concepts
- Customization
- Demo

## Features
- Multiple named clocks with parent blending (world, player, enemy, environment by default).
- Drop-in `Timeline` node exposes a clock's effective `time_scale` to your scripts.
- Global `TimeController` autoload to fetch or edit clocks from anywhere.
- Works with 2D or 3D; deterministic blending (additive or multiplicative).

## Compatibility
Godot 4.2+.

## Installation
1) Download the latest release: https://github.com/zekostudio/godot-time-control/releases  
2) Copy `addons/time_control` into your project's `addons` folder.  
3) In the editor: **Project > Project Settings > Plugins** and enable **TimeControl**.

## Quick Start
1) **Use the provided autoload**
   - The plugin registers `res://addons/time_control/time_control.tscn` as an autoload named `TimeController`.
   - It contains four clocks: `WORLD` (root), `PLAYER`, `ENEMY`, `ENVIRONMENT` (children of `WORLD`).

2) **Add a Timeline to a scene**
   - Add a `Timeline` node.
   - Assign a `ClockConfiguration` resource to `clock_configuration` (for example `player_clock.tres` for the player).

3) **Consume the time scale in code**
   ```gdscript
   extends CharacterBody2D

   const Timeline = preload("res://addons/time_control/scripts/timeline.gd")
   const SPEED: float = 300.0

   @export var timeline: Timeline

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
   const ClockConfiguration = preload("res://addons/time_control/scripts/clock_configuration.gd")
   @export var clock_configuration: ClockConfiguration

   func _process(_delta: float) -> void:
       TimeController.get_clock(configuration).local_time_scale = 0.5
       # or by key
       # TimeController.get_clock_by_key("PLAYER").local_time_scale = 0.5
   ```

## Core Concepts
### ClockConfiguration (Resource)
Defines a clock and its key.

Property:
- `key: String` — Identifier used to fetch the clock.

### Clock (Node)
Computes an independent `time_scale`, optionally blended with a parent clock.

Properties:
- `configuration: ClockConfiguration` — Which clock this node represents.
- `local_time_scale: float` — Local multiplier applied before blending.
- `parent_configuration: ClockConfiguration` (optional) — Parent clock resource.
- `parent_blend_mode: BlendModeEnum` — `Multiplicative` (default) or `Additive`.

Method:
- `get_time_scale() -> float` — Returns the blended time scale.

### Timeline (Node)
Bridge node that exposes the effective time scale of a chosen clock.

Properties:
- `mode: ModeEnum` — `Global` (default) uses `clock_configuration`; `Local` uses `local_clock`.
- `time_scale: float` — The resolved time scale of the targeted clock.
- `local_clock: Clock` — Used when mode is `Local`.
- `clock_configuration: ClockConfiguration` — Used when mode is `Global`.

### TimeController (Singleton / Autoload)
Registry for all clocks; available globally.

Methods:
- `has_clock(configuration: ClockConfiguration) -> bool`
- `get_clock(configuration: ClockConfiguration) -> Clock`
- `get_clock_by_key(key: String) -> Clock`
- `add_clock(configuration: ClockConfiguration) -> Clock`
- `remove_clock(configuration: ClockConfiguration) -> void`

## Timeline-aware helper nodes
Drop these glue scripts next to existing nodes to keep their playback in sync with a `Timeline` without rewriting their logic.

- `timeline_aware_node/animation_player_timeline.gd` — Drives `AnimationPlayer.speed_scale` from a bound `Timeline`.
- `timeline_aware_node/gpu_particles_2d_timeline.gd` / `gpu_particles_3d_timeline.gd` — Drive particle `speed_scale` in 2D or 3D.
- `timeline_aware_node/area2D_timeline.gd` / `area3D_timeline.gd` — Apply `timescale_multiplier` to bodies entering an `Area2D` or `Area3D`.

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
1) Add a plain `Node` as a sibling or parent, attach `gpu_particles_2d_timeline.gd`.
2) Assign `gpu_particles_2d` to your particles node and `timeline` to the relevant `Timeline` (e.g., player or enemy).
3) Press play — particle playback automatically speeds up / slows down with the clock.

## Customization
**Swap the autoload scene**
1) Duplicate `res://addons/time_control/time_control.tscn` to another path.  
2) Edit the copy (add/remove global clocks, change hierarchy).  
3) In **Project > Project Settings > Addons > Time Control**, set `autoload_path` to your scene (e.g., `res://scenes/time_control.tscn`).  
4) Disable and re-enable the plugin (or restart the editor) to reload.

## Demo
Open `res://addons/time_control/demo/demo.tscn` for a runnable example showing multiple clocks.
