extends TimeflowRewindable

class_name TimeflowRewindableGPUParticles2D

@export var target: GPUParticles2D
@export var timeline: TimeflowTimeline
@export var particles_sync: TimeflowGPUParticles2DSync
@export var restart_on_rewind_start: bool = true
@export_enum("Freeze", "Continue Timeline Speed") var rewind_exhausted_behavior: int = 0

var _forward_direction: Vector3 = Vector3.ZERO
var _has_forward_direction: bool = false

func _ready() -> void:
	if target == null:
		var parent := get_parent()
		if parent is GPUParticles2D:
			target = parent
	if particles_sync == null:
		particles_sync = _find_particles_sync()
	if timeline == null and particles_sync != null:
		timeline = particles_sync.timeline

func capture_timeflow_state() -> Dictionary:
	if target == null:
		return {}
	var state: Dictionary = {"speed_scale": target.speed_scale}
	var material := _get_particle_material()
	if material != null:
		state["direction"] = material.direction
	return state

func apply_timeflow_state(state: Dictionary) -> void:
	if target == null or state.is_empty():
		return
	if state.has("speed_scale"):
		target.speed_scale = float(state["speed_scale"])
	if state.has("direction"):
		var material := _get_particle_material()
		if material != null:
			var direction_value = state["direction"]
			if direction_value is Vector3:
				material.direction = -direction_value if _get_effective_time_scale() < 0.0 else direction_value

func interpolate_timeflow_state(from_state: Dictionary, to_state: Dictionary, weight: float) -> Dictionary:
	if from_state.is_empty():
		return to_state.duplicate(true)
	if to_state.is_empty():
		return from_state.duplicate(true)
	return from_state if weight < 0.5 else to_state

func on_timeflow_rewind_started() -> void:
	var material := _get_particle_material()
	if material != null:
		_forward_direction = material.direction
		_has_forward_direction = true
	if restart_on_rewind_start and target != null:
		target.restart()

func on_timeflow_rewind_stopped() -> void:
	var material := _get_particle_material()
	if material == null or not _has_forward_direction:
		return
	material.direction = _forward_direction
	_has_forward_direction = false

func on_timeflow_rewind_exhausted() -> void:
	if target == null:
		return
	match rewind_exhausted_behavior:
		0:
			if particles_sync != null:
				particles_sync.set_freeze_while_negative(true)
			target.speed_scale = 0.0
		1:
			if particles_sync != null:
				particles_sync.set_freeze_while_negative(false)
			target.speed_scale = absf(_get_effective_time_scale())

func _find_particles_sync() -> TimeflowGPUParticles2DSync:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is TimeflowGPUParticles2DSync:
			var typed_sync: TimeflowGPUParticles2DSync = child
			if typed_sync.gpu_particles_2d == null or typed_sync.gpu_particles_2d == target:
				return typed_sync
	return null

func _get_particle_material() -> ParticleProcessMaterial:
	if target == null:
		return null
	return target.process_material as ParticleProcessMaterial

func _get_effective_time_scale() -> float:
	if timeline != null:
		if timeline.clock != null:
			return timeline.clock.time_scale
		return timeline.time_scale
	if particles_sync != null and particles_sync.timeline != null:
		var sync_timeline := particles_sync.timeline
		if sync_timeline.clock != null:
			return sync_timeline.clock.time_scale
		return sync_timeline.time_scale
	return 1.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target == null and not (get_parent() is GPUParticles2D):
		warnings.append("Assign a GPUParticles2D target or place this node under a GPUParticles2D parent.")
	if target != null and target.process_material != null and not (target.process_material is ParticleProcessMaterial):
		warnings.append("Target process_material must be ParticleProcessMaterial to rewind direction.")
	return warnings
