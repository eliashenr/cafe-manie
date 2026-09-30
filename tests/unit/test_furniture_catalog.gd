extends TestCase
## Catálogo de móveis: carregamento dos dados reais e recusa de dados ruins.


func _definition(id: StringName, level := 1, price := 10) -> FurnitureDefinition:
	var definition := FurnitureDefinition.new()
	definition.id = id
	definition.display_name = String(id)
	definition.min_level = level
	definition.price = price
	return definition


func test_loads_every_furniture_file_from_data_folder() -> void:
	var catalog := FurnitureCatalog.load_from()
	assert_eq(catalog.size(), 9)
	for id in [&"table_round", &"chair_wood", &"stove_basic", &"counter_basic", &"plant_pot", &"table_long",
			&"flower_vase", &"floor_lamp", &"bookshelf"]:
		assert_true(catalog.get_definition(id) != null, "falta %s" % id)


func test_every_data_file_is_valid_and_complete() -> void:
	for definition in FurnitureCatalog.load_from().all():
		assert_true(definition.is_valid(), "%s inválido" % definition.id)
		assert_false(definition.display_name.is_empty(), "%s sem nome" % definition.id)
		assert_true(definition.placeholder_height > 0.0, "%s sem altura" % definition.id)


func test_functional_furniture_needs_access_and_decor_does_not() -> void:
	var catalog := FurnitureCatalog.load_from()
	assert_true(catalog.get_definition(&"stove_basic").needs_access)
	assert_true(catalog.get_definition(&"table_round").needs_access)
	assert_false(catalog.get_definition(&"plant_pot").needs_access)


func test_all_is_sorted_by_level_then_price() -> void:
	var catalog := FurnitureCatalog.new()
	catalog.add(_definition(&"c", 2, 5))
	catalog.add(_definition(&"b", 1, 90))
	catalog.add(_definition(&"a", 1, 20))
	var ids := catalog.all().map(func(d: FurnitureDefinition) -> StringName: return d.id)
	assert_eq(ids, [&"a", &"b", &"c"])


func test_add_rejects_duplicate_and_invalid_definitions() -> void:
	var catalog := FurnitureCatalog.new()
	assert_true(catalog.add(_definition(&"mesa")))
	assert_false(catalog.add(_definition(&"mesa")), "id repetido")
	assert_false(catalog.add(_definition(&"")), "id vazio")
	var broken := _definition(&"quebrado")
	broken.footprint = Vector2i(0, 1)
	assert_false(catalog.add(broken), "tamanho zero")
	assert_false(catalog.add(null), "nulo")
	assert_eq(catalog.size(), 1)


func test_unknown_id_returns_null() -> void:
	assert_eq(FurnitureCatalog.load_from().get_definition(&"nao_existe"), null)
