extends MarginContainer
class_name DemoHudShowcase

const TimeflowRecorder = preload("res://addons/timeflow/scripts/rewind/timeflow_recorder.gd")

enum DemoPreset {
	NORMAL_FLOW,
	GLOBAL_SLOW_MOTION,
	PLAYER_ACCELERATED,
	REWIND,
	ENVIRONMENT_BURST,
	GLOBAL_ACCELERATION,
}

@export var clock_controls: DemoHudClockControls
@export var showcase_label: Label
@export var normal_preset_button: Button
@export var slow_preset_button: Button
@export var rewind_preset_button: Button
@export var acceleration_preset_button: Button
@export var run_showcase_on_start: bool = true
@export var showcase_loop: bool = true
@export var showcase_step_duration: float = 2.2
@export var stop_showcase_on_manual_input: bool = true

var _showcase_tween: Tween
var _showcase_active: bool = false
var _preset_buttons: Dictionary = {}
var _rewind_recorders: Array[TimeflowRecorder] = []
var _rewind_button_base_text: String = "Rewind"

func _ready() -> void:
	if clock_controls != null and not clock_controls.manual_override_requested.is_connected(_on_manual_override):
		clock_controls.manual_override_requested.connect(_on_manual_override)
	if clock_controls != null and not clock_controls.default_timescale_restored.is_connected(_on_default_timescale_restored):
		clock_controls.default_timescale_restored.connect(_on_default_timescale_restored)
	_connect_preset_buttons()
	_bind_rewind_recorders()
	_set_selected_preset(DemoPreset.NORMAL_FLOW)
	_update_rewind_button_text()
	if showcase_label != null:
		showcase_label.visible = run_showcase_on_start
	if run_showcase_on_start:
		call_deferred("_run_showcase")

func _process(_delta: float) -> void:
	_update_rewind_button_text()

func _run_showcase() -> void:
	if _showcase_active:
		return
	_showcase_active = true
	var preset_order: Array[int] = [
		DemoPreset.NORMAL_FLOW,
		DemoPreset.GLOBAL_SLOW_MOTION,
		DemoPreset.PLAYER_ACCELERATED,
		DemoPreset.REWIND,
		DemoPreset.ENVIRONMENT_BURST,
		DemoPreset.GLOBAL_ACCELERATION,
	]
	while _showcase_active:
		for preset in preset_order:
			await _showcase_phase(int(preset))
			if not _showcase_active:
				break
		if not showcase_loop:
			break
	_showcase_active = false

func _showcase_phase(preset: int) -> void:
	if not _showcase_active:
		return
	_apply_preset(preset)
	await get_tree().create_timer(showcase_step_duration).timeout

func _apply_preset(preset: int) -> void:
	if clock_controls == null:
		return
	var preset_data: Dictionary = _get_preset_data(preset)
	if preset_data.is_empty():
		return
	_set_selected_preset(preset)
	clock_controls.apply_scales(
		float(preset_data["world"]),
		float(preset_data["player"]),
		float(preset_data["enemy"]),
		float(preset_data["environment"])
	)
	_animate_showcase_label(
		str(preset_data["title"]),
		preset_data["color"],
		float(preset_data["label_scale"])
	)

func _get_preset_data(preset: int) -> Dictionary:
	match preset:
		DemoPreset.NORMAL_FLOW:
			return {"title": "Normal Flow", "world": 1.0, "player": 1.0, "enemy": 1.0, "environment": 1.0, "color": Color(1, 1, 1, 1), "label_scale": 1.1}
		DemoPreset.GLOBAL_SLOW_MOTION:
			return {"title": "Global Slow Motion", "world": 0.1, "player": 1.0, "enemy": 1.0, "environment": 1.0, "color": Color(0.65, 0.9, 1.0, 1.0), "label_scale": 1.2}
		DemoPreset.GLOBAL_ACCELERATION:
			return {"title": "Global Acceleration", "world": 1.0, "player": 1.0, "enemy": 4.0, "environment": 6.0, "color": Color(1.0, 0.72, 0.58, 1.0), "label_scale": 1.2}
		DemoPreset.REWIND:
			return {"title": "Enemy Rewind", "world": -4.0, "player": 1.0, "enemy": 1.0, "environment": 1.0, "color": Color(0.5, 0.92, 1.0, 1.0), "label_scale": 1.3}
		_:
			return {}

