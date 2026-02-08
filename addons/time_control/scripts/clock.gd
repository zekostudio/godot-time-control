@tool
extends Node

enum BlendModeEnum { Additive, Multiplicative }

const ClockConfiguration = preload("res://addons/time_control/scripts/clock_configuration.gd")

static var BLEND_STRATEGIES := {
	BlendModeEnum.Multiplicative: func(parent_scale: float, local_scale: float) -> float:
		return parent_scale * local_scale,
	BlendModeEnum.Additive: func(parent_scale: float, local_scale: float) -> float:
		return parent_scale + local_scale,
}

@export var controller_path: NodePath

@export var configuration: Resource:
	set = set_configuration, get = get_configuration
@export var local_time_scale: float = 1.0:
	set = set_local_time_scale, get = get_local_time_scale
@export var paused: bool = false:
	set = set_paused, get = get_paused
@export var parent_configuration: Resource:
	set = set_parent_configuration, get = get_parent_configuration
@export var parent_blend_mode: BlendModeEnum = BlendModeEnum.Multiplicative:
	set = set_parent_blend_mode, get = get_parent_blend_mode

var time_scale: float = 1.0
var time: float = 0.0
var unscaled_time: float = 0.0
var delta_time: float = 0.0
var physics_delta_time: float = 0.0

var parent_clock: Node
var _registered: bool = false

var _configuration: Resource
var _local_time_scale: float = 1.0
var _paused: bool = false
var _parent_configuration: Resource
var _parent_blend_mode: BlendModeEnum = BlendModeEnum.Multiplicative

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	_register_with_controller()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
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

func set_configuration(value: Resource) -> void:
	if _configuration == value:
		return
	var previous: Resource = _configuration
	_configuration = value
	if Engine.is_editor_hint():
		return
	_register_with_controller(previous)

func get_configuration() -> Resource:
	return _configuration

func set_local_time_scale(value: float) -> void:
	_local_time_scale = value
	_recalculate_time_scale()

func get_local_time_scale() -> float:
	return _local_time_scale

func set_paused(value: bool) -> void:
	_paused = value
	_recalculate_time_scale()

func get_paused() -> bool:
	return _paused

func set_parent_configuration(value: Resource) -> void:
	_parent_configuration = value
	_resolve_parent()
	_recalculate_time_scale()

func get_parent_configuration() -> Resource:
	return _parent_configuration

func set_parent_blend_mode(value: BlendModeEnum) -> void:
	_parent_blend_mode = value
	_recalculate_time_scale()

func get_parent_blend_mode() -> BlendModeEnum:
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
	if _parent_configuration == null:
		parent_clock = null
		return
	var controller := _get_controller()
	if controller == null:
		return
	parent_clock = controller.get_clock(_parent_configuration)

func _register_with_controller(previous: ClockConfiguration = null) -> void: 
	if not is_inside_tree():
		return
	var controller := _get_controller()
	if controller == null:
		push_error("TimeController autoload is missing. Enable the plugin or set controller_path.")
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
	if Engine.has_singleton("TimeController"):
		return TimeController
		
	var node := get_parent()
	while node != null:
		if node.has_method("register_clock") and node.has_method("unregister_clock"):
			return node
		node = node.get_parent()

	if is_inside_tree() and get_tree() != null:
		var found := get_tree().root.find_child("TimeController", true, false)
		if found != null:
			return found
	return null

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if _configuration == null:
		warnings.append("Assign a ClockConfiguration resource.")
	if _parent_configuration != null and _configuration != null and _parent_configuration == _configuration:
		warnings.append("Parent clock cannot be the same configuration as this clock.")
	return warnings
