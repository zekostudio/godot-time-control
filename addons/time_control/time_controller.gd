extends Node

const GlobalClock := preload("res://addons/time_control/global_clock.gd")
const ClockConfiguration := preload("res://addons/time_control/clock_configuration.gd")

@export var debug: bool = false
@export var clocks: Dictionary

var last_updated: float = Time.get_ticks_usec()
var unscaled_delta_time: float

func _ready():
	for child in get_children():
		if child is GlobalClock:
			clocks[child.configuration.key] = child
			
func _process(_delta):
	var now = Time.get_ticks_usec()
	unscaled_delta_time = now - last_updated
	last_updated = now

func set_debug(value):
	debug = value 

func get_debug():
	return debug

func has_clock(clock_configuration: ClockConfiguration) -> bool:
	if clock_configuration == null:
		push_error("Clock configuration cannot be null")
		return false
	return clock_configuration.key in clocks

func get_clock_by_key(key: String) -> GlobalClock:
	if key not in clocks:
		push_error("Unknown global clock '%s'" % key)
		return null
	return clocks[key]

func get_clock(clock_configuration: ClockConfiguration) -> GlobalClock:
	if clock_configuration == null:
		push_error("Key cannot be null")
		return null
	if not has_clock(clock_configuration):
		push_error("Unknown global clock '%s'" % clock_configuration.key)
		return null
	return clocks[clock_configuration.key]

func add_clock(clock_configuration: ClockConfiguration) -> GlobalClock:
	if clock_configuration == null:
		push_error("Key cannot be null")
		return null
	if has_clock(clock_configuration):
		push_error("Global clock '%s' already exists" % clock_configuration.key)
		return null
	var clock = GlobalClock.new()
	clock.key = clock_configuration.key
	add_child(clock)
	clocks[clock_configuration.key] = clock
	return clock

func remove_clock(clock_configuration: ClockConfiguration):
	if clock_configuration == null:
		push_error("Key cannot be null")
		return
	if not has_clock(clock_configuration):
		push_error("Unknown global clock '%s'" % clock_configuration.key)
		return
	clocks.erase(clock_configuration.key)

# Internal static methods
static func get_time_state(time_scale: float) -> String:
	if time_scale < 0:
		return "Reversed"
	elif time_scale == 0:
		return "Paused"
	elif time_scale < 1:
		return "Slowed"
	elif time_scale == 1:
		return "Normal"
	else:  # if time_scale > 1
		return "Accelerated"

func get_unscaled_delta_time() -> float:
	return min(unscaled_delta_time / 1000000, 0.02)
