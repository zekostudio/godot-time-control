extends Object

var _last_ticks_usec: int = 0
var _unscaled_delta_time: float = 0.0

func reset() -> void:
	_last_ticks_usec = Time.get_ticks_usec()
	_unscaled_delta_time = 0.0

func update() -> void:
	var now := Time.get_ticks_usec()
	_unscaled_delta_time = clamp((now - _last_ticks_usec) / 1_000_000.0, 0.0, 0.05)
	_last_ticks_usec = now

func get_unscaled_delta_time() -> float:
	return _unscaled_delta_time
