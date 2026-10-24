extends CafeTestCase
## Terraço na cena (DT-069): o cartão da aba Pisos, a compra com confirmação, o deque na fileira da frente e a cerca
## de jardim no lugar da mureta.


func _terrace_card(cafe: Cafe) -> Button:
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
	cafe.build_bar.show_shop_collection(&"classico")
	await settle()
	return cafe.build_bar.find_button("Terrace")


func test_the_terrace_art_exists() -> void:
	await spawn_cafe()
	assert_true(ArtSprites.terrace_floor(Vector2i(0, 7)) != null, "deque")
	assert_true(ArtSprites.terrace_floor(Vector2i(1, 7)) != null, "a outra tábua")
	assert_true(ArtSprites.terrace_fence("R") != null, "cerca")


func test_the_card_is_locked_at_first() -> void:
	var cafe := await spawn_cafe()
	var card := await _terrace_card(cafe)
	assert_true(card != null and card.disabled, "o terraço está na aba Pisos, bloqueado no começo")
	assert_true(card.text.contains("Nível %d" % cafe.simulation.terrace_config.min_level), card.text)


func test_building_asks_and_draws_the_deck_and_the_fence() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, sim.terrace_config.price, "teste")
	var card := await _terrace_card(cafe)
	assert_false(card.disabled)
	buy_in_shop(cafe, card)
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.get_cancel_button().has_focus(), "construir pede confirmação, com Cancelar selecionado")
	assert_false(sim.has_terrace(), "nada muda antes de confirmar")
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_true(sim.has_terrace())
	assert_eq(cafe.floor_view.terrace, sim.terrace_cells(), "o deque aparece na fileira da frente")
	assert_eq(cafe.floor_view.tile_at(Vector2i(2, 7)), ArtSprites.terrace_floor(Vector2i(2, 7)), "desenhado com a peça do deque")
	assert_eq(cafe.floor_view.tile_at(Vector2i(2, 6)), ArtSprites.floor_tile(&"floor_beige", Vector2i(2, 6)), "lá dentro, o piso de antes")
	sim.style.own(&"floor_wood")
	sim.style.paint_floor([Vector2i(3, 7)] as Array[Vector2i], &"floor_wood")
	await settle()
	assert_eq(cafe.floor_view.tile_at(Vector2i(3, 7)), ArtSprites.floor_tile(&"floor_wood", Vector2i(3, 7)), "piso pintado no terraço fica")
	assert_true(cafe.front_view.terrace, "a mureta da frente vira cerca")
	assert_true(cafe.front_view.is_fence(CafeStyle.segment(CafeStyle.EDGE_BOTTOM, 2)))
	assert_false(cafe.front_view.is_fence(CafeStyle.segment(CafeStyle.EDGE_RIGHT, 2)), "o lado da porta continua com a mureta")
	assert_true(all_messages(cafe).contains("Terraço pronto"), all_messages(cafe))
	assert_true(card.disabled and card.text.contains("Construído"), card.text)


func test_the_terrace_follows_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 99999, "teste")
	simulation.build_terrace()
	var cafe := await spawn_cafe(simulation)
	cafe.expand_cafe()
	await settle()
	assert_eq(cafe.floor_view.terrace, simulation.terrace_cells(), "o deque vai para a frente nova")
