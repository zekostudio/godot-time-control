@tool
extends Node
class_name TimeflowTimeline

const TimeflowEnums = preload("res://addons/timeflow/scripts/clock/timeflow_enums.gd")

signal clock_bound(clock: TimeflowClock)
signal clock_unbound(clock: TimeflowClock)
signal time_scale_changed(previous_time_scale: float, time_scale: float)
signal rewind_started(time_scale: float)
signal rewind_stopped(time_scale: float)

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
	var previous_clock: TimeflowClock = clock

	match mode:
		TimeflowEnums.TimeflowTimelineMode.GLOBAL:
			if clock_configuration == null or Timeflow == null:
				clock = null
			else:
				clock = Timeflow.get_clock(clock_configuration)
		TimeflowEnums.TimeflowTimelineMode.LOCAL:
			clock = local_clock
		_:
			clock = null

	if clock == null and not Engine.is_editor_hint():
		push_error("TimeflowTimeline could not bind to a clock. Check mode and configuration.")
	if previous_clock != clock:
		if previous_clock != null:
			clock_unbound.emit(previous_clock)
		if clock != null:
			clock_bound.emit(clock)

func _update_time_scale() -> void:
	var previous_time_scale: float = time_scale
	if clock == null:
		time_scale = 1.0
	else:
		time_scale = clock.time_scale
	_emit_time_scale_events(previous_time_scale, time_scale)

func is_rewinding() -> bool:
	return time_scale < 0.0

func _emit_time_scale_events(previous_time_scale: float, next_time_scale: float) -> void:
	if is_equal_approx(previous_time_scale, next_time_scale):
		return
	time_scale_changed.emit(previous_time_scale, next_time_scale)
	if previous_time_scale >= 0.0 and next_time_scale < 0.0:
		rewind_started.emit(next_time_scale)
	elif previous_time_scale < 0.0 and next_time_scale >= 0.0:
		rewind_stopped.emit(next_time_scale)

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
