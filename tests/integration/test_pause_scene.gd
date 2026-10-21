extends CafeTestCase
## Pausa na cena (DT-049): o botão e a tecla P pausam e continuam, a faixa avisa, personagens, vapor e
## trânsito ficam parados, e dá para construir com o jogo pausado.


func _standing(cafe: Cafe, at: Vector2, serial := 60) -> AgentView:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	customer.state = Customer.State.LEAVING
	customer.position = at
	cafe.simulation.customers.append(customer)
	cafe.world_layer.refresh(cafe.simulation)
	return cafe.world_layer.get_node("Agent_%d" % serial)


func test_pause_button_pauses_and_continues_the_game() -> void:
	var cafe := await spawn_cafe()
	var button := cafe.hud.find_child("PauseButton", true, false) as Button
	assert_false(cafe.is_paused())
	assert_false(cafe.hud.is_pause_banner_visible())
	assert_eq(button.icon, ArtSprites.get_sprite("botao_pause").texture)
	button.pressed.emit()
	await settle()
	assert_true(cafe.is_paused() and cafe.simulation.paused, "o botão pausa o jogo")
	assert_true(cafe.hud.is_pause_banner_visible(), "a faixa avisa")
	assert_eq(button.icon, ArtSprites.get_sprite("botao_play").texture, "e o botão vira o de continuar")
	assert_eq(cafe.street_view.process_mode, Node.PROCESS_MODE_DISABLED, "o trânsito para")
	button.pressed.emit()
	await settle()
	assert_false(cafe.is_paused(), "tocar de novo continua")
	assert_false(cafe.hud.is_pause_banner_visible())
	assert_eq(cafe.street_view.process_mode, Node.PROCESS_MODE_INHERIT)


func test_p_key_toggles_the_pause() -> void:
	var cafe := await spawn_cafe()
	press_key(KEY_P)
	await settle()
	assert_true(cafe.is_paused())
	press_key(KEY_P)
	await settle()
	assert_false(cafe.is_paused())


func test_characters_and_steam_freeze_and_new_stoves_too() -> void:
	var cafe := await spawn_cafe()
	var stove := cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0))
	cafe.simulation.start_cooking(stove, &"coffee")
	var walker := _standing(cafe, Vector2(4.0, 4.0))
	await settle()
	cafe.set_paused(true)
	assert_eq(walker.process_mode, Node.PROCESS_MODE_DISABLED, "o personagem fica parado")
	var fx: Node = cafe.world_layer.view_for(stove).get_node("Fx")
	assert_eq(fx.process_mode, Node.PROCESS_MODE_DISABLED, "o vapor fica parado no ar")
	var second := cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(1, 0))
	await settle()
	assert_eq(cafe.world_layer.view_for(second).get_node("Fx").process_mode, Node.PROCESS_MODE_DISABLED,
		"fogão posto durante a pausa também fica parado")
	cafe.set_paused(false)
	assert_eq(walker.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(fx.process_mode, Node.PROCESS_MODE_INHERIT)


func test_nobody_stays_invisible_when_the_game_pauses_while_they_appear() -> void:
	var cafe := await spawn_cafe()
	var appearing := _standing(cafe, Vector2(3.0, 3.0))
	assert_true(appearing.modulate.a < 1.0, "acabou de chegar: ainda aparecendo aos poucos")
	cafe.set_paused(true)
	assert_almost_eq(appearing.modulate.a, 1.0, 0.001, "pausou: aparece inteiro, sem ficar invisível")
	var created := _standing(cafe, Vector2(5.0, 3.0), 61)
	assert_almost_eq(created.modulate.a, 1.0, 0.001, "criado durante a pausa já aparece")
	assert_eq(created.process_mode, Node.PROCESS_MODE_DISABLED, "e fica parado")


func test_building_while_paused() -> void:
	var cafe := await spawn_cafe()
	cafe.set_paused(true)
	assert_true(cafe.start_placing(&"table_round"))
	tap_cell(cafe, Vector2i(4, 4))
	tap_cell(cafe, Vector2i(4, 4))
	await settle()
	assert_eq(cafe.layout.count(), 1, "comprou e pôs a mesa com o jogo pausado")
	assert_true(cafe.is_paused(), "sem tirar a pausa")
