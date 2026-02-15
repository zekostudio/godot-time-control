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

var _tween: Tween
var _rewind_vfx_tween: Tween
var area_timescale_multiplier: float = 1.0
var _base_modulate: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	_base_modulate = modulate
	_bind_recorder()
	path_follow_2d.progress = _ratio_to_progress(tween_start_ratio)
	_start()

func _process(_delta: float) -> void:
	if _tween:
		_tween.set_speed_scale(timeline.time_scale * area_timescale_multiplier)

func _start() -> void:
	_tween = get_tree().create_tween();
	_tween.tween_property(path_follow_2d, "progress", _ratio_to_progress(tween_end_ratio), tween_duration)
	_tween.set_ease(Tween.EaseType.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BOUNCE)
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
	_tween.set_trans(Tween.TRANS_BOUNCE)
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
	if timeline == null:
		return
	var effective_scale := _get_effective_time_scale()
	if effective_scale <= 0.0:
		await get_tree().process_frame
		effective_scale = _get_effective_time_scale()
	if effective_scale <= 0.0:
		return
	_restart_tween_from_current_progress()

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

func _get_effective_time_scale() -> float:
	if timeline == null:
		return 1.0
	if timeline.clock != null:
		return timeline.clock.time_scale
	return timeline.time_scale
