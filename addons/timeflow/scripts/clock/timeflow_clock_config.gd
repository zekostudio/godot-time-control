extends Resource

class_name TimeflowClockConfig

const TimeflowEnums = preload("res://addons/timeflow/scripts/clock/timeflow_enums.gd")

@export var key: StringName
@export var default_local_time_scale: float = 1.0
@export var default_paused: bool = false
@export var parent_key: StringName
@export var parent_blend_mode: TimeflowEnums.TimeflowBlendMode = TimeflowEnums.TimeflowBlendMode.MULTIPLICATIVE
@export var min_time_scale: float = -10.0
@export var max_time_scale: float = 10.0
