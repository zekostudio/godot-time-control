extends RefCounted

class_name TimeflowSnapshotBuffer

var _capacity: int = 2
var _entries: Array = []
var _head: int = 0
var _size: int = 0

func _init(capacity: int = 2) -> void:
	configure(capacity)

func configure(capacity: int) -> void:
	_capacity = maxi(2, capacity)
	_entries.resize(_capacity)
	for i in range(_capacity):
		_entries[i] = null
	_head = 0
	_size = 0

func clear() -> void:
	for i in range(_capacity):
		_entries[i] = null
	_head = 0
	_size = 0

func capacity() -> int:
	return _capacity

func size() -> int:
	return _size

func is_empty() -> bool:
	return _size == 0

func push(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	if _size < _capacity:
		var insert_index: int = (_head + _size) % _capacity
		_entries[insert_index] = snapshot
		_size += 1
		return

	_entries[_head] = snapshot
	_head = (_head + 1) % _capacity

func get_oldest() -> Dictionary:
	if _size == 0:
		return {}
	var value = _entries[_head]
	return value if value is Dictionary else {}

func get_newest() -> Dictionary:
	if _size == 0:
		return {}
	var index: int = (_head + _size - 1) % _capacity
	var value = _entries[index]
	return value if value is Dictionary else {}

func get_at(index_from_oldest: int) -> Dictionary:
	if index_from_oldest < 0 or index_from_oldest >= _size:
		return {}
	var index: int = (_head + index_from_oldest) % _capacity
	var value = _entries[index]
	return value if value is Dictionary else {}

func sample(sample_time: float) -> Dictionary:
	if _size == 0:
		return {}
	if _size == 1:
		var only := get_oldest()
		return {"from": only, "to": only, "alpha": 0.0}

	var oldest := get_oldest()
	var newest := get_newest()
	var oldest_time: float = float(oldest.get("t", 0.0))
	var newest_time: float = float(newest.get("t", oldest_time))

	if sample_time <= oldest_time:
		return {"from": oldest, "to": oldest, "alpha": 0.0}
	if sample_time >= newest_time:
		return {"from": newest, "to": newest, "alpha": 0.0}

	for i in range(_size - 1):
		var left := get_at(i)
		var right := get_at(i + 1)
		if left.is_empty() or right.is_empty():
			continue
		var left_time: float = float(left.get("t", oldest_time))
		var right_time: float = float(right.get("t", left_time))
		if sample_time >= left_time and sample_time <= right_time:
			var span := right_time - left_time
			var alpha: float = 0.0 if is_zero_approx(span) else (sample_time - left_time) / span
			return {"from": left, "to": right, "alpha": clampf(alpha, 0.0, 1.0)}

	return {"from": newest, "to": newest, "alpha": 0.0}
