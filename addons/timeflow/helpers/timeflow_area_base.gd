extends Node
class_name TimeflowAreaBase

@export var timescale_multiplier: float = 0.25

var _bodies: Array = []

func _ready() -> void:
	_connect_area()
	set_deferred("monitoring", true)

func _connect_area() -> void:
	var area: Node = _get_area()
	if area == null:
		push_warning("TimeflowArea is missing an Area reference.")
		return
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _get_area() -> Node:
	# Implemented by subclasses to return Area2D or Area3D.
	return null

func _on_body_entered(body: Node) -> void:
	if body in _bodies:
		return
	_bodies.append(body)
	_apply_multiplier_to_body(body, timescale_multiplier)

func _on_body_exited(body: Node) -> void:
	if body in _bodies:
		_bodies.erase(body)
		_apply_multiplier_to_body(body, 1.0)

func _exit_tree() -> void:
	for body in _bodies:
		_apply_multiplier_to_body(body, 1.0)
	_bodies.clear()

func _apply_multiplier_to_body(body: Node, multiplier: float) -> void:
	# Preferred order:
	# 1) set_area_timescale_multiplier()
	# 2) area_timescale_multiplier property
	# Backward compatibility:
	# - set_area_timeline_multiplier()
	# - area_timeline_multiplier property
	if body.has_method("set_area_timescale_multiplier"):
		body.call("set_area_timescale_multiplier", multiplier)
		return
	if body.has_method("set_area_timeline_multiplier"):
		body.call("set_area_timeline_multiplier", multiplier)
		return
	if _has_property(body, "area_timescale_multiplier"):
		body.set("area_timescale_multiplier", multiplier)
		return
	if _has_property(body, "area_timeline_multiplier"):
		body.set("area_timeline_multiplier", multiplier)
		return

func _has_property(target: Object, property_name: StringName) -> bool:
	for property_info in target.get_property_list():
		if property_info.name == property_name:
			return true
	return false
