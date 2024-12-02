extends "res://addons/time_control/clock.gd"


@export var configuration: ClockConfiguration

var clocks: Array = [] 
var timelines: Array[Timeline] = []
 
func _init():
	clocks = [] 
	timelines = []  

func register_timeline(timeline: Timeline): 
	if timeline == null:
		push_error("Timeline cannot be null") 
		return
	if timeline not in timelines:
		timelines.append(timeline) 

func unregister_timeline(timeline: Timeline):
	if timeline == null:
		push_error("Timeline cannot be null") 
		return
	if timeline in timelines:
		timelines.erase(timeline)

func register_clock(clock: Clock):
	if clock == null: 
		push_error("Clock cannot be null")
		return
	if clock not in clocks: 
		clocks.append(clock)  

func unregister_clock(clock: Clock): 
	if clock == null:
		push_error("Clock cannot be null") 
		return
	if clock in clocks:
		clocks.erase(clock)
