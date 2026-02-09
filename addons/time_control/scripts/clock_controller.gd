extends Node

const GlobalClock := preload("res://addons/time_control/scripts/global_clock.gd")
const ClockConfiguration := preload("res://addons/time_control/scripts/clock_configuration.gd")

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

func has_clock(configuration: ClockConfiguration) -> bool:
	if configuration == null:
		push_error("Clock configuration cannot be null")
		return false
	return configuration.key in clocks

func get_clock_by_key(key: String) -> GlobalClock:
	if key not in clocks:
		push_error("Unknown global clock '%s'" % key)
		return null
	return clocks[key]

func get_clock(configuration: ClockConfiguration) -> GlobalClock:
	if configuration == null:
		push_error("Key cannot be null")
		return null
	if not has_clock(configuration):
		push_error("Unknown global clock '%s'" % configuration.key)
		return null
	return clocks[configuration.key]

func add_clock(configuration: ClockConfiguration) -> GlobalClock:
	if configuration == null:
		push_error("Key cannot be null")
		return null
	if has_clock(configuration):
		push_error("Global clock '%s' already exists" % configuration.key)
		return null
	var clock = GlobalClock.new()
	clock.key = configuration.key
	add_child(clock)
	clocks[configuration.key] = clock
	return clock

func remove_clock(configuration: ClockConfiguration) -> void:
	if configuration == null:
		push_error("Key cannot be null")
		return
	if not has_clock(configuration):
		push_error("Unknown global clock '%s'" % configuration.key)
		return
	clocks.erase(configuration.key)

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
