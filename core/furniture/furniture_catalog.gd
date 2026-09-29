class_name FurnitureCatalog
extends RefCounted
## Todos os tipos de móvel disponíveis, carregados de res://data/furniture.

const DEFAULT_DIR := "res://data/furniture"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort_by_level_then_price)


static func load_from(dir_path := DEFAULT_DIR) -> FurnitureCatalog:
	var catalog := FurnitureCatalog.new()
	catalog._store.load_dir(dir_path, FurnitureDefinition)
	return catalog


## Adiciona uma definição. Retorna false se ela for inválida ou se o id já existir.
func add(definition: FurnitureDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> FurnitureDefinition:
	return _store.get_definition(id) as FurnitureDefinition


## Todas as definições, ordenadas por nível mínimo e depois por preço.
func all() -> Array[FurnitureDefinition]:
	var result: Array[FurnitureDefinition] = []
	result.assign(_store.all())
	return result


func size() -> int:
	return _store.size()


static func _sort_by_level_then_price(a: FurnitureDefinition, b: FurnitureDefinition) -> bool:
	if a.min_level != b.min_level:
		return a.min_level < b.min_level
	if a.price != b.price:
		return a.price < b.price
	return String(a.id) < String(b.id)
