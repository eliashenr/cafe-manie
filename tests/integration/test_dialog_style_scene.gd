extends CafeTestCase
## Janelas no padrão Nova York Futurista (DT-079): o papel de cada botão (verde para receber e confirmar, fantasma
## para Fechar e Cancelar, vermelho para apagar, abas iguais às da loja), o fundo escurecido atrás da janela e os
## avisos que continuam à vista.


func _role(button: Button) -> StringName:
	return button.theme_type_variation


func test_each_dialog_button_has_its_role() -> void:
	var cafe := await spawn_cafe()
	var hud := cafe.hud
	assert_eq(_role(hud.missions_dialog().get_ok_button()), UiTheme.GHOST_BUTTON, "Fechar é botão fantasma")
	assert_eq(_role(hud.achievements_dialog().get_ok_button()), UiTheme.GHOST_BUTTON)
	assert_eq(_role(hud.coin_dialog().get_ok_button()), UiTheme.GHOST_BUTTON)
	assert_eq(_role(hud.daily_dialog().get_ok_button()), UiTheme.SUCCESS_BUTTON, "Receber é verde")
	assert_eq(_role(hud.name_dialog().get_ok_button()), UiTheme.SUCCESS_BUTTON)
	assert_eq(_role(hud.name_dialog().get_cancel_button()), UiTheme.GHOST_BUTTON)
	assert_eq(_role(hud.restart_dialog().get_ok_button()), UiTheme.DANGER_BUTTON, "apagar o progresso é vermelho")
	assert_eq(_role(hud.restart_dialog().get_cancel_button()), UiTheme.GHOST_BUTTON)
	var confirm := cafe.build_bar.confirm_dialog()
	assert_eq(_role(confirm.get_ok_button()), UiTheme.SUCCESS_BUTTON, "confirmar uma compra é verde")
	assert_eq(_role(confirm.get_cancel_button()), UiTheme.GHOST_BUTTON)
	assert_true(confirm.dialog_autowrap and confirm.min_size.x == UiTheme.QUESTION_WIDTH, "a pergunta quebra em linhas")
	var avatar := hud.avatar_dialog()
	assert_eq(_role(avatar.find_child("AvatarBuy", true, false) as Button), UiTheme.SUCCESS_BUTTON)
	assert_eq(_role(avatar.find_child("AvatarCancel", true, false) as Button), UiTheme.GHOST_BUTTON)
	assert_eq(_role(avatar.find_child("AvatarTab_HAT", true, false) as Button), UiTheme.TAB_BUTTON)
	var city := hud.city_dialog()
	assert_eq(_role(city.find_child("CollectBranch", true, false) as Button), UiTheme.SUCCESS_BUTTON)
	assert_eq(_role(city.find_child("BranchCancel", true, false) as Button), UiTheme.GHOST_BUTTON)
	assert_eq(_role(city.find_child("CityTab_neighbors", true, false) as Button), UiTheme.TAB_BUTTON)
	cafe.build_bar.open_shop()
	await settle()
	assert_eq(_role(cafe.build_bar.find_button("Tab_SALON")), UiTheme.TAB_BUTTON, "as abas da loja usam o mesmo papel")


func test_theme_defines_every_role() -> void:
	var theme := UiTheme.theme()
	for role in [UiTheme.SUCCESS_BUTTON, UiTheme.GHOST_BUTTON, UiTheme.DANGER_BUTTON, UiTheme.TAB_BUTTON]:
		assert_eq(theme.get_type_variation_base(role), &"Button", "%s é um botão" % role)
		assert_true(theme.has_stylebox("normal", role) and theme.has_stylebox("pressed", role), String(role))
	var success := theme.get_stylebox("normal", UiTheme.SUCCESS_BUTTON) as StyleBoxFlat
	assert_eq(success.bg_color, UiTheme.GREEN)
	var tab_active := theme.get_stylebox("pressed", UiTheme.TAB_BUTTON) as StyleBoxFlat
	assert_eq(tab_active.bg_color, UiTheme.TECH_BLUE, "a aba escolhida em azul tecnológico")
	assert_eq(tab_active.border_color, UiTheme.CYAN, "com a borda ciano")


