extends CharacterBody2D

@export var timeline: TimeflowTimeline
@export var speed: float = 300.0
@export var keep_inside_screen: bool = true

const JUMP_VELOCITY = -400.0

var direction: Vector2
var area_timescale_multiplier: float = 1.0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

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
	if keep_inside_screen:
		_clamp_to_visible_world()

func _clamp_to_visible_world() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return

	var visible_rect: Rect2 = viewport.get_visible_rect()
	var inverse_canvas: Transform2D = viewport.get_canvas_transform().affine_inverse()
	var top_left: Vector2 = inverse_canvas * visible_rect.position
	var bottom_right: Vector2 = inverse_canvas * (visible_rect.position + visible_rect.size)
	var margin: float = _collision_margin()

	global_position = Vector2(
		clampf(global_position.x, top_left.x + margin, bottom_right.x - margin),
		clampf(global_position.y, top_left.y + margin, bottom_right.y - margin)
	)

func _collision_margin() -> float:
	if collision_shape_2d == null or collision_shape_2d.shape == null:
		return 0.0

	if collision_shape_2d.shape is CircleShape2D:
		var circle_shape := collision_shape_2d.shape as CircleShape2D
		var scale_factor: float = maxf(absf(collision_shape_2d.global_scale.x), absf(collision_shape_2d.global_scale.y))
		return circle_shape.radius * scale_factor

	return 0.0
