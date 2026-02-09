extends Node

const Timeline = preload("res://addons/time_control/scripts/timeline.gd")

@export var gpu_particles_2d: GPUParticles2D
@export var timeline: Timeline

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null or gpu_particles_2d == null:
		return
	gpu_particles_2d.speed_scale = timeline.time_scale
