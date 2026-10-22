class_name DrinkCatalog
extends RefCounted
## Todas as bebidas, carregadas de res://data/drinks (DT-052).

const DEFAULT_DIR := "res://data/drinks"

var _store: DefinitionStore


func _init() -> void:
	_store = DefinitionStore.new(_sort_by_machine_then_level)


static func load_from(dir_path := DEFAULT_DIR) -> DrinkCatalog:
	var catalog := DrinkCatalog.new()
	catalog._store.load_dir(dir_path, DrinkDefinition)
	return catalog


func add(definition: DrinkDefinition) -> bool:
	return _store.add(definition)


func get_definition(id: StringName) -> DrinkDefinition:
	return _store.get_definition(id) as DrinkDefinition


## Todas as bebidas, por máquina e depois por nível.
func all() -> Array[DrinkDefinition]:
	var result: Array[DrinkDefinition] = []
	result.assign(_store.all())
	return result


## Bebidas que a máquina [param machine] prepara e que os clientes já pedem no nível [param level].
func for_machine(machine: StringName, level: int) -> Array[DrinkDefinition]:
	return all().filter(func(d: DrinkDefinition) -> bool: return d.machine == machine and d.unlock_level <= level)


func size() -> int:
	return _store.size()


static func _sort_by_machine_then_level(a: DrinkDefinition, b: DrinkDefinition) -> bool:
	if a.machine != b.machine:
		return String(a.machine) < String(b.machine)
	if a.unlock_level != b.unlock_level:
		return a.unlock_level < b.unlock_level
	return String(a.id) < String(b.id)
