extends CafeTestCase
## Janela das missões na cena: as abas das diárias, semanais e do começo, o progresso, o cadeado, a
## contagem até recomeçar e o aviso quando uma missão é concluída.


func _cafe_with_boards() -> Cafe:
	var simulation := quiet_simulation()
	simulation.set_missions(CafeSimulation.default_missions())
	simulation.set_mission_boards(CafeSimulation.load_missions(CafeSimulation.DAILY_MISSIONS_DIR),
		CafeSimulation.load_missions(CafeSimulation.WEEKLY_MISSIONS_DIR))
	simulation.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	var cafe := await spawn_cafe(simulation)
	await settle()
	cafe.hud.daily_dialog().hide()  # o presente do dia abre sozinho ao entrar
	return cafe


func _row(cafe: Cafe, id: String) -> Control:
	return cafe.hud.missions_dialog().find_child("Mission_" + id, true, false) as Control


func _text(row: Control, part: String) -> String:
	return (row.find_child(part, true, false) as Label).text


func test_panel_lists_ten_dailies_twenty_weeklies_and_the_start() -> void:
	var cafe := await _cafe_with_boards()
	cafe.hud.show_missions()
	await settle()
	var dialog := cafe.hud.missions_dialog()
	assert_true(dialog.visible)
	assert_true(cafe.is_dialog_open(), "conta como janela aberta (uma por vez)")
	var tabs := dialog.find_child("MissionTabs", true, false) as TabContainer
	assert_eq(tabs.get_tab_title(0), "Diárias 0/10")
	assert_eq(tabs.get_tab_title(1), "Semanais 0/20")
	assert_false(tabs.is_tab_hidden(2), "o começo aparece enquanto o tutorial não acabou")
	assert_eq((tabs.get_child(0).find_child("List", true, false) as Control).get_child_count(), 10)
	assert_eq((tabs.get_child(1).find_child("List", true, false) as Control).get_child_count(), 20)
	assert_eq(_text(_row(cafe, "d02_serve"), "Title"), "Sirva 12 clientes")
	assert_eq(_text(_row(cafe, "d02_serve"), "Count"), "0/12")
	assert_true(_text(_row(cafe, "d02_serve"), "Reward").contains("+40 ouro"))
	assert_eq(_text(_row(cafe, "w20_slow"), "Count"), "Libera no nível 3", "com cadeado")
	var header := tabs.get_child(0).find_child("Header", true, false) as Label
	assert_true(header.text.contains("Novas em"), header.text)


func test_progress_shows_up_and_completion_is_announced() -> void:
	var cafe := await _cafe_with_boards()
	var gold := cafe.simulation.wallet.balance(Wallet.SOFT)
	cafe.simulation.claim_daily()
	await settle()
	assert_true(all_messages(cafe).contains("Missão diária concluída: Receba o presente diário  +30 ouro  +5 XP"),
		all_messages(cafe))
	assert_true(cafe.simulation.wallet.balance(Wallet.SOFT) > gold + 30)
	cafe.hud.show_missions()
	await settle()
	assert_true(_text(_row(cafe, "d07_gift"), "Title").begins_with("✓ "), "concluída ganha o visto")
	var tabs := cafe.hud.missions_dialog().find_child("MissionTabs", true, false) as TabContainer
	assert_eq(tabs.get_tab_title(0), "Diárias 1/10")
	assert_eq(_text(_row(cafe, "w07_gifts"), "Count"), "1/5")


func test_panel_waits_while_another_window_is_open() -> void:
	var cafe := await _cafe_with_boards()
	cafe.hud.show_achievements()
	cafe.hud.show_missions()
	await settle()
	assert_false(cafe.hud.missions_dialog().visible, "uma janela por vez")


func test_start_tab_hides_when_the_tutorial_is_done() -> void:
	var cafe := await _cafe_with_boards()
	cafe.simulation.missions.restore({"index": 6, "progress": 0})
	cafe.hud.show_missions()
	await settle()
	var tabs := cafe.hud.missions_dialog().find_child("MissionTabs", true, false) as TabContainer
	assert_true(tabs.is_tab_hidden(2))


func test_time_text() -> void:
	assert_eq(MissionsPanel.time_text(5 * 3600 + 12 * 60), "5h 12min")
	assert_eq(MissionsPanel.time_text(2 * 86400 + 3 * 3600 + 30), "2 dias e 3h")
	assert_eq(MissionsPanel.time_text(86400 + 60), "1 dia e 0h")
	assert_eq(MissionsPanel.time_text(59), "1min")
	assert_eq(MissionsPanel.time_text(0), "menos de 1min")
