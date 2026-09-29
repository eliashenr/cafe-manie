class_name DefinitionStore
extends RefCounted
## Armazém genérico de definições de conteúdo (móveis, receitas...).
##
## Carrega Resources de uma pasta, recusa inválidos e ids repetidos, indexa
## por id e mantém uma ordem de exibição. Os catálogos tipados (como
## FurnitureCatalog) usam um destes por dentro.
##
## Cada definição precisa ter [code]id: StringName[/code] e [code]is_valid() -> bool[/code].

var _by_id: Dictionary = {}  # StringName -> Resource
var _ordered: Array[Resource] = []
var _less: Callable


## [param less] recebe duas definições e diz se a primeira vem antes.
func _init(less: Callable) -> void:
	_less = less


## Carrega todos os .tres da pasta. Arquivos de outro tipo, inválidos ou com
## id repetido são recusados e reportados como erro (nunca em silêncio).
func load_dir(dir_path: String, expected_type: Script) -> void:
	# list_directory também funciona no jogo exportado, onde os .tres são remapeados.
	for file_name in ResourceLoader.list_directory(dir_path):
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue
		var path := dir_path.path_join(file_name)
		var resource := load(path)
		if not is_instance_of(resource, expected_type):
			push_error("Conteúdo ignorado, tipo errado: %s" % path)
		elif not add(resource):
			push_error("Conteúdo ignorado, inválido ou com id repetido: %s" % path)


func add(definition: Resource) -> bool:
	if definition == null or not definition.has_method("is_valid") or not definition.is_valid():
		return false
	if _by_id.has(definition.id):
		return false
	_by_id[definition.id] = definition
	_ordered.append(definition)
	_ordered.sort_custom(_less)
	return true


func get_definition(id: StringName) -> Resource:
	return _by_id.get(id)


func all() -> Array[Resource]:
	return _ordered.duplicate()


func size() -> int:
	return _ordered.size()
