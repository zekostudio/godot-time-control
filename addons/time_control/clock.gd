extends Node

enum BlendModeEnum {Additive, Multiplicative}

const ClockConfiguration := preload("./clock_configuration.gd")
const GlobalClock := preload("./global_clock.gd")
const Clock := preload("./clock.gd")
const Timeline := preload("./timeline.gd")

@export var local_time_scale: float = 1:
	set(value):
		if TimeController.debug:
			print("Set clock %s time scale to %f", [self, value])
		local_time_scale = value
@export var paused: bool = false 
@export var parent_clock_configuration: ClockConfiguration
@export var parent_blend_mode: BlendModeEnum = BlendModeEnum.Multiplicative

var time_scale: float = 1
 
var time: float
var unscaled_time: float  
var delta_time: float
var physics_delta_time: float
var parent: GlobalClock 
 
func _ready():
	assert(TimeController != null, "Missing TimeController in scene")

	await TimeController.ready

	if (!parent_clock_configuration != null && TimeController.has_clock(parent_clock_configuration)):
		parent = TimeController.get_clock(parent_clock_configuration);
	calculate_time_scale() 

func _process(_delta):
	calculate_time_scale()
	var unscaled_delta_time = TimeController.get_unscaled_delta_time()
	delta_time = unscaled_delta_time * time_scale;
	physics_delta_time = get_physics_process_delta_time() * time_scale;
	time += delta_time;
	unscaled_time += unscaled_delta_time;

func calculate_time_scale():
	if paused:
		time_scale = 0;
		return
	 
	if parent == null:
		time_scale = local_time_scale;
		return
	
	if parent_blend_mode == BlendModeEnum.Multiplicative:
		time_scale = parent.time_scale * local_time_scale
	else:
		time_scale = parent.time_scale + local_time_scale;
