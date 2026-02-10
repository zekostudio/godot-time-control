extends "res://addons/time_control/scripts/timeline_aware_node/area_timeline_base.gd"

@export var area3D: Area3D

func _get_area() -> Node:
	return area3D
