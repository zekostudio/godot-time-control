extends Node

class_name TimeflowRewindable

func capture_timeflow_state() -> Dictionary:
	return {}

func apply_timeflow_state(_state: Dictionary) -> void:
	pass

func interpolate_timeflow_state(from_state: Dictionary, to_state: Dictionary, weight: float) -> Dictionary:
	if from_state.is_empty():
		return to_state.duplicate(true)
	if to_state.is_empty():
		return from_state.duplicate(true)
	return from_state if weight < 0.5 else to_state

func on_timeflow_rewind_started() -> void:
	pass

func on_timeflow_rewind_stopped() -> void:
	pass

func on_timeflow_rewind_exhausted() -> void:
	pass
