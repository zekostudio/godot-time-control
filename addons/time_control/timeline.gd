extends Node

enum ModeEnum {Global, Local}

const Clock = preload("res://addons/time_control/clock.gd")
const Timeline = preload("res://addons/time_control/timeline.gd")
const ClockConfiguration = preload("res://addons/time_control/clock_configuration.gd")

signal register_timeline(timeline: Timeline)
signal unregister_timeline(timeline: Timeline)

@export var mode: ModeEnum
@export var local_clock: Clock
@export var global_clock_configuration: ClockConfiguration

var clock: Clock
var time_scale: float
var last_time_scale: float
var delta_time: float
var physics_delta_time: float
var time: float
var unscaled_time: float

func _init():
	time_scale = 1
	last_time_scale = 1
	
func _ready():
	clock = find_clock()
	time_scale = clock.get_time_scale()
	last_time_scale = clock.get_time_scale()
	
func _process(_delta): 
	last_time_scale = time_scale
	time_scale = clock.get_time_scale()

	var unscaled_delta_time = ClockController.get_unscaled_delta_time(); 
	time += delta_time;

	
func _physics_process(_delta):
	var unscaled_delta_time = ClockController.get_unscaled_delta_time();
	physics_delta_time = get_physics_process_delta_time() * time_scale;
	unscaled_time += unscaled_delta_time;
	
func find_clock():
	match mode:
		ModeEnum.Global:
			var previous_global_clock = clock;
			if (previous_global_clock != null):
				previous_global_clock.unregister_timeline(self)
			
			if (!ClockController.has_clock(global_clock_configuration)):
				push_error("Missing global clock for timeline")
			
			var global_clock = ClockController.get_clock(global_clock_configuration)
			global_clock.register_timeline(self)
 
			clock = global_clock
			
			return global_clock
		ModeEnum.Local: 
			assert(local_clock != null, "Missing local clock for timeline")
			clock = local_clock
			return local_clock
		_:
			push_error("Unknown clock mode")
