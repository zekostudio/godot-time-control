extends CharacterBody2D

const Timeline = preload("res://addons/time_control/timeline.gd")

@export var timeline: Timeline
@export var path_follow_2d: PathFollow2D

var _tween: Tween


func _ready() -> void:
	path_follow_2d.progress_ratio = 0
	_start()

func _process(_delta: float) -> void:
	_tween.set_speed_scale(timeline.time_scale)

func _start() -> void:
	_tween = get_tree().create_tween();
	_tween.tween_property(path_follow_2d, "progress_ratio", 1.0, 2.5)
	_tween.finished.connect(_on_forward_finished)

func _on_forward_finished() -> void:
	path_follow_2d.progress_ratio = 0
	_start()
