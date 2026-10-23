extends CafeTestCase
## Troféus na cena (DT-057): o troféu escolhido mostra no chão as casas que acelera e quantos pratos ainda acelera;
## gasto, fica apagado e avisa; renovar pede confirmação; o livro e o fogão mostram o tempo acelerado; na loja, os
## troféus ficam na aba da cozinha, com a dica do que fazem.


func _trophy_cafe() -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(14500)  # nível 16
	simulation.wallet.earn(Wallet.SOFT, 20000, "teste")
	var stove := simulation.layout.place(simulation.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(3, 0))
	var trophy := simulation.layout.place(simulation.furniture.get_definition(&"trophy_bronze"), Vector2i(1, 0))
	var cafe := await spawn_cafe(simulation)
	return [cafe, stove, trophy]


func _select(cafe: Cafe, cell: Vector2i) -> void:
	cafe.select_at_world(IsoProjection.cell_center(cell))
	await settle()


func test_a_selected_trophy_shows_its_area_and_charges() -> void:
	var setup := await _trophy_cafe()
	var cafe: Cafe = setup[0]
	var trophy: StringName = setup[2]
	var view := cafe.world_layer.view_for(trophy)
	assert_false(view.shows_trophy_area(), "sem escolher, sem marca no chão")
	await _select(cafe, Vector2i(1, 0))
	assert_true(view.shows_trophy_area(), "escolhido: as casas que ele acelera")
	var definition := cafe.simulation.furniture.get_definition(&"trophy_bronze")
	assert_true(cafe.build_bar.message_text().contains("%d%% mais rápidos" % roundi(definition.stove_speed_bonus * 100.0)),
		cafe.build_bar.message_text())
	assert_true(cafe.build_bar.message_text().contains("%d de %d pratos" % [definition.trophy_dishes, definition.trophy_dishes]))
	assert_true(cafe.build_bar.find_button("RenewButton").disabled, "cheio, renovar fica apagado")


func test_placing_a_trophy_shows_the_area_it_will_boost() -> void:
	var setup := await _trophy_cafe()
	var cafe: Cafe = setup[0]
	cafe.start_placing(&"trophy_silver")
	cafe._on_tapped(IsoProjection.cell_center(Vector2i(5, 5)))  # o primeiro toque mostra onde ficaria
	await settle()
	var ghost := cafe.world_layer.get_node("Ghost") as FurnitureView
	assert_true(ghost.shows_trophy_area(), "o fantasma mostra onde vai acelerar")


func test_a_worn_trophy_dims_warns_and_renews_with_confirmation() -> void:
	var setup := await _trophy_cafe()
	var cafe: Cafe = setup[0]
	var trophy: StringName = setup[2]
	var definition := cafe.simulation.furniture.get_definition(&"trophy_bronze")
	for i in definition.trophy_dishes - 1:
		cafe.simulation.trophies.use(trophy)
	cafe.simulation.start_cooking(setup[1], &"coffee")  # o último prato gasta o troféu
	await settle()
	assert_true(all_messages(cafe).contains(Cafe.TROPHY_WORN_MESSAGE % definition.display_name), all_messages(cafe))
	var view := cafe.world_layer.view_for(trophy)
	assert_true(view.worn and view.modulate == FurnitureView.WORN_MODULATE, "gasto fica apagado")
	await _select(cafe, Vector2i(1, 0))
	assert_true(cafe.build_bar.message_text().contains("gasto"), cafe.build_bar.message_text())
	var renew := cafe.build_bar.find_button("RenewButton")
	assert_false(renew.disabled)
	var gold := cafe.simulation.wallet.balance(Wallet.SOFT)
	renew.pressed.emit()
	await settle()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.get_cancel_button().has_focus(), "pede confirmação com Cancelar escolhido")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold, "nada cobrado antes de confirmar")
	dialog.confirmed.emit()
	dialog.hide()
	await settle()
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold - definition.renew_price)
	assert_false(view.worn, "renovado, volta a brilhar")


func test_the_book_and_the_stove_show_the_faster_time() -> void:
	var setup := await _trophy_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	await _select(cafe, Vector2i(0, 0))
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	var faster := WorldLayer.format_time(cafe.simulation.cook_time_on(stove, coffee))
	assert_true(cafe.build_bar.find_button("Cook_coffee").text.contains(faster), cafe.build_bar.find_button("Cook_coffee").text)
	assert_true(cafe.build_bar.message_text().contains("troféu"), cafe.build_bar.message_text())
	cafe.build_bar.find_button("Cook_coffee").pressed.emit()
	await settle()
	assert_true(cafe.build_bar.message_text().contains("troféu: 25% mais rápido"), cafe.build_bar.message_text())


## Procura o cartão em todas as páginas da aba aberta da loja.
func _find_in_shop(cafe: Cafe, button_name: String) -> Button:
	for page in cafe.build_bar.shop_page_count():
		cafe.build_bar.shop_page = page
		await settle()
		var card := cafe.build_bar.find_button(button_name)
		if card != null:
			return card
	return null


func test_trophies_are_sold_in_the_kitchen_tab() -> void:
	var setup := await _trophy_cafe()
	var cafe: Cafe = setup[0]
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	await settle()
	var card := await _find_in_shop(cafe, "Build_trophy_bronze")
	assert_true(card != null, "na aba da cozinha")
	if card != null:
		assert_true(card.tooltip_text.contains("8 casas em volta"), card.tooltip_text)
	cafe.build_bar.open_shop(BuildBar.ShopTab.DECOR)
	await settle()
	assert_true(await _find_in_shop(cafe, "Build_trophy_bronze") == null, "e não na decoração")
