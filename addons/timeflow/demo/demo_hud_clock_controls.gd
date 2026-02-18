extends Control
class_name DemoHudClockControls

signal manual_override_requested
signal default_timescale_restored

@export var world_input: LineEdit
@export var player_input: LineEdit
@export var moon_1_input: LineEdit
@export var moon_2_input: LineEdit
@export var moon_3_input: LineEdit
@export var environment_input: LineEdit
@export var reset_button: Button
@export var rewind_texture: ColorRect
@export var player_recorder: Node
@export var moon_1_recorder: Node
@export var moon_2_recorder: Node
@export var moon_3_recorder: Node
@export var environment_recorder: Node
@export var restore_default_timescale_on_rewind_end: bool = true
@export var world_clock_configuration: TimeflowClockConfig
@export var player_clock_configuration: TimeflowClockConfig
@export var moon_1_clock_configuration: TimeflowClockConfig
@export var moon_2_clock_configuration: TimeflowClockConfig
@export var moon_3_clock_configuration: TimeflowClockConfig
@export var environment_clock_configuration: TimeflowClockConfig

var _active_rewinds: Dictionary = {}

func _ready() -> void:
	_bind_input(world_input, world_clock_configuration)
	_bind_input(player_input, player_clock_configuration)
	_bind_input(moon_1_input, moon_1_clock_configuration)
	_bind_input(moon_2_input, moon_2_clock_configuration)
	_bind_input(moon_3_input, moon_3_clock_configuration)
	_bind_input(environment_input, environment_clock_configuration)
	if reset_button != null and not reset_button.pressed.is_connected(_on_reset_button_pressed):
		reset_button.pressed.connect(_on_reset_button_pressed)
	if rewind_texture != null:
		rewind_texture.visible = false
	_bind_rewind_recorder(player_recorder)
	_bind_rewind_recorder(moon_1_recorder)
	_bind_rewind_recorder(moon_2_recorder)
	_bind_rewind_recorder(moon_3_recorder)
	_bind_rewind_recorder(environment_recorder)

func apply_scales(world_scale: float, player_scale: float, moon_scale: float, environment_scale: float) -> void:
	_set_clock_scale(world_clock_configuration, world_scale, world_input)
	_set_clock_scale(player_clock_configuration, player_scale, player_input)
	_set_clock_scale(moon_1_clock_configuration, moon_scale, moon_1_input)
	_set_clock_scale(moon_2_clock_configuration, moon_scale, moon_2_input)
	_set_clock_scale(moon_3_clock_configuration, moon_scale, moon_3_input)
	_set_clock_scale(environment_clock_configuration, environment_scale, environment_input)

func reset_to_default() -> void:
	apply_scales(1.0, 1.0, 1.0, 1.0)
	default_timescale_restored.emit()

func _bind_input(input: LineEdit, configuration: TimeflowClockConfig) -> void:
	if input == null:
		return
	input.focus_mode = Control.FOCUS_CLICK
	input.focus_exited.connect(_on_input_blurred.bind(input, configuration))
	input.gui_input.connect(_on_input_enter.bind(input))
	input.text_submitted.connect(_on_input_submitted.bind(input))

func _set_clock_scale(configuration: TimeflowClockConfig, timescale: float, input: LineEdit) -> void:
	var clock := Timeflow.get_clock(configuration)
	if clock == null:
		return
	clock.local_time_scale = timescale
	if input != null:
		input.text = _format_scale(timescale)

func _on_reset_button_pressed() -> void:
	manual_override_requested.emit()
	reset_to_default()

func _on_input_blurred(input: LineEdit, configuration: TimeflowClockConfig) -> void:
	manual_override_requested.emit()
	if input == null:
		return
	var clock := Timeflow.get_clock(configuration)
	if clock == null:
		return

	var text := input.text.strip_edges()
	if not text.is_valid_float():
		_set_clock_scale(configuration, 1.0, input)
		return

	var value := clampf(text.to_float(), clock.configuration.min_time_scale, clock.configuration.max_time_scale)
	_set_clock_scale(configuration, value, input)

func _on_input_enter(event: InputEvent, input: LineEdit) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == Key.KEY_ENTER or event.keycode == Key.KEY_KP_ENTER):
		input.call_deferred("release_focus")

func _on_input_submitted(_text: String, input: LineEdit) -> void:
	input.call_deferred("release_focus")

func _format_scale(scale_value: float) -> String:
	if is_equal_approx(scale_value, roundf(scale_value)):
		return str(int(roundf(scale_value)))
	return "%.2f" % scale_value

func _bind_rewind_recorder(recorder: Node) -> void:
	if recorder == null:
		return
	if not recorder.has_signal("rewind_started") or not recorder.has_signal("rewind_stopped"):
		return
	var started_callback := Callable(self, "_on_rewind_started").bind(recorder)
	var stopped_callback := Callable(self, "_on_rewind_stopped").bind(recorder)
	if not recorder.is_connected("rewind_started", started_callback):
		recorder.connect("rewind_started", started_callback)
	if not recorder.is_connected("rewind_stopped", stopped_callback):
		recorder.connect("rewind_stopped", stopped_callback)

func _on_rewind_started(recorder: Node) -> void:
	_active_rewinds[recorder.get_instance_id()] = true
	_update_rewind_texture_visibility()

func _on_rewind_stopped(recorder: Node) -> void:
	_active_rewinds.erase(recorder.get_instance_id())
	_update_rewind_texture_visibility()
	if restore_default_timescale_on_rewind_end and _active_rewinds.is_empty():
		reset_to_default()

func _update_rewind_texture_visibility() -> void:
	if rewind_texture == null:
		return
	rewind_texture.visible = not _active_rewinds.is_empty()
