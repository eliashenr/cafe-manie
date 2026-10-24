extends CafeTestCase
## Loja nova (DT-078): categorias à esquerda, grade de cartões e o painel de detalhes com o botão Comprar.


func _text(cafe: Cafe, node_name: String) -> String:
	return (cafe.build_bar.find_child(node_name, true, false) as Label).text


## Benefícios mostrados no painel (só as linhas visíveis).
func _benefits(cafe: Cafe) -> Array[String]:
	var lines: Array[String] = []
	for line: Label in cafe.build_bar.find_child("DetailBenefits", true, false).get_children():
		if line.visible:
			lines.append(line.text.trim_prefix("•  "))
	return lines


## Procura o cartão em todas as páginas da aba aberta.
func _find_card(cafe: Cafe, card_name: String) -> ShopItemButton:
	for page in cafe.build_bar.shop_page_count():
		cafe.build_bar.show_shop_page(page)
		await settle()
		var card := cafe.build_bar.find_button(card_name) as ShopItemButton
		if card != null:
			return card
	return null


func test_opening_the_shop_shows_the_first_item_in_the_detail_panel() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop(BuildBar.ShopTab.SALON)
	await settle()
	var first := cafe.build_bar._items.get_child(0) as ShopItemButton
	assert_true(first.selected, "ao abrir, o primeiro item já está escolhido")
	assert_eq(_text(cafe, "DetailTitle"), first.title)
	assert_true(cafe.build_bar.find_child("Detail", true, false).visible)
	assert_eq(cafe.build_bar._items.get_child_count(), BuildBar.ITEMS_PER_PAGE, "a grade cheia: 5 colunas por 3 linhas")
	for tab: Button in cafe.build_bar._tabs.get_children():
		assert_true(tab.icon != null, "cada categoria tem o ícone dela: " + tab.name)


func test_first_tap_picks_the_item_and_a_second_tap_buys_it() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.earn(Wallet.SOFT, 5000, "teste")
	cafe.build_bar.open_shop(BuildBar.ShopTab.SALON)
	await settle()
	var table := cafe.build_bar.find_button("Build_table_round") as ShopItemButton
	var first := cafe.build_bar._items.get_child(0) as ShopItemButton
	table.pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.VIEW, "o primeiro toque só escolhe")
	assert_true(table.selected, "o cartão escolhido fica destacado")
	assert_eq(first.selected, first == table, "só um destacado por vez")
	var definition := cafe.catalog.get_definition(&"table_round")
	assert_eq(_text(cafe, "DetailTitle"), definition.display_name)
	assert_true(_text(cafe, "DetailText").begins_with("Mesa"), _text(cafe, "DetailText"))
	assert_eq(_text(cafe, "DetailPrice"), UiTheme.thousands(definition.price))
	assert_eq(_text(cafe, "DetailTag"), cafe.simulation.collections.get_definition(definition.collection).display_name)
	assert_eq(cafe.build_bar.find_button("BuyButton").text, "Comprar")
	assert_true(_benefits(cafe).has("+%d de beleza" % definition.beauty), str(_benefits(cafe)))
	table.pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "tocar de novo no mesmo item compra")
	assert_eq(cafe.session.definition.id, &"table_round")


func test_buy_button_buys_the_chosen_item() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.earn(Wallet.SOFT, 5000, "teste")
	cafe.build_bar.open_shop(BuildBar.ShopTab.SALON)
	await settle()
	cafe.build_bar.find_button("Build_chair_wood").pressed.emit()
	await settle()
	cafe.build_bar.find_button("Build_table_round").pressed.emit()  # trocou de ideia: o painel mostra a mesa
	await settle()
	cafe.build_bar.find_button("BuyButton").pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD)
	assert_eq(cafe.session.definition.id, &"table_round", "Comprar leva o item do painel, não o primeiro tocado")


