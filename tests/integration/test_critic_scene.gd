extends CafeTestCase
## Crítico na cena (DT-061): o aviso da chegada com o tema; a estrela na mesa, que dá o prêmio ao ser tocada; o
## contador de cupons no HUD; o aviso quando ele vai embora sem estrela.


func _critic_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.customer_types.append(load("res://data/customers/regular.tres"))  # com clientes, o crítico vem
	simulation.config.spawn_interval = 1.0e9
	simulation._spawn_timer = 1.0e9
	simulation.progression.add_xp(300)  # nível 5
	simulation.layout.place(simulation.furniture.get_definition(&"table_round"), Vector2i(4, 4))
	simulation.layout.place(simulation.furniture.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	var cafe := await spawn_cafe(simulation)
	return cafe


func _arrive(cafe: Cafe) -> Customer:
	cafe.simulation.tick(cafe.simulation.critic_config.arrival_delay + 0.1)
	await settle()
	for customer in cafe.simulation.customers:
		if customer.critic:
			return customer
	return null


func test_the_arrival_is_announced_with_the_theme() -> void:
	var cafe := await _critic_cafe()
	var critic := await _arrive(cafe)
	assert_true(critic != null, "o crítico entrou")
	var theme := cafe.simulation.recipes.get_book(cafe.simulation.critic_theme()).display_name
	assert_true(all_messages(cafe).contains(Cafe.CRITIC_ARRIVED_MESSAGE % theme), all_messages(cafe))


func test_tapping_the_star_pays_and_shows_the_coupons() -> void:
	var cafe := await _critic_cafe()
	var critic := await _arrive(cafe)
	assert_eq(cafe.hud.shown_coupons(), -1, "sem cupons, o contador fica escondido")
	critic.patience_when_served = 1.0
	critic.order = cafe.simulation.recipes.get_definition(&"coffee")
	critic.state = Customer.State.EATING
	critic.eat_left = 0.0
	cafe.simulation.tick(0.01)
	await settle()
	assert_true(all_messages(cafe).contains(Cafe.CRITIC_STAR_MESSAGE), all_messages(cafe))
	var star := cafe.world_layer.get_node("CriticStar") as Sprite2D
	assert_true(star.visible, "a estrela aparece na mesa")
	var coupons: int = cafe.simulation.critic_star["coupons"]
	cafe.tap_at_world(star.position)
	await settle()
	assert_false(star.visible, "tocada, ela some")
	assert_eq(cafe.simulation.wallet.balance(Wallet.COUPONS), coupons)
	assert_eq(cafe.hud.shown_coupons(), coupons, "o contador de cupons aparece")
	assert_eq((cafe.effects.get_child(-1) as FloatingText).text, "+%d cupons" % coupons)


func test_leaving_unserved_is_announced() -> void:
	var cafe := await _critic_cafe()
	var critic := await _arrive(cafe)
	critic.patience_left = 0.0
	critic.state = Customer.State.WAITING_FOR_FOOD
	cafe.simulation.tick(0.01)
	await settle()
	assert_true(all_messages(cafe).contains(Cafe.CRITIC_UNHAPPY_MESSAGE), all_messages(cafe))
