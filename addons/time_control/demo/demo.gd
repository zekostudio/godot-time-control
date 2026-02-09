extends Node2D

const ClockConfiguration = preload("res://addons/time_control/scripts/clock_configuration.gd")
const Clock = preload("res://addons/time_control/scripts/clock.gd")

@export var world_input : LineEdit
@export var player_input : LineEdit
@export var enemy_input : LineEdit
@export var environment_input : LineEdit
@export var reset_button : Button
@export var world_clock_configuration : ClockConfiguration
@export var player_clock_configuration : ClockConfiguration
@export var enemy_clock_configuration : ClockConfiguration
@export var environment_clock_configuration : ClockConfiguration


func _ready() -> void:
	world_input.focus_exited.connect(_on_input_blurred.bind(world_input, TimeController.get_clock(world_clock_configuration)))
	world_input.gui_input.connect(_on_input_enter.bind(world_input))
	player_input.focus_exited.connect(_on_input_blurred.bind(player_input, TimeController.get_clock(player_clock_configuration)))
	player_input.gui_input.connect(_on_input_enter.bind(player_input))
	enemy_input.focus_exited.connect(_on_input_blurred.bind(enemy_input, TimeController.get_clock(enemy_clock_configuration)))
	enemy_input.gui_input.connect(_on_input_enter.bind(enemy_input))
	environment_input.focus_exited.connect(_on_input_blurred.bind(environment_input, TimeController.get_clock(environment_clock_configuration)))
	environment_input.gui_input.connect(_on_input_enter.bind(environment_input))
	reset_button.pressed.connect(_on_reset_button_pressed)


func _on_clock_time_scale_change(timescale: float, clock: Clock, input: LineEdit) -> void:
	clock.local_time_scale = timescale
	if input and is_equal_approx(timescale, int(timescale)):
		input.text = str(int(timescale))

func _on_reset_button_pressed() -> void:
	TimeController.get_clock(player_clock_configuration).local_time_scale = 1.0
	TimeController.get_clock(enemy_clock_configuration).local_time_scale = 1.0
	TimeController.get_clock(environment_clock_configuration).local_time_scale = 1.0
	if world_input:
		world_input.text = "1"
	if player_input:
		player_input.text = "1"
	if enemy_input:
		enemy_input.text = "1"
	if environment_input:
		environment_input.text = "1"

func _on_input_blurred(input: LineEdit, clock: Clock) -> void:
	if input == null:
		return
	var text := input.text.strip_edges()
	if not text.is_valid_float():
		input.text = "1"
		_on_clock_time_scale_change(1.0, clock, input)
		return

	var value = clamp(text.to_float(), 0.0, 100.0)
	input.text = str(value)
	_on_clock_time_scale_change(float(value), clock, input)

func _on_input_enter(event: InputEvent, input: LineEdit) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == Key.KEY_ENTER or event.keycode == Key.KEY_KP_ENTER):
		input.release_focus()
