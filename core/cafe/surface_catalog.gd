class_name SurfaceCatalog
extends RefCounted
## Revestimentos de piso e parede, carregados de res://data/surfaces.

const DEFAULT_DIR := "res://data/surfaces"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort)


static func load_from(dir_path := DEFAULT_DIR) -> SurfaceCatalog:
	var catalog := SurfaceCatalog.new()
	catalog._store.load_dir(dir_path, SurfaceDefinition)
	return catalog


func add(definition: SurfaceDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> SurfaceDefinition:
	return _store.get_definition(id) as SurfaceDefinition


## Todos, ou só os de um tipo, em ordem de nível e preço.
func all(kind := -1) -> Array[SurfaceDefinition]:
	var result: Array[SurfaceDefinition] = []
	for definition in _store.all():
		if kind < 0 or definition.kind == kind:
			result.append(definition)
	return result


## O revestimento inicial de um tipo, ou null se os dados não tiverem um.
func default_for(kind: SurfaceDefinition.Kind) -> SurfaceDefinition:
	for definition in all(kind):
		if definition.is_default:
			return definition
	return null


func size() -> int:
	return _store.size()


static func _sort(a: SurfaceDefinition, b: SurfaceDefinition) -> bool:
	if a.is_default != b.is_default:
		return a.is_default
	if a.min_level != b.min_level:
		return a.min_level < b.min_level
	if a.price != b.price:
		return a.price < b.price
	return String(a.id) < String(b.id)
