extends CafeTestCase
## Apresentação da Cidade: estados legíveis sem duplicar regras de filial ou visitas.


func _city(cafe: Cafe) -> CityDialog:
	cafe.build_bar.find_button("CityBarButton").pressed.emit()
	await settle()
	return cafe.hud.city_dialog()


func _label(dialog: CityDialog, label_name: String) -> String:
	return (dialog.find_child(label_name, true, false) as Label).text


func test_city_explains_locked_branch_and_uses_the_actual_balance() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _city(cafe)
	assert_eq(dialog.title, "Cidade")
	assert_eq((dialog.find_child("CityTab_branch", true, false) as Button).text, "Filial")
	assert_true(_label(dialog, "BranchStatus").contains(str(cafe.simulation.branch_config.unlock_level)))
	assert_true(_label(dialog, "BranchReserve").contains("Seu café: nível"))
	assert_true(_label(dialog, "CityBalance").contains(UiTheme.thousands(cafe.simulation.wallet.balance(Wallet.SOFT))))
	assert_true((dialog.find_child("BranchAction", true, false) as Button).disabled)
	assert_false((dialog.find_child("NeighborsScroll", true, false) as Control).visible)


func test_city_shows_missing_gold_and_keeps_cancel_selected_before_buying() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "preparar saldo insuficiente")
	var dialog := await _city(cafe)
	var action := dialog.find_child("BranchAction", true, false) as Button
	assert_true(action.disabled, "o custo indisponível é explicado antes da confirmação")
	assert_true(_label(dialog, "BranchCostHint").contains("Faltam"))
	sim.wallet.earn(Wallet.SOFT, sim.branch_config.open_price, "teste")
	await settle()
	assert_false(action.disabled, "o estado acompanha a carteira com a janela aberta")
	action.pressed.emit()
	await settle()
	assert_true((dialog.find_child("BranchCancel", true, false) as Button).has_focus())
	assert_false(sim.branch.opened, "abrir a pergunta não compra")
	assert_true(dialog.confirm_text().contains(UiTheme.thousands(sim.branch_config.open_price)))
	dialog.cancel()
	assert_eq(dialog.confirm_text(), "")
	assert_false(sim.branch.opened)


func test_city_separates_full_reserve_from_completed_branch() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.branch.open(clock.now())
	sim.branch.level = sim.branch_config.max_level()
	clock.advance(sim.branch.capacity_hours() * 3600.0)
	var dialog := await _city(cafe)
	assert_true(_label(dialog, "BranchStatus").contains("Reserva cheia"))
	assert_true(_label(dialog, "BranchCostHint").contains("Filial completa"))
	assert_false((dialog.find_child("BranchAction", true, false) as Button).visible)
	assert_false((dialog.find_child("CollectBranch", true, false) as Button).disabled)
	var progress := dialog.find_child("BranchProgress", true, false) as ProgressBar
	assert_eq(progress.value, progress.max_value)
	dialog.collect()
	await settle()
	assert_eq(progress.value, 0.0)
	assert_true(_label(dialog, "BranchStatus").contains("trabalhando"))
	assert_true(_label(dialog, "BranchCostHint").contains("Filial completa"))


func test_neighbor_cards_explain_local_visits_and_refresh_when_the_day_changes() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	var dialog := await _city(cafe)
	dialog.show_tab(&"neighbors")
	await settle()
	assert_true(_label(dialog, "CitySummary").contains("personagens da cidade"))
	var frame := dialog.find_child("Neighbor_beto", true, false)
	assert_true((frame.find_child("CafeName", true, false) as Label).text.contains(sim.neighbors.get_definition(&"beto").cafe_name))
	assert_true((frame.find_child("VisitStatus", true, false) as Label).text.contains("XP"))
	var button := dialog.neighbor_button(&"beto")
	sim.visit_neighbor(&"beto")
	await settle()
	assert_true(button.disabled)
	assert_eq(button.text, "Visitado hoje")
	assert_true((frame.find_child("VisitStatus", true, false) as Label).text.contains("amanhã"))
	clock.advance(86400.0)
	await settle()
	assert_false(button.disabled, "a virada do dia atualiza o cartão sem fechar a janela")
	assert_true(button == dialog.neighbor_button(&"beto"), "a atualização não recria controles a cada quadro")
	assert_true((frame.find_child("Friendship", true, false) as Label).text.contains("1/"))
