extends Node
class_name TimeflowGPUParticles3DSync

const TimeflowTimeline = preload("res://addons/timeflow/scripts/clock/timeflow_timeline.gd")

@export var gpu_particles_3d: GPUParticles3D
@export var timeline: TimeflowTimeline
@export var use_absolute_time_scale: bool = true

var _freeze_while_negative: bool = false

func set_freeze_while_negative(enabled: bool) -> void:
	_freeze_while_negative = enabled
	_apply_time_scale()

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_bind_timeline_signals()
	_apply_time_scale()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	_unbind_timeline_signals()

func _bind_timeline_signals() -> void:
	if timeline != null and not timeline.time_scale_changed.is_connected(_on_timeline_time_scale_changed):
		timeline.time_scale_changed.connect(_on_timeline_time_scale_changed)

func _unbind_timeline_signals() -> void:
	if timeline != null and timeline.time_scale_changed.is_connected(_on_timeline_time_scale_changed):
		timeline.time_scale_changed.disconnect(_on_timeline_time_scale_changed)

func _on_timeline_time_scale_changed(_previous_time_scale: float, next_time_scale: float) -> void:
	_apply_time_scale(next_time_scale)

func _apply_time_scale(scale: float = NAN) -> void:
	if timeline == null or gpu_particles_3d == null:
		return

	var resolved_scale: float = timeline.time_scale if is_nan(scale) else scale
	if _freeze_while_negative and resolved_scale < 0.0:
		gpu_particles_3d.speed_scale = 0.0
		return
	if _freeze_while_negative:
		_freeze_while_negative = false
	gpu_particles_3d.speed_scale = absf(resolved_scale) if use_absolute_time_scale else resolved_scale
