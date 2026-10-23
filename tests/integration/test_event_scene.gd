extends CafeTestCase
## Evento na cena (DT-063): o medalhão aparece só durante o evento, com os dias que faltam; tocar abre a historinha,
## um quadro por vez, e depois as missões; ganhar o caldeirão avisa.


func _event_cafe(date := "2026-10-25T12:00:00") -> Cafe:
	var simulation := quiet_simulation()
	clock.time = Time.get_unix_time_from_datetime_string(date)
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_the_medallion_shows_only_during_the_event() -> void:
	var cafe := await _event_cafe()
	assert_true(cafe.hud.is_event_visible())
	assert_eq((cafe.hud.find_child("EventDays", true, false) as Label).text, "9d")
	var later := await _event_cafe("2026-12-01T12:00:00")
	assert_false(later.hud.is_event_visible(), "fora do evento, some")


func test_the_story_then_the_missions() -> void:
	var cafe := await _event_cafe()
	(cafe.hud.find_child("EventButton", true, false) as Button).pressed.emit()
	await settle()
	var dialog := cafe.hud.event_dialog()
	var event := cafe.simulation.current_event()
	assert_true(dialog.visible and cafe.is_dialog_open())
	assert_eq(dialog.text(), event.story[0], "começa pela historinha")
	for page in event.story.size():
		dialog.confirmed.emit()
		await settle()
	assert_eq(dialog.story_page, -1, "depois do último quadro, as missões")
	assert_eq(dialog.mission_texts().size(), 5)
	assert_false(cafe.simulation.event_story_pending(), "a historinha não volta nesta edição")


func test_winning_the_cauldron_is_announced() -> void:
	var cafe := await _event_cafe()
	cafe.simulation.refresh_event()
	var entry := cafe.simulation.event_board.entries()[0]
	cafe.simulation.event_board.record(entry.mission.kind, entry.target, null, -1)
	await settle()
	assert_true(all_messages(cafe).contains("Você ganhou o Caldeirão da Bruxa!"), all_messages(cafe))
