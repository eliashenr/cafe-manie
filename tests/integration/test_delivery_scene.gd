extends CafeTestCase
## Entregas na cena (DT-071): o Balcão de Entregas está na aba Cozinha; escolhido, a barra mostra um botão por
## pedido, aceso quando há porções nos balcões; mandar faz o ouro subir.


func _delivery_cafe() -> Array:
	var simulation := quiet_simulation()
	var counter := simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(0, 3))
	var delivery := simulation.layout.place(simulation.furniture.get_definition(&"delivery_counter"), Vector2i(0, 6))
	var cafe := await spawn_cafe(simulation)
	simulation.tick(0.1)
	await settle()
	return [cafe, counter, delivery]


func test_the_delivery_counter_has_art_and_is_in_the_kitchen_tab() -> void:
	var cafe := await spawn_cafe()
	for rotation in 4:
		assert_true(ArtSprites.furniture(&"delivery_counter", rotation) != null, "rotação %d" % rotation)
	assert_true(cafe.build_bar.shows_in_tab(cafe.catalog.get_definition(&"delivery_counter"), BuildBar.ShopTab.KITCHEN))


func test_selecting_the_counter_shows_the_orders_and_sending_pays() -> void:
	var setup := await _delivery_cafe()
	var cafe: Cafe = setup[0]
	var sim := cafe.simulation
	var order: DeliveryBoard.Order = sim.delivery.orders[0]
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 6)))
	await settle()
	var button := cafe.build_bar.find_button("Delivery_0")
	assert_true(button != null and button.text.contains(order.recipe.display_name), "um botão por pedido")
	assert_true(button.disabled, "sem porções no balcão, apagado")
	assert_true(cafe.build_bar.message_text().contains("Entregas"), cafe.build_bar.message_text())
	sim.kitchen.restore_counter(setup[1], order.recipe, order.servings)
	await settle()
	assert_false(button.disabled, "com as porções, aceso")
	var gold := sim.wallet.balance(Wallet.SOFT)
	button.pressed.emit()
	await settle()
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + order.gold)
	assert_true(all_messages(cafe).contains("Entrega enviada"), all_messages(cafe))
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+%s ouro" % UiTheme.thousands(order.gold))
	assert_true(cafe.build_bar.find_button("Delivery_0") == null or cafe.build_bar.find_button("Delivery_0") != button,
		"o pedido saiu da barra")


func test_a_double_tap_sends_only_one_order() -> void:
	var setup := await _delivery_cafe()
	var cafe: Cafe = setup[0]
	var sim := cafe.simulation
	sim.delivery.orders.append(sim.delivery.make_order(sim.recipes.get_definition(&"coffee"), 3))
	sim.delivery.orders[0] = sim.delivery.make_order(sim.recipes.get_definition(&"coffee"), 3)
	sim.kitchen.restore_counter(setup[1], sim.recipes.get_definition(&"coffee"), 6)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 6)))
	await settle()
	var button := cafe.build_bar.find_button("Delivery_0")
	button.pressed.emit()
	button.pressed.emit()  # o segundo toque chega antes de a barra se refazer
	assert_eq(sim.delivery.orders.size(), 1, "só um pedido saiu")
	assert_eq(sim.kitchen.servings_of(sim.recipes.get_definition(&"coffee")), 3, "só as porções de um pedido")
