extends Node

@export var area2D : Area2D
@export var timescale_multiplier : float = 0.25

var _bodies: Array = []

func _ready() -> void:
	area2D.body_entered.connect(_on_body_entered)
	area2D.body_exited.connect(_on_body_exited)
	set_deferred("monitoring", true)

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
