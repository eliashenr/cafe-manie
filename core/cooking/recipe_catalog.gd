class_name RecipeCatalog
extends RefCounted
## Todas as receitas, carregadas de res://data/recipes, e as abas do livro de receitas (res://data/recipe_books).

const DEFAULT_DIR := "res://data/recipes"
const BOOKS_DIR := "res://data/recipe_books"

var _store: DefinitionStore
var _books: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort_by_level_then_time)
	_books = DefinitionStore.new(func(a: RecipeBookDefinition, b: RecipeBookDefinition) -> bool: return a.order < b.order)


static func load_from(dir_path := DEFAULT_DIR, books_dir := BOOKS_DIR) -> RecipeCatalog:
	var catalog := RecipeCatalog.new()
	catalog._store.load_dir(dir_path, RecipeDefinition)
	catalog._books.load_dir(books_dir, RecipeBookDefinition)
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


## Abas do livro de receitas, na ordem.
func books() -> Array[RecipeBookDefinition]:
	var result: Array[RecipeBookDefinition] = []
	result.assign(_books.all())
	return result


func get_book(id: StringName) -> RecipeBookDefinition:
	return _books.get_definition(id) as RecipeBookDefinition


## Receitas de uma aba do livro (por nível e tempo).
func in_book(book_id: StringName) -> Array[RecipeDefinition]:
	return all().filter(func(r: RecipeDefinition) -> bool: return r.book == book_id)


static func _sort_by_level_then_time(a: RecipeDefinition, b: RecipeDefinition) -> bool:
	if a.unlock_level != b.unlock_level:
		return a.unlock_level < b.unlock_level
	if a.cook_time != b.cook_time:
		return a.cook_time < b.cook_time
	return String(a.id) < String(b.id)
