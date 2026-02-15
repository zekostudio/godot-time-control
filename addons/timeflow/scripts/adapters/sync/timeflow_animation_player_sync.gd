extends Node
class_name TimeflowAnimationPlayerSync

const TimeflowTimeline = preload("res://addons/timeflow/scripts/clock/timeflow_timeline.gd")

@export var animation_player: AnimationPlayer
@export var timeline: TimeflowTimeline

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null or animation_player == null:
		return
	animation_player.speed_scale = timeline.time_scale
