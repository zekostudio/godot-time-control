extends TimeflowRewindable
class_name TimeflowRewindablePathFollow2D

@export var path_follow_2d: PathFollow2D
@export var clamp_progress_to_path: bool = true
@export var snap_on_discontinuity: bool = true
@export_range(0.05, 1.0, 0.01) var discontinuity_ratio: float = 0.5

func _ready() -> void:
	if path_follow_2d == null:
		var parent := get_parent()
		if parent is PathFollow2D:
			path_follow_2d = parent

func capture_timeflow_state() -> Dictionary:
	if path_follow_2d == null:
		return {}
	return {"progress": _sanitize_progress(path_follow_2d.progress)}

func apply_timeflow_state(state: Dictionary) -> void:
	if path_follow_2d == null or state.is_empty():
		return
	if state.has("progress"):
		path_follow_2d.progress = _sanitize_progress(float(state["progress"]))

func interpolate_timeflow_state(from_state: Dictionary, to_state: Dictionary, weight: float) -> Dictionary:
	if from_state.is_empty():
		return to_state.duplicate(true)
	if to_state.is_empty():
		return from_state.duplicate(true)

	var from_progress: float = _sanitize_progress(float(from_state.get("progress", 0.0)))
	var to_progress: float = _sanitize_progress(float(to_state.get("progress", from_progress)))
	var w: float = clampf(weight, 0.0, 1.0)
	if _is_discontinuous_jump(from_progress, to_progress):
		return {"progress": from_progress if w < 0.5 else to_progress}
	return {"progress": _sanitize_progress(lerpf(from_progress, to_progress, w))}

func _sanitize_progress(value: float) -> float:
	if not clamp_progress_to_path:
		return value
	var length: float = _get_path_length()
	if length <= 0.0:
		return value
	return clampf(value, 0.0, length)

func _is_discontinuous_jump(from_progress: float, to_progress: float) -> bool:
	if not snap_on_discontinuity:
		return false
	var length: float = _get_path_length()
	if length <= 0.0:
		return false
	var max_continuous_delta: float = length * clampf(discontinuity_ratio, 0.05, 1.0)
	return absf(to_progress - from_progress) > max_continuous_delta

func _get_path_length() -> float:
	if path_follow_2d == null:
		return 0.0
	var parent := path_follow_2d.get_parent()
	if parent is Path2D and parent.curve != null:
		return max(parent.curve.get_baked_length(), 0.001)
	return 0.0

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if path_follow_2d == null and not (get_parent() is PathFollow2D):
		warnings.append("Assign a PathFollow2D or place this node under a PathFollow2D parent.")
	return warnings
