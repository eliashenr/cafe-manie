extends TestCase
## Coleções da loja (estilos e culturas): carregam na ordem de exibição, recusam dados ruins e
## cada uma tem nome e cor próprios para o filtro da loja.


func _collection(id: StringName, order: int, display_name := "Nome") -> CollectionDefinition:
	var collection := CollectionDefinition.new()
	collection.id = id
	collection.display_name = display_name
	collection.order = order
	return collection


func test_loads_the_collections_in_display_order_starting_with_the_classics() -> void:
	var catalog := CollectionCatalog.load_from()
	assert_true(catalog.size() >= 13, "o clássico e as 12 coleções: %d" % catalog.size())
	var all := catalog.all()
	assert_eq(all[0].id, CollectionCatalog.DEFAULT_ID, "o clássico vem primeiro")
	var last_order := -1
	var names := {}
	var colors := {}
	for collection in all:
		assert_true(collection.is_valid(), "%s inválida" % collection.id)
		assert_true(collection.order > last_order, "fora de ordem: %s" % collection.id)
		last_order = collection.order
		names[collection.display_name] = true
		colors[collection.color.to_html()] = true
	assert_eq(names.size(), all.size(), "cada coleção com o seu nome")
	assert_eq(colors.size(), all.size(), "cada coleção com a sua cor no filtro da loja")


func test_orders_by_order_then_id_and_rejects_bad_definitions() -> void:
	var catalog := CollectionCatalog.new()
	assert_true(catalog.add(_collection(&"b", 2)))
	assert_true(catalog.add(_collection(&"z", 1)))
	assert_true(catalog.add(_collection(&"a", 2)))
	assert_false(catalog.add(_collection(&"a", 5)), "id repetido")
	assert_false(catalog.add(_collection(&"", 3)), "sem id")
	assert_false(catalog.add(_collection(&"c", 3, "")), "sem nome para o botão da loja")
	var ids: Array[StringName] = []
	for collection in catalog.all():
		ids.append(collection.id)
	assert_eq(ids, [&"z", &"a", &"b"] as Array[StringName])
	assert_eq(catalog.get_definition(&"a").order, 2)
	assert_eq(catalog.get_definition(&"nada"), null)
