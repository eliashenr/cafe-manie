extends CafeTestCase
## Bebidas na cena (DT-052): tocar no cliente do balão verde serve a bebida; sem energia, o aviso explica; o
## contador de energia aparece quando o café tem máquina; as máquinas estão na aba Cozinha da loja.


## Café de teste com a máquina de café, uma mesa, uma cadeira e um cliente esperando um expresso.
func _thirsty_cafe() -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(30)  # nível 2: o expresso já sai
	simulation.layout.place(simulation.furniture.get_definition(&"machine_coffee"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"table_round"), Vector2i(4, 4))
	var chair := simulation.layout.place(simulation.furniture.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	var customer := Customer.new()
	customer.serial = 90
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	customer.state = Customer.State.WAITING_FOR_DRINK
	customer.patience_total = 999.0
	customer.patience_left = 999.0
	customer.drink = simulation.drinks.get_definition(&"espresso")
	simulation.customers.append(customer)
	return [simulation, customer]


## Toca na tela em cima do balão do cliente.
func _tap_balloon(cafe: Cafe, customer: Customer) -> void:
	var view := cafe.world_layer.get_node("Agent_%d" % customer.serial) as AgentView
	var rect := view.tap_rect()
	var world := Vector2(rect.get_center().x, rect.position.y + AgentView.TAP_REACH_ABOVE * 0.5)  # no meio do balão
	var viewport_size := cafe.camera.get_viewport_rect().size
	var screen := (world - cafe.camera.global_position) * cafe.camera.zoom + viewport_size / 2.0
	touch(0, screen, true)
	touch(0, screen, false)


func test_tapping_the_green_balloon_serves_the_drink() -> void:
	var setup := _thirsty_cafe()
	var simulation: CafeSimulation = setup[0]
	var customer: Customer = setup[1]
	var cafe := await spawn_cafe(simulation)
	for i in 30:  # o desenho chega na cadeira
		await tree.process_frame
	var energy := simulation.energy.amount(clock.now())
	_tap_balloon(cafe, customer)
	await settle()
	assert_eq(customer.state, Customer.State.EATING, "a bebida foi servida")
	assert_eq(simulation.energy.amount(clock.now()), energy - customer.drink.energy_cost, "gastando energia")
	assert_eq(cafe.selected_id, &"", "o toque serviu, não escolheu um móvel")


func test_without_energy_the_message_explains() -> void:
	var setup := _thirsty_cafe()
	var simulation: CafeSimulation = setup[0]
	var customer: Customer = setup[1]
	simulation.energy.spend(simulation.energy.amount(clock.now()), clock.now())
	var cafe := await spawn_cafe(simulation)
	assert_eq(cafe.serve_drink(customer), ServiceResult.NOT_ENOUGH_ENERGY)
	await settle()
	assert_eq(customer.state, Customer.State.WAITING_FOR_DRINK)
	assert_true(cafe.build_bar.find_child("Message", true, false) != null)
	assert_eq(cafe.last_service_result, ServiceResult.NOT_ENOUGH_ENERGY)
	assert_true(BuildBar.SERVICE_MESSAGES[ServiceResult.NOT_ENOUGH_ENERGY].contains("energia"))


func test_energy_counter_shows_with_a_machine() -> void:
	var cafe := await spawn_cafe()
	assert_false(cafe.hud.is_energy_visible(), "sem máquina, sem contador")
	cafe.simulation.progression.add_xp(30)
	cafe.layout.place(cafe.catalog.get_definition(&"machine_coffee"), Vector2i(0, 0))
	await settle()
	var maximum := cafe.simulation.energy.maximum()
	assert_true(cafe.hud.is_energy_visible())
	assert_eq(cafe.hud.energy_texts(), ["%d/%d" % [maximum, maximum], ""] as Array[String], "cheia, sem contagem")
	cafe.simulation.energy.spend(1, clock.now())
	await settle()
	assert_eq(cafe.hud.energy_texts(), ["%d/%d" % [maximum - 1, maximum], "+1 1:00"] as Array[String])
	(cafe.hud.find_child("EnergyButton", true, false) as Button).pressed.emit()
	assert_true(all_messages(cafe).contains("1 ponto por minuto"), "tocar no contador explica a energia")


func test_spending_energy_marks_the_save_dirty() -> void:
	var cafe := await spawn_cafe()
	cafe._save_dirty = false
	cafe.simulation.energy.spend(1, clock.now())
	assert_true(cafe._save_dirty, "a energia é gravada no próximo salvamento")


func test_machines_are_in_the_kitchen_tab() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(160)  # nível 4: as duas máquinas
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	await settle()
	var ids: Array[StringName] = []
	for page in cafe.build_bar.shop_page_count():
		ids.append_array(cafe.build_bar.shop_item_ids())
		cafe.build_bar.find_child("NextPageButton", true, false).pressed.emit()
		await settle()
	assert_true(ids.has(&"machine_coffee") and ids.has(&"machine_juice"), "as máquinas estão na aba Cozinha")


func test_level_up_announces_the_new_machine() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(30)
	assert_true(all_messages(cafe).contains("Nova máquina na Loja: Máquina de Café"), "o nível 2 avisa da máquina de café")


func test_machine_has_art_in_every_rotation() -> void:
	for id in [&"machine_coffee", &"machine_juice"]:
		for rotation in 4:
			assert_true(ArtSprites.furniture(id, rotation) != null, "%s girado %d" % [id, rotation])
