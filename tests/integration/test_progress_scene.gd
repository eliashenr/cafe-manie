extends CafeTestCase
## Conquistas, avisos em fila e (mais abaixo) recompensa diária e nome da cafeteria.


func _cafe_with_achievements() -> Cafe:
	var simulation := quiet_simulation()
	simulation.set_achievements(CafeSimulation.default_achievements())
	return await spawn_cafe(simulation)


func test_unlocking_shows_a_toast_with_the_reward() -> void:
	var cafe := await _cafe_with_achievements()
	cafe.start_placing(&"chair_wood")
	tap_cell(cafe, Vector2i(2, 2))
	tap_cell(cafe, Vector2i(2, 2))
	assert_true(cafe.hud.toast_text().contains("Conquista: Primeira Compra!  +10 ouro"), cafe.hud.toast_text())
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200 - 30 + 10)


func test_toasts_wait_their_turn() -> void:
	var cafe := await spawn_cafe()
	EventBus.message_posted.emit("primeiro")
	EventBus.message_posted.emit("segundo")
	assert_eq(cafe.hud.toast_text(), "primeiro", "um aviso não apaga o outro")
	assert_eq(cafe.hud.queued_messages(), ["segundo"] as Array[String])
	cafe.hud._process(60.0)
	assert_eq(cafe.hud.toast_text(), "segundo")


func test_achievements_panel_lists_progress() -> void:
	var cafe := await _cafe_with_achievements()
	cafe.simulation.stats.add(PlayerStats.CUSTOMERS_SERVED, 12)
	var button := _find(cafe.hud, "AchievementsButton") as Button
	assert_true(button != null, "botão Conquistas no canto de cima")
	button.pressed.emit()
	var dialog := cafe.hud.achievements_dialog()
	assert_true(dialog.visible)
	var total := cafe.simulation.achievements.tiers_total()
	assert_eq(dialog.title, "Conquistas (1 de %d)" % total)
	var row := _find(dialog, "Achievement_a01_customers") as Label
	assert_true(row.text.contains("Primeiro Cliente  (degrau 1 de 3)"), row.text)
	assert_true(row.text.contains("Próximo: Anfitrião — 12/50 clientes servidos (+50 ouro)"), row.text)
	var dishes := _find(dialog, "Achievement_a02_dishes") as Label
	assert_true(dishes.text.contains("Ainda não conquistada"), dishes.text)


func test_completed_achievement_says_so() -> void:
	var cafe := await _cafe_with_achievements()
	cafe.simulation.stats.add(PlayerStats.EXPANSIONS, 4)
	var achievement: AchievementDefinition = cafe.simulation.achievements.achievements.filter(
		func(a: AchievementDefinition) -> bool: return a.id == &"a04_expansions")[0]
	assert_true(cafe.hud.achievement_text(achievement).contains("Completa!"))


func test_stat_changes_trigger_autosave() -> void:
	var dir := "user://test_progress_autosave"
	DirAccess.make_dir_recursive_absolute(dir)
	var service := SaveService.new(dir + "/save.json")
	service.delete_save()
	var cafe: Cafe = CafeScene.instantiate()
	cafe.simulation = quiet_simulation()
	cafe.save_service = service
	cafe.autosave_min_interval = 0.0
	add_to_tree(cafe)
	await settle()
	cafe.simulation.stats.add(PlayerStats.DISHES_COOKED)
	await settle()
	await settle()
	var loaded := service.load_game(ManualClock.new())
	assert_eq(loaded.simulation.stats.value(PlayerStats.DISHES_COOKED), 1)
	service.delete_save()


func _find(root: Node, node_name: String) -> Node:
	return root.find_child(node_name, true, false)


# --- Recompensa diária ---------------------------------------------------------

func _cafe_with_daily() -> Cafe:
	var simulation := quiet_simulation()
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	return await spawn_cafe(simulation)


func test_daily_reward_pops_up_on_start_and_pays() -> void:
	var cafe := await _cafe_with_daily()
	var dialog := cafe.hud.daily_dialog()
	assert_true(dialog.visible, "aparece ao abrir o jogo")
	var today := _find(dialog, "Day1").get_child(0) as Label
	assert_true(today.text.contains("50 ouro"), today.text)
	dialog.get_ok_button().pressed.emit()
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 250)
	assert_true(all_messages(cafe).contains("Recompensa do dia 1: 50 ouro"), all_messages(cafe))
	assert_false(cafe.offer_daily_reward(), "não aparece de novo no mesmo dia")


func test_closing_without_claiming_keeps_the_reward() -> void:
	var cafe := await _cafe_with_daily()
	cafe.hud.daily_dialog().hide()
	assert_true(cafe.simulation.can_claim_daily())
	assert_true(cafe.offer_daily_reward(), "volta a oferecer depois")


func test_next_day_shows_while_the_game_stays_open() -> void:
	var cafe := await _cafe_with_daily()
	cafe.hud.daily_dialog().get_ok_button().pressed.emit()
	clock.advance(86400.0)
	cafe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(cafe.hud.daily_dialog().visible, "voltar ao jogo no dia seguinte oferece o dia 2")
	var day2 := _find(cafe.hud.daily_dialog(), "Day2").get_child(0) as Label
	assert_true(day2.text.contains("20 XP"), day2.text)


func test_quiet_simulation_has_no_daily_popup() -> void:
	var cafe := await spawn_cafe()
	assert_false(cafe.hud.daily_dialog().visible)


func test_daily_reward_waits_for_an_open_question() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(30)
	var cafe := await spawn_cafe(simulation)
	cafe.build_bar.ask_expand()
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	cafe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_false(cafe.hud.daily_dialog().visible, "não empilha janelas: a pergunta aberta vem primeiro")
