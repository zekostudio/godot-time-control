@tool
extends EditorPlugin

const AUTOLOAD_NAME: String = "Timeflow"
const SETTINGS_AUTOLOAD_PATH: String = "addons/timeflow/autoload_path"
const DEFAULT_AUTOLOAD_SCENE_PATH: String = "res://addons/timeflow/timeflow.tscn"

static var _instance: EditorPlugin

func _init() -> void:
	_instance = self

static func instance() -> EditorPlugin:
	return _instance

func _enter_tree() -> void:
	_add_settings()
	add_autoload_singleton(AUTOLOAD_NAME, ProjectSettings.get_setting(SETTINGS_AUTOLOAD_PATH))

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)

func _add_settings() -> void:
	_add_setting(SETTINGS_AUTOLOAD_PATH, TYPE_STRING, DEFAULT_AUTOLOAD_SCENE_PATH)

func _add_setting(name: String, type: int, value: Variant) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, value)

	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
	})
	ProjectSettings.set_initial_value(name, value)
