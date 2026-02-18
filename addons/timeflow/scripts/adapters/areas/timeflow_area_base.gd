extends Node
class_name TimeflowAreaBase

@export var timescale_multiplier: float = 0.25

var _bodies: Array = []
var _area: Node

func _ready() -> void:
	_area = _get_area()
	_connect_area(_area)
	_set_area_monitoring(true)

func _exit_tree() -> void:
	_disconnect_area()
	for body in _bodies:
		_apply_multiplier_to_body(body, 1.0)
	_bodies.clear()

func _get_area() -> Node:
	return null

func _on_body_entered(body: Node) -> void:
	if body in _bodies:
		return
	_bodies.append(body)
	_apply_multiplier_to_body(body, timescale_multiplier)

func _on_body_exited(body: Node) -> void:
	if body not in _bodies:
		return
	_bodies.erase(body)
	_apply_multiplier_to_body(body, 1.0)

func _connect_area(area: Node) -> void:
	if area == null:
		push_warning("TimeflowArea is missing an Area reference.")
		return
	if not area.has_signal("body_entered") or not area.has_signal("body_exited"):
		push_warning("TimeflowArea reference must be an Area2D or Area3D.")
		return
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)

func _disconnect_area() -> void:
	if _area == null:
		return
	if _area.body_entered.is_connected(_on_body_entered):
		_area.body_entered.disconnect(_on_body_entered)
	if _area.body_exited.is_connected(_on_body_exited):
		_area.body_exited.disconnect(_on_body_exited)

func _set_area_monitoring(enabled: bool) -> void:
	if _area != null:
		_area.set_deferred("monitoring", enabled)

func _apply_multiplier_to_body(body: Node, multiplier: float) -> void:
	if body.has_method("set_area_timescale_multiplier"):
		body.set_area_timescale_multiplier(multiplier)
		return
	if body.has_method("set_area_timeline_multiplier"):
		body.set_area_timeline_multiplier(multiplier)
		return
	if _has_property(body, "area_timescale_multiplier"):
		body.area_timescale_multiplier = multiplier
		return
	if _has_property(body, "area_timeline_multiplier"):
		body.area_timeline_multiplier = multiplier

func _has_property(target: Object, property_name: StringName) -> bool:
	for property_info in target.get_property_list():
		if property_info.name == property_name:
			return true
	return false
