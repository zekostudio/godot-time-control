extends CharacterBody2D

enum LoopReturnMode { MIRROR, WRAP_FROM_ZERO, WRAP_FROM_ONE }

@export var timeline: TimeflowTimeline
@export var path_follow_2d: PathFollow2D
@export var tween_duration: float = 3.0
@export var tween_loop: bool = false
@export_range(0.0, 1.0, 0.001) var tween_start_ratio: float = 0.0
@export_range(0.0, 1.0, 0.001) var tween_end_ratio: float = 1.0
@export var loop_return_mode: LoopReturnMode = LoopReturnMode.MIRROR

var _tween: Tween
var area_timescale_multiplier: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
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
