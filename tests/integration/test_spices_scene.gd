extends CafeTestCase
## Temperos na cena (DT-056): o fogão que cozinha mostra os temperos com quantos você tem ou o preço; usar o da
## prateleira é na hora, comprar pede confirmação; o fogão estragado oferece as ervas; o presente diário e a
## missão mostram o tempero do prêmio.


func _stove_cafe(xp := 14500) -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(xp)  # nível 16: todos os temperos à venda
	simulation.wallet.earn(Wallet.SOFT, 5000, "teste")
	var stove := simulation.layout.place(simulation.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	var cafe := await spawn_cafe(simulation)
	return [cafe, stove]


func _select_stove(cafe: Cafe) -> void:
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()


func test_a_cooking_stove_offers_the_spices() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	cafe.simulation.spice_shelf.add(&"salt", 2)
	cafe.simulation.start_cooking(setup[1], &"pizza")
	await _select_stove(cafe)
	for spice_id in [&"salt", &"pepper", &"paprika", &"instant"]:
		assert_true(cafe.build_bar.find_button("Spice_" + String(spice_id)) != null, "cartão de %s" % spice_id)
	assert_true(cafe.build_bar.find_button("Spice_herbs") == null, "as ervas são para o prato estragado")
	var salt := cafe.build_bar.find_button("Spice_salt")
	assert_true(salt.text.contains("Você tem 2"), salt.text)
	assert_eq(salt.icon, ArtSprites.spice(&"salt").texture, "com o ícone")
	var pepper := cafe.build_bar.find_button("Spice_pepper")
	assert_true(pepper.text.contains("%d ouro" % cafe.simulation.spices.get_definition(&"pepper").price), pepper.text)


func test_using_a_spice_from_the_shelf_is_instant() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	cafe.simulation.spice_shelf.add(&"salt")
	cafe.simulation.start_cooking(stove, &"pizza")
	await _select_stove(cafe)
	var gold := cafe.simulation.wallet.balance(Wallet.SOFT)
	cafe.build_bar.find_button("Spice_salt").pressed.emit()
	await settle()
	assert_false(cafe.build_bar.confirm_dialog().visible, "o que você já tem não pede confirmação")
	assert_true(cafe.simulation.kitchen.is_seasoned(stove))
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold, "não cobra nada")
	var extra := cafe.simulation.kitchen.stove_servings(stove) - cafe.simulation.recipes.get_definition(&"pizza").servings
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+%d porções" % extra, "o efeito sobe do fogão")
	var salt := cafe.build_bar.find_button("Spice_salt")
	assert_true(salt.disabled and salt.text.contains("Já temperado"), salt.text)
	assert_true(cafe.build_bar.message_text().contains("com tempero"), cafe.build_bar.message_text())


func test_buying_a_spice_asks_first() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	cafe.simulation.start_cooking(stove, &"pizza")
	await _select_stove(cafe)
	var gold := cafe.simulation.wallet.balance(Wallet.SOFT)
	cafe.build_bar.find_button("Spice_instant").pressed.emit()
	await settle()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible, "comprar pede confirmação")
	assert_true(dialog.get_cancel_button().has_focus(), "com o Cancelar já escolhido")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold, "nada cobrado antes de confirmar")
	dialog.confirmed.emit()
	dialog.hide()
	await settle()
	var price := cafe.simulation.spices.get_definition(&"instant").price
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold - price)
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "pronto na hora")


func test_a_spoiled_stove_offers_the_herbs() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	cafe.simulation.spice_shelf.add(&"herbs")
	cafe.simulation.start_cooking(stove, &"coffee")
	clock.advance(coffee.cook_time + cafe.simulation.kitchen.spoil_time(coffee))
	await _select_stove(cafe)
	assert_true(cafe.build_bar.find_button("DiscardButton") != null)
	var herbs := cafe.build_bar.find_button("Spice_herbs")
	assert_true(herbs != null and not herbs.disabled, "as ervas aparecem ao lado do Jogar fora")
	herbs.pressed.emit()
	await settle()
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "o prato foi salvo")
	assert_false(cafe.world_layer.view_for(stove).stinking())


func test_rewards_show_the_spice() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var days := (load("res://data/config/daily_rewards.tres") as DailyRewardCalendar).days
	for day in days:
		if StringName(day.get("spice", &"")) != &"":
			var spice := cafe.simulation.spices.get_definition(StringName(day["spice"]))
			assert_true(cafe.hud.reward_text(day).contains(spice.display_name), cafe.hud.reward_text(day))
	var mission := MissionDefinition.new()
	mission.id = &"teste"
	mission.title = "Teste"
	mission.target = 1
	mission.reward_spice = &"salt"
	cafe.simulation._on_mission_completed(mission)
	await settle()
	assert_true(all_messages(cafe).contains("+1 Sal da Fartura"), all_messages(cafe))
