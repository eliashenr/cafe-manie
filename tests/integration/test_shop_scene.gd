extends CafeTestCase
## Loja, inventário, expansão e missões na cena: o que o jogador vê e toca.


func _gold(cafe: Cafe) -> int:
	return cafe.simulation.wallet.balance(Wallet.SOFT)


## Cafeteria vazia com as missões e expansões reais.
func _cafe_with_game_data() -> Cafe:
	var simulation := quiet_simulation()
	simulation.set_missions(CafeSimulation.default_missions())
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	return await spawn_cafe(simulation)


# --- Loja ------------------------------------------------------------------------

func test_shop_buttons_show_price_and_level_lock() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var table := cafe.build_bar.find_button("Build_table_round")
	assert_true(table.text.contains("60 ouro"), table.text)
	assert_false(table.disabled)
	var long_table := cafe.build_bar.find_button("Build_table_long")
	assert_true(long_table.text.contains("Nível 3"), long_table.text)
	assert_true(long_table.disabled, "móvel de nível alto fica bloqueado")


func test_buttons_turn_off_when_gold_runs_out_without_rebuilding() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var stove := cafe.build_bar.find_button("Build_stove_basic")
	assert_false(stove.disabled, "200 ouro: dá para comprar fogão (150)")
	cafe.simulation.wallet.spend(Wallet.SOFT, 100, "teste")
	await settle()
	assert_true(stove.disabled, "100 ouro: fogão fica indisponível")
	assert_true(is_instance_valid(stove) and stove.is_inside_tree(), "o mesmo botão, atualizado no lugar")


func test_confirming_a_new_item_buys_it() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"table_round")
	tap_cell(cafe, Vector2i(2, 2))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("60 ouro"), "a barra mostra o preço antes de confirmar")
	tap_cell(cafe, Vector2i(2, 2))
	assert_eq(cafe.layout.count(), 1)
	assert_eq(_gold(cafe), 140, "cobrou 60")


func test_cannot_start_placing_what_you_cannot_afford() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.spend(Wallet.SOFT, 200, "teste")
	assert_false(cafe.start_placing(&"table_round"))
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	await settle()
	assert_true(cafe.build_bar.message_text().contains("insuficiente"), cafe.build_bar.message_text())


func test_money_spent_during_placement_is_refused_without_placing() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"stove_basic")
	tap_cell(cafe, Vector2i(1, 1))
	cafe.simulation.wallet.spend(Wallet.SOFT, 100, "teste")  # sobrou 100, fogão custa 150
	assert_false(cafe.confirm_placement())
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "continua construindo; o jogador pode cancelar")
	await settle()
	assert_true(cafe.build_bar.message_text().contains("insuficiente"), cafe.build_bar.message_text())


# --- Inventário --------------------------------------------------------------------

func test_store_button_keeps_the_item_and_placing_again_is_free() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"table_round")
	tap_cell(cafe, Vector2i(2, 2))
	tap_cell(cafe, Vector2i(2, 2))
	var gold := _gold(cafe)
	tap_cell(cafe, Vector2i(2, 2))
	await settle()
	var store := cafe.build_bar.find_button("RemoveButton")
	assert_eq(store.text, "Guardar")
	store.pressed.emit()
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.simulation.inventory.count(&"table_round"), 1)
	await settle()
	var table := cafe.build_bar.find_button("Build_table_round")
	assert_true(table.text.contains("1 guardado"), table.text)

	cafe.start_placing(&"table_round")
	tap_cell(cafe, Vector2i(4, 4))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("guardado"), cafe.build_bar.message_text())
	tap_cell(cafe, Vector2i(4, 4))
	assert_eq(cafe.layout.count(), 1)
	assert_eq(_gold(cafe), gold, "recolocar é grátis")
	assert_eq(cafe.simulation.inventory.count(&"table_round"), 0)


# --- Expansão ----------------------------------------------------------------------

func test_expand_asks_first_then_grows_floor_and_camera() -> void:
	var cafe := await _cafe_with_game_data()
	await settle()
	var expand := cafe.build_bar.find_button("ExpandButton")
	assert_true(expand != null)
	assert_true(expand.disabled and expand.text.contains("Nível 2"), expand.text)

	cafe.simulation.progression.add_xp(30)
	await settle()
	assert_false(expand.disabled)
	assert_true(expand.text.contains("10×8"), expand.text)
	expand.pressed.emit()
	var dialog := cafe.build_bar.expand_dialog()
	assert_true(dialog.visible, "pede confirmação antes de gastar")
	assert_eq(cafe.layout.grid.size, Vector2i(8, 8), "nada muda antes de confirmar")
	assert_true(dialog.get_cancel_button().has_focus(), "o botão seguro vem selecionado")

	dialog.get_ok_button().pressed.emit()
	assert_eq(cafe.layout.grid.size, Vector2i(10, 8))
	assert_eq(_gold(cafe), 50)
	assert_eq(cafe.floor_view.grid_size, Vector2i(10, 8), "o piso acompanha")
	assert_eq(cafe.floor_view.entrance, cafe.layout.entrance)
	var bounds := IsoProjection.grid_bounds(Vector2i(10, 8))
	assert_true(cafe.camera.get_viewport_rect().size.x > 0)
	assert_true(bounds.has_point(IsoProjection.cell_center(Vector2i(9, 7))), "novo canto dentro dos limites")
	assert_true(cafe.hud.toast_text().contains("10×8"), cafe.hud.toast_text())

	tap_cell(cafe, Vector2i(9, 0))
	assert_eq(cafe.selected_cell, Vector2i(9, 0), "dá para tocar nos pisos novos")


