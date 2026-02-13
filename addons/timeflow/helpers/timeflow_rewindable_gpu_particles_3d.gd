extends TimeflowRewindable

class_name TimeflowRewindableGPUParticles3D

@export var target: GPUParticles3D
@export var particles_sync: TimeflowGPUParticles3DSync
@export var duplicate_process_material: bool = true
@export var restart_on_rewind_start: bool = true
@export_enum("Freeze", "Continue Rewind Direction") var rewind_exhausted_behavior: int = 0

var _original_velocity_min: float = 0.0
var _original_velocity_max: float = 0.0
var _original_direction: Vector3 = Vector3.ZERO
var _has_captured_velocity: bool = false
var _has_forward_state: bool = false

func _ready() -> void:
	if target == null:
		var parent := get_parent()
		if parent is GPUParticles3D:
			target = parent
	if target != null and duplicate_process_material and target.process_material != null:
		target.process_material = target.process_material.duplicate(true)
	if particles_sync == null:
		particles_sync = _find_particles_sync()

func on_timeflow_rewind_started() -> void:
	var material := _get_particle_material()
	if material == null:
		return
	_capture_forward_state(material)
	_has_captured_velocity = true
	_apply_rewind_state(material)
	if restart_on_rewind_start and target != null:
		target.restart()

func on_timeflow_rewind_stopped() -> void:
	var material := _get_particle_material()
	if material == null or not _has_captured_velocity:
		return
	_restore_forward_state(material)
	_has_captured_velocity = false

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

func _capture_forward_state(material: ParticleProcessMaterial) -> void:
	if _has_forward_state:
		return
	_original_velocity_min = material.initial_velocity_min
	_original_velocity_max = material.initial_velocity_max
	_original_direction = material.direction
	_has_forward_state = true

func _apply_rewind_state(material: ParticleProcessMaterial) -> void:
	material.initial_velocity_min = -_original_velocity_max
	material.initial_velocity_max = -_original_velocity_min
	material.direction = -_original_direction

func _restore_forward_state(material: ParticleProcessMaterial) -> void:
	material.initial_velocity_min = _original_velocity_min
	material.initial_velocity_max = _original_velocity_max
	material.direction = _original_direction

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

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target == null and not (get_parent() is GPUParticles3D):
		warnings.append("Assign a GPUParticles3D target or place this node under a GPUParticles3D parent.")
	if target != null and target.process_material != null and not (target.process_material is ParticleProcessMaterial):
		warnings.append("Target process_material must be a ParticleProcessMaterial to invert velocity during rewind.")
	return warnings
