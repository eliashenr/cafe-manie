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
	assert_true(catalog.size() >= 57, "os 9 clássicos e as coleções: %d" % catalog.size())
	for id in [&"table_round", &"chair_wood", &"stove_basic", &"counter_basic", &"plant_pot", &"table_long",
			&"flower_vase", &"floor_lamp", &"bookshelf"]:
		assert_true(catalog.get_definition(id) != null, "falta %s" % id)
		assert_eq(catalog.get_definition(id).collection, &"classico", "%s é clássico" % id)


func test_every_item_belongs_to_a_known_collection_and_each_collection_has_a_full_set() -> void:
	var collections := CollectionCatalog.load_from()
	assert_true(collections.size() >= 13, "clássico e as 12 coleções")
	var furniture := FurnitureCatalog.load_from()
	var surfaces := SurfaceCatalog.load_from()
	var kinds := {}
	for definition in furniture.all():
		assert_true(collections.get_definition(definition.collection) != null, "%s sem coleção conhecida" % definition.id)
		kinds[[definition.collection, definition.category]] = true
	for surface in surfaces.all():
		assert_true(collections.get_definition(surface.collection) != null, "%s sem coleção conhecida" % surface.id)
		kinds[[surface.collection, "piso" if surface.kind == SurfaceDefinition.Kind.FLOOR else "parede"]] = true
	for collection in collections.all():
		for kind in [FurnitureDefinition.Category.SEATING, FurnitureDefinition.Category.TABLE, FurnitureDefinition.Category.DECOR,
				"piso", "parede"]:
			assert_true(kinds.has([collection.id, kind]), "%s sem %s" % [collection.display_name, kind])


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


func test_counters_take_a_single_cell_and_there_are_more_stoves_and_counters() -> void:
	var catalog := FurnitureCatalog.load_from()
	var stoves := 0
	var counters := 0
	for definition: FurnitureDefinition in catalog.all():
		if definition.category == FurnitureDefinition.Category.COUNTER:
			counters += 1
			assert_eq(definition.footprint, Vector2i.ONE, "%s ocupa 1 piso" % definition.id)
		elif definition.category == FurnitureDefinition.Category.COOKING:
			stoves += 1
	assert_true(stoves >= 8, "fogões variados (%d)" % stoves)
	assert_true(counters >= 8, "balcões variados (%d)" % counters)
