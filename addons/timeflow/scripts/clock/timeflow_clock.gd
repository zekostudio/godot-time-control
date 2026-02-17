extends Node
class_name TimeflowClock

const TimeflowEnums = preload("res://addons/timeflow/scripts/clock/timeflow_enums.gd")

signal local_time_scale_changed(previous_local_time_scale: float, local_time_scale: float)
signal paused_changed(paused: bool)
signal parent_blend_mode_changed(previous_parent_blend_mode: int, parent_blend_mode: int)
signal time_scale_changed(previous_time_scale: float, time_scale: float)
signal rewind_started(time_scale: float)
signal rewind_stopped(time_scale: float)

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
var _parent_dirty: bool = true
var _controller_ref: Node = null

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
	_parent_dirty = true
	_refresh_parent_if_needed()
	_recalculate_time_scale()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_unregister_from_controller()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_refresh_parent_if_needed()
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
	_parent_dirty = true
	_refresh_parent_if_needed()
	_recalculate_time_scale()
	_register_with_controller(previous)

func get_configuration() -> TimeflowClockConfig:
	return _configuration

func set_local_time_scale(value: float) -> void:
	var previous_local_time_scale: float = _local_time_scale
	if _configuration != null:
		_local_time_scale = clampf(value, _configuration.min_time_scale, _configuration.max_time_scale)
	else:
		_local_time_scale = value
	if is_equal_approx(previous_local_time_scale, _local_time_scale):
		return
	local_time_scale_changed.emit(previous_local_time_scale, _local_time_scale)
	_recalculate_time_scale()

func get_local_time_scale() -> float:
	return _local_time_scale

func set_paused(value: bool) -> void:
	if _paused == value:
		return
	_paused = value
	paused_changed.emit(_paused)
	_recalculate_time_scale()

func get_paused() -> bool:
	return _paused

func set_parent_blend_mode(value: int) -> void:
	if _parent_blend_mode == value:
		return
	var previous_parent_blend_mode: int = _parent_blend_mode
	_parent_blend_mode = value
	parent_blend_mode_changed.emit(previous_parent_blend_mode, _parent_blend_mode)
	_recalculate_time_scale()

func get_parent_blend_mode() -> int:
	return _parent_blend_mode

func _recalculate_time_scale() -> void:
	var previous_time_scale: float = time_scale
	var new_time_scale: float = _local_time_scale
	if _paused:
		new_time_scale = 0.0
	elif parent_clock == null or not parent_clock is Node:
		new_time_scale = _local_time_scale
	else:
		var blend = BLEND_STRATEGIES.get(_parent_blend_mode, null)
		if blend == null:
			new_time_scale = _local_time_scale
		else:
			new_time_scale = blend.call(parent_clock.time_scale, _local_time_scale)
	time_scale = new_time_scale
	_emit_time_scale_events(previous_time_scale, time_scale)

func _resolve_parent() -> void:
	if Engine.is_editor_hint():
		parent_clock = null
		_parent_dirty = false
		return
	if _configuration == null:
		parent_clock = null
		_parent_dirty = false
		return
	if _configuration.parent_key == StringName():
		parent_clock = null
		_parent_dirty = false
		return
	if _configuration.parent_key == _configuration.key:
		parent_clock = null
		_parent_dirty = false
		return
	var controller := _get_controller()
	if controller == null:
		parent_clock = null
		_parent_dirty = true
		return
	_update_controller_signal_connections(controller)
	if controller.has_method("has_clock_by_key") and not controller.has_clock_by_key(_configuration.parent_key):
		parent_clock = null
		_parent_dirty = false
		return
	var candidate = controller.get_clock_by_key(_configuration.parent_key)
	parent_clock = candidate if candidate is TimeflowClock else null
	_parent_dirty = false

func _register_with_controller(previous: TimeflowClockConfig = null) -> void: 
	if not is_inside_tree():
		return
	var controller := _get_controller()
	if controller == null:
		push_error("Timeflow autoload is missing. Enable the plugin or set controller_path.")
		return
	_update_controller_signal_connections(controller)
	controller.register_clock(self, previous)
	_registered = true
	_parent_dirty = true

func _unregister_from_controller() -> void:
	if not _registered:
		_disconnect_controller_signals()
		return
	if _controller_ref != null and is_instance_valid(_controller_ref) and _controller_ref.has_method("unregister_clock"):
		_controller_ref.unregister_clock(self)
	_disconnect_controller_signals()
	_registered = false
	_parent_dirty = true

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

func _refresh_parent_if_needed() -> void:
	if _parent_dirty or _is_parent_reference_invalid():
		_resolve_parent()

func _is_parent_reference_invalid() -> bool:
	if _configuration == null:
		return parent_clock != null
	if _configuration.parent_key == StringName() or _configuration.parent_key == _configuration.key:
		return parent_clock != null
	if parent_clock == null:
		return true
	return not is_instance_valid(parent_clock)

func _update_controller_signal_connections(controller: Node) -> void:
	if _controller_ref == controller:
		return
	_disconnect_controller_signals()
	_controller_ref = controller
	if _controller_ref == null:
		return
	if _controller_ref.has_signal("clock_registered"):
		if not _controller_ref.clock_registered.is_connected(_on_controller_clock_registered):
			_controller_ref.clock_registered.connect(_on_controller_clock_registered)
	if _controller_ref.has_signal("clock_unregistered"):
		if not _controller_ref.clock_unregistered.is_connected(_on_controller_clock_unregistered):
			_controller_ref.clock_unregistered.connect(_on_controller_clock_unregistered)

func _disconnect_controller_signals() -> void:
	if _controller_ref == null:
		return
	if not is_instance_valid(_controller_ref):
		_controller_ref = null
		return
	if _controller_ref.clock_registered.is_connected(_on_controller_clock_registered):
		_controller_ref.clock_registered.disconnect(_on_controller_clock_registered)
	if _controller_ref.clock_unregistered.is_connected(_on_controller_clock_unregistered):
		_controller_ref.clock_unregistered.disconnect(_on_controller_clock_unregistered)
	_controller_ref = null

func _on_controller_clock_registered(_clock: TimeflowClock) -> void:
	_parent_dirty = true

func _on_controller_clock_unregistered(_clock: TimeflowClock) -> void:
	_parent_dirty = true

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
	var previous_local_time_scale: float = _local_time_scale
	var previous_paused: bool = _paused
	var previous_parent_blend_mode: int = _parent_blend_mode
	_local_time_scale = clampf(
		_configuration.default_local_time_scale,
		_configuration.min_time_scale,
		_configuration.max_time_scale
	)
	_paused = _configuration.default_paused
	_parent_blend_mode = int(_configuration.parent_blend_mode)
	if not is_equal_approx(previous_local_time_scale, _local_time_scale):
		local_time_scale_changed.emit(previous_local_time_scale, _local_time_scale)
	if previous_paused != _paused:
		paused_changed.emit(_paused)
	if previous_parent_blend_mode != _parent_blend_mode:
		parent_blend_mode_changed.emit(previous_parent_blend_mode, _parent_blend_mode)

func _emit_time_scale_events(previous_time_scale: float, next_time_scale: float) -> void:
	if is_equal_approx(previous_time_scale, next_time_scale):
		return
	time_scale_changed.emit(previous_time_scale, next_time_scale)
	if previous_time_scale >= 0.0 and next_time_scale < 0.0:
		rewind_started.emit(next_time_scale)
	elif previous_time_scale < 0.0 and next_time_scale >= 0.0:
		rewind_stopped.emit(next_time_scale)
