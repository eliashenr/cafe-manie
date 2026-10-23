extends CafeTestCase
## Chão sujo na cena (DT-068): a mancha aparece no piso com um aviso de como limpar, e o toque nela limpa,
## com o ouro subindo.


func test_a_spot_shows_on_the_floor_with_a_hint() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.floor_view.dirt.is_empty())
	cafe.simulation.dirt.add(Vector2i(2, 5))
	await settle()
	assert_eq(cafe.floor_view.dirt, [Vector2i(2, 5)] as Array[Vector2i], "a mancha aparece no piso")
	assert_true(ArtSprites.floor_dirt(Vector2i(2, 5)) != null, "e a arte dela existe")
	assert_true(all_messages(cafe).contains(Cafe.DIRT_HINT_MESSAGE), all_messages(cafe))


func test_tapping_the_spot_cleans_it() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.dirt.add(Vector2i(2, 5))
	await settle()
	var gold := sim.wallet.balance(Wallet.SOFT)
	tap_cell(cafe, Vector2i(2, 5))
	await settle()
	assert_false(sim.dirt.has_spot(Vector2i(2, 5)), "o toque limpa")
	assert_true(cafe.floor_view.dirt.is_empty(), "a mancha some do piso")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + sim.dirt_config.clean_gold)
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+%d ouro" % sim.dirt_config.clean_gold)
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL, "limpar não seleciona o piso")
