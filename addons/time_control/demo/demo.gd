extends Node2D

const ClockConfiguration = preload("res://addons/time_control/clock_configuration.gd")

@export var player_00_button : Button
@export var player_05_button : Button
@export var player_10_button : Button
@export var player_20_button : Button
@export var enemy_00_button : Button
@export var enemy_05_button : Button
@export var enemy_10_button : Button
@export var enemy_20_button : Button
@export var reset_button : Button
@export var player_clock_configuration : ClockConfiguration
@export var enemy_clock_configuration : ClockConfiguration

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_00_button.pressed.connect(_on_player_time_scale_change.bind(0))
	player_05_button.pressed.connect(_on_player_time_scale_change.bind(0.5))
	player_10_button.pressed.connect(_on_player_time_scale_change.bind(1))
	player_20_button.pressed.connect(_on_player_time_scale_change.bind(2))
	enemy_00_button.pressed.connect(_on_enemy_time_scale_change.bind(0))
	enemy_05_button.pressed.connect(_on_enemy_time_scale_change.bind(0.5))
	enemy_10_button.pressed.connect(_on_enemy_time_scale_change.bind(1))
	enemy_20_button.pressed.connect(_on_enemy_time_scale_change.bind(2))
	reset_button.pressed.connect(_on_reset_button_pressed)

func _on_player_time_scale_change(timescale: float) -> void:
	ClockController.get_clock(player_clock_configuration).local_time_scale = timescale


func _on_enemy_time_scale_change(timescale: float) -> void:
	ClockController.get_clock(enemy_clock_configuration).local_time_scale = timescale

func _on_reset_button_pressed() -> void:
	ClockController.get_clock(player_clock_configuration).local_time_scale = 1.0
	ClockController.get_clock(enemy_clock_configuration).local_time_scale = 1.0
