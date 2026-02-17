extends CharacterBody2D

enum LoopReturnMode { MIRROR, WRAP_FROM_ZERO, WRAP_FROM_ONE }

const TimeflowRecorder = preload("res://addons/timeflow/scripts/rewind/timeflow_recorder.gd")

@export var timeline: TimeflowTimeline
@export var path_follow_2d: PathFollow2D
@export var recorder: TimeflowRecorder
@export var tween_duration: float = 3.0
@export var tween_loop: bool = false
@export_range(0.0, 1.0, 0.001) var tween_start_ratio: float = 0.0
@export_range(0.0, 1.0, 0.001) var tween_end_ratio: float = 1.0
@export var loop_return_mode: LoopReturnMode = LoopReturnMode.MIRROR
@export var enable_rewind_visuals: bool = true
@export var rewind_tint: Color = Color(0.45, 0.8, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var rewind_tint_strength: float = 0.6
@export_range(0.5, 20.0, 0.1) var rewind_pulse_speed: float = 8.0
@export var impact_impulse_scale: float = 0.65
@export var impact_impulse_max: float = 300.0
@export var external_damping: float = 7.0
@export var external_mass: float = 1.5

var _tween: Tween
var _rewind_vfx_tween: Tween
var area_timescale_multiplier: float = 1.0
var _base_modulate: Color = Color(1, 1, 1, 1)
var _external_velocity: Vector2 = Vector2.ZERO
var _detached_from_path_follow: bool = false


func _ready() -> void:
	_base_modulate = modulate
	_bind_timeline()
	_bind_recorder()
	path_follow_2d.progress = _ratio_to_progress(tween_start_ratio)
	_start()

func _exit_tree() -> void:
	_unbind_timeline()

func _physics_process(delta: float) -> void:
	if path_follow_2d == null:
		return
	var path_motion: Vector2 = Vector2.ZERO
	if not _detached_from_path_follow:
		var target_position: Vector2 = path_follow_2d.global_position
		path_motion = target_position - global_position
	_external_velocity = _external_velocity.move_toward(Vector2.ZERO, external_damping * delta)
	var motion: Vector2 = path_motion + (_external_velocity * delta)
	if motion.length_squared() <= 0.000001:
		if not _detached_from_path_follow:
			rotation = path_follow_2d.global_rotation
		return
	var collision: KinematicCollision2D = move_and_collide(motion)
	if collision != null:
		_transfer_collision_impulse(collision, delta)
	if not _detached_from_path_follow:
		rotation = path_follow_2d.global_rotation

func apply_external_impulse(impulse: Vector2) -> void:
	_external_velocity += impulse / maxf(external_mass, 0.001)

func set_area_timescale_multiplier(multiplier: float) -> void:
	area_timescale_multiplier = multiplier
	_apply_tween_speed()

func detach_from_path_follow() -> void:
	if _detached_from_path_follow:
		return
	_detached_from_path_follow = true
	_disable_remote_position_drivers()

func _transfer_collision_impulse(collision: KinematicCollision2D, delta: float) -> void:
	var collider := collision.get_collider()
	if collider == null or not collider.has_method("apply_external_impulse"):
		return
	var push_direction: Vector2 = -collision.get_normal().normalized()
	var impact_speed: float = maxf(0.0, (collision.get_travel() / maxf(delta, 0.0001)).dot(push_direction))
	var impulse_strength: float = minf(impact_speed * impact_impulse_scale, impact_impulse_max)
	if impulse_strength <= 0.0:
		return
	var impulse: Vector2 = push_direction * impulse_strength
	collider.apply_external_impulse(impulse)
	apply_external_impulse(-impulse)

func _disable_remote_position_drivers() -> void:
	if path_follow_2d == null:
		return
	for child in path_follow_2d.get_children():
		var remote := child as RemoteTransform2D
		if remote == null:
			continue
		remote.update_position = false
		remote.update_rotation = false
		remote.update_scale = false
		remote.remote_path = NodePath("")

func _start() -> void:
	_tween = get_tree().create_tween();
	_apply_tween_speed()
	_tween.tween_property(path_follow_2d, "progress", _ratio_to_progress(tween_end_ratio), tween_duration)
	_tween.set_ease(Tween.EaseType.EASE_IN)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.finished.connect(_on_forward_finished)

func _on_forward_finished() -> void:
	if not tween_loop:
		path_follow_2d.progress = _ratio_to_progress(tween_start_ratio)
		_start()
		return
	match loop_return_mode:
		LoopReturnMode.WRAP_FROM_ZERO:
			path_follow_2d.progress = 0.0
		LoopReturnMode.WRAP_FROM_ONE:
			path_follow_2d.progress = _get_path_length()
	_tween = get_tree().create_tween();
	_tween.tween_property(path_follow_2d, "progress", _ratio_to_progress(tween_start_ratio), tween_duration)
	_tween.set_ease(Tween.EaseType.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.finished.connect(_on_backward_finished)

func _on_backward_finished() -> void:
	_start()

func _get_path_length() -> float:
	var parent := path_follow_2d.get_parent()
	if parent is Path2D and parent.curve != null:
		return max(parent.curve.get_baked_length(), 0.001)
	return 1.0

func _ratio_to_progress(ratio: float) -> float:
	return clampf(ratio, 0.0, 1.0) * _get_path_length()

func _on_rewind_started() -> void:
	if _tween != null:
		_tween.pause()
	_start_rewind_vfx()

func _on_rewind_stopped() -> void:
	_stop_rewind_vfx()
	await get_tree().process_frame
	_try_resume_tween_if_forward_time()

func _restart_tween_from_current_progress() -> void:
	if path_follow_2d == null:
		return
	if _tween != null:
		_tween.kill()

	var current_progress: float = path_follow_2d.progress
	var end_progress: float = _ratio_to_progress(tween_end_ratio)
	var full_span: float = absf(end_progress - _ratio_to_progress(tween_start_ratio))
	var remaining_span: float = absf(end_progress - current_progress)
	var duration: float = tween_duration
	if full_span > 0.0001:
		duration = maxf(remaining_span / full_span * tween_duration, 0.01)
	_tween = get_tree().create_tween()
	_apply_tween_speed()
	_tween.tween_property(path_follow_2d, "progress", end_progress, duration)
	_tween.set_ease(Tween.EaseType.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.finished.connect(_on_forward_finished)

func _start_rewind_vfx() -> void:
	if not enable_rewind_visuals:
		return
	if _rewind_vfx_tween != null:
		_rewind_vfx_tween.kill()

	var pulse_half_duration: float = maxf(0.05, 0.5 / rewind_pulse_speed)
	var tinted: Color = _base_modulate.lerp(rewind_tint, clampf(rewind_tint_strength, 0.0, 1.0))
	_rewind_vfx_tween = get_tree().create_tween()
	_rewind_vfx_tween.set_loops()
	_rewind_vfx_tween.tween_property(self, "modulate", tinted, pulse_half_duration)
	_rewind_vfx_tween.tween_property(self, "modulate", _base_modulate, pulse_half_duration)

func _stop_rewind_vfx() -> void:
	if _rewind_vfx_tween != null:
		_rewind_vfx_tween.kill()
		_rewind_vfx_tween = null
	modulate = _base_modulate

func _bind_recorder() -> void:
	if recorder == null:
		return
	if not recorder.rewind_started.is_connected(_on_rewind_started):
		recorder.rewind_started.connect(_on_rewind_started)
	if not recorder.rewind_stopped.is_connected(_on_rewind_stopped):
		recorder.rewind_stopped.connect(_on_rewind_stopped)

func _bind_timeline() -> void:
	if timeline == null:
		return
	if not timeline.time_scale_changed.is_connected(_on_timeline_time_scale_changed):
		timeline.time_scale_changed.connect(_on_timeline_time_scale_changed)

func _unbind_timeline() -> void:
	if timeline == null:
		return
	if timeline.time_scale_changed.is_connected(_on_timeline_time_scale_changed):
		timeline.time_scale_changed.disconnect(_on_timeline_time_scale_changed)

func _on_timeline_time_scale_changed(_previous_time_scale: float, _next_time_scale: float) -> void:
	_apply_tween_speed()
	if _previous_time_scale < 0.0 and _next_time_scale >= 0.0:
		_try_resume_tween_if_forward_time()

func _apply_tween_speed() -> void:
	if _tween == null or timeline == null:
		return
	_tween.set_speed_scale(timeline.time_scale * area_timescale_multiplier)

func _try_resume_tween_if_forward_time() -> void:
	if timeline == null:
		return
	if _get_effective_time_scale() <= 0.0:
		return
	_restart_tween_from_current_progress()

func _get_effective_time_scale() -> float:
	if timeline == null:
		return 1.0
	if timeline.clock != null:
		return timeline.clock.time_scale
	return timeline.time_scale
