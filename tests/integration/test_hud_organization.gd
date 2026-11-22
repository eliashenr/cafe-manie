extends CafeTestCase
## Organização do HUD: ações explícitas, preferências existentes e uma janela por vez.


func _control(cafe: Cafe, node_name: String) -> Control:
	return cafe.hud.find_child(node_name, true, false) as Control


func _settle_layout() -> void:
	for _frame in 3:
		await tree.process_frame


func _tap(window: Window, control: Control) -> void:
	var at := control.get_global_rect().get_center()
	if window != tree.root:
		at += Vector2(window.position)
	touch(0, at, true)
	touch(0, at, false)
	await _settle_layout()


func _open_settings(cafe: Cafe) -> AcceptDialog:
	await _tap(tree.root, _control(cafe, "SettingsButton"))
	return cafe.hud.settings_dialog()


func test_settings_opens_preferences_without_offering_to_erase_the_cafe() -> void:
	var simulation := quiet_simulation()
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	var cafe := await spawn_cafe(simulation)
	cafe.hud.daily_dialog().hide()
	await _settle_layout()
	var before := SaveCodec.encode(simulation)
	var dialog := await _open_settings(cafe)
	assert_true(dialog.visible, "a engrenagem abre Configurações")
	assert_true(cafe.is_dialog_open(), "Configurações participa da exclusão entre janelas")
	assert_false(cafe.hud.restart_dialog().visible, "abrir preferências não pede apagar progresso")
	assert_true(dialog.size.y <= 520, "a janela não conserva uma altura inflada pelo texto: " + str(dialog.size))
	var bounds := Rect2(Vector2.ZERO, Vector2(dialog.size))
	for button_name in ["SoundButton", "MusicButton", "RestartButton"]:
		var button := _control(cafe, button_name)
		assert_true(button.is_visible_in_tree())
		assert_true(bounds.encloses(button.get_global_rect()), button_name + " cabe na janela")
		assert_true(button.size.y >= UiTheme.MIN_TOUCH, button_name + " mantém área de toque")
	assert_true(bounds.encloses(dialog.get_ok_button().get_global_rect()), "Fechar não sai da janela")
	cafe.hud.show_missions()
	assert_false(cafe.hud.missions_dialog().visible, "Missões espera fechar Configurações")
	cafe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _settle_layout()
	assert_false(cafe.hud.daily_dialog().visible, "voltar ao aplicativo não empilha presente sobre Configurações")
	assert_eq(SaveCodec.encode(simulation), before)
	await _tap(dialog, dialog.get_ok_button())
	assert_false(dialog.visible)
	assert_false(cafe.is_dialog_open())


func test_audio_preferences_can_be_changed_by_touch_and_keep_the_existing_storage() -> void:
	var cafe := await spawn_cafe()
	var path := "user://test_hud_organization_audio.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	cafe.sound_board.settings_path = path
	var before := SaveCodec.encode(cafe.simulation)
	var dialog := await _open_settings(cafe)
	var sound := _control(cafe, "SoundButton") as Button
	var music := _control(cafe, "MusicButton") as Button
	await _tap(dialog, sound)
	assert_true(cafe.sound_board.muted)
	assert_false(cafe.sound_board.music_muted, "efeitos e música continuam independentes")
	assert_eq(sound.text, "Som: desligado")
	await _tap(dialog, music)
	assert_true(cafe.sound_board.music_muted)
	assert_eq(music.text, "Música: desligada")
	var config := ConfigFile.new()
	assert_eq(config.load(path), OK)
	assert_eq(config.get_value("audio", "muted"), true)
	assert_eq(config.get_value("audio", "music_muted"), true)
	await _tap(dialog, sound)
	assert_false(cafe.sound_board.muted)
	assert_true(cafe.sound_board.music_muted)
	await _tap(dialog, dialog.get_ok_button())
	dialog = await _open_settings(cafe)
	assert_eq(sound.text, "Som: ligado", "reabrir mostra a preferência atual")
	assert_eq(music.text, "Música: desligada")
	assert_eq(SaveCodec.encode(cafe.simulation), before, "preferências não alteram a economia ou o progresso")
	cafe.sound_board.settings_path = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_restart_from_settings_requires_confirmation_and_cancel_preserves_progress() -> void:
	var cafe := await spawn_cafe()
	var before := SaveCodec.encode(cafe.simulation)
	var requested := [false]
	cafe.hud.restart_requested.connect(func() -> void: requested[0] = true)
	var settings := await _open_settings(cafe)
	var restart := _control(cafe, "RestartButton") as Button
	assert_true(restart.text.contains("Recomeçar"), "ação destrutiva tem nome explícito")
	assert_true(restart.icon == null, "Recomeçar não usa a engrenagem de configurações")
	await _tap(settings, restart)
	var confirmation := cafe.hud.restart_dialog()
	assert_false(settings.visible, "a confirmação substitui Configurações")
	assert_true(confirmation.visible)
	assert_true(confirmation.get_cancel_button().has_focus(), "Cancelar continua sendo a ação inicial segura")
	assert_false(requested[0])
	assert_eq(SaveCodec.encode(cafe.simulation), before)
	await _tap(confirmation, confirmation.get_cancel_button())
	assert_false(confirmation.visible)
	assert_true(settings.visible, "Cancelar retorna às preferências")
	assert_false(requested[0])
	assert_eq(SaveCodec.encode(cafe.simulation), before)


