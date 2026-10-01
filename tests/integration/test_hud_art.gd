extends CafeTestCase
## Interface da v3: contadores, nível, estrelas da satisfação, presente diário com
## cronômetro, botões de zoom, medalhões e a faixa de ícones de baixo.


func _find(cafe: Cafe, node_name: String) -> Node:
	return cafe.find_child(node_name, true, false)


func test_counters_show_gold_with_thousands_and_the_level() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.earn(Wallet.SOFT, 12280, "teste")
	await settle()
	assert_eq((_find(cafe, "GoldValue") as Label).text, "12.480", "200 + 12.280, com ponto de milhar")
	assert_eq((_find(cafe, "LevelValue") as Label).text, "1")
	cafe.simulation.progression.add_xp(30)
	await settle()
	assert_eq((_find(cafe, "LevelValue") as Label).text, "2")
	assert_eq(UiTheme.thousands(1234567), "1.234.567")
	assert_eq(UiTheme.thousands(999), "999")


func test_rating_lights_stars_by_popularity() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.restore_popularity(80.0)
	await settle()
	assert_eq((_find(cafe, "RatingValue") as Label).text, "80%")
	var lit := 0
	var full := ArtSprites.get_sprite("icone_estrela").texture
	for star in _find(cafe, "Rating").find_children("*", "TextureRect", true, false):
		if (star as TextureRect).texture == full:
			lit += 1
	assert_eq(lit, 4, "80% acende 4 de 5 estrelas")


func test_daily_panel_offers_the_gift_then_counts_down() -> void:
	var simulation := quiet_simulation()
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	var cafe := await spawn_cafe(simulation)
	await settle()
	cafe.hud.daily_dialog().hide()  # o presente aparece sozinho na abertura; aqui o jogador fechou
	var panel := _find(cafe, "DailyButton") as Button
	assert_true(cafe.simulation.can_claim_daily())
	panel.pressed.emit()
	assert_true(cafe.hud.daily_dialog().visible, "tocar no presente abre a recompensa")
	cafe.hud.daily_dialog().get_ok_button().pressed.emit()
	await settle()
	assert_false(cafe.simulation.can_claim_daily())
	var digits: Array = panel.find_child("Digits", true, false).find_children("*", "Label", true, false)
	assert_true(digits.size() >= 3, "o cronômetro aparece")
	panel.pressed.emit()
	assert_true(all_messages(cafe).contains("Próximo presente em"), all_messages(cafe))


func test_zoom_buttons_change_the_camera() -> void:
	var cafe := await spawn_cafe()
	var before := cafe.camera.zoom.x
	(_find(cafe, "ZoomOutButton") as Button).pressed.emit()
	assert_true(cafe.camera.zoom.x < before, "afastou")
	(_find(cafe, "ZoomInButton") as Button).pressed.emit()
	(_find(cafe, "ZoomInButton") as Button).pressed.emit()
	assert_true(cafe.camera.zoom.x > before, "aproximou")


func test_missions_medallion_hides_and_shows_the_card() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.set_missions(CafeSimulation.default_missions())
	await settle()
	var card := _find(cafe, "MissionCard") as Control
	assert_true(card.visible, "o cartão da missão começa à vista (tutorial)")
	(_find(cafe, "MissionsButton") as Button).pressed.emit()
	await settle()
	assert_false(card.visible, "o medalhão esconde o cartão")
	assert_false(cafe.hud.mission_text().is_empty(), "a missão continua valendo")
	(_find(cafe, "MissionsBarButton") as Button).pressed.emit()
	await settle()
	assert_true(card.visible, "o ícone de baixo mostra de novo")


func test_icon_bar_opens_the_shop_and_the_achievements() -> void:
	var cafe := await spawn_cafe()
	await settle()
	cafe.build_bar.find_button("RenovateButton").pressed.emit()
	await settle()
	assert_true(cafe.build_bar.shop_open and cafe.build_bar.shop_tab == BuildBar.ShopTab.FLOOR, "Reformar abre os pisos")
	cafe.build_bar.close_shop()
	await settle()
	cafe.build_bar.find_button("AchievementsBarButton").pressed.emit()
	assert_true(cafe.hud.achievements_dialog().visible, "Conquistas abre a lista")
