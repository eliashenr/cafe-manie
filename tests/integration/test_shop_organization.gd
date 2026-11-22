extends CafeTestCase
## Organização visual da Loja: os filtros não mudam catálogo, compras, inventário ou save.


func test_types_partition_the_catalog_without_losing_special_items() -> void:
	var cafe := await spawn_cafe()
	var bar := cafe.build_bar
	for tab in [BuildBar.ShopTab.SALON, BuildBar.ShopTab.KITCHEN, BuildBar.ShopTab.WALL]:
		bar.show_shop_tab(tab)
		await settle()
		var original := bar.shop_item_ids()
		var union: Array[StringName] = []
		var filters: Array = {
			BuildBar.ShopTab.SALON: [&"tables", &"seats"],
			BuildBar.ShopTab.KITCHEN: [&"stoves", &"counters", &"drinks"],
			BuildBar.ShopTab.WALL: [&"surfaces", &"windows", &"doors", &"ornaments"],
		}[tab]
		for filter_id: StringName in filters:
			bar.find_button("Filter_" + String(filter_id)).pressed.emit()
			await settle()
			var ids := bar.shop_item_ids()
			assert_false(ids.is_empty(), "o tipo tem itens: " + String(filter_id))
			for id: StringName in ids:
				assert_false(union.has(id), "o item tem um tipo único: " + String(id))
				union.append(id)
		original.sort()
		union.sort()
		assert_eq(union, original, "nenhum item some ao organizar a aba %s" % tab)
	bar.show_shop_tab(BuildBar.ShopTab.KITCHEN)
	bar.show_shop_filter(&"counters")
	assert_true(bar.shop_item_ids().has(&"delivery_counter"), "entregas continua junto dos balcões")
	bar.show_shop_filter(&"drinks")
	assert_true(bar.shop_item_ids().has(&"machine_coffee"), "bebidas encontram a máquina de café")


func test_windows_and_doors_are_discoverable_inside_cultural_collections() -> void:
	var cafe := await spawn_cafe()
	var bar := cafe.build_bar
	bar.show_shop_tab(BuildBar.ShopTab.WALL)
	await settle()
	bar.find_button("Filter_windows").pressed.emit()
	await settle()
	for window_id: StringName in [&"janelao_brasileiro", &"janela_shoji"]:
		# Usa a coleção declarada pelo item, sem inventar aliases de conteúdo.
		var window: WallItemDefinition = cafe.simulation.wall_items.get_definition(window_id)
		bar.find_button("Collection_" + String(window.collection)).pressed.emit()
		await settle()
		assert_eq(bar.shop_item_ids(), [window.id] as Array[StringName])
		assert_true(bar.find_button("WallItem_" + String(window.id)) != null)
		bar.find_button("Filter_doors").pressed.emit()
		await settle()
		assert_false(bar.shop_item_ids().is_empty(), "a mesma coleção também oferece sua porta")
		for id: StringName in bar.shop_item_ids():
			assert_true(cafe.simulation.doors.get_definition(id) != null, "o filtro só mostra portas")
		bar.find_button("Filter_windows").pressed.emit()
		await settle()
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200, "navegar não compra nada")


func test_search_ignores_accents_and_empty_results_offer_a_reset() -> void:
	var cafe := await spawn_cafe()
	var bar := cafe.build_bar
	bar.show_shop_tab(BuildBar.ShopTab.WALL)
	bar.show_shop_filter(&"windows")
	bar.show_shop_search("JANELA JAPAO")
	await settle()
	assert_eq(bar.shop_item_ids(), [&"janela_shoji"] as Array[StringName], "nome e coleção, sem exigir acento")
	assert_eq((bar.find_child("ShopResultCount", true, false) as Label).text, "1 item")
	bar.show_shop_search("item que nao existe")
	await settle()
	assert_true(bar.shop_item_ids().is_empty())
	assert_true((bar.find_child("ShopEmptyState", true, false) as Control).is_visible_in_tree())
	assert_true((bar.find_child("PrevPageButton", true, false) as Button).disabled)
	assert_true((bar.find_child("NextPageButton", true, false) as Button).disabled)
	bar.find_button("ClearShopFiltersButton").pressed.emit()
	await settle()
	assert_eq(bar.shop_filter, &"")
	assert_eq(bar.shop_query, "")
	assert_true(bar.shop_item_ids().has(&"janela_shoji"))
	assert_true(bar.shop_item_ids().has(&"wall_brick"), "limpar também devolve os revestimentos")


