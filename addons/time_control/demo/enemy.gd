extends CharacterBody2D

const Timeline = preload("res://addons/time_control/scripts/timeline.gd")

@export var timeline: Timeline
@export var path_follow_2d: PathFollow2D

var _tween: Tween
var _tween_duration: float = 2.0


func _ready() -> void:
	path_follow_2d.progress_ratio = 0
	_start()

func _process(_delta: float) -> void:
	_tween.set_speed_scale(timeline.time_scale)

func _start() -> void:
	_tween = get_tree().create_tween();
	_tween.tween_property(path_follow_2d, "progress_ratio", 1.0, _tween_duration)
	_tween.set_ease(Tween.EaseType.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.set_process_mode(Tween.TweenProcessMode.TWEEN_PROCESS_PHYSICS)
	_tween.finished.connect(_on_forward_finished)

func _on_forward_finished() -> void:
	await get_tree().create_timer(1.0).timeout
	_tween = get_tree().create_tween();
	_tween.tween_property(path_follow_2d, "progress_ratio", 0.0, _tween_duration)
	_tween.set_ease(Tween.EaseType.EASE_OUT)
	_tween.set_trans(Tween.TRANS_BOUNCE)
	_tween.set_process_mode(Tween.TweenProcessMode.TWEEN_PROCESS_PHYSICS)
	_tween.finished.connect(_on_backward_finished)

func _on_backward_finished() -> void:
	await get_tree().create_timer(1.0).timeout
	_start()
