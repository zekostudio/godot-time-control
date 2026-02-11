extends Resource

class_name TimeflowClockConfig

@export var key: StringName
@export var default_local_time_scale: float = 1.0
@export var default_paused: bool = false
@export var parent_key: StringName
@export_enum("MULTIPLICATIVE", "ADDITIVE") var parent_blend_mode: int = 0
@export var min_time_scale: float = -10.0
@export var max_time_scale: float = 10.0