func test_typing_search_keeps_focus_and_does_not_trigger_cafe_shortcuts() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop()
	await settle()
	var field := cafe.build_bar.find_child("ShopSearch", true, false) as LineEdit
	field.grab_focus()
	for letter: String in "piso":
		var event := InputEventKey.new()
		event.keycode = letter.to_upper().unicode_at(0)
		event.unicode = letter.unicode_at(0)
		event.pressed = true
		send(event)
		event = event.duplicate()
		event.pressed = false
		send(event)
		await settle()
		assert_true(field.has_focus() and field.is_inside_tree(), "digitar não recria o campo")
	assert_eq(cafe.build_bar.shop_query, "piso")
	assert_false(cafe.is_paused(), "P na busca não pausa o café")


func test_filter_and_page_return_after_cancelling_placement_and_reopening() -> void:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 999999, "teste")
	var cafe := await spawn_cafe(simulation)
	var bar := cafe.build_bar
	bar.show_shop_filter(&"seats")
	bar.open_shop()
	bar.show_shop_page(1)
	await settle()
	assert_eq(bar.shop_page, 1)
	var gold := simulation.wallet.balance(Wallet.SOFT)
	var first := bar._items.get_child(0) as Button
	first.pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD)
	bar.find_button("CancelButton").pressed.emit()
	await settle()
	assert_eq(bar.shop_filter, &"seats")
	assert_eq(bar.shop_page, 1)
	bar.close_shop()
	await settle()
	bar.find_button("ShopButton").pressed.emit()
	await settle()
	assert_eq(bar.shop_filter, &"seats")
	assert_eq(bar.shop_page, 1)
	assert_eq(simulation.wallet.balance(Wallet.SOFT), gold, "cancelar não gasta ouro")


func test_bottom_navigation_has_five_aligned_actions() -> void:
	var cafe := await spawn_cafe()
	await settle()
	await settle()
	var previous := Rect2()
	for entry in [["ShopButton", "Loja"], ["ExpandButton", "Expandir"], ["HireButton", "Garçons"],
			["ChefBarButton", "Chef"], ["CityBarButton", "Cidade"]]:
		var button := cafe.build_bar.find_button(entry[0])
		assert_true(button != null, "entrada estável " + entry[0])
		assert_eq(button.text.split("\n")[0], entry[1])
		assert_eq(button.text.split("\n").size(), 2, "título e estado alinhados")
		var rect := button.get_global_rect()
		assert_true(rect.size.y >= UiTheme.MIN_TOUCH and rect.size.x >= UiTheme.MIN_TOUCH)
		if previous.size != Vector2.ZERO:
			assert_eq(rect.size, previous.size, "todos os botões têm o mesmo tamanho")
			assert_eq(rect.position.y, previous.position.y)
		previous = rect
	assert_eq(cafe.build_bar._buttons.get_child_count(), 5)
	assert_true(cafe.build_bar.find_button("RenovateButton") == null)


func test_selected_collection_is_visible_after_selecting_and_reopening() -> void:
	var cafe := await spawn_cafe()
	var bar := cafe.build_bar
	bar.open_shop()
	await settle()
	for collection: StringName in [&"brasileiro", &"japones"]:
		bar.show_shop_collection(collection)
		await settle()
		await settle()
		var chip := bar.find_button("Collection_" + String(collection))
		var scroll := bar.find_child("CollectionScroll", true, false) as ScrollContainer
		assert_true(chip.button_pressed)
		assert_true(scroll.get_global_rect().encloses(chip.get_global_rect()), "a coleção ativa aparece inteira")
		bar.close_shop()
		await settle()
		scroll.scroll_horizontal = 0
		bar.find_button("ShopButton").pressed.emit()
		await settle()
		await settle()
		chip = bar.find_button("Collection_" + String(collection))
		assert_true(scroll.get_global_rect().encloses(chip.get_global_rect()), "reabrir %s traz %s para %s" % [collection, chip.get_global_rect(), scroll.get_global_rect()])
