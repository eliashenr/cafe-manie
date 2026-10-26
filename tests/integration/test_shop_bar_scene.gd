extends CafeTestCase
## Loja na barra de baixo (DT-088): o café continua à vista, os cartões por página seguem a largura da tela (celular),
## arrastar para o lado troca a página sem comprar, um toque põe o item no café e o que ele faz aparece enquanto ele é
## posicionado; a máquina escolhida conta as bebidas que faz.


func _rich_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 999999, "teste")
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_the_shop_is_a_bar_at_the_bottom() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop()
	await settle()
	await settle()
	var shop := cafe.build_bar.find_child("Shop", true, false) as Control
	var screen := cafe.build_bar.get_viewport().get_visible_rect().size
	var rect := shop.get_global_rect()
	assert_true(rect.end.y > screen.y - 40.0, "colada embaixo: %s em %s" % [rect, screen])
	assert_true(rect.size.y < screen.y * 0.45, "o café continua à vista em cima (altura %d de %d)" % [rect.size.y, screen.y])
	assert_false(cafe.hud.is_rating_visible(), "a satisfação, que ficaria embaixo da barra, sai")
	var missions := cafe.hud.find_child("MissionsButton", true, false) as Control
	assert_true(missions.is_visible_in_tree(), "o menu lateral continua")
	cafe.build_bar.close_shop()
	await settle()
	assert_true(cafe.hud.is_rating_visible())


func test_cards_per_page_follow_the_screen_width() -> void:
	assert_eq(BuildBar.cards_for_width(200.0), BuildBar.SHOP_MIN_ITEMS, "tela estreita: o mínimo")
	assert_eq(BuildBar.cards_for_width(4000.0), BuildBar.SHOP_MAX_ITEMS, "tela larga: o máximo")
	assert_true(BuildBar.cards_for_width(960.0) < BuildBar.cards_for_width(1280.0), "tablet 4:3 mostra menos que a tela 16:9")
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop(BuildBar.ShopTab.SALON)
	await settle()
	var per_page := cafe.build_bar.items_per_page()
	assert_eq(cafe.build_bar._items.get_child_count(), mini(per_page, cafe.build_bar.shop_item_ids().size()),
		"a página tem os cartões que cabem")
	assert_eq(cafe.build_bar.shop_page_count(), ceili(cafe.build_bar.shop_item_ids().size() / float(per_page)))


func test_swiping_the_cards_turns_the_page_without_buying() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop(BuildBar.ShopTab.SALON)
	await settle()
	await settle()
	assert_true(cafe.build_bar.shop_page_count() > 1)
	var first := cafe.build_bar._items.get_child(0) as Control
	var start := first.get_global_rect().get_center()
	touch(0, start, true)
	touch_drag(0, start - Vector2(120, 0))
	touch(0, start - Vector2(120, 0), false)
	await settle()
	assert_eq(cafe.build_bar.shop_page, 1, "arrastar para a esquerda mostra a próxima página")
	assert_eq(cafe.mode, Cafe.Mode.VIEW, "o arrasto não comprou o cartão onde começou")
	first = cafe.build_bar._items.get_child(0) as Control
	start = first.get_global_rect().get_center()
	touch(0, start, true)
	touch_drag(0, start + Vector2(120, 0))
	touch(0, start + Vector2(120, 0), false)
	await settle()
	assert_eq(cafe.build_bar.shop_page, 0, "para a direita volta")
	var table := cafe.build_bar.find_button("Build_table_round")
	var center := table.get_global_rect().get_center()
	touch(0, center, true)
	touch(0, center, false)
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "um toque sem arrastar põe o item no café")


func test_one_tap_places_and_the_bar_explains_the_item() -> void:
	var cafe := await _rich_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.KITCHEN)
	cafe.build_bar.show_shop_collection(&"classico")
	await settle()
	cafe.build_bar.find_button("Build_machine_coffee").pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "um toque começa a posicionar")
	var message := cafe.build_bar.message_text()
	assert_true(message.contains("Máquina de bebidas"), "diz para que serve: " + message)
	assert_true(message.contains("balão verde"), message)
	var beauty: int = (cafe.catalog.get_definition(&"machine_coffee") as FurnitureDefinition).beauty
	assert_true(message.contains("+%d de beleza" % beauty), "e os benefícios: " + message)


func test_a_placed_machine_tells_which_drinks_it_makes() -> void:
	var cafe := await _rich_cafe()
	var machine: FurnitureDefinition = cafe.catalog.get_definition(&"machine_coffee")
	var placed := cafe.layout.place(machine, Vector2i(5, 5))
	assert_true(placed != &"")
	await settle()
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(5, 5)))
	await settle()
	var message := cafe.build_bar.message_text()
	for drink: DrinkDefinition in cafe.simulation.drinks.all():
		if drink.machine == machine.machine:
			assert_true(message.contains(drink.display_name), "%s na lista: %s" % [drink.display_name, message])
	assert_true(message.contains("balão verde") and message.contains("energia"), "e como servir: " + message)