func test_cancelling_the_expansion_changes_nothing() -> void:
	var cafe := await _cafe_with_game_data()
	cafe.simulation.progression.add_xp(30)
	await settle()
	cafe.build_bar.find_button("ExpandButton").pressed.emit()
	cafe.build_bar.expand_dialog().get_cancel_button().pressed.emit()
	assert_eq(cafe.layout.grid.size, Vector2i(8, 8))
	assert_eq(_gold(cafe), 200)


# --- Missões -----------------------------------------------------------------------

func test_mission_card_shows_progress_and_hint_then_celebrates() -> void:
	var cafe := await _cafe_with_game_data()
	var stove := cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0))
	cafe.layout.place(cafe.catalog.get_definition(&"counter_basic"), Vector2i(2, 0))
	await settle()
	var text := cafe.hud.mission_text()
	assert_true(text.contains("Missão 1/6: Prepare 3 pratos  (0/3)"), text)
	assert_false(text.split("\n")[1].is_empty(), "a dica aparece embaixo")

	for i in 3:
		cafe.simulation.start_cooking(stove, &"coffee")
		clock.advance(15.0)
		cafe.collect_stove(stove)
		await settle()
		if i < 2:
			assert_true(cafe.hud.mission_text().contains("(%d/3)" % (i + 1)), cafe.hud.mission_text())
	assert_true(cafe.hud.toast_text().contains("Missão concluída: Prepare 3 pratos"), cafe.hud.toast_text())
	assert_true(cafe.hud.toast_text().contains("+30 ouro"), cafe.hud.toast_text())
	assert_true(cafe.hud.mission_text().contains("Missão 2/6: Sirva 3 clientes"), cafe.hud.mission_text())


func test_mission_card_hides_when_everything_is_done() -> void:
	var cafe := await _cafe_with_game_data()
	cafe.simulation.missions.restore({"index": 6, "progress": 0})
	await settle()
	assert_eq(cafe.hud.mission_text(), "")


func test_inventory_and_mission_changes_trigger_autosave() -> void:
	var dir := "user://test_shop_autosave"
	DirAccess.make_dir_recursive_absolute(dir)
	var service := SaveService.new(dir + "/save.json")
	service.delete_save()
	var simulation := quiet_simulation()
	var cafe: Cafe = CafeScene.instantiate()
	cafe.simulation = simulation
	cafe.save_service = service
	cafe.autosave_min_interval = 0.0
	add_to_tree(cafe)
	await settle()
	simulation.inventory.add(&"plant_pot")
	await settle()
	await settle()
	assert_true(FileAccess.file_exists(service.path), "guardar um móvel salva o jogo")
	var loaded := service.load_game(ManualClock.new())
	assert_eq(loaded.simulation.inventory.count(&"plant_pot"), 1)
	service.delete_save()


# --- Venda -------------------------------------------------------------------------

func test_sell_asks_first_then_pays() -> void:
	var cafe := await spawn_cafe()
	cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(2, 2))
	tap_cell(cafe, Vector2i(2, 2))
	await settle()
	cafe.build_bar.find_button("SellButton").pressed.emit()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.dialog_text.contains("30 Café Ouro"), dialog.dialog_text)
	assert_true(dialog.get_cancel_button().has_focus())
	assert_eq(cafe.layout.count(), 1, "nada some antes de confirmar")
	dialog.get_ok_button().pressed.emit()
	assert_eq(cafe.layout.count(), 0)
	assert_eq(_gold(cafe), 230)
	assert_eq(cafe.selected_id, &"")


func test_selling_the_last_stove_is_explained_without_asking() -> void:
	var cafe := await spawn_cafe()
	cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0))
	tap_cell(cafe, Vector2i(0, 0))
	await settle()
	cafe.build_bar.find_button("SellButton").pressed.emit()
	assert_false(cafe.build_bar.confirm_dialog().visible)
	await settle()
	assert_true(cafe.build_bar.message_text().contains("último"), cafe.build_bar.message_text())
	assert_eq(cafe.layout.count(), 1)
