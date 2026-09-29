class_name FurnitureCatalog
extends RefCounted
## Todos os tipos de móvel disponíveis, carregados de res://data/furniture.

const DEFAULT_DIR := "res://data/furniture"

var _by_id: Dictionary = {}  # StringName -> FurnitureDefinition
var _ordered: Array[FurnitureDefinition] = []


## Carrega todos os .tres da pasta. Arquivos inválidos ou com id repetido
## são recusados e reportados como erro (não passam em silêncio).
static func load_from(dir_path := DEFAULT_DIR) -> FurnitureCatalog:
	var catalog := FurnitureCatalog.new()
	# list_directory também funciona no jogo exportado, onde os .tres são remapeados.
	for file_name in ResourceLoader.list_directory(dir_path):
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var path := dir_path.path_join(file_name)
		var definition := load(path) as FurnitureDefinition
		if definition == null:
			push_error("Móvel ignorado, arquivo não é um FurnitureDefinition: %s" % path)
		elif not catalog.add(definition):
			push_error("Móvel ignorado, inválido ou com id repetido: %s" % path)
	return catalog


## Adiciona uma definição. Retorna false se ela for inválida ou se o id já existir.
func add(definition: FurnitureDefinition) -> bool:
	if definition == null or not definition.is_valid() or _by_id.has(definition.id):
		return false
	_by_id[definition.id] = definition
	_ordered.append(definition)
	_ordered.sort_custom(_sort_by_level_then_price)
	return true


func get_definition(id: StringName) -> FurnitureDefinition:
	return _by_id.get(id)


## Todas as definições, ordenadas por nível mínimo e depois por preço.
func all() -> Array[FurnitureDefinition]:
	return _ordered.duplicate()


func size() -> int:
	return _ordered.size()


static func _sort_by_level_then_price(a: FurnitureDefinition, b: FurnitureDefinition) -> bool:
	if a.min_level != b.min_level:
		return a.min_level < b.min_level
	if a.price != b.price:
		return a.price < b.price
	return String(a.id) < String(b.id)
