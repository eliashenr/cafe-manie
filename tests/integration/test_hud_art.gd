extends CafeTestCase
## Interface da v3: contadores, nível, estrelas da popularidade, presente diário com
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
	assert_eq((_find(cafe, "RatingValue") as Label).text, "80/100")
	var lit := 0
	var full := ArtSprites.get_sprite("icone_estrela").texture
	for star in _find(cafe, "Rating").find_children("*", "TextureRect", true, false):
		if (star as TextureRect).texture == full:
			lit += 1
	assert_eq(lit, 4, "80/100 acende 4 de 5 estrelas")


## A popularidade sobe e desce com o atendimento: não pode parecer a parte dos clientes que saiu satisfeita (DT-090).
func test_popularity_is_named_for_what_it_measures() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var rating := _find(cafe, "Rating")
	assert_eq((_find(cafe, "RatingCaption") as Label).text, "Popularidade")
	for label in rating.find_children("*", "Label", true, false):
		var text: String = (label as Label).text
		assert_false(text.contains("%") or text.contains("Satisfeit"), "sem cara de percentual de satisfeitos: " + text)
	assert_true(cafe.hud.stats_text().contains("Popularidade: 50/100"), cafe.hud.stats_text())


## A barra da beleza enche junto com o bônus, que vai até beauty_for_max_bonus, e não num 100 fixo (DT-090).
func test_beauty_bar_follows_the_real_bonus() -> void:
	var cafe := await spawn_cafe()
	await settle()
	cafe.layout.place(cafe.catalog.get_definition(&"plant_pot"), Vector2i(0, 7))
	await settle()
	assert_almost_eq((_find(cafe, "BeautyBar") as StripedBar).value, cafe.simulation.beauty_factor(), 0.001)


## Cada função só tem um lugar, e continua alcançável com a loja aberta (DT-090).
func test_menus_are_not_repeated_and_stay_reachable() -> void:
	var cafe := await spawn_cafe()
	await settle()
	for repeated in ["MissionsBarButton", "GiftsBarButton", "AchievementsBarButton", "GiftButton"]:
		assert_true(_find(cafe, repeated) == null, "sem o botão repetido " + repeated)
	cafe.build_bar.open_shop()
	await settle()
	for reachable in ["MissionsButton", "AchievementsButton", "DailyButton"]:
		assert_true((_find(cafe, reachable) as Control).is_visible_in_tree(), reachable + " continua à vista com a loja aberta")


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


func test_mission_card_hides_on_tap_and_the_medallion_opens_the_missions() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.set_missions(CafeSimulation.default_missions())
	await settle()
	var card := _find(cafe, "MissionCard") as Control
	assert_true(card.visible, "o cartão da missão começa à vista (tutorial)")
	click(card.get_global_rect().get_center())
	await settle()
	assert_false(card.visible, "tocar no cartão esconde")
	assert_false(cafe.hud.mission_text().is_empty(), "a missão continua valendo")
	(_find(cafe, "MissionsButton") as Button).pressed.emit()
	await settle()
	assert_true(cafe.hud.missions_dialog().visible, "o medalhão abre as missões")
	assert_true(card.visible, "e o cartão volta")


func test_icon_bar_opens_the_shop_and_the_achievements() -> void:
	var cafe := await spawn_cafe()
	await settle()
	cafe.build_bar.find_button("RenovateButton").pressed.emit()
	await settle()
	assert_true(cafe.build_bar.shop_open and cafe.build_bar.shop_tab == BuildBar.ShopTab.FLOOR, "Reformar abre os pisos")
	cafe.build_bar.close_shop()
	await settle()
	(_find(cafe, "AchievementsButton") as Button).pressed.emit()
	assert_true(cafe.hud.achievements_dialog().visible, "Conquistas abre a lista")


## Cartão do perfil (DT-077): o retrato do chef acompanha o avatar; o nome do café, o nível e a barra de XP.
func test_profile_card_shows_the_chef_name_level_and_xp() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var portrait := _find(cafe, "ChefPortrait") as AvatarPortrait
	assert_eq(portrait.layers[1], "avatar_cabeca_clara_curto_castanho", "o retrato é o avatar do chef")
	cafe.simulation.use_avatar_part(&"hair_rabo_preto")
	await settle()
	assert_eq(portrait.layers[1], "avatar_cabeca_clara_rabo_preto", "e troca junto com o avatar")
	assert_eq((_find(cafe, "CafeNameButton") as Button).text, "Cafeteria de Teste")
	assert_eq((_find(cafe, "XpBar") as StripedBar).text, "0 / 30 XP")
	assert_true((_find(cafe, "BeautyBar") as StripedBar).text.begins_with("Beleza "))

