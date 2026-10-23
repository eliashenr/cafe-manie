extends CafeTestCase
## Filial na praia na cena (DT-072): o botão Cidade abre a janela com a ilustração; abrir e melhorar pedem
## confirmação, com Cancelar selecionado; coletar faz o ouro subir.


func _open_city(cafe: Cafe) -> CityDialog:
	cafe.build_bar.find_button("CityBarButton").pressed.emit()
	await settle()
	return cafe.hud.city_dialog()


func test_the_branch_art_exists() -> void:
	await spawn_cafe()
	assert_true(ArtSprites.get_sprite("filial_praia") != null, "ilustração da filial")
	assert_true(ArtSprites.get_sprite("icone_cidade") != null, "ícone do botão Cidade")


func test_the_city_button_opens_the_locked_branch() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open_city(cafe)
	assert_true(dialog.visible, "o botão Cidade abre a janela")
	assert_true(cafe.is_dialog_open(), "conta como janela aberta: nada abre por cima (uma por vez)")
	assert_true(dialog.info_text().contains("nível %d" % cafe.simulation.branch_config.unlock_level), dialog.info_text())
	assert_true((dialog.find_child("BranchAction", true, false) as Button).disabled, "bloqueada no começo")
	assert_false((dialog.find_child("CollectBranch", true, false) as Button).visible, "fechada, sem coletar")


func test_opening_collecting_and_upgrading() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 99999, "teste")
	var dialog := await _open_city(cafe)
	var action := dialog.find_child("BranchAction", true, false) as Button
	var gold := sim.wallet.balance(Wallet.SOFT)
	action.pressed.emit()
	await settle()
	assert_true(dialog.confirm_text().contains("Abrir a filial"), dialog.confirm_text())
	assert_true((dialog.find_child("BranchCancel", true, false) as Button).has_focus(), "Cancelar já selecionado")
	assert_false(sim.branch.opened, "nada muda antes de confirmar")
	(dialog.find_child("BranchConfirm", true, false) as Button).pressed.emit()
	await settle()
	assert_true(sim.branch.opened)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - sim.branch_config.open_price)
	assert_true(dialog.heading_text().contains("nível 1"), dialog.heading_text())
	assert_true(dialog.menu_text().contains("Açaí"), dialog.menu_text())
	clock.advance(3600.0)
	await settle()
	var collect := dialog.find_child("CollectBranch", true, false) as Button
	assert_false(collect.disabled, "uma hora depois, tem ouro para coletar")
	gold = sim.wallet.balance(Wallet.SOFT)
	collect.pressed.emit()
	await settle()
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + sim.branch.income_per_hour())
	assert_true(all_messages(cafe).contains("Filial na Praia: +"), all_messages(cafe))
	action.pressed.emit()
	await settle()
	assert_true(dialog.confirm_text().contains("Peixe frito"), "a pergunta conta o prato novo: " + dialog.confirm_text())
	(dialog.find_child("BranchConfirm", true, false) as Button).pressed.emit()
	await settle()
	assert_eq(sim.branch.level, 2)
	gold = sim.wallet.balance(Wallet.SOFT)
	dialog.confirm()  # um toque a mais, sem pergunta na tela
	assert_eq(sim.branch.level, 2, "sem pergunta pendente, nada é comprado")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold)
	assert_true(dialog.menu_text().contains("Peixe frito"), dialog.menu_text())