func test_a_locked_stove_shows_its_level_and_real_profile() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	cafe.build_bar.show_shop_collection(&"anos2010")
	await settle()
	var stove := await _find_card(cafe, "Build_stove_steel")
	assert_true(stove != null and stove.disabled, "o fogão inox libera no nível 5")
	stove.pressed.emit()
	await settle()
	var buy := cafe.build_bar.find_button("BuyButton")
	assert_true(buy.disabled)
	assert_eq(buy.text, "Nível 5")
	assert_eq(_text(cafe, "DetailPrice"), "Libera no nível 5")
	assert_true(_text(cafe, "DetailText").begins_with("Fogão"), _text(cafe, "DetailText"))
	assert_eq(_benefits(cafe), ["25% menos tempo para cozinhar", "+8 de beleza"] as Array[String],
		"os benefícios vêm do .tres (perfil do fogão e beleza), nada inventado")
	buy.pressed.emit()
	assert_eq(cafe.mode, Cafe.Mode.VIEW, "bloqueado não compra")
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 5000, "teste")
	await settle()
	assert_false(buy.disabled, "subiu de nível: o painel libera sem fechar a loja")
	assert_eq(buy.text, "Comprar")
	assert_eq(_text(cafe, "DetailPrice"), "900")


func test_trophy_and_terrace_explain_what_they_do() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(99999)
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	await settle()
	var trophy := await _find_card(cafe, "Build_trophy_bronze")
	trophy.pressed.emit()
	await settle()
	assert_true(_text(cafe, "DetailText").begins_with("Troféu"), _text(cafe, "DetailText"))
	assert_true(_benefits(cafe).has("Fogões em volta 25% mais rápidos, por 30 pratos"), str(_benefits(cafe)))
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
	cafe.build_bar.show_shop_collection(&"classico")
	await settle()
	var terrace := await _find_card(cafe, "Terrace")
	terrace.pressed.emit()
	await settle()
	assert_true(_benefits(cafe).has("De dia, quem senta lá paga 25% a mais"), str(_benefits(cafe)))
	var wood := await _find_card(cafe, "Surface_floor_wood")
	wood.pressed.emit()
	await settle()
	assert_true(_text(cafe, "DetailText").begins_with("Piso"), _text(cafe, "DetailText"))
	assert_eq(_text(cafe, "DetailPrice"), "6/piso", "o preço do piso é por piso")
	assert_eq(_benefits(cafe), ["+10 de beleza"] as Array[String])
	var title := cafe.build_bar.find_child("DetailBenefits", true, false).get_parent().get_child(-2) as Label
	assert_true(title.visible, "com benefícios, o título aparece")
	var beige := await _find_card(cafe, "Surface_floor_beige")
	beige.pressed.emit()
	await settle()
	assert_eq(cafe.build_bar.find_button("BuyButton").text, "Usar", "o piso de graça se usa")
	assert_false(title.visible, "sem benefícios, nada de título vazio")


func test_shop_covers_the_side_menu_and_shows_its_note_inside() -> void:
	var cafe := await spawn_cafe()
	var missions := cafe.hud.find_child("MissionsButton", true, false) as Control
	var pause := cafe.hud.find_child("PauseButton", true, false) as Control
	assert_true(missions.is_visible_in_tree() and pause.is_visible_in_tree())
	cafe.build_bar.open_shop(BuildBar.ShopTab.COUPONS)
	await settle()
	assert_false(missions.is_visible_in_tree(), "o menu lateral sai com a loja aberta")
	assert_false(pause.is_visible_in_tree(), "os botões da direita também (a loja ocupa a tela)")
	assert_true(cafe.hud.find_child("Profile", true, false).is_visible_in_tree(), "o perfil e os contadores ficam")
	var note := cafe.build_bar.find_child("ShopNote", true, false) as Label
	assert_true(note.visible and note.text.contains("itens novos em"), note.text)
	assert_false(cafe.build_bar.find_child("Message", true, false).visible, "o aviso vai para dentro da loja")
	assert_true(cafe.build_bar.message_text().contains("itens novos em"))
	cafe.build_bar.close_shop()
	await settle()
	assert_true(missions.is_visible_in_tree() and pause.is_visible_in_tree(), "e voltam quando ela fecha")
