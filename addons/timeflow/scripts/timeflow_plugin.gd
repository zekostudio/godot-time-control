@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Timeflow"
const SETTINGS_AUTOLOAD_PATH = "addons/timeflow/autoload_path"

static var _instance: EditorPlugin


func _init() -> void:
	_instance = self


static func instance() -> EditorPlugin:
	return _instance

func _enter_tree() -> void:
	_add_settings() 

	add_autoload_singleton(AUTOLOAD_NAME, ProjectSettings.get_setting(SETTINGS_AUTOLOAD_PATH))
 
func _add_settings() -> void:
	_add_setting(SETTINGS_AUTOLOAD_PATH, TYPE_STRING, "res://addons/timeflow/timeflow.tscn")


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
	ProjectSettings.set(SETTINGS_AUTOLOAD_PATH, null)