func test_an_open_dialog_dims_the_cafe_and_moves_the_toast_down() -> void:
	var cafe := await spawn_cafe()
	await settle()
	assert_false(cafe.hud.is_dimmed())
	var toast := cafe.hud.find_child("Toast", true, false) as Control
	assert_eq(toast.anchor_top, 0.0, "sem janela, o aviso fica no alto")
	cafe.hud.show_missions()
	await settle()
	assert_true(cafe.hud.is_dimmed(), "com uma janela aberta, o café escurece atrás dela")
	assert_eq(toast.anchor_top, 1.0, "e o aviso desce (a janela cobriria o do alto)")
	var overlay := cafe.hud.find_child("Overlay", true, false) as CanvasLayer
	assert_true(overlay.layer > cafe.hud.layer and overlay.layer > cafe.build_bar.layer, "o escuro cobre o HUD e a barra")
	assert_true(toast.get_viewport() == overlay.get_viewport() and overlay.is_ancestor_of(toast), "o aviso fica por cima do escuro")
	cafe.hud.missions_dialog().hide()
	await settle()
	assert_false(cafe.hud.is_dimmed())
	assert_eq(toast.anchor_top, 0.0)


func test_daily_cards_mark_today_and_the_days_already_received() -> void:
	var simulation := quiet_simulation()
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	simulation.daily.streak = 2
	simulation.daily.last_claim_day = clock.local_day() - 1
	var cafe := await spawn_cafe(simulation)
	cafe.hud.show_daily_reward()
	var dialog := cafe.hud.daily_dialog()
	assert_eq((dialog.find_child("Day3", true, false).find_child("Caption", true, false) as Label).text, "Hoje")
	assert_true((dialog.find_child("Day1", true, false).find_child("Caption", true, false) as Label).text.begins_with("✓"),
		"os dias já recebidos ganham o visto")
	assert_true((dialog.find_child("Day1", true, false) as Control).modulate.a < 1.0, "e ficam apagados")
	assert_eq((dialog.find_child("Day4", true, false).find_child("Caption", true, false) as Label).text, "Dia 4")


func test_only_the_best_coin_pack_is_marked_best_value() -> void:
	var cafe := await spawn_cafe()
	cafe.hud.show_coin_shop()
	var marked: Array[String] = []
	for pack: Button in cafe.hud.coin_dialog().find_child("CoinPacks", true, false).get_children():
		for label: Label in pack.find_children("*", "Label", true, false):
			if label.text.contains(GameHud.BEST_VALUE_TEXT):
				marked.append(pack.name)
	var best: CoinPack = null
	for pack in cafe.simulation.coin_shop.packs():
		if best == null or pack.gold_per_real() > best.gold_per_real():
			best = pack
	assert_eq(marked, ["Pack_" + String(best.id)] as Array[String], "o selo vai só no pacote que rende mais por real")


func test_event_button_changes_role_with_the_page() -> void:
	var simulation := quiet_simulation()
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T12:00:00")
	var cafe := await spawn_cafe(simulation)
	await settle()
	cafe.hud.show_event()
	var dialog := cafe.hud.event_dialog()
	var event := cafe.simulation.current_event()
	assert_eq(_role(dialog.get_ok_button()), &"", "Próximo é o azul principal")
	for page in event.story.size() - 1:
		dialog.confirmed.emit()
	assert_eq(dialog.get_ok_button().text, "Vamos lá!")
	assert_eq(_role(dialog.get_ok_button()), UiTheme.SUCCESS_BUTTON, "o último quadro anima em verde")
	dialog.confirmed.emit()
	assert_eq(_role(dialog.get_ok_button()), UiTheme.GHOST_BUTTON, "nas missões, Fechar volta a ser fantasma")
