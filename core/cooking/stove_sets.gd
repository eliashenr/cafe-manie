class_name StoveSets
extends RefCounted
## Conjuntos de multifogão na cafeteria (DT-060): diz se um fogão faz parte de um conjunto completo (as peças lado a
## lado, em linha reta e na ordem, para qualquer lado) e lembra quais conjuntos já deram o prêmio.

const DEFAULT_DIR := "res://data/stove_sets"
const DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

var layout: CafeLayout
var _store: DefinitionStore
## Conjuntos que já deram o prêmio (id -> true).
var _rewarded := {}


func _init(cafe_layout: CafeLayout, dir_path := DEFAULT_DIR) -> void:
	layout = cafe_layout
	_store = DefinitionStore.new(func(a: StoveSetDefinition, b: StoveSetDefinition) -> bool: return String(a.id) < String(b.id))
	_store.load_dir(dir_path, StoveSetDefinition)


func all() -> Array[StoveSetDefinition]:
	var result: Array[StoveSetDefinition] = []
	result.assign(_store.all())
	return result


## O conjunto de que este móvel é peça (completo ou não), ou null.
func set_of_part(furniture_id: StringName) -> StoveSetDefinition:
	for stove_set in all():
		if stove_set.parts.has(furniture_id):
			return stove_set
	return null


## O conjunto completo de que este fogão faz parte agora, ou null.
func complete_set_of(stove_id: StringName) -> StoveSetDefinition:
	var placement := layout.get_placement(stove_id)
	if placement == null:
		return null
	var stove_set := set_of_part(placement.definition.id)
	if stove_set == null:
		return null
	for row in _complete_rows(stove_set):
		if row.has(stove_id):
			return stove_set
	return null


## Quantas peças diferentes do conjunto já estão na cafeteria.
func parts_placed(stove_set: StoveSetDefinition) -> int:
	var count := 0
	for part in stove_set.parts:
		for placement in layout.placements():
			if placement.definition.id == part:
				count += 1
				break
	return count


func is_complete(stove_set: StoveSetDefinition) -> bool:
	return not _complete_rows(stove_set).is_empty()


## Conjuntos que acabaram de ficar completos pela primeira vez (e passam a contar como premiados).
func claim_new_rewards() -> Array[StoveSetDefinition]:
	var fresh: Array[StoveSetDefinition] = []
	for stove_set in all():
		if not _rewarded.has(stove_set.id) and is_complete(stove_set):
			_rewarded[stove_set.id] = true
			fresh.append(stove_set)
	return fresh


func was_rewarded(set_id: StringName) -> bool:
	return _rewarded.has(set_id)


func to_data() -> Dictionary:
	var rewarded: Array[String] = []
	for id: StringName in _rewarded:
		rewarded.append(String(id))
	rewarded.sort()
	return {"rewarded": rewarded}


func restore(data: Dictionary) -> void:
	_rewarded.clear()
	for id in (data.get("rewarded", []) if data.get("rewarded") is Array else []):
		_rewarded[StringName(str(id))] = true


## Cada fileira completa do conjunto: os ids das peças, da primeira à última, em casas vizinhas em linha reta.
func _complete_rows(stove_set: StoveSetDefinition) -> Array:
	var rows := []
	for first in layout.placements():
		if first.definition.id != stove_set.parts[0]:
			continue
		for direction in DIRECTIONS:
			var row: Array[StringName] = [first.id]
			for i in range(1, stove_set.parts.size()):
				var next := layout.placement_at(first.origin + direction * i)
				if next == null or next.definition.id != stove_set.parts[i] or next.origin != first.origin + direction * i:
					break
				row.append(next.id)
			if row.size() == stove_set.parts.size():
				rows.append(row)
	return rows
