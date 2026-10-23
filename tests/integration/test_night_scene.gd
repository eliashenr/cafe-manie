extends CafeTestCase
## Noite na cena (DT-064): de dia o mundo fica com a cor normal e as luminárias apagadas; à noite escurece e elas
## acendem; o livro mostra os pratos da noite apagados de dia, com "Só à noite"; anoitecer avisa.


func _night_cafe(hour: float) -> Cafe:
	var simulation := quiet_simulation()
	clock.offset = 0
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T00:00:00") + hour * 3600.0
	simulation.progression.add_xp(99999)  # nível 30
	simulation.wallet.earn(Wallet.SOFT, 50000, "teste")
	simulation.layout.place(simulation.furniture.get_definition(&"stove_moon"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(3, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"floor_lamp"), Vector2i(5, 5))
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_day_and_night_look() -> void:
	var day := await _night_cafe(12.0)
	assert_eq(day.night_tint.color, Color.WHITE, "de dia, sem escuro")
	var lamp_day := day.world_layer.view_for(day.layout.placement_at(Vector2i(5, 5)).id)
	assert_false(lamp_day.light_on(), "de dia, apagada")
	clock.advance(11 * 3600.0)  # o jogo continua aberto até as 23h
	await settle()
	assert_true(day.night_tint.color.is_equal_approx(NightTint.NIGHT_COLOR), "com o jogo aberto, escurece quando anoitece")
	var night := await _night_cafe(23.0)
	assert_true(night.night_tint.color.is_equal_approx(NightTint.NIGHT_COLOR), "noite fechada")
	var lamp_night := night.world_layer.view_for(night.layout.placement_at(Vector2i(5, 5)).id)
	assert_true(lamp_night.light_on(), "à noite, a luminária acende")


func test_the_book_shows_night_dishes_only_at_night() -> void:
	var cafe := await _night_cafe(12.0)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()
	cafe.build_bar.find_button("Book_noite").pressed.emit()
	await settle()
	var card := cafe.build_bar.find_button("Cook_fondue")
	assert_true(card.disabled and card.text.contains("Só à noite"), card.text)


func test_nightfall_is_announced() -> void:
	var cafe := await _night_cafe(18.9)
	clock.advance(0.2 * 3600.0)
	cafe.simulation.tick(0.1)
	await settle()
	assert_true(all_messages(cafe).contains(Cafe.NIGHT_MESSAGE), all_messages(cafe))
