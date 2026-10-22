extends CafeTestCase
## Placa ABERTO/FECHADO na cena (DT-051): o botão da porta e a tecla F fecham e abrem o café, a faixa e o
## aviso explicam, a plaquinha da porta muda e o jogo continua rodando (não é a pausa).


func test_door_button_closes_and_opens_the_cafe() -> void:
	var cafe := await spawn_cafe()
	var button := cafe.hud.find_child("ClosedButton", true, false) as Button
	assert_false(cafe.is_closed())
	assert_false(cafe.hud.is_closed_banner_visible())
	assert_eq(button.icon, ArtSprites.get_sprite("botao_door_close").texture, "aberto, o botão é o de fechar")
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_L")
	button.pressed.emit()
	await settle()
	assert_true(cafe.is_closed() and cafe.simulation.closed, "o botão fecha o café")
	assert_true(cafe.hud.is_closed_banner_visible(), "a faixa avisa")
	assert_eq(button.icon, ArtSprites.get_sprite("botao_door_open").texture, "e o botão vira o de abrir")
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_fechada_L", "a plaquinha diz FECHADO")
	assert_true(ArtSprites.get_sprite(cafe.front_view.door_sprite_name()) != null, "e a arte dela existe")
	assert_true(all_messages(cafe).contains(Cafe.CLOSED_MESSAGE), "o aviso explica o que acontece")
	assert_false(cafe.is_paused(), "fechar não pausa o jogo")
	button.pressed.emit()
	await settle()
	assert_false(cafe.is_closed(), "tocar de novo abre")
	assert_false(cafe.hud.is_closed_banner_visible())
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_L")
	assert_true(all_messages(cafe).contains(Cafe.OPEN_MESSAGE))


func test_f_key_toggles_the_sign() -> void:
	var cafe := await spawn_cafe()
	press_key(KEY_F)
	await settle()
	assert_true(cafe.is_closed())
	press_key(KEY_F)
	await settle()
	assert_false(cafe.is_closed())


func test_a_closed_cafe_from_the_save_opens_closed() -> void:
	var simulation := quiet_simulation()
	simulation.set_closed(true)
	var cafe := await spawn_cafe(simulation)
	assert_true(cafe.hud.is_closed_banner_visible(), "a faixa já aparece ao abrir o jogo")
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_fechada_L")
	assert_eq((cafe.hud.find_child("ClosedButton", true, false) as Button).icon,
		ArtSprites.get_sprite("botao_door_open").texture)


func test_closing_marks_the_save_dirty() -> void:
	var cafe := await spawn_cafe()
	cafe._save_dirty = false  # como logo depois de um salvamento
	cafe.set_closed(true)
	assert_true(cafe._save_dirty, "a placa é gravada no próximo salvamento")


func test_closed_and_paused_banners_do_not_overlap() -> void:
	var cafe := await spawn_cafe()
	cafe.set_closed(true)
	cafe.set_paused(true)
	await settle()
	var closed := cafe.hud.find_child("ClosedBanner", true, false) as Control
	var paused := cafe.hud.find_child("PauseBanner", true, false) as Control
	assert_true(closed.visible and paused.visible)
	assert_false(closed.get_global_rect().intersects(paused.get_global_rect()), "uma faixa acima da outra")
