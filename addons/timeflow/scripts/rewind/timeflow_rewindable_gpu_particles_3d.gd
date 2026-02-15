extends TimeflowRewindable

class_name TimeflowRewindableGPUParticles3D

@export var target: GPUParticles3D
@export var timeline: TimeflowTimeline
@export var particles_sync: TimeflowGPUParticles3DSync
@export var duplicate_process_material: bool = true
@export var restart_on_rewind_start: bool = true
@export var capture_particle_properties: bool = true
@export var capture_process_material_properties: bool = true
@export_enum("Freeze", "Continue Rewind Direction") var rewind_exhausted_behavior: int = 0

func _ready() -> void:
	if target == null:
		var parent := get_parent()
		if parent is GPUParticles3D:
			target = parent
	if target != null and duplicate_process_material and target.process_material != null:
		target.process_material = target.process_material.duplicate(true)
	if particles_sync == null:
		particles_sync = _find_particles_sync()
	if timeline == null and particles_sync != null:
		timeline = particles_sync.timeline

func capture_timeflow_state() -> Dictionary:
	if target == null:
		return {}
	var state: Dictionary = {}
	if capture_particle_properties:
		state["particles"] = _capture_particle_state()
	if capture_process_material_properties:
		var material_state := _capture_material_state()
		if not material_state.is_empty():
			state["material"] = material_state
	return state

func apply_timeflow_state(state: Dictionary) -> void:
	if target == null or state.is_empty():
		return
	if capture_particle_properties and state.has("particles"):
		var particles_state = state["particles"]
		if particles_state is Dictionary:
			_apply_particle_state(particles_state)
	if capture_process_material_properties and state.has("material"):
		var material_state = state["material"]
		if material_state is Dictionary:
			_apply_material_state(material_state)

func interpolate_timeflow_state(from_state: Dictionary, to_state: Dictionary, weight: float) -> Dictionary:
	if from_state.is_empty():
		return to_state.duplicate(true)
	if to_state.is_empty():
		return from_state.duplicate(true)
	return from_state if weight < 0.5 else to_state

func on_timeflow_rewind_started() -> void:
	var material := _get_particle_material()
	if material == null:
		return
	_apply_rewind_state(material)
	if restart_on_rewind_start and target != null:
		target.restart()

func on_timeflow_rewind_stopped() -> void:
	var material := _get_particle_material()
	if material == null:
		return
	_restore_forward_state(material)

func on_timeflow_rewind_exhausted() -> void:
	var material := _get_particle_material()
	if target == null or material == null:
		return
	match rewind_exhausted_behavior:
		0:
			if particles_sync != null:
				particles_sync.set_freeze_while_negative(true)
			target.speed_scale = 0.0
		1:
			if particles_sync != null:
				particles_sync.set_freeze_while_negative(false)
			_apply_rewind_state(material)

func _capture_particle_state() -> Dictionary:
	return {
		"emitting": target.emitting,
		"speed_scale": target.speed_scale,
		"amount_ratio": target.amount_ratio,
		"lifetime": target.lifetime,
		"preprocess": target.preprocess,
		"explosiveness": target.explosiveness,
		"randomness": target.randomness,
		"fixed_fps": target.fixed_fps,
		"interp_to_end": target.interp_to_end,
		"one_shot": target.one_shot,
	}

func _apply_particle_state(state: Dictionary) -> void:
	if state.has("emitting"):
		target.emitting = bool(state["emitting"])
	if state.has("speed_scale"):
		target.speed_scale = float(state["speed_scale"])
	if state.has("amount_ratio"):
		target.amount_ratio = float(state["amount_ratio"])
	if state.has("lifetime"):
		target.lifetime = float(state["lifetime"])
	if state.has("preprocess"):
		target.preprocess = float(state["preprocess"])
	if state.has("explosiveness"):
		target.explosiveness = float(state["explosiveness"])
	if state.has("randomness"):
		target.randomness = float(state["randomness"])
	if state.has("fixed_fps"):
		target.fixed_fps = int(state["fixed_fps"])
	if state.has("interp_to_end"):
		target.interp_to_end = float(state["interp_to_end"])
	if state.has("one_shot"):
		target.one_shot = bool(state["one_shot"])

func _capture_material_state() -> Dictionary:
	var material := _get_particle_material()
	if material == null:
		return {}
	return {
		"direction": material.direction,
		"initial_velocity_min": material.initial_velocity_min,
		"initial_velocity_max": material.initial_velocity_max,
		"spread": material.spread,
		"gravity": material.gravity,
	}

func _apply_material_state(state: Dictionary) -> void:
	var material := _get_particle_material()
	if material == null:
		return
	var direction: Vector3 = state.get("direction", material.direction)
	var velocity_min: float = float(state.get("initial_velocity_min", material.initial_velocity_min))
	var velocity_max: float = float(state.get("initial_velocity_max", material.initial_velocity_max))
	if _is_rewinding_now():
		material.direction = -direction
		material.initial_velocity_min = -velocity_max
		material.initial_velocity_max = -velocity_min
	else:
		material.direction = direction
		material.initial_velocity_min = velocity_min
		material.initial_velocity_max = velocity_max
	if state.has("spread"):
		material.spread = float(state["spread"])
	if state.has("gravity"):
		var gravity_value = state["gravity"]
		if gravity_value is Vector3:
			material.gravity = gravity_value

func _apply_rewind_state(material: ParticleProcessMaterial) -> void:
	var current_velocity_min: float = material.initial_velocity_min
	var current_velocity_max: float = material.initial_velocity_max
	material.initial_velocity_min = -current_velocity_max
	material.initial_velocity_max = -current_velocity_min
	material.direction = -material.direction

func _restore_forward_state(material: ParticleProcessMaterial) -> void:
	_apply_rewind_state(material)

func _find_particles_sync() -> TimeflowGPUParticles3DSync:
	var parent := get_parent()
	if parent == null:
		return null
	for child in parent.get_children():
		if child is TimeflowGPUParticles3DSync:
			var typed_sync: TimeflowGPUParticles3DSync = child
			if typed_sync.gpu_particles_3d == null or typed_sync.gpu_particles_3d == target:
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

func _is_rewinding_now() -> bool:
	return _get_effective_time_scale() < 0.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target == null and not (get_parent() is GPUParticles3D):
		warnings.append("Assign a GPUParticles3D target or place this node under a GPUParticles3D parent.")
	if target != null and target.process_material != null and not (target.process_material is ParticleProcessMaterial):
		warnings.append("Target process_material must be a ParticleProcessMaterial to rewind material properties.")
	return warnings
