extends Node

@export var timescale_multiplier: float = 0.25

var _bodies: Array = []

func _ready() -> void:
	_connect_area()
	set_deferred("monitoring", true)

func _connect_area() -> void:
	var area: Node = _get_area()
	if area == null:
		push_warning("AreaTimeline is missing an Area reference.")
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
	if body.has_signal("zone_multiplier_changed"):
		body.zone_multiplier_changed.emit(timescale_multiplier)

func _on_body_exited(body: Node) -> void:
	if body in _bodies:
		_bodies.erase(body)
		if body.has_signal("zone_multiplier_changed"):
			body.zone_multiplier_changed.emit(1.0)

func _exit_tree() -> void:
	for body in _bodies:
		if body.has_signal("zone_multiplier_changed"):
			body.zone_multiplier_changed.emit(1.0)
	_bodies.clear()
