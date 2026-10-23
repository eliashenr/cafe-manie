class_name NeighborVisits
extends RefCounted
## Visitas aos vizinhos (DT-074): o último dia (local) em que cada um foi visitado e a amizade com ele.

signal changed

## id -> dia local da última visita (GameClock.local_day()).
var _last_day := {}
## id -> corações de amizade.
var _friendship := {}


func visited_on(id: StringName, day: int) -> bool:
	return int(_last_day.get(id, -1)) == day


func friendship(id: StringName) -> int:
	return int(_friendship.get(id, 0))


## Marca a visita do dia e soma um coração (até [param max_friendship]).
func record(id: StringName, day: int, max_friendship: int) -> void:
	_last_day[id] = day
	_friendship[id] = mini(friendship(id) + 1, max_friendship)
	changed.emit()


func to_data() -> Dictionary:
	var data := {}
	for id: StringName in _last_day:
		data[String(id)] = {"day": _last_day[id], "friendship": friendship(id)}
	return data


func restore(data: Dictionary) -> void:
	_last_day.clear()
	_friendship.clear()
	for key in data:
		var entry: Variant = data[key]
		if entry is Dictionary:
			var id := StringName(str(key))
			_last_day[id] = int(entry.get("day", -1))
			_friendship[id] = maxi(0, int(entry.get("friendship", 0)))
	changed.emit()
