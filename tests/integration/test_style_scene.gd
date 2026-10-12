extends CafeTestCase
## Abas da loja, revestimentos de piso e parede e a beleza no HUD.


func test_shop_tabs_split_furniture_and_decor() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop()
	await settle()
	assert_true(cafe.build_bar.find_button("Build_table_round") != null, "Salão é a aba inicial")
	assert_true(cafe.build_bar.find_button("Build_stove_basic") == null, "fogão fica em Cozinha")
	assert_true(cafe.build_bar.find_button("Build_plant_pot") == null, "planta fica em Decoração")
	cafe.build_bar.find_button("Tab_DECOR").pressed.emit()
	await settle()
	assert_true(cafe.build_bar.find_button("Build_plant_pot") != null)
	assert_true(cafe.build_bar.find_button("Build_table_round") == null)
	assert_true(cafe.build_bar.find_button("Tab_DECOR").button_pressed, "a aba ativa aparece marcada")


func test_new_cafe_draws_default_floor_and_walls() -> void:
	var cafe := await spawn_cafe()
	assert_eq(cafe.floor_view.floor_style.id, &"floor_beige")
	assert_eq(cafe.wall_view.wall_style.id, &"wall_cream")
	assert_eq(cafe.wall_view.grid_size, Vector2i(8, 8))


func test_choosing_a_floor_starts_a_renovation_where_taps_mark_cells() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
	cafe.build_bar.show_shop_collection(&"classico")
	await settle()
	var wood := cafe.build_bar.find_button("Surface_floor_wood")
	assert_true(wood.text.contains("6 ouro/piso"), "o preço é por piso: " + wood.text)
	wood.pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.PAINT, "escolher o piso começa a reforma")
	assert_true(cafe.build_bar.find_button("Surface_floor_wood") == null and cafe.build_bar.find_button("ConfirmButton") != null,
		"a loja sai da frente e entram os controles da reforma (ao terminar, ela volta)")
	tap_cell(cafe, Vector2i(2, 2))
	tap_cell(cafe, Vector2i(3, 2))
	tap_cell(cafe, Vector2i(4, 2))
	tap_cell(cafe, Vector2i(4, 2))  # tocar de novo desmarca
	await settle()
	assert_eq(cafe.paint_target_count(), 2)
	assert_eq(cafe.floor_view.surface_at(Vector2i(2, 2)).id, &"floor_wood", "a prévia já mostra o piso novo")
	assert_true(cafe.build_bar.message_text().contains("2 marcados · 12 ouro"), cafe.build_bar.message_text())
	assert_eq(cafe.simulation.style.floor_at(Vector2i(2, 2)), &"floor_beige", "nada muda antes de confirmar")

	cafe.build_bar.find_button("ConfirmButton").pressed.emit()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible, "pagar pede confirmação (seção 32)")
	assert_true(dialog.get_cancel_button().has_focus(), "Cancelar já selecionado")
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_eq(cafe.simulation.style.floor_at(Vector2i(2, 2)), &"floor_wood")
	assert_eq(cafe.simulation.style.floor_at(Vector2i(3, 2)), &"floor_wood")
	assert_eq(cafe.simulation.style.floor_at(Vector2i(0, 0)), &"floor_beige", "o resto continua como estava")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 188, "6 ouro por piso")
	assert_eq(cafe.floor_view.surface_at(Vector2i(3, 2)).id, &"floor_wood", "o piso desenhado acompanha")
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_true(all_messages(cafe).contains("Reforma feita"), all_messages(cafe))


func test_walls_are_painted_one_stretch_at_a_time() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.start_painting(&"wall_brick"))
	var stretch := CafeStyle.segment(CafeStyle.EDGE_TOP, 3)
	var center := Vector2.ZERO
	for point in cafe.wall_view.segment_polygon(stretch):
		center += point / 4.0
	assert_eq(cafe.wall_view.segment_at(center), stretch, "o toque acha o trecho de parede")
	cafe.toggle_paint_at(center)
	assert_eq(cafe.paint_cost(), 30)
	cafe.build_bar.ask_confirm_paint()
	cafe.build_bar.confirm_dialog().get_ok_button().pressed.emit()
	await settle()
	assert_eq(cafe.simulation.style.wall_at(stretch), &"wall_brick")
	assert_eq(cafe.simulation.style.wall_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 4)), &"wall_cream", "só o trecho tocado")
	assert_eq(cafe.wall_view.surface_at(stretch).id, &"wall_brick", "a parede desenhada acompanha")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 170)


func test_paint_all_then_cancel_changes_nothing() -> void:
	var cafe := await spawn_cafe()
	cafe.start_painting(&"wall_brick")
	await settle()
	cafe.build_bar.find_button("PaintAllButton").pressed.emit()
	assert_eq(cafe.paint_target_count(), 31, "Tudo marca as paredes do fundo (8 + 8) e a mureta da frente (8 + 7)")
	cafe.build_bar.find_button("CancelButton").pressed.emit()
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_eq(cafe.simulation.style.wall_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 0)), &"wall_cream")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200)
	assert_eq(cafe.wall_view.paint_segments.size(), 0, "a prévia some")


