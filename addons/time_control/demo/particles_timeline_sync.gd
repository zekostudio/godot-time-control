extends GPUParticles2D

@export var timeline_path: NodePath = NodePath("../Timeline")

var _timeline: Node

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_resolve_timeline()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _timeline == null:
		_resolve_timeline()
		if _timeline == null:
			speed_scale = 1.0
			return
	speed_scale = _timeline.time_scale

func _resolve_timeline() -> void:
	if timeline_path == NodePath():
		return
	_timeline = get_node_or_null(timeline_path)
