@tool
extends EditorPlugin

const AUTOLOAD_NAME = "TimeController"

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/time_control/time_control.tscn")
	add_custom_type("TimeController", "Node", preload("res://addons/time_control/time_controller.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("Timeline", "Node", preload("res://addons/time_control/timeline.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("Clock", "Node", preload("res://addons/time_control/clock.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("GlobalClock", "Node", preload("res://addons/time_control/global_clock.gd"), preload("res://addons/time_control/time_control.svg"))
 

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.  
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_custom_type("TimeController")
	remove_custom_type("Timeline") 
	remove_custom_type("Clock") 
	remove_custom_type("GlobalClock")
	pass
  