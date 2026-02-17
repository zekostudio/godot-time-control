extends Node
const TimeflowClockRegistry = preload("res://addons/timeflow/scripts/clock/timeflow_clock_registry.gd")
const UnscaledTimeSource = preload("res://addons/timeflow/scripts/core/unscaled_time_source.gd")

signal clock_registered(clock: TimeflowClock)
signal clock_unregistered(clock: TimeflowClock)
signal clock_time_scale_changed(clock: TimeflowClock, previous_time_scale: float, time_scale: float)
signal clock_rewind_started(clock: TimeflowClock, time_scale: float)
signal clock_rewind_stopped(clock: TimeflowClock, time_scale: float)

@export var debug: bool = false

var _registry = TimeflowClockRegistry.new()
var _time_source = UnscaledTimeSource.new()

func _ready() -> void:
	_time_source.reset()

func _process(_delta: float) -> void:
	_time_source.update()

func set_debug(value: bool) -> void:
	debug = value

func get_debug() -> bool:
	return debug

func has_clock(configuration: TimeflowClockConfig) -> bool:
	return _registry.has(configuration)

func has_clock_by_key(key: StringName) -> bool:
	return _registry.get_by_key(key) != null

func get_clock_by_key(key: StringName) -> TimeflowClock:
	var clock := _registry.get_by_key(key)
	if clock == null:
		push_error("Unknown global clock '%s'" % key)
	return clock

func get_clock(configuration: TimeflowClockConfig) -> TimeflowClock:
	var clock := _registry.get_by_configuration(configuration)
	if clock == null:
		clock = add_clock(configuration)
		if clock == null:
			push_error("Unknown global clock '%s'" % configuration.key)
	return clock

func register_clock(clock: TimeflowClock, previous: TimeflowClockConfig = null) -> void:
	_registry.register(clock, previous)
	_connect_clock_signals(clock)
	clock_registered.emit(clock)

func unregister_clock(clock: TimeflowClock) -> void:
	_disconnect_clock_signals(clock)
	_registry.unregister(clock)
	clock_unregistered.emit(clock)

func add_clock(configuration: TimeflowClockConfig) -> TimeflowClock:
	if configuration == null:
		push_error("TimeflowClock configuration cannot be null")
		return null

	var existing_child := _find_child_clock(configuration)
	if existing_child != null:
		if not has_clock(configuration):
			register_clock(existing_child)
		return existing_child

	if has_clock(configuration):
		return _registry.get_by_configuration(configuration)
	var clock: TimeflowClock = TimeflowClock.new() 
	clock.configuration = configuration
	add_child(clock)
	if not has_clock(configuration):
		register_clock(clock)
	return clock

func _find_child_clock(configuration: TimeflowClockConfig) -> TimeflowClock:
	for child in get_children():
		if child is TimeflowClock:
			var config: TimeflowClockConfig = child.get_configuration()
			if config != null and config.key == configuration.key:
				return child
	return null

func remove_clock(configuration: TimeflowClockConfig) -> void:
	if configuration == null:
		push_error("TimeflowClock configuration cannot be null")
		return
	var clock := _registry.get_by_configuration(configuration)
	if clock == null:
		push_error("Unknown global clock '%s'" % configuration.key)
		return
	unregister_clock(clock)
	clock.queue_free()

func _connect_clock_signals(clock: TimeflowClock) -> void:
	if clock == null:
		return
	var time_scale_changed_callback := Callable(self, "_on_clock_time_scale_changed").bind(clock)
	var rewind_started_callback := Callable(self, "_on_clock_rewind_started").bind(clock)
	var rewind_stopped_callback := Callable(self, "_on_clock_rewind_stopped").bind(clock)
	if not clock.time_scale_changed.is_connected(time_scale_changed_callback):
		clock.time_scale_changed.connect(time_scale_changed_callback)
	if not clock.rewind_started.is_connected(rewind_started_callback):
		clock.rewind_started.connect(rewind_started_callback)
	if not clock.rewind_stopped.is_connected(rewind_stopped_callback):
		clock.rewind_stopped.connect(rewind_stopped_callback)

func _disconnect_clock_signals(clock: TimeflowClock) -> void:
	if clock == null or not is_instance_valid(clock):
		return
	var time_scale_changed_callback := Callable(self, "_on_clock_time_scale_changed").bind(clock)
	var rewind_started_callback := Callable(self, "_on_clock_rewind_started").bind(clock)
	var rewind_stopped_callback := Callable(self, "_on_clock_rewind_stopped").bind(clock)
	if clock.time_scale_changed.is_connected(time_scale_changed_callback):
		clock.time_scale_changed.disconnect(time_scale_changed_callback)
	if clock.rewind_started.is_connected(rewind_started_callback):
		clock.rewind_started.disconnect(rewind_started_callback)
	if clock.rewind_stopped.is_connected(rewind_stopped_callback):
		clock.rewind_stopped.disconnect(rewind_stopped_callback)

func _on_clock_time_scale_changed(previous_time_scale: float, time_scale: float, clock: TimeflowClock) -> void:
	clock_time_scale_changed.emit(clock, previous_time_scale, time_scale)

func _on_clock_rewind_started(time_scale: float, clock: TimeflowClock) -> void:
	clock_rewind_started.emit(clock, time_scale)

func _on_clock_rewind_stopped(time_scale: float, clock: TimeflowClock) -> void:
	clock_rewind_stopped.emit(clock, time_scale)

static func get_time_state(time_scale: float) -> String:
	if time_scale < 0.0:
		return "Reversed"
	if time_scale == 0.0:
		return "Paused"
	if time_scale < 1.0:
		return "Slowed"
	if time_scale == 1.0:
		return "Normal"
	return "Accelerated"

func get_unscaled_delta_time() -> float:
	return _time_source.get_unscaled_delta_time()
