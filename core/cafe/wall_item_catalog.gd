class_name WallItemCatalog
extends RefCounted
## Itens de parede de res://data/wall_items, na ordem da loja (nível, depois preço).

const DEFAULT_DIR := "res://data/wall_items"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(func(a: WallItemDefinition, b: WallItemDefinition) -> bool:
		if a.min_level != b.min_level:
			return a.min_level < b.min_level
		return a.price < b.price if a.price != b.price else String(a.id) < String(b.id))


static func load_from(dir_path := DEFAULT_DIR) -> WallItemCatalog:
	var catalog := WallItemCatalog.new()
	catalog._store.load_dir(dir_path, WallItemDefinition)
	return catalog


func add(definition: WallItemDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> WallItemDefinition:
	return _store.get_definition(id) as WallItemDefinition


func all() -> Array[WallItemDefinition]:
	var result: Array[WallItemDefinition] = []
	result.assign(_store.all())
	return result


func size() -> int:
	return _store.size()
