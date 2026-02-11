extends Node
class_name TimeflowClock

const TimeflowEnums = preload("res://addons/timeflow/scripts/timeflow_enums.gd")

static var BLEND_STRATEGIES := {
	TimeflowEnums.TimeflowBlendMode.MULTIPLICATIVE: func(parent_scale: float, local_scale: float) -> float:
		return parent_scale * local_scale,
	TimeflowEnums.TimeflowBlendMode.ADDITIVE: func(parent_scale: float, local_scale: float) -> float:
		return parent_scale + local_scale,
}

@export var controller_path: NodePath

@export var configuration: TimeflowClockConfig:
	set = set_configuration, get = get_configuration
var local_time_scale: float = 1.0:
	set = set_local_time_scale, get = get_local_time_scale
var paused: bool = false:
	set = set_paused, get = get_paused
var parent_blend_mode: int = TimeflowEnums.TimeflowBlendMode.MULTIPLICATIVE:
	set = set_parent_blend_mode, get = get_parent_blend_mode

var time_scale: float = 1.0
var time: float = 0.0
var unscaled_time: float = 0.0
var delta_time: float = 0.0
var physics_delta_time: float = 0.0

var parent_clock: TimeflowClock
var _registered: bool = false

var _configuration: TimeflowClockConfig
var _local_time_scale: float = 1.0
var _paused: bool = false
var _parent_blend_mode: int = TimeflowEnums.TimeflowBlendMode.MULTIPLICATIVE

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	_register_with_controller()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_apply_configuration_defaults()
	_resolve_parent()
	_recalculate_time_scale()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_unregister_from_controller()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_resolve_parent()
	_recalculate_time_scale()
	unscaled_time += delta
	delta_time = delta * time_scale
	time += delta_time

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	physics_delta_time = delta * time_scale

func get_time_scale() -> float:
	return time_scale

func set_configuration(value: TimeflowClockConfig) -> void:
	if _configuration == value:
		return
	var previous: TimeflowClockConfig = _configuration
	_configuration = value
	if Engine.is_editor_hint():
		return
	_apply_configuration_defaults()
	_resolve_parent()
	_recalculate_time_scale()
	_register_with_controller(previous)

func get_configuration() -> TimeflowClockConfig:
	return _configuration

func set_local_time_scale(value: float) -> void:
	if _configuration != null:
		_local_time_scale = clampf(value, _configuration.min_time_scale, _configuration.max_time_scale)
	else:
		_local_time_scale = value
	_recalculate_time_scale()

func get_local_time_scale() -> float:
	return _local_time_scale

func set_paused(value: bool) -> void:
	_paused = value
	_recalculate_time_scale()

func get_paused() -> bool:
	return _paused

func set_parent_blend_mode(value: int) -> void:
	_parent_blend_mode = value
	_recalculate_time_scale()

func get_parent_blend_mode() -> int:
	return _parent_blend_mode

func _recalculate_time_scale() -> void:
	if _paused:
		time_scale = 0.0
		return

	if parent_clock == null or not parent_clock is Node:
		time_scale = _local_time_scale
		return

	var blend = BLEND_STRATEGIES.get(_parent_blend_mode, null)
	if blend == null:
		time_scale = _local_time_scale
		return
	time_scale = blend.call(parent_clock.time_scale, _local_time_scale)

func _resolve_parent() -> void:
	if Engine.is_editor_hint():
		parent_clock = null
		return
	if _configuration == null:
		parent_clock = null
		return
	if _configuration.parent_key == StringName():
		parent_clock = null
		return
	if _configuration.parent_key == _configuration.key:
		parent_clock = null
		return
	var controller := _get_controller()
	if controller == null:
		return
	if controller.has_method("has_clock_by_key") and not controller.has_clock_by_key(_configuration.parent_key):
		parent_clock = null
		return
	var candidate = controller.get_clock_by_key(_configuration.parent_key)
	parent_clock = candidate if candidate is TimeflowClock else null

func _register_with_controller(previous: TimeflowClockConfig = null) -> void: 
	if not is_inside_tree():
		return
	var controller := _get_controller()
	if controller == null:
		push_error("Timeflow autoload is missing. Enable the plugin or set controller_path.")
		return
	controller.register_clock(self, previous)
	_registered = true

func _unregister_from_controller() -> void:
	if not _registered:
		return
	var controller := _get_controller()
	if controller == null:
		return
	controller.unregister_clock(self)
	_registered = false

func _get_controller() -> Node:
	if controller_path != NodePath():
		return get_node_or_null(controller_path)
	if Engine.has_singleton("Timeflow"):
		return Timeflow
		
	var node := get_parent()
	while node != null:
		if node.has_method("register_clock") and node.has_method("unregister_clock"):
			return node
		node = node.get_parent()

	if is_inside_tree() and get_tree() != null:
		var found := get_tree().root.find_child("Timeflow", true, false)
		if found != null:
			return found
	return null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if _configuration == null:
		warnings.append("Assign a TimeflowClockConfig resource.")
		return warnings
	if _configuration.key == "":
		warnings.append("TimeflowClockConfig key cannot be empty.")
	if _configuration.parent_key == _configuration.key and _configuration.parent_key != StringName():
		warnings.append("Parent clock cannot be the same key as this clock.")
	if _configuration.min_time_scale > _configuration.max_time_scale:
		warnings.append("min_time_scale cannot be greater than max_time_scale.")
	return warnings

func _apply_configuration_defaults() -> void:
	if _configuration == null:
		return
	_local_time_scale = clampf(
		_configuration.default_local_time_scale,
		_configuration.min_time_scale,
		_configuration.max_time_scale
	)
	_paused = _configuration.default_paused
	_parent_blend_mode = int(_configuration.parent_blend_mode)
