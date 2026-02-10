@tool
extends EditorPlugin

const AUTOLOAD_NAME = "TimeController"
const SETTINGS_AUTOLOAD_PATH = "addons/time_control/autoload_path"

static var _instance: EditorPlugin


func _init() -> void:
	_instance = self


static func instance() -> EditorPlugin:
	return _instance

func _enter_tree() -> void:
	_add_settings() 

	add_autoload_singleton(AUTOLOAD_NAME, ProjectSettings.get_setting(SETTINGS_AUTOLOAD_PATH))
	add_custom_type("TimeController", "Node", preload("res://addons/time_control/scripts/time_controller.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("Timeline", "Node", preload("res://addons/time_control/scripts/timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("Clock", "Node", preload("res://addons/time_control/scripts/clock.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("ClockConfiguration", "Resource", preload("res://addons/time_control/scripts/clock_configuration.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("GPUParticles2DTimeline", "Node", preload("res://addons/time_control/scripts/timeline_aware_node/gpu_particles_2d_timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("GPUParticles3DTimeline", "Node", preload("res://addons/time_control/scripts/timeline_aware_node/gpu_particles_3d_timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("AnimationPlayerTimeline", "Node", preload("res://addons/time_control/scripts/timeline_aware_node/animation_player_timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("Area2DTimeline", "Node", preload("res://addons/time_control/scripts/timeline_aware_node/area2D_timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
	add_custom_type("Area3DTimeline", "Node", preload("res://addons/time_control/scripts/timeline_aware_node/area3D_timeline.gd"), preload("res://addons/time_control/icons/time_control.svg"))
 
func _add_settings() -> void:
	_add_setting(SETTINGS_AUTOLOAD_PATH, TYPE_STRING, "res://addons/time_control/scenes/time_control.tscn")


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
	remove_custom_type("TimeController")
	remove_custom_type("Timeline") 
	remove_custom_type("Clock") 
	remove_custom_type("ClockConfiguration")
	remove_custom_type("GPUParticles2DTimeline")
	remove_custom_type("GPUParticles3DTimeline")
	remove_custom_type("AnimationPlayerTimeline")
	remove_custom_type("Area2DTimeline")
	remove_custom_type("Area3DTimeline")
	ProjectSettings.set(SETTINGS_AUTOLOAD_PATH, null)
