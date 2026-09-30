extends CafeTestCase
## Abas da loja, revestimentos de piso e parede e a beleza no HUD.


func test_shop_tabs_split_furniture_and_decor() -> void:
	var cafe := await spawn_cafe()
	await settle()
	assert_true(cafe.build_bar.find_button("Build_table_round") != null, "Móveis é a aba inicial")
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


func test_buying_a_floor_asks_first_then_applies() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
	await settle()
	var wood := cafe.build_bar.find_button("Surface_floor_wood")
	assert_true(wood.text.contains("90 ouro"), wood.text)
	wood.pressed.emit()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible, "comprar pede confirmação (seção 32)")
	assert_true(dialog.get_cancel_button().has_focus(), "Cancelar já selecionado")
	assert_eq(cafe.simulation.style.floor_id, &"floor_beige", "nada muda antes de confirmar")

	dialog.get_ok_button().pressed.emit()
	assert_eq(cafe.simulation.style.floor_id, &"floor_wood")
	assert_eq(cafe.floor_view.floor_style.id, &"floor_wood", "o piso desenhado acompanha")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 110)
	await settle()
	assert_true(wood.text.contains("Em uso") and wood.disabled, wood.text)
	var beige := cafe.build_bar.find_button("Surface_floor_beige")
	assert_true(beige.text.contains("Aplicar"), beige.text)


func test_owned_surface_applies_without_asking() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.use_surface(cafe.simulation.surfaces.get_definition(&"wall_brick"))
	cafe.simulation.use_surface(cafe.simulation.surfaces.get_definition(&"wall_cream"))
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	await settle()
	var gold := cafe.simulation.wallet.balance(Wallet.SOFT)
	cafe.build_bar.find_button("Surface_wall_brick").pressed.emit()
	assert_false(cafe.build_bar.confirm_dialog().visible, "já é seu: troca direto")
	assert_eq(cafe.wall_view.wall_style.id, &"wall_brick")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), gold)


func test_cancelling_a_surface_purchase_changes_nothing() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	await settle()
	cafe.build_bar.find_button("Surface_wall_brick").pressed.emit()
	cafe.build_bar.confirm_dialog().get_cancel_button().pressed.emit()
	assert_eq(cafe.simulation.style.wall_id, &"wall_cream")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200)


func test_locked_surface_button_is_disabled() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.FLOOR)
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
