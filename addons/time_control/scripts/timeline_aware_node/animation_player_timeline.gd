extends Node

const Timeline = preload("res://addons/time_control/scripts/timeline.gd")

@export var animation_player: AnimationPlayer
@export var timeline: Timeline

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null or animation_player == null:
		return
	animation_player.speed_scale = timeline.time_scale
