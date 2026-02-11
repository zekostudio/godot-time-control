@tool
extends Node
class_name TimeflowTimeline

const TimeflowEnums = preload("res://addons/timeflow/scripts/timeflow_enums.gd")

@export var mode: TimeflowEnums.TimeflowTimelineMode = TimeflowEnums.TimeflowTimelineMode.GLOBAL
@export var local_clock: TimeflowClock
@export var clock_configuration: TimeflowClockConfig

var clock
var time_scale: float = 1.0
var last_time_scale: float = 1.0 
var delta_time: float = 0.0
var physics_delta_time: float = 0.0
var time: float = 0.0
var unscaled_time: float = 0.0

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

func tween_time_scale(target_scale: float, duration: float) -> void:
	if clock == null:
		_bind_clock()
	if clock == null:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(clock, "local_time_scale", target_scale, duration)
	await tween.finished

func _bind_clock(force: bool = false) -> void:
	if Engine.is_editor_hint():
		return
	if not force and clock != null:
		return

	match mode:
		TimeflowEnums.TimeflowTimelineMode.GLOBAL:
			if clock_configuration == null or Timeflow == null:
				clock = null
				return
			clock = Timeflow.get_clock(clock_configuration)
		TimeflowEnums.TimeflowTimelineMode.LOCAL:
			clock = local_clock
		_:
			clock = null

	if clock == null and not Engine.is_editor_hint():
		push_error("TimeflowTimeline could not bind to a clock. Check mode and configuration.")

func _update_time_scale() -> void:
	if clock == null:
		time_scale = 1.0
		return
	time_scale = clock.time_scale

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	match mode:
		TimeflowEnums.TimeflowTimelineMode.GLOBAL:
			if clock_configuration == null:
				warnings.append("Assign a TimeflowClockConfig when mode is GLOBAL.")
		TimeflowEnums.TimeflowTimelineMode.LOCAL:
			if local_clock == null:
				warnings.append("Assign a local TimeflowClock node when mode is LOCAL.")
	return warnings
