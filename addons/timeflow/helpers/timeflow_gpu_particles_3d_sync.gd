extends Node
class_name TimeflowGPUParticles3DSync

const TimeflowTimeline = preload("res://addons/timeflow/scripts/timeflow_timeline.gd")

@export var gpu_particles_3d: GPUParticles3D
@export var timeline: TimeflowTimeline

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null or gpu_particles_3d == null:
		return
	gpu_particles_3d.speed_scale = timeline.time_scale
