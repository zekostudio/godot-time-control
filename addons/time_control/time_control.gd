@tool
extends EditorPlugin

const AUTOLOAD_NAME = "ClockController"
const SETTINGS_AUTOLOAD_PATH = "addons/time_control/autoload_path"

static var _instance: EditorPlugin


func _init() -> void:
	_instance = self


static func instance() -> EditorPlugin:
	return _instance

func _enter_tree() -> void:
	_add_settings() 

	add_autoload_singleton(AUTOLOAD_NAME, ProjectSettings.get_setting(SETTINGS_AUTOLOAD_PATH))
	add_custom_type("ClockController", "Node", preload("res://addons/time_control/clock_controller.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("Timeline", "Node", preload("res://addons/time_control/timeline.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("Clock", "Node", preload("res://addons/time_control/clock.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("GlobalClock", "Node", preload("res://addons/time_control/global_clock.gd"), preload("res://addons/time_control/time_control.svg"))
	add_custom_type("ClockConfiguration", "Resource", preload("res://addons/time_control/clock_configuration.gd"), preload("res://addons/time_control/time_control.svg"))
 
func _add_settings() -> void:
	_add_setting(SETTINGS_AUTOLOAD_PATH, TYPE_STRING, "res://addons/time_control/time_control.tscn")


func _add_setting(_name: String, type: int, value) -> void:
	if !ProjectSettings.has_setting(_name):
		ProjectSettings.set_setting(_name, value)

	ProjectSettings.add_property_info({
		"name": _name,
		"type": type
	})
	ProjectSettings.set_initial_value(_name, value)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.  
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_custom_type("ClockController")
	remove_custom_type("Timeline") 
	remove_custom_type("Clock") 
	remove_custom_type("GlobalClock")
	remove_custom_type("ClockConfiguration")
	ProjectSettings.set(SETTINGS_AUTOLOAD_PATH, null)