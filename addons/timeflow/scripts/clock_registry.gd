extends Object
class_name TimeflowClockRegistry

var _clocks: Dictionary[StringName, Node] = {}

func register(clock: TimeflowClock, previous: TimeflowClockConfig = null) -> void:
	if previous != null and previous.key in _clocks and _clocks[previous.key] == clock:
		_clocks.erase(previous.key)

	if clock == null:
		push_error("TimeflowClock instance cannot be null")
		return
	if clock.get_configuration() == null:
		push_error("TimeflowClock must have a configuration before registering")
		return

	var key: StringName = clock.get_configuration().key
	if key == "":
		push_error("TimeflowClock configuration key cannot be empty")
		return

	if key in _clocks and _clocks[key] != clock:
		push_error("A clock with key '%s' is already registered" % key)
		return

	_clocks[key] = clock

func unregister(clock: TimeflowClock) -> void:
	if clock == null or clock.get_configuration() == null:
		return
	var key: StringName = clock.get_configuration().key
	if key in _clocks and _clocks[key] == clock:
		_clocks.erase(key)

func has(configuration: TimeflowClockConfig) -> bool:
	if configuration == null:
		return false
	return configuration.key in _clocks

func get_by_key(key: StringName) -> TimeflowClock:
	return _clocks.get(key, null)

func get_by_configuration(configuration: TimeflowClockConfig) -> TimeflowClock:
	if configuration == null:
		return null
	return _clocks.get(configuration.key, null)

func clear() -> void:
	_clocks.clear()

func all() -> Dictionary:
	return _clocks.duplicate()
