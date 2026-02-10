extends CharacterBody2D

const Timeline = preload("res://addons/time_control/scripts/timeline.gd")

@export var timeline: Timeline
@export var speed: float = 300.0

const JUMP_VELOCITY = -400.0

signal zone_multiplier_changed(multiplier: float)

var direction: Vector2
var _zone_time_multiplier: float = 1.0

func _ready() -> void:
	zone_multiplier_changed.connect(_on_zone_multiplier_changed)

func _process(delta: float) -> void:
	direction.x = Input.get_axis("move_left", "move_right")
	if direction.x == 0:
		direction.x = Input.get_axis("ui_left", "ui_right")
	direction.y = Input.get_axis("move_up", "move_down")
	if direction.y == 0:
		direction.y = Input.get_axis("ui_up", "ui_down")
	direction = direction.normalized()

func _physics_process(delta: float) -> void:
	velocity = Vector2(direction.x, direction.y) * speed * timeline.time_scale * _zone_time_multiplier
	move_and_slide()

func _on_zone_multiplier_changed(multiplier: float) -> void:
	_zone_time_multiplier = multiplier
