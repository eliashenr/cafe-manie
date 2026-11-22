extends CafeTestCase
## Geometria e legibilidade que precisam sobreviver aos recursos/eventos opcionais.


func _control(cafe: Cafe, node_name: String) -> Control:
	return cafe.hud.find_child(node_name, true, false) as Control


func _contrast(a: Color, b: Color) -> float:
	var la := a.srgb_to_linear().get_luminance()
	var lb := b.srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func test_all_optional_resources_fit_beside_daily_and_event() -> void:
	var simulation := quiet_simulation()
	clock.time = Time.get_unix_time_from_datetime_string("2026-12-10T12:00:00")
	simulation.wallet.earn(Wallet.COUPONS, 1234, "teste")
	simulation.layout.place(simulation.furniture.get_definition(&"machine_coffee"), Vector2i(0, 0))
	var cafe := await spawn_cafe(simulation)
	await settle()
	var names := ["Profile", "Gold", "EnergyButton", "CouponPill", "Beauty", "DailyButton", "RestartButton", "EventTimer"]
	var viewport := Rect2(Vector2.ZERO, cafe.get_viewport_rect().size)
	for i in names.size():
		var control := _control(cafe, names[i])
		assert_true(control.is_visible_in_tree(), names[i] + " está visível no caso completo")
		assert_true(viewport.encloses(control.get_global_rect()), names[i] + " está dentro da tela")
		for j in range(i + 1, names.size()):
			assert_false(control.get_global_rect().intersects(_control(cafe, names[j]).get_global_rect()),
				names[i] + " não se sobrepõe a " + names[j])
	for name in ["BuyGoldButton", "EnergyButton", "CafeNameButton", "DailyButton"]:
		assert_true(_control(cafe, name).size.y >= UiTheme.MIN_TOUCH, name + " preserva área de toque")


func test_theme_and_cultural_chips_keep_readable_contrast() -> void:
	for ink in [UiTheme.TEXT, UiTheme.TEXT_SOFT, UiTheme.GOLD, UiTheme.CYAN, UiTheme.GREEN, UiTheme.RED]:
		assert_true(_contrast(ink, UiTheme.PANEL) >= 4.5, "texto legível sobre o creme: " + str(ink))
	for fill in [UiTheme.BLUE, UiTheme.GREEN, UiTheme.RED]:
		assert_true(_contrast(Color.WHITE, fill) >= 4.5, "ação com texto branco legível: " + str(fill))
	var catalog := RecipeCatalog.load_from()
	for book in catalog.books():
		assert_true(_contrast(UiTheme.text_on(book.color), book.color) >= 4.5,
			"aba cultural legível: " + String(book.id))


func test_long_toast_wraps_within_the_viewport() -> void:
	var cafe := await spawn_cafe()
	cafe.hud.show_message("Seu café está crescendo. ".repeat(16))
	await settle()
	var toast := _control(cafe, "Toast") as Label
	assert_true(toast.size.y > 60, "mensagem longa quebra em linhas")
	assert_true(toast.size.x <= 560, "aviso não cresce para fora da tela")
	assert_true(toast.position.x >= 0 and toast.position.x + toast.size.x <= cafe.get_viewport_rect().size.x,
		"aviso fica centralizado dentro da tela")
	cafe.hud.show_achievements()
	await settle()
	assert_true(toast.position.y >= 0 and toast.position.y + toast.size.y <= cafe.get_viewport_rect().size.y,
		"ao abrir uma janela o aviso cresce para cima sem cortar o fim")


func test_touch_can_collapse_goal_and_the_missions_keep_its_guidance() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.set_missions(CafeSimulation.default_missions())
	await settle()
	var card := _control(cafe, "MissionCard")
	var at := card.get_global_rect().get_center()
	touch(0, at, true)
	touch(0, at, false)
	await settle()
	assert_false(card.visible, "toque real recolhe o objetivo")
	cafe.hud.show_missions()
	await settle()
	var tabs := cafe.hud.missions_dialog().find_child("MissionTabs", true, false) as TabContainer
	assert_true(tabs.get_tab_bar().get_tab_rect(0).size.y >= UiTheme.MIN_TOUCH, "abas das missões aceitam toque confortável")
	var current := cafe.simulation.missions.current()
	var row := cafe.hud.missions_dialog().find_child("Mission_" + String(current.id), true, false)
	var hint := row.find_child("Hint", true, false) as Label
	assert_true(hint != null and hint.text == current.hint, "a instrução completa continua acessível nas Missões")
