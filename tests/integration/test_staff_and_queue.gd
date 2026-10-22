extends CafeTestCase
## Na tela: contratar garçom (com confirmação), a fila na calçada e os pedidos que faltam cozinhar
## no painel do fogão.


func test_hire_button_shows_the_level_then_the_price_and_asks_first() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var sim := cafe.simulation
	var hire := cafe.build_bar.find_button("HireButton")
	assert_true(hire != null, "a faixa de baixo tem o botão de contratar")
	assert_true(hire.disabled and hire.text.contains("Nível %d" % sim.next_waiter_level()), hire.text)
	while sim.progression.level < sim.next_waiter_level():
		sim.progression.add_xp(sim.progression.table.xp_for_next(sim.progression.level))
	sim.wallet.earn(Wallet.SOFT, sim.next_waiter_price(), "teste")
	await settle()
	assert_false(hire.disabled)
	assert_true(hire.text.contains(UiTheme.thousands(sim.next_waiter_price())), hire.text)
	hire.pressed.emit()
	var dialog := cafe.build_bar.expand_dialog()
	assert_true(dialog.visible, "pede confirmação antes de gastar")
	assert_true(dialog.get_cancel_button().has_focus(), "o botão seguro vem selecionado")
	assert_eq(sim.waiters.size(), 1, "nada muda antes de confirmar")
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_eq(sim.waiters.size(), 2)
	assert_true(all_messages(cafe).contains("Garçom contratado"), all_messages(cafe))
	assert_true(cafe.world_layer.get_node_or_null("Agent_%d" % sim.waiters[1].serial) != null, "o garçom novo aparece")


func test_the_line_waits_on_the_sidewalk_and_who_gives_up_walks_away() -> void:
	var simulation := quiet_simulation()
	simulation.customer_types.append(load("res://data/customers/regular.tres"))
	simulation.config.spawn_jitter = 0.0
	simulation.config.spawn_interval = 1.0
	var cafe := await spawn_cafe(simulation)
	for i in 60:  # sem nenhuma cadeira: todo mundo que chega vai para a fila
		simulation.tick(0.1)
	cafe.world_layer.refresh(simulation)
	var line := simulation.queued()
	assert_true(line.size() >= 2, "a fila se formou")
	var front_edge := simulation.layout.grid.size.x - 0.5
	for customer in line:
		assert_true(customer.position.x > front_edge, "a fila fica na calçada, fora da cafeteria")
		var view: AgentView = cafe.world_layer.get_node("Agent_%d" % customer.serial)
		assert_true(view.shown.distance_to(customer.position + WorldLayer.QUEUE_WALK) < 0.01,
			"quem entra na fila chega andando pela calçada")
	var first := line[0]
	first.patience_left = 0.0
	simulation.tick(0.1)
	cafe.world_layer.refresh(simulation)
	assert_true(first.gave_up_in_line)
	assert_eq(cafe.world_layer.exiting_count(), 1, "quem desistiu termina a caminhada na tela")


func test_stove_panel_shows_how_many_customers_wait_for_each_dish() -> void:
	var simulation := quiet_simulation()
	var cafe := await spawn_cafe(simulation)
	cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0), 3)
	cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(4, 4))
	var chair := cafe.layout.place(cafe.catalog.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	var customer := Customer.new()
	customer.serial = 900
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	customer.state = Customer.State.WAITING_TO_ORDER
	customer.patience_total = 100.0
	customer.patience_left = 100.0
	simulation.customers.append(customer)
	simulation.tick(0.1)
	assert_eq(customer.state, Customer.State.WAITING_FOR_FOOD, "pediu com o balcão vazio")
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()
	assert_eq(cafe.build_bar.current_book(cafe.selected_id), customer.order.book, "o livro abre na aba do prato esperado")
	for recipe in simulation.recipes.all():
		cafe.build_bar.show_recipe_book(recipe.book)
		await settle()
		var button := cafe.build_bar.find_button("Cook_" + String(recipe.id))
		var badge := button.get_node("DemandBadge") as Label
		if recipe == customer.order:
			assert_true(badge.visible, "a receita pedida ganha a bolinha")
			assert_eq(badge.text, "1")
		else:
			assert_false(badge.visible, "%s ninguém pediu" % recipe.id)
	assert_true(cafe.build_bar.message_text().contains("Clientes esperando: %s ×1" % customer.order.display_name),
		cafe.build_bar.message_text())
