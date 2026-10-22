class_name SpiceCatalog
extends RefCounted
## Todos os temperos, carregados de res://data/spices (DT-056).

const DEFAULT_DIR := "res://data/spices"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort_by_order)


static func load_from(dir_path := DEFAULT_DIR) -> SpiceCatalog:
	var catalog := SpiceCatalog.new()
	catalog._store.load_dir(dir_path, SpiceDefinition)
	return catalog


func add(definition: SpiceDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> SpiceDefinition:
	return _store.get_definition(id) as SpiceDefinition


## Todos, na ordem da prateleira.
func all() -> Array[SpiceDefinition]:
	var result: Array[SpiceDefinition] = []
	result.assign(_store.all())
	return result


## Os que servem para um fogão neste estado.
func for_status(status: Kitchen.StoveStatus) -> Array[SpiceDefinition]:
	return all().filter(func(s: SpiceDefinition) -> bool: return s.works_on(status))


func size() -> int:
	return _store.size()


static func _sort_by_order(a: SpiceDefinition, b: SpiceDefinition) -> bool:
	if a.order != b.order:
		return a.order < b.order
	return String(a.id) < String(b.id)
