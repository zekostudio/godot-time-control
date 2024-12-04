extends Node

enum BlendModeEnum {Additive, Multiplicative}

const ClockConfiguration := preload("res://addons/time_control/clock_configuration.gd")
const GlobalClock := preload("res://addons/time_control/global_clock.gd")
const Clock := preload("res://addons/time_control/clock.gd")
const Timeline := preload("res://addons/time_control/timeline.gd")

@export var local_time_scale: float = 1:
	set(value):
		if ClockController.debug: 
			print("Set clock %s time scale to %f" % [self, value])
		local_time_scale = value
@export var paused: bool = false 
@export var parent_clock_configuration: ClockConfiguration
@export var parent_blend_mode: BlendModeEnum = BlendModeEnum.Multiplicative
 
var _time_scale: float = 1
 
var time: float
var unscaled_time: float  
var delta_time: float
var physics_delta_time: float
var parent: GlobalClock 
  
func _ready():
	assert(ClockController != null, "Missing ClockController in scene")

	await ClockController.ready

	if parent_clock_configuration != null && ClockController.has_clock(parent_clock_configuration):
		parent = ClockController.get_clock(parent_clock_configuration);
	calculate_time_scale() 

func _process(_delta):
	calculate_time_scale()
	var unscaled_delta_time = ClockController.get_unscaled_delta_time()
	delta_time = unscaled_delta_time * _time_scale;
	physics_delta_time = get_physics_process_delta_time() * _time_scale;
	time += delta_time;
	unscaled_time += unscaled_delta_time;

func calculate_time_scale():
	if paused:
		_time_scale = 0;
		return
	 
	if parent == null:
		_time_scale = local_time_scale;
		return
	
	if parent_blend_mode == BlendModeEnum.Multiplicative:
		_time_scale = parent.get_time_scale() * local_time_scale
	else:
		_time_scale = parent.get_time_scale() + local_time_scale;

func get_time_scale() -> float:
	return _time_scale