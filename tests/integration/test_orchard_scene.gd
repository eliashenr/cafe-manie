extends CafeTestCase
## Plantação na cena (DT-065): o pé maduro mostra a fruta e o toque colhe; a barra diz quanto falta; a máquina de
## frozen mostra o estoque de frutas.


func _orchard_cafe() -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(1000)  # nível 8
	var tree := simulation.layout.place(simulation.furniture.get_definition(&"tree_strawberry"), Vector2i(4, 4))
	simulation.layout.place(simulation.furniture.get_definition(&"machine_frozen"), Vector2i(1, 1))
	var cafe := await spawn_cafe(simulation)
	await settle()
	return [cafe, tree]


func test_a_ripe_tree_shows_its_fruit_and_a_tap_harvests() -> void:
	var setup := await _orchard_cafe()
	var cafe: Cafe = setup[0]
	var tree: StringName = setup[1]
	var view := cafe.world_layer.view_for(tree)
	assert_false(view.fruit_ready, "crescendo")
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(4, 4)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("fica madura em"), cafe.build_bar.message_text())
	cafe.clear_selection()
	clock.advance(cafe.catalog.get_definition(&"tree_strawberry").fruit_grow_time)
	await settle()
	assert_true(view.fruit_ready, "maduro: a fruta aparece")
	cafe.tap_at_world(IsoProjection.cell_center(Vector2i(4, 4)))
	await settle()
	assert_eq(cafe.simulation.fruit_stock.count(&"strawberry"), 3, "o toque colhe")
	assert_false(view.fruit_ready)
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+3 Morango")


func test_the_frozen_machine_shows_the_fruit_stock() -> void:
	var setup := await _orchard_cafe()
	var cafe: Cafe = setup[0]
	cafe.simulation.fruit_stock.add(&"mango", 2)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(1, 1)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("Manga ×2"), cafe.build_bar.message_text())
