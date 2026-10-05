class_name CollectionCatalog
extends RefCounted
## Coleções da loja, carregadas de res://data/collections, na ordem de exibição.

const DEFAULT_DIR := "res://data/collections"
## Coleção de quem não diz a sua (os itens do começo do jogo).
const DEFAULT_ID := &"classico"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(func(a: CollectionDefinition, b: CollectionDefinition) -> bool:
		return a.order < b.order if a.order != b.order else String(a.id) < String(b.id))


static func load_from(dir_path := DEFAULT_DIR) -> CollectionCatalog:
	var catalog := CollectionCatalog.new()
	catalog._store.load_dir(dir_path, CollectionDefinition)
	return catalog


func add(definition: CollectionDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> CollectionDefinition:
	return _store.get_definition(id) as CollectionDefinition


func all() -> Array[CollectionDefinition]:
	var result: Array[CollectionDefinition] = []
	result.assign(_store.all())
	return result


func size() -> int:
	return _store.size()
