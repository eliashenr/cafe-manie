class_name CafeStyle
extends RefCounted
## Revestimentos que o jogador possui e os que estão aplicados na cafeteria.

signal changed

var floor_id: StringName = &""
var wall_id: StringName = &""
var _owned: Dictionary = {}  # StringName -> true


func owns(id: StringName) -> bool:
	return _owned.has(id)


func own(id: StringName) -> void:
	if not _owned.has(id):
		_owned[id] = true
		changed.emit()


func owned() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_owned.keys())
	result.sort()
	return result


func current(kind: SurfaceDefinition.Kind) -> StringName:
	return floor_id if kind == SurfaceDefinition.Kind.FLOOR else wall_id


## Aplica um revestimento que o jogador já possui.
func apply(definition: SurfaceDefinition) -> bool:
	if not owns(definition.id):
		return false
	if definition.kind == SurfaceDefinition.Kind.FLOOR:
		floor_id = definition.id
	else:
		wall_id = definition.id
	changed.emit()
	return true


func to_data() -> Dictionary:
	return {"floor": String(floor_id), "wall": String(wall_id), "owned": owned().map(func(id: StringName) -> String: return String(id))}


func restore(data: Dictionary) -> void:
	_owned.clear()
	for id in data.get("owned", []):
		_owned[StringName(str(id))] = true
	floor_id = StringName(str(data.get("floor", "")))
	wall_id = StringName(str(data.get("wall", "")))
	changed.emit()
