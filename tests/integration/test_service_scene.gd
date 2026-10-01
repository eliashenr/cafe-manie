extends CafeTestCase
## Cozinha e atendimento na cena: painel do fogão, coleta por toque, HUD,
## personagens e feedback visual.


func _place(cafe: Cafe, id: StringName, cell: Vector2i, rotation := 0) -> StringName:
	return cafe.layout.place(cafe.catalog.get_definition(id), cell, rotation)


func _cafe_with_kitchen() -> Array:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(0, 0))
	var counter := _place(cafe, &"counter_basic", Vector2i(2, 0))
	return [cafe, stove, counter]


func test_real_scene_starts_a_new_game_from_data() -> void:
	# Pasta própria e vazia: sem ela, a cena leria o save de quem jogou neste PC.
	var dir := "user://test_new_game"
	DirAccess.make_dir_recursive_absolute(dir)
	var cafe: Cafe = CafeScene.instantiate()
	cafe.save_service = SaveService.new(dir.path_join("save.json"))
	cafe.save_service.delete_save()
	add_to_tree(cafe)
	await tree.process_frame
	var new_game: NewGameConfig = load("res://data/config/new_game.tres")
	assert_eq(cafe.layout.count(), new_game.starter_items.size(), "móveis iniciais no lugar")
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), new_game.starting_gold)
	assert_true(cafe.hud.stats_text().contains("Nível 1"))
	assert_true(cafe.hud.stats_text().contains("Café Ouro: %d" % new_game.starting_gold))


func test_hud_follows_gold_xp_and_popularity() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.earn(Wallet.SOFT, 55, "teste")
	cafe.simulation.progression.add_xp(10)
	await settle()
	var stats := cafe.hud.stats_text()
	assert_true(stats.contains("Café Ouro: 255"), stats)
	assert_true(stats.contains("10 / 30 XP"), stats)
	assert_true(stats.contains("Popularidade: 50%"), stats)


func test_tapping_idle_stove_shows_recipes_with_locks() -> void:
	var setup := await _cafe_with_kitchen()
	var cafe: Cafe = setup[0]
	tap_cell(cafe, Vector2i(0, 0))
	await settle()
	assert_eq(cafe.selected_id, setup[1])
	assert_true(cafe.build_bar.message_text().contains("escolha o que cozinhar"))
	var coffee := cafe.build_bar.find_button("Cook_coffee")
	assert_true(coffee != null and not coffee.disabled, "Café liberado no nível 1")
	var lasagna := cafe.build_bar.find_button("Cook_lasagna")
	assert_true(lasagna != null and lasagna.disabled, "Lasanha bloqueada")
	assert_true(lasagna.text.contains("Nível 6"), "o botão diz quando libera")


func test_cooking_from_the_bar_charges_and_shows_the_timer() -> void:
	var setup := await _cafe_with_kitchen()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	tap_cell(cafe, Vector2i(0, 0))
	await settle()
	cafe.build_bar.find_button("Cook_coffee").pressed.emit()
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING)
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200 - coffee.ingredient_cost)
	await settle()
	assert_true(cafe.build_bar.message_text().contains("pronto em 0:15"), cafe.build_bar.message_text())
	clock.advance(5.0)
	await settle()
	assert_true(cafe.build_bar.message_text().contains("0:10"), "o tempo atualiza sozinho: " + cafe.build_bar.message_text())
	assert_eq(cafe.world_layer.view_for(stove).status_text, "Café 0:10", "etiqueta sobre o fogão")


func test_busy_stove_cannot_be_removed_and_the_bar_says_why() -> void:
	var setup := await _cafe_with_kitchen()
	var cafe: Cafe = setup[0]
	tap_cell(cafe, Vector2i(0, 0))
	cafe.cook_on_selected(&"coffee")
	assert_false(cafe.remove_selected())
	await settle()
	assert_true(cafe.build_bar.message_text().contains("em uso"), cafe.build_bar.message_text())
	assert_false(cafe.start_moving_selected(), "também não dá para mover")


func test_tapping_a_ready_stove_sends_the_dish_to_the_counter() -> void:
	var setup := await _cafe_with_kitchen()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	var counter: StringName = setup[2]
	cafe.simulation.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	await settle()
	assert_true(cafe.world_layer.view_for(stove).status_ready, "etiqueta verde de pronto")

	tap_cell(cafe, Vector2i(0, 0))
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	assert_eq(cafe.simulation.kitchen.counter_stack(counter).servings, coffee.servings)
	assert_eq(cafe.simulation.progression.xp, coffee.xp_reward)
	assert_eq(cafe.selected_id, &"", "servir não seleciona o fogão")
	assert_true(cafe.effects.get_child_count() >= 2, "texto flutuante de porções e XP")
	await settle()
	assert_eq(cafe.world_layer.view_for(counter).status_text, "Café ×6")


func test_full_counter_keeps_the_dish_and_explains() -> void:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(0, 0))
	cafe.simulation.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	tap_cell(cafe, Vector2i(0, 0))
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "sem balcão, o prato fica no fogão")
	assert_eq(cafe.selected_id, stove, "o fogão fica selecionado para explicar")
	await settle()
	assert_true(cafe.build_bar.message_text().contains("Sem espaço no balcão"), cafe.build_bar.message_text())
	assert_true(cafe.build_bar.find_button("ServeButton") != null)


func test_characters_appear_walk_and_leave_the_screen() -> void:
	var simulation := quiet_simulation()
	simulation.customer_types.append(load("res://data/customers/regular.tres"))
	simulation.config.spawn_jitter = 0.0
	var cafe := await spawn_cafe(simulation)
	_place(cafe, &"table_round", Vector2i(4, 4))
	_place(cafe, &"chair_wood", Vector2i(3, 4))
	assert_eq(cafe.world_layer.agent_view_count(), 1, "só o garçom")
	for i in 60:
		simulation.tick(0.1)
	cafe.world_layer.refresh(simulation)
	assert_eq(simulation.customers.size(), 1)
	assert_eq(cafe.world_layer.agent_view_count(), 2, "garçom e cliente na tela")
	simulation.customers[0].state = Customer.State.GONE
	simulation.tick(0.0)
	cafe.world_layer.refresh(simulation)
	await settle()
	assert_eq(cafe.world_layer.agent_view_count(), 1, "quem saiu some da tela")


func test_level_up_announces_the_new_recipe() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(30)
	assert_true(cafe.hud.toast_text().contains("Nível 2"), cafe.hud.toast_text())
	assert_true(cafe.hud.toast_text().contains("Misto-quente"), "diz o que desbloqueou")


func test_payment_shows_floating_gold() -> void:
	var cafe := await spawn_cafe()
	var customer := Customer.new()
	customer.seat_cell = Vector2i(3, 4)
	var before := cafe.effects.get_child_count()
	cafe.simulation.payment_received.emit(customer, 7)
	assert_eq(cafe.effects.get_child_count(), before + 1)
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+7")


func test_time_format() -> void:
	assert_eq(WorldLayer.format_time(9.2), "0:10", "arredonda para cima")
	assert_eq(WorldLayer.format_time(185.0), "3:05")
	assert_eq(WorldLayer.format_time(3730.0), "1:02:10")
