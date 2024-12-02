# Godot Time Control Plugin

![Godot Time Control](./addons/time_control/icons/logo.png)

> Easy to use time control for godot.<br>
Define multiple clocks to use different time scales on your nodes.

This plugin heavily inspired by *[CyberSys/ChronosTimeControl](https://github.com/CyberSys/ChronosTimeControl)* Unity asset.

## Compatibility

Godot 4.2+

# Documentation
1. [Installation](#installation)
2. [Basic setup](#basic-setup)
3. [Resources](#resources)
4. [Nodes](#nodes)
5. [Customization](#customization)
5. [Examples](#examples)

## Installation

1. Download the latest [release](https://github.com/zekostudio/godot-time-control/releases).
2. Extract the `addons/time_control` folder to your project's `addons` folder.
2. From editor toolbar, go to Project > Project Settings, then in Plugins tab activate **TimeControl** plugin.

## Basic setup

1. Setup global clocks

    The plugin provides a default [`ClockController`](#clockcontroller) autoload scene located in `res://addons/time_control/time_control.tscn` which gives you access to the following `GlobalClock` from anywhere in your project :

    - The **WORLD** clock, the main clock. The other clocks are parented to this clock
    - The **PLAYER** clock, manages the player time scale
    - The **ENEMY** clock, manages the enemies time scale
    - The **ENVIRONMENT** clock, manages the environment time scale on objects such as ambiant particle effects or animated props

    These [`Clock`](#clock) nodes are automatically registered to their parent  [`ClockController`](#clockcontroller)  node, which keeps track of all registered clocks.

    > To customize this scene and the registered global clocks, see [Customize `ClockController` autoload scene](#change-the-clockcontroller-autoload-scene).

<br>

2. Setup a `Timeline`

    Add a [`Timeline`](#timeline) node to your scene, and add a `ClockConfiguration` resource to the `global_clock_configuration` field.
    
    Example: If the `Timeline` is on your player scene, set the `player_clock.tres` resource (used on the **PLAYER** `GlobalClock`) in the `global_clock_configuration` field.

<br>

3. Use the `Timeline` node in your script.<br><br>

    ```gdscript
    extends CharacterBody2D

    const Timeline = preload("res://addons/time_control/timeline.gd")
    const SPEED = 300

    @export var timeline: Timeline

    func _physics_process(delta: float) -> void:
        var direction = Vector2.ONE
        velocity = direction * SPEED * timeline.time_scale
        move_and_slide() 
    ```

4. Change the *time scale* from anywhere using `ClockController`

    ```gdscript
    extends Node

    const ClockConfiguration = preload("res://addons/time_control/clock_configuration.gd")

    @export var clock_configuration: ClockConfiguration

    func _process(delta: float) -> void:
        ClockController.get_clock(clock_configuration).local_time_scale = 0.5
    ```

    or

    ```gdscript
    extends Node

    func _process(delta: float) -> void:
        ClockController.get_clock_by_key("PLAYER").local_time_scale = 0.5
    ```


## Resources

### ClockConfiguration

Resource representing a clock.

<details>
<summary>Properties</summary>
<br>

#### `key`: String

The clock identifier key.

</details>

## Nodes

### Clock

This *Node* calculates an indenpendant *time scale* based on the [`local_time_scale`](#local_time_scale-float). 

If the clock has a parent, the parent *time scale* is blended with the `local_time_scale`.

<details>
<summary>Properties</summary>

#### `local_time_scale`: float

The current clock time scale. Set this property to modify the clock time scale.

#### `parent_clock_configuration`: ClockConfiguration

*Optional*

Assign a `ClockConfiguration` resource as a parent clock if needed.

#### `parent_blend_mode`: BlendModeEnum

- `BlendModeEnum.Multiplicative`<br> 
*Default value*<br>
Multiply the current clock `time_scale` by the parent clock `time_scale`

- `BlendModeEnum.Additive`<br>
Adds the current clock `time_scale` to the parent clock `time_scale`

</details>

<details>
<summary>Methods</summary>

#### `get_time_scale()` -> **float**:

Returns the calculated time scale based on the [`local_time_scale`](#local_time_scale-float) and the parent clock *time scale*.
</details>

### GlobalClock

Inherits [`Clock`](#clock)

You can retrieve a `GlobalClock` node from anywhere with the  [`ClockController`](#clockcontroller) autoload.

The [`ClockConfiguration`](#clockconfiguration) resource parameter is *required*.

If you need to access the `GlobalClock` *time scale* only, we recommend adding a [`Timeline`](#timeline) node to your scene.


### Timeline

Add this node anywhere in your scene to access a `Clock` or a `GlobalClock` time scale.

<details>
<summary>Properties</summary>

#### `mode`: ModeEnum

- `ModeEnum.Global`<br> 
*Default value*<br>
The **Timeline** will target a `GlobalClock` with the `global_clock_configuration` setting. 

- `ModeEnum.Local`<br> 
*Default value*<br>
The **Timeline** will target a `Clock` node with the `local_clock` setting.

#### `time_scale`: float

Returns the target clock calculated *time scale*.

#### `local_clock`: Clock

Assign a `Clock` node. Works with `ModeEnum.Local`


#### `global_clock_configuration`: ClockConfiguration

Assign a global `ClockConfiguration` resource. Works with `ModeEnum.Global
</details>


### ClockController

This node keeps track of all [`GlobalClock`](#global-clock) in your project and provides methods to get / add / remove them from anywhere in your project at runtime.

<details>
<summary>Methods</summary>

#### `has_clock(clock_configuration: ClockConfiguration) -> bool`<br>
Returns `true` or `false` if the `GlobalClock` matching the `clock_configuration` is registered.<br>

#### `get_clock(clock_configuration: ClockConfiguration) -> GlobalClock`<br>
Returns the registered  `GlobalClock` from the `clock_configuration`<br>

#### `add_clock(clock_configuration: ClockConfiguration) -> GlobalClock`<br>
Registers and returns the new  `GlobalClock`<br>

#### `remove_clock(clock_configuration: ClockConfiguration) -> void`<br>
Removes a  `GlobalClock`<br>

</details>

## Customization 

### Change the `ClockController` autoload scene

1. Copy/paste the `res://addons/time_control/time_control.tscn` anywhere in your project
2. Open the copied scene and apply changes (ie: add / remove global clocks)
3. Go to Project > Project Settings > Addons > Time Control and modify the `autoload_path` with your new scene path. <br>Example: `res://scenes/time_control.tscn`
4. Disable/Enable the plugin or reload project to apply changes

## Examples

Check out the demo scene `res://addons/time_control/demo/demo.tscn`