extends CafeTestCase
## Fogão temático na cena (DT-059): no fogão comum, a aba Japão mostra as receitas apagadas, com "Só no Fogão Japonês";
## no Fogão Japonês elas saem.


func _cafe_with(stove_id: StringName) -> Cafe:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(46000)  # nível 30
	simulation.wallet.earn(Wallet.SOFT, 50000, "teste")
	simulation.layout.place(simulation.furniture.get_definition(stove_id), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(3, 0))
	var cafe := await spawn_cafe(simulation)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()
	cafe.build_bar.find_button("Book_japao").pressed.emit()
	await settle()
	return cafe


func test_a_common_stove_shows_japanese_dishes_as_only_on_their_stove() -> void:
	var cafe := await _cafe_with(&"stove_basic")
	var card := cafe.build_bar.find_button("Cook_yakisoba")
	assert_true(card != null, "a aba Japão mostra as receitas")
	assert_true(card.disabled and card.text.contains("Só no Fogão Japonês"), card.text)


func test_the_japanese_stove_cooks_them() -> void:
	var cafe := await _cafe_with(&"stove_blue")
	var card := cafe.build_bar.find_button("Cook_yakisoba")
	assert_false(card.disabled, card.text)
	card.pressed.emit()
	await settle()
	assert_eq(cafe.simulation.kitchen.stove_recipe(cafe.selected_id).id, &"yakisoba")