func test_front_wall_stretch_is_painted_by_tapping_it() -> void:
	var cafe := await spawn_cafe()
	cafe.start_painting(&"wall_brick")
	var stretch := CafeStyle.segment(CafeStyle.EDGE_BOTTOM, 5)
	var center := Vector2.ZERO
	for point in cafe.front_view.segment_polygon(stretch):
		center += point / 4.0
	cafe.toggle_paint_at(center)
	assert_eq(cafe.paint_target_count(), 1)
	assert_eq(cafe.front_view.surface_at(stretch).id, &"wall_brick", "a prévia aparece na mureta")
	cafe.build_bar.ask_confirm_paint()
	cafe.build_bar.confirm_dialog().get_ok_button().pressed.emit()
	assert_eq(cafe.simulation.style.wall_at(stretch), &"wall_brick")
	assert_eq(cafe.front_view.surface_at(stretch).id, &"wall_brick")


func test_hanging_a_tv_on_the_wall() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	await settle()
	var tv := cafe.build_bar.find_button("WallItem_tv")
	while tv == null and cafe.build_bar.shop_page < cafe.build_bar.shop_page_count() - 1:
		cafe.build_bar.show_shop_page(cafe.build_bar.shop_page + 1)
		await settle()
		tv = cafe.build_bar.find_button("WallItem_tv")
	assert_true(tv != null and tv.disabled, "a TV está na aba Paredes, bloqueada no começo")
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 1000, "teste")
	await settle()
	tv.pressed.emit()
	await settle()
	assert_true(cafe.hanging_items and cafe.mode == Cafe.Mode.PAINT, "escolher o item começa a pendurar")
	var stretch := CafeStyle.segment(CafeStyle.EDGE_TOP, 5)
	var center := Vector2.ZERO
	for point in cafe.wall_view.segment_polygon(stretch):
		center += point / 4.0
	cafe.toggle_paint_at(center)
	assert_eq(cafe.wall_view.item_at(stretch).id, &"tv", "a prévia mostra a TV na parede")
	var gold := sim.wallet.balance(Wallet.SOFT)
	cafe.build_bar.find_button("ConfirmButton").pressed.emit()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.get_cancel_button().has_focus(), "pagar pede confirmação")
	assert_eq(sim.style.wall_item_at(stretch), &"", "nada muda antes de confirmar")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold)
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_eq(sim.style.wall_item_at(stretch), &"tv")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - sim.wall_items.get_definition(&"tv").price)
	assert_eq(cafe.wall_view.item_at(stretch).id, &"tv")
	assert_true(all_messages(cafe).contains("Pendurado"), all_messages(cafe))


func test_taking_a_decoration_off_is_free() -> void:
	var cafe := await spawn_cafe()
	var stretch := CafeStyle.segment(CafeStyle.EDGE_TOP, 2)
	cafe.simulation.style.hang([stretch] as Array[String], &"janela")
	await settle()
	assert_eq(cafe.wall_view.item_at(stretch).id, &"janela")
	assert_true(cafe.start_hanging(&""))
	var center := Vector2.ZERO
	for point in cafe.wall_view.segment_polygon(stretch):
		center += point / 4.0
	cafe.toggle_paint_at(center)
	cafe.build_bar.ask_confirm_paint()
	assert_false(cafe.build_bar.confirm_dialog().visible, "de graça: sem pergunta")
	assert_eq(cafe.simulation.style.wall_item_at(stretch), &"")
	assert_eq(cafe.wall_view.item_at(stretch), null)


func test_surface_bought_before_paints_for_free_without_asking() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.style.own(&"wall_brick")  # comprada inteira num save antigo
	cafe.start_painting(&"wall_brick")
	cafe.paint_all()
	cafe.build_bar.ask_confirm_paint()
	assert_false(cafe.build_bar.confirm_dialog().visible, "de graça: não precisa perguntar")
	assert_eq(cafe.simulation.style.wall_at(CafeStyle.segment(CafeStyle.EDGE_LEFT, 5)), &"wall_brick")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200)


func test_locked_surface_button_is_disabled() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
	cafe.build_bar.show_shop_collection(&"classico")
	await settle()
	var marble := cafe.build_bar.find_button("Surface_floor_marble")
	assert_true(marble.disabled and marble.text.contains("Nível 5"), marble.text)


func test_hud_shows_beauty() -> void:
	var cafe := await spawn_cafe()
	cafe.layout.place(cafe.catalog.get_definition(&"plant_pot"), Vector2i(0, 7))
	await settle()
	assert_true(cafe.hud.stats_text().contains("Beleza: 15"), cafe.hud.stats_text())


func test_walls_grow_with_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(30)
	var cafe := await spawn_cafe(simulation)
	cafe.expand_cafe()
	assert_eq(cafe.wall_view.grid_size, Vector2i(10, 8))
