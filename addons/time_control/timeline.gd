extends Node

enum ModeEnum {Global, Local}

const Clock = preload("./clock.gd")
const Timeline = preload("./timeline.gd")

signal register_timeline(timeline: Timeline)

signal unregister_timeline(timeline: Timeline)

@export var mode: ModeEnum
@export var local_clock: Clock
@export var globalClockKey: String 

var clock: Clock
var timeScale: float
var lastTimeScale: float
var deltaTime: float
var physicsDeltaTime: float
var time: float
var unscaledTime: float

func _init():
	timeScale = 1
	lastTimeScale = 1
	
func _ready():
	clock = find_clock()
	timeScale = clock.timeScale
	lastTimeScale = clock.timeScale
	
func _process(_delta):
	lastTimeScale = timeScale
	timeScale = clock.timeScale

	var unscaledDeltaTime = TimeController.get_unscaled_delta_time();
	time += deltaTime;

	
func _physics_process(_delta):
	var unscaledDeltaTime = TimeController.get_unscaled_delta_time();
	physicsDeltaTime = get_physics_process_delta_time() * timeScale;
	unscaledTime += unscaledDeltaTime;
	
func find_clock():
	match mode:
		ModeEnum.Global:
			var oldGlobalClock = clock;
			if (oldGlobalClock != null):
				oldGlobalClock.unregister_timeline(self)
			
			if (!TimeController.has_clock(globalClockKey)):
				push_error("Missing global clock for timeline")
			
			var globalClock = TimeController.get_clock(globalClockKey)
			globalClock.register_timeline(self)
 
			clock = globalClock
			
			return globalClock
		ModeEnum.Local: 
			assert(local_clock != null, "Missing local clock for timeline")
			clock = local_clock
			return local_clock
		_:
			push_error("Unknown clock mode")