func _animate_showcase_label(text_value: String, text_color: Color, target_scale: float) -> void:
	if showcase_label == null:
		return
	showcase_label.visible = true
	showcase_label.text = "Demo: %s" % text_value
	if _showcase_tween != null:
		_showcase_tween.kill()
	showcase_label.modulate = Color(1, 1, 1, 0.65)
	showcase_label.scale = Vector2.ONE
	_showcase_tween = create_tween()
	_showcase_tween.parallel().tween_property(showcase_label, "modulate", text_color, 0.25)
	_showcase_tween.parallel().tween_property(showcase_label, "scale", Vector2.ONE * target_scale, 0.25)
	_showcase_tween.tween_property(showcase_label, "scale", Vector2.ONE, 0.35)
	_showcase_tween.parallel().tween_property(showcase_label, "modulate", text_color.lightened(0.08), 0.35)

func _connect_preset_buttons() -> void:
	_connect_preset_button(normal_preset_button, DemoPreset.NORMAL_FLOW)
	_connect_preset_button(slow_preset_button, DemoPreset.GLOBAL_SLOW_MOTION)
	_connect_preset_button(rewind_preset_button, DemoPreset.REWIND)
	_connect_preset_button(acceleration_preset_button, DemoPreset.GLOBAL_ACCELERATION)

func _connect_preset_button(button: Button, preset: int) -> void:
	if button == null:
		return
	button.toggle_mode = true
	_preset_buttons[preset] = button
	var callback := Callable(self, "_on_preset_button_pressed").bind(preset)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _bind_rewind_recorders() -> void:
	_rewind_recorders.clear()
	if rewind_preset_button != null:
		_rewind_button_base_text = rewind_preset_button.text
	if clock_controls == null:
		return
	_try_add_rewind_recorder(clock_controls.player_recorder)
	_try_add_rewind_recorder(clock_controls.moon_1_recorder)
	_try_add_rewind_recorder(clock_controls.moon_2_recorder)
	_try_add_rewind_recorder(clock_controls.moon_3_recorder)
	_try_add_rewind_recorder(clock_controls.environment_recorder)

func _try_add_rewind_recorder(candidate: Node) -> void:
	var recorder := candidate as TimeflowRecorder
	if recorder == null:
		return
	if _rewind_recorders.has(recorder):
		return
	_rewind_recorders.append(recorder)

func _update_rewind_button_text() -> void:
	if rewind_preset_button == null:
		return
	if _rewind_recorders.is_empty():
		rewind_preset_button.text = _rewind_button_base_text
		return
	var min_remaining: float = INF
	for recorder in _rewind_recorders:
		if recorder == null:
			continue
		min_remaining = minf(min_remaining, recorder.get_remaining_rewind_seconds())
	if min_remaining == INF:
		rewind_preset_button.text = _rewind_button_base_text
		return
	rewind_preset_button.text = "%s (%ss)" % [_rewind_button_base_text, int(ceili(min_remaining))]

func _set_selected_preset(selected_preset: int) -> void:
	for preset in _preset_buttons.keys():
		var button: Button = _preset_buttons[preset]
		if button == null:
			continue
		button.button_pressed = int(preset) == selected_preset

func _on_preset_button_pressed(preset: int) -> void:
	_stop_showcase_for_manual_override()
	_apply_preset(preset)

func _on_manual_override() -> void:
	_stop_showcase_for_manual_override()

func _on_default_timescale_restored() -> void:
	_set_selected_preset(DemoPreset.NORMAL_FLOW)

func _stop_showcase_for_manual_override() -> void:
	if not stop_showcase_on_manual_input:
		return
	if not _showcase_active:
		return
	_showcase_active = false
	showcase_loop = false
	if _showcase_tween != null:
		_showcase_tween.kill()
	if showcase_label != null:
		showcase_label.text = "Demo: Manual control"
		showcase_label.modulate = Color(1, 1, 1, 1)
		showcase_label.scale = Vector2.ONE
