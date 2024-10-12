extends Node

const GlobalClock := preload("./global_clock.gd")

var lastUpdated: float = Time.get_ticks_usec()
var unscaledDeltaTime: float

# Declare member variables here.
@export var _debug: bool = false
@export var _clocks: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is GlobalClock:
			_clocks[child.key] = child
			
func _process(_delta):
	var now = Time.get_ticks_usec()
	unscaledDeltaTime = now - lastUpdated
	lastUpdated = now

# Properties
func set_debug(value):
	_debug = value

func get_debug():
	return _debug

# Clocks
func has_clock(key: String) -> bool:
	if key == null:
		push_error("Key cannot be null")
		return false
	return key in _clocks

func get_clock(key: String) -> GlobalClock:
	if key == null:
		push_error("Key cannot be null")
		return null
	if not has_clock(key):
		push_error("Unknown global clock '%s'" % key)
		return null
	return _clocks[key]

func add_clock(key: String) -> GlobalClock:
	if key == null:
		push_error("Key cannot be null")
		return null
	if has_clock(key):
		push_error("Global clock '%s' already exists" % key)
		return null
	var clock = GlobalClock.new()
	clock.key = key
	add_child(clock)
	_clocks[key] = clock
	return clock

func remove_clock(key: String):
	if key == null:
		push_error("Key cannot be null")
		return
	if not has_clock(key):
		push_error("Unknown global clock '%s'" % key)
		return
	_clocks.erase(key)

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
	return min(unscaledDeltaTime / 1000000, 0.02)
