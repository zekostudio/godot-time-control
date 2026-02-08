@tool
extends Node

enum ModeEnum { Global, Local }

const Clock = preload("res://addons/time_control/scripts/clock.gd")
const ClockConfiguration = preload("res://addons/time_control/scripts/clock_configuration.gd")

@export var mode: ModeEnum = ModeEnum.Global:
	set = set_mode, get = get_mode
@export var local_clock: Clock:
	set = set_local_clock, get = get_local_clock
@export var clock_configuration: ClockConfiguration:
	set = set_clock_configuration, get = get_clock_configuration

var clock
var time_scale: float = 1.0
var last_time_scale: float = 1.0 
var delta_time: float = 0.0
var physics_delta_time: float = 0.0
var time: float = 0.0
var unscaled_time: float = 0.0

var _mode: ModeEnum = ModeEnum.Global
var _local_clock
var _clock_configuration

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_bind_clock(true)
	_update_time_scale()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if clock == null:
		_bind_clock()
		if clock == null:
			return

	last_time_scale = time_scale
	_update_time_scale()
	unscaled_time += delta
	delta_time = delta * time_scale
	time += delta_time

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if clock == null:
		return
	physics_delta_time = delta * time_scale

func set_time_scale(value: float) -> void:
	if clock == null:
		_bind_clock()
	if clock != null:
		clock.local_time_scale = value

func set_mode(value: ModeEnum) -> void:
	if _mode == value:
		return
	_mode = value
	_bind_clock(true)

func get_mode() -> ModeEnum:
	return _mode

func set_local_clock(value: Clock) -> void:
	_local_clock = value
	if _mode == ModeEnum.Local:
		_bind_clock(true)

func get_local_clock() -> Clock:
	return _local_clock

func set_clock_configuration(value: ClockConfiguration) -> void:
	_clock_configuration = value
	if _mode == ModeEnum.Global:
		_bind_clock(true)

func get_clock_configuration() -> ClockConfiguration:
	return _clock_configuration

func tween_time_scale(target_scale: float, duration: float) -> void:
	if clock == null:
		_bind_clock()
	if clock == null:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(clock, "local_time_scale", target_scale, duration)
	await tween.finished

func _bind_clock(force: bool = false) -> void:
	if not force and clock != null:
		return

	match _mode:
		ModeEnum.Global:
			if _clock_configuration == null or TimeController == null:
				clock = null
				return
			clock = TimeController.get_clock(_clock_configuration)
		ModeEnum.Local:
			clock = _local_clock
		_:
			clock = null

	if clock == null and not Engine.is_editor_hint():
		push_error("Timeline could not bind to a clock. Check mode and configuration.")

func _update_time_scale() -> void:
	if clock == null:
		time_scale = 1.0
		return
	time_scale = clock.time_scale

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	match _mode:
		ModeEnum.Global:
			if _clock_configuration == null:
				warnings.append("Assign a ClockConfiguration when mode is Global.")
		ModeEnum.Local:
			if _local_clock == null:
				warnings.append("Assign a local Clock node when mode is Local.")
	return warnings
