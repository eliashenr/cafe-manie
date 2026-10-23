extends CafeTestCase
## Atrações e palco na cena (DT-066): a atração com ouro mostra a moeda e o toque coleta; a barra diz quanto há
## guardado; no show, as notas sobem do palco e um aviso explica.


func _fun_cafe() -> Array:
	var simulation := quiet_simulation()
	var arcade := simulation.layout.place(simulation.furniture.get_definition(&"arcade"), Vector2i(4, 4))
	var stage := simulation.layout.place(simulation.furniture.get_definition(&"stage"), Vector2i(1, 5))
	var cafe := await spawn_cafe(simulation)
	await settle()
	return [cafe, arcade, stage]


func test_an_attraction_with_gold_shows_a_coin_and_a_tap_collects() -> void:
	var setup := await _fun_cafe()
	var cafe: Cafe = setup[0]
	var arcade: StringName = setup[1]
	cafe.simulation.attractions.add_play(arcade)
	await settle()
	var view := cafe.world_layer.view_for(arcade)
	var gold := cafe.simulation.attractions.gold(arcade)
	assert_eq(view.attraction_gold, gold, "a moeda aparece")
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(4, 4)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("%d de" % gold), cafe.build_bar.message_text())
	cafe.clear_selection()
	var wallet := cafe.simulation.wallet.balance(Wallet.SOFT)
	cafe.tap_at_world(IsoProjection.cell_center(Vector2i(4, 4)))
	await settle()
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), wallet + gold, "o toque coleta")
	assert_eq(view.attraction_gold, 0)
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+%d ouro" % gold)


func test_the_show_plays_notes_and_is_announced() -> void:
	var setup := await _fun_cafe()
	var cafe: Cafe = setup[0]
	var stage: StringName = setup[2]
	var view := cafe.world_layer.view_for(stage)
	assert_false(view.showing())
	cafe.simulation.tick(cafe.simulation.stage_config.show_interval + 0.1)
	await settle()
	assert_true(view.showing(), "as notas sobem do palco")
	assert_true(all_messages(cafe).contains(Cafe.SHOW_STARTED_MESSAGE), all_messages(cafe))