func test_collapsed_mission_keeps_a_visible_summary_and_can_be_expanded_by_touch() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.set_missions(CafeSimulation.default_missions())
	await _settle_layout()
	var before := SaveCodec.encode(cafe.simulation)
	var details := _control(cafe, "MissionCard")
	var toggle := _control(cafe, "MissionToggle")
	var title := _control(cafe, "MissionTitle") as Label
	var summary := _control(cafe, "MissionSummary") as Label
	var action := _control(cafe, "MissionToggleLabel") as Label
	var mission := cafe.simulation.missions.current()
	assert_true(details.visible)
	assert_eq(title.text, mission.title)
	assert_true(action.text.contains("Recolher"))
	assert_true(toggle.size.y >= UiTheme.MIN_TOUCH)
	await _tap(tree.root, toggle)
	assert_false(details.visible)
	assert_true(toggle.is_visible_in_tree(), "o objetivo não desaparece com a dica")
	assert_eq(title.text, mission.title)
	assert_true(summary.text.contains("0/%d" % mission.target) and summary.text.contains("+%d" % mission.reward_gold))
	assert_true(action.text.contains("Ver dica"))
	assert_true(cafe.hud.mission_text().contains(mission.hint))
	await _tap(tree.root, toggle)
	assert_true(details.visible)
	var hint := _control(cafe, "MissionHint") as Label
	assert_true(hint.is_visible_in_tree() and hint.text == mission.hint, "a instrução completa está visível sem tooltip")
	assert_eq(SaveCodec.encode(cafe.simulation), before, "recolher ou expandir não altera a missão")


func test_operation_and_zoom_share_one_panel_and_keep_their_existing_actions() -> void:
	var cafe := await spawn_cafe()
	await _settle_layout()
	var panel := _control(cafe, "CafeControls")
	for button_name in ["PauseButton", "ClosedButton", "ZoomOutButton", "ZoomInButton"]:
		var button := _control(cafe, button_name)
		assert_true(panel.is_ancestor_of(button), button_name + " pertence ao mesmo painel")
		assert_true(panel.get_global_rect().encloses(button.get_global_rect()), button_name + " cabe no painel")
		assert_true(button.size.x >= UiTheme.MIN_TOUCH and button.size.y >= UiTheme.MIN_TOUCH)
	assert_false(_control(cafe, "SoundButton").is_visible_in_tree(), "áudio sai da lateral e fica em Configurações")
	assert_false(_control(cafe, "MusicButton").is_visible_in_tree())
	await _tap(tree.root, _control(cafe, "PauseButton"))
	assert_true(cafe.simulation.paused)
	assert_eq((_control(cafe, "PauseButton") as Button).text, "Continuar")
	await _tap(tree.root, _control(cafe, "PauseButton"))
	assert_false(cafe.simulation.paused)
	await _tap(tree.root, _control(cafe, "ClosedButton"))
	assert_true(cafe.simulation.closed)
	assert_eq((_control(cafe, "OperationStatus") as Label).text, "Café fechado")
	assert_eq((_control(cafe, "ClosedButton") as Button).text, "Abrir")
	await _tap(tree.root, _control(cafe, "ClosedButton"))
	assert_false(cafe.simulation.closed)
	var zoom_before := cafe.camera.zoom.x
	await _tap(tree.root, _control(cafe, "ZoomOutButton"))
	assert_true(cafe.camera.zoom.x < zoom_before)
	await _tap(tree.root, _control(cafe, "ZoomInButton"))
	assert_almost_eq(cafe.camera.zoom.x, zoom_before)
	assert_true((_control(cafe, "TeamStatus") as Label).text.contains(str(cafe.simulation.waiters.size())))
