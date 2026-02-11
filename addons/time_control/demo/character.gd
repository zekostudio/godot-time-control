extends CharacterBody2D

const Timeline = preload("res://addons/time_control/scripts/timeline.gd")

@export var timeline: Timeline
@export var speed: float = 300.0

const JUMP_VELOCITY = -400.0

var direction: Vector2
var area_timescale_multiplier: float = 1.0

func _process(delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	if direction.x == 0:
		direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.y == 0:
		direction.y = Input.get_axis("ui_up", "ui_down")
	direction = direction.normalized()

func _physics_process(delta: float) -> void:
	velocity = Vector2(direction.x, direction.y) * speed * timeline.time_scale * area_timescale_multiplier
	move_and_slide()
