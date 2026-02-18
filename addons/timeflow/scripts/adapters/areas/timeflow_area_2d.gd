extends TimeflowAreaBase
class_name TimeflowArea2D

@export var area2D: Area2D
@export var use_distance_lerp: bool = false
@export_enum("From Center", "From Collision Shape") var distance_lerp_mode: int = 0
@export_range(0.001, 4096.0, 0.1, "or_greater") var distance_lerp_range: float = 128.0

func _get_area() -> Node:
	return area2D

func _on_body_entered(body: Node) -> void:
	if body in _bodies:
		return
	_bodies.append(body)
	_apply_multiplier_to_body(body, _get_body_multiplier(body))

func _physics_process(_delta: float) -> void:
	if not use_distance_lerp:
		return
	for i in range(_bodies.size() - 1, -1, -1):
		var body: Node = _bodies[i]
		if not is_instance_valid(body):
			_bodies.remove_at(i)
			continue
		_apply_multiplier_to_body(body, _get_body_multiplier(body))

func _get_body_multiplier(body: Node) -> float:
	if not use_distance_lerp:
		return timescale_multiplier

	var body_2d := body as Node2D
	if body_2d == null:
		return timescale_multiplier

	var point: Vector2 = body_2d.global_position
	var proximity: float = _center_proximity(point) if distance_lerp_mode == 0 else _shape_proximity(point)
	return lerpf(1.0, timescale_multiplier, proximity)

func _center_proximity(point: Vector2) -> float:
	if area2D == null:
		return 1.0
	var dist: float = area2D.global_position.distance_to(point)
	return clampf(1.0 - (dist / maxf(distance_lerp_range, 0.001)), 0.0, 1.0)

func _shape_proximity(point: Vector2) -> float:
	var shape_data: Dictionary = _closest_shape_boundary_data(point)
	var boundary_distance: float = shape_data.get("distance", -1.0)
	if boundary_distance < 0.0:
		return _center_proximity(point)

	var lerp_range: float = maxf(distance_lerp_range, 0.001)
	var max_depth: float = shape_data.get("max_depth", -1.0)
	if lerp_range <= 1.0 and max_depth > 0.0:
		return clampf(boundary_distance / maxf(max_depth * lerp_range, 0.001), 0.0, 1.0)
	return clampf(boundary_distance / lerp_range, 0.0, 1.0)

func _closest_shape_boundary_data(point: Vector2) -> Dictionary:
	if area2D == null:
		return {"distance": -1.0, "max_depth": -1.0}

	var best_distance: float = INF
	var best_max_depth: float = -1.0
	for child in area2D.find_children("*", "CollisionShape2D", true, false):
		var collider := child as CollisionShape2D
		if collider == null or collider.disabled or collider.shape == null:
			continue
		var shape_distance: float = _distance_to_shape_boundary(collider, point)
		if shape_distance < 0.0:
			continue
		if shape_distance < best_distance:
			best_distance = shape_distance
			best_max_depth = _shape_max_depth(collider)

	if best_distance < INF:
		return {"distance": best_distance, "max_depth": best_max_depth}
	return {"distance": -1.0, "max_depth": -1.0}

func _distance_to_shape_boundary(collider: CollisionShape2D, world_point: Vector2) -> float:
	var local_point: Vector2 = collider.global_transform.affine_inverse() * world_point
	var shape := collider.shape

	if shape is CircleShape2D:
		var circle: CircleShape2D = shape
		return absf(local_point.length() - circle.radius)

	if shape is RectangleShape2D:
		var rectangle: RectangleShape2D = shape
		var half_size: Vector2 = rectangle.size * 0.5
		var q: Vector2 = Vector2(absf(local_point.x), absf(local_point.y)) - half_size
		var outside: Vector2 = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0))
		var signed_distance: float = outside.length() + minf(maxf(q.x, q.y), 0.0)
		return absf(signed_distance)

	return -1.0

func _shape_max_depth(collider: CollisionShape2D) -> float:
	var shape := collider.shape
	if shape is CircleShape2D:
		var circle: CircleShape2D = shape
		return circle.radius
	if shape is RectangleShape2D:
		var rectangle: RectangleShape2D = shape
		var half_size: Vector2 = rectangle.size * 0.5
		return minf(half_size.x, half_size.y)
	return -1.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if area2D == null:
		warnings.append("Assign an Area2D reference.")
	if use_distance_lerp and distance_lerp_mode == 1 and area2D != null:
		var has_supported_shape: bool = false
		for child in area2D.find_children("*", "CollisionShape2D", true, false):
			var collider := child as CollisionShape2D
			if collider == null or collider.shape == null or collider.disabled:
				continue
			if collider.shape is CircleShape2D or collider.shape is RectangleShape2D:
				has_supported_shape = true
				break
		if not has_supported_shape:
			warnings.append("Collision-shape lerp currently supports CircleShape2D and RectangleShape2D. Falling back to center distance.")
	return warnings
