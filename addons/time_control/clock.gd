extends Node

enum BlendModeEnum {Additive, Multiplicative}

const GlobalClock := preload("./global_clock.gd")
const Clock := preload("./clock.gd")
const Timeline := preload("./timeline.gd")

@export var localTimeScale: float = 1
@export var timeScale: float = 1 
var time: float
var unscaledTime: float  
var deltaTime: float
var physicsDeltaTime: float
var startTime: float
@export var paused: bool = false
@export var parentKey: String
@export var parentBlend: BlendModeEnum = BlendModeEnum.Multiplicative
var parent: GlobalClock 
 
func _ready():
	assert(TimeController != null, "Missing TimeController in scene")
	await TimeController.ready
	if (!parentKey.is_empty() && TimeController.has_clock(parentKey)):
		parent = TimeController.get_clock(parentKey);
	calculateTimeScale()

func _process(_delta):
	calculateTimeScale()
	var unscaledDeltaTime = TimeController.get_unscaled_delta_time()
	deltaTime = unscaledDeltaTime * timeScale;
	physicsDeltaTime = get_physics_process_delta_time() * timeScale;
	time += deltaTime;
	unscaledTime += unscaledDeltaTime;

func calculateTimeScale():
	if (paused): 
		timeScale = 0;
		return
	 
	if (parent == null):
		timeScale = localTimeScale;
		return
	
	if (parentBlend == BlendModeEnum.Multiplicative):
		timeScale = parent.timeScale * localTimeScale
	else:
		timeScale = parent.timeScale + localTimeScale;
