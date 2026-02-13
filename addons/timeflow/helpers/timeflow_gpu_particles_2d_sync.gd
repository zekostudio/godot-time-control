extends Node
class_name TimeflowGPUParticles2DSync

const TimeflowTimeline = preload("res://addons/timeflow/scripts/timeflow_timeline.gd")

@export var gpu_particles_2d: GPUParticles2D
@export var timeline: TimeflowTimeline
@export var use_absolute_time_scale: bool = true

var _freeze_while_negative: bool = false

func set_freeze_while_negative(enabled: bool) -> void:
	_freeze_while_negative = enabled

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null or gpu_particles_2d == null:
		return
	if _freeze_while_negative:
		if timeline.time_scale < 0.0:
			gpu_particles_2d.speed_scale = 0.0
			return
		_freeze_while_negative = false
	gpu_particles_2d.speed_scale = absf(timeline.time_scale) if use_absolute_time_scale else timeline.time_scale
