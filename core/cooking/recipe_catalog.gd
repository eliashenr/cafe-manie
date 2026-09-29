class_name RecipeCatalog
extends RefCounted
## Todas as receitas, carregadas de res://data/recipes.

const DEFAULT_DIR := "res://data/recipes"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort_by_level_then_time)


static func load_from(dir_path := DEFAULT_DIR) -> RecipeCatalog:
	var catalog := RecipeCatalog.new()
	catalog._store.load_dir(dir_path, RecipeDefinition)
	return catalog


func add(definition: RecipeDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> RecipeDefinition:
	return _store.get_definition(id) as RecipeDefinition


## Todas as receitas, ordenadas por nível de desbloqueio e depois por tempo de preparo.
func all() -> Array[RecipeDefinition]:
	var result: Array[RecipeDefinition] = []
	result.assign(_store.all())
	return result


## Receitas liberadas para o nível informado.
func unlocked_at(level: int) -> Array[RecipeDefinition]:
	return all().filter(func(r: RecipeDefinition) -> bool: return r.unlock_level <= level)


func size() -> int:
	return _store.size()


static func _sort_by_level_then_time(a: RecipeDefinition, b: RecipeDefinition) -> bool:
	if a.unlock_level != b.unlock_level:
		return a.unlock_level < b.unlock_level
	if a.cook_time != b.cook_time:
		return a.cook_time < b.cook_time
	return String(a.id) < String(b.id)
