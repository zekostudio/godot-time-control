extends Node
class_name TimeflowRecorder

const TimeflowSnapshotBuffer = preload("res://addons/timeflow/scripts/timeflow_snapshot_buffer.gd")
const TimeflowTimeline = preload("res://addons/timeflow/scripts/timeflow_timeline.gd")
const TimeflowRewindable = preload("res://addons/timeflow/scripts/timeflow_rewindable.gd")

signal rewind_started
signal rewind_stopped
signal rewind_exhausted

@export var timeline: TimeflowTimeline
@export var rewindables: Array[TimeflowRewindable] = []
@export_range(1.0, 600.0, 0.5, "or_greater") var recording_duration: float = 10.0
@export_range(0.01, 1.0, 0.01, "or_greater") var recording_interval: float = 0.05
@export var record_when_paused: bool = false
@export var auto_add_parent_rewindable: bool = true

var _buffer := TimeflowSnapshotBuffer.new()
var _record_accumulator: float = 0.0
var _rewind_sample_time: float = 0.0
var _is_rewinding: bool = false
var _emitted_exhausted: bool = false
var _last_buffer_capacity: int = -1

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if auto_add_parent_rewindable:
		_try_add_parent_rewindable()
	_ensure_buffer_capacity(true)
	_record_snapshot()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if timeline == null:
		return

	_ensure_buffer_capacity()
	var effective_time_scale: float = _get_effective_time_scale()

	if effective_time_scale < 0.0:
		_step_rewind(delta, effective_time_scale)
		return

	_stop_rewind_if_needed()
	if is_zero_approx(effective_time_scale) and not record_when_paused:
		return

	_record_accumulator += delta
	while _record_accumulator >= recording_interval:
		_record_accumulator -= recording_interval
		_record_snapshot()

func _step_rewind(delta: float, time_scale: float) -> void:
	if _buffer.is_empty():
		return

	if not _is_rewinding:
		_is_rewinding = true
		_emitted_exhausted = false
		_rewind_sample_time = float(_buffer.get_newest().get("t", timeline.unscaled_time))
		_notify_rewind_started()
		rewind_started.emit()

	_rewind_sample_time -= delta * absf(time_scale)

	var oldest_time: float = float(_buffer.get_oldest().get("t", _rewind_sample_time))
	if _rewind_sample_time <= oldest_time:
		_end_rewind(true)
		if not _emitted_exhausted:
			_emitted_exhausted = true
			_notify_rewind_exhausted()
			rewind_exhausted.emit()
		return
	_emitted_exhausted = false

	var segment: Dictionary = _buffer.sample(_rewind_sample_time)
	if segment.is_empty():
		return
	_apply_segment(segment)

func _apply_segment(segment: Dictionary) -> void:
	var from_snapshot: Dictionary = segment.get("from", {})
	var to_snapshot: Dictionary = segment.get("to", from_snapshot)
	var alpha: float = float(segment.get("alpha", 0.0))
	var from_states: Array = from_snapshot.get("states", [])
	var to_states: Array = to_snapshot.get("states", from_states)

	for i in range(rewindables.size()):
		var rewindable: TimeflowRewindable = rewindables[i]
		if rewindable == null:
			continue

		var from_state = from_states[i] if i < from_states.size() else {}
		var to_state = to_states[i] if i < to_states.size() else from_state
		if from_state == null and to_state == null:
			continue
		if from_state == null:
			from_state = to_state
		if to_state == null:
			to_state = from_state
		if not (from_state is Dictionary) or not (to_state is Dictionary):
			continue

		var state_to_apply: Dictionary = rewindable.interpolate_timeflow_state(from_state, to_state, alpha)
		rewindable.apply_timeflow_state(state_to_apply)

func _record_snapshot() -> void:
	if timeline == null:
		return
	if rewindables.is_empty():
		return

	var states: Array = []
	for rewindable in rewindables:
		if rewindable == null:
			states.append({})
			continue
		states.append(rewindable.capture_timeflow_state())

	_buffer.push({
		"t": timeline.unscaled_time,
		"states": states,
	})

func _ensure_buffer_capacity(force: bool = false) -> void:
	var snapshot_count: int = maxi(2, int(ceil(recording_duration / recording_interval)) + 1)
	if force or snapshot_count != _last_buffer_capacity:
		_last_buffer_capacity = snapshot_count
		_buffer.configure(snapshot_count)
		_record_accumulator = 0.0
		_end_rewind(false)

func _stop_rewind_if_needed() -> void:
	if not _is_rewinding:
		return
	_end_rewind(true)

func _try_add_parent_rewindable() -> void:
	var parent := get_parent()
	if parent == null or not (parent is TimeflowRewindable):
		return
	var parent_rewindable: TimeflowRewindable = parent
	if not rewindables.has(parent_rewindable):
		rewindables.append(parent_rewindable)

func _notify_rewind_started() -> void:
	for rewindable in rewindables:
		var typed_rewindable: TimeflowRewindable = rewindable
		if typed_rewindable == null:
			continue
		typed_rewindable.on_timeflow_rewind_started()

func _notify_rewind_stopped() -> void:
	for rewindable in rewindables:
		var typed_rewindable: TimeflowRewindable = rewindable
		if typed_rewindable == null:
			continue
		typed_rewindable.on_timeflow_rewind_stopped()

func _notify_rewind_exhausted() -> void:
	for rewindable in rewindables:
		var typed_rewindable: TimeflowRewindable = rewindable
		if typed_rewindable == null:
			continue
		typed_rewindable.on_timeflow_rewind_exhausted()

func _end_rewind(clear_history: bool) -> void:
	if _is_rewinding:
		_is_rewinding = false
		_notify_rewind_stopped()
		rewind_stopped.emit()

	if clear_history:
		_reset_history()

func _reset_history() -> void:
	_buffer.clear()
	_record_accumulator = 0.0
	_emitted_exhausted = false
	if timeline != null:
		_rewind_sample_time = timeline.unscaled_time
	_record_snapshot()

func _get_effective_time_scale() -> float:
	if timeline == null:
		return 1.0
	if timeline.clock != null:
		return timeline.clock.time_scale
	return timeline.time_scale

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if timeline == null:
		warnings.append("Assign a TimeflowTimeline to drive rewind/record direction.")
	if recording_interval <= 0.0:
		warnings.append("recording_interval must be greater than 0.")
	if recording_duration <= recording_interval:
		warnings.append("recording_duration should be greater than recording_interval.")
	if rewindables.is_empty() and not auto_add_parent_rewindable:
		warnings.append("Assign at least one rewindable node or enable auto_add_parent_rewindable.")
	return warnings
