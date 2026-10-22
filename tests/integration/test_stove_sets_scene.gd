extends CafeTestCase
## Multifogão na cena (DT-060): a loja explica a peça; o fogão diz quantas peças faltam e, completo, que rende o dobro;
## completar avisa do prêmio, que aparece na Loja para pôr na cafeteria.


func _train_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(46000)  # nível 30
	simulation.wallet.earn(Wallet.SOFT, 50000, "teste")
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(5, 0))
	var cafe := await spawn_cafe(simulation)
	return cafe


func _buy(cafe: Cafe, id: StringName, cell: Vector2i) -> void:
	assert_eq(cafe.simulation.acquire_and_place(cafe.catalog.get_definition(id), cell, 0), ServiceResult.OK)


## Procura o cartão em todas as páginas da aba aberta da loja.
func _find_in_shop(cafe: Cafe, button_name: String) -> Button:
	for page in cafe.build_bar.shop_page_count():
		cafe.build_bar.shop_page = page
		await settle()
		var card := cafe.build_bar.find_button(button_name)
		if card != null:
			return card
	return null


func test_the_shop_explains_each_train_part() -> void:
	var cafe := await _train_cafe()
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	await settle()
	var wagon := await _find_in_shop(cafe, "Build_train_wagon")
	assert_true(wagon != null and wagon.tooltip_text.contains("Peça 2 de 3"), wagon.tooltip_text if wagon else "sem cartão")
	cafe.build_bar.open_shop(BuildBar.ShopTab.DECOR)
	await settle()
	assert_true(await _find_in_shop(cafe, "Build_station_clock") == null, "o prêmio não está à venda")


func test_the_stove_tells_the_set_progress_and_the_reward_is_announced() -> void:
	var cafe := await _train_cafe()
	_buy(cafe, &"train_locomotive", Vector2i(1, 1))
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(1, 1)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("1 de 3 peças"), cafe.build_bar.message_text())
	cafe.clear_selection()
	_buy(cafe, &"train_wagon", Vector2i(2, 1))
	_buy(cafe, &"train_dining", Vector2i(3, 1))
	await settle()
	assert_true(all_messages(cafe).contains("Multifogão Trem completo!"), all_messages(cafe))
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(1, 1)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("o dobro de porções"), cafe.build_bar.message_text())
	cafe.clear_selection()
	cafe.build_bar.open_shop(BuildBar.ShopTab.DECOR)
	await settle()
	var clock_card := await _find_in_shop(cafe, "Build_station_clock")
	assert_true(clock_card != null and clock_card.text.contains("1 guardado"), "o prêmio aparece guardado na Loja")
