extends CharacterBody2D

const Timeline = preload("res://addons/time_control/timeline.gd")

@export var timeline: Timeline

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var direction: Vector2

func _physics_process(delta: float) -> void:
	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	velocity = Vector2(direction_x, direction_y) * SPEED * timeline.time_scale
	move_and_slide()