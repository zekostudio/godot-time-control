extends TimeflowRewindable

class_name TimeflowRewindable2D

const TimeflowTimeline = preload("res://addons/timeflow/scripts/clock/timeflow_timeline.gd")

@export var target: Node2D
@export var use_global_transform: bool = false
@export var include_scale: bool = true
@export var include_visibility: bool = false
@export var disable_target_processing_while_rewinding: bool = true
@export var lock_target_while_negative_after_rewind_exhausted: bool = false
@export var timeline: TimeflowTimeline

var _was_processing: bool = false
var _was_physics_processing: bool = false
var _was_input_processing: bool = false
var _was_unhandled_input_processing: bool = false
var _freeze_was_processing: bool = false
var _freeze_was_physics_processing: bool = false
var _freeze_was_input_processing: bool = false
var _freeze_was_unhandled_input_processing: bool = false
var _has_freeze_snapshot: bool = false
var _is_locked_after_exhaustion: bool = false

func _ready() -> void:
	if target == null:
		var parent := get_parent()
		if parent is Node2D:
			target = parent
	if timeline == null and target != null:
		var target_timeline = target.get("timeline")
		if target_timeline is TimeflowTimeline:
			timeline = target_timeline

func _process(_delta: float) -> void:
	if not _is_locked_after_exhaustion:
		return
	if _get_effective_time_scale() > 0.0:
		_unlock_after_exhaustion()

func capture_timeflow_state() -> Dictionary:
	if target == null:
		return {}

	var state: Dictionary = {}
	if use_global_transform:
		state["position"] = target.global_position
		state["rotation"] = target.global_rotation
		if include_scale:
			state["scale"] = target.global_scale
	else:
		state["position"] = target.position
		state["rotation"] = target.rotation
		if include_scale:
			state["scale"] = target.scale

	if include_visibility:
		state["visible"] = target.visible
	return state

func apply_timeflow_state(state: Dictionary) -> void:
	if target == null or state.is_empty():
		return

	if use_global_transform:
		if state.has("position"):
			target.global_position = state["position"]
		if state.has("rotation"):
			target.global_rotation = state["rotation"]
		if include_scale and state.has("scale"):
			target.global_scale = state["scale"]
	else:
		if state.has("position"):
			target.position = state["position"]
		if state.has("rotation"):
			target.rotation = state["rotation"]
		if include_scale and state.has("scale"):
			target.scale = state["scale"]

	if include_visibility and state.has("visible"):
		target.visible = bool(state["visible"])

func interpolate_timeflow_state(from_state: Dictionary, to_state: Dictionary, weight: float) -> Dictionary:
	if from_state.is_empty():
		return to_state.duplicate(true)
	if to_state.is_empty():
		return from_state.duplicate(true)

	var w: float = clampf(weight, 0.0, 1.0)
	var interpolated: Dictionary = {}

	var from_position: Vector2 = from_state.get("position", Vector2.ZERO)
	var to_position: Vector2 = to_state.get("position", from_position)
	interpolated["position"] = from_position.lerp(to_position, w)

	var from_rotation: float = float(from_state.get("rotation", 0.0))
	var to_rotation: float = float(to_state.get("rotation", from_rotation))
	interpolated["rotation"] = lerp_angle(from_rotation, to_rotation, w)

	if include_scale:
		var from_scale: Vector2 = from_state.get("scale", Vector2.ONE)
		var to_scale: Vector2 = to_state.get("scale", from_scale)
		interpolated["scale"] = from_scale.lerp(to_scale, w)

	if include_visibility:
		interpolated["visible"] = from_state.get("visible", true) if w < 0.5 else to_state.get("visible", true)

	return interpolated

func on_timeflow_rewind_started() -> void:
	if target == null or not disable_target_processing_while_rewinding:
		return
	_was_processing = target.is_processing()
	_was_physics_processing = target.is_physics_processing()
	_was_input_processing = target.is_processing_input()
	_was_unhandled_input_processing = target.is_processing_unhandled_input()
	target.set_process(false)
	target.set_physics_process(false)
	target.set_process_input(false)
	target.set_process_unhandled_input(false)

func on_timeflow_rewind_stopped() -> void:
	if target == null or not disable_target_processing_while_rewinding:
		return
	target.set_process(_was_processing)
	target.set_physics_process(_was_physics_processing)
	target.set_process_input(_was_input_processing)
	target.set_process_unhandled_input(_was_unhandled_input_processing)

func on_timeflow_rewind_exhausted() -> void:
	if target == null or not lock_target_while_negative_after_rewind_exhausted:
		return
	if not _has_freeze_snapshot:
		_freeze_was_processing = target.is_processing()
		_freeze_was_physics_processing = target.is_physics_processing()
		_freeze_was_input_processing = target.is_processing_input()
		_freeze_was_unhandled_input_processing = target.is_processing_unhandled_input()
		_has_freeze_snapshot = true
	_set_target_processing(false)
	_is_locked_after_exhaustion = true

func _unlock_after_exhaustion() -> void:
	if target == null or not _has_freeze_snapshot:
		_is_locked_after_exhaustion = false
		return
	target.set_process(_freeze_was_processing)
	target.set_physics_process(_freeze_was_physics_processing)
	target.set_process_input(_freeze_was_input_processing)
	target.set_process_unhandled_input(_freeze_was_unhandled_input_processing)
	_has_freeze_snapshot = false
	_is_locked_after_exhaustion = false

func _set_target_processing(enabled: bool) -> void:
	if target == null:
		return
	target.set_process(enabled)
	target.set_physics_process(enabled)
	target.set_process_input(enabled)
	target.set_process_unhandled_input(enabled)

func _get_effective_time_scale() -> float:
	if timeline == null:
		return 1.0
	if timeline.clock != null:
		return timeline.clock.time_scale
	return timeline.time_scale

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if target == null and not (get_parent() is Node2D):
		warnings.append("Assign a Node2D target or place this node under a Node2D parent.")
	if lock_target_while_negative_after_rewind_exhausted and timeline == null:
		warnings.append("Assign a TimeflowTimeline (or a target.timeline) to unlock after rewind exhaustion when time becomes positive.")
	return warnings
