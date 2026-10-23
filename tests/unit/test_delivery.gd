extends TestCase
## Entregas (DT-071): com o Balcão de Entregas, chegam até 3 pedidos (um a cada intervalo, também com o jogo
## fechado); mandar as porções dos balcões dá mais ouro que no salão, e XP.

var clock: ManualClock
var sim: CafeSimulation
var counter: StringName


func _setup(with_delivery := true) -> void:
	clock = ManualClock.new()
	clock.time = 1_000_000
	var no_customers: Array[CustomerType] = []
	var config: ServiceConfig = load("res://data/config/service.tres").duplicate()
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), config, FurnitureCatalog.load_from(),
		RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	counter = sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(0, 3))
	if with_delivery:
		sim.layout.place(sim.furniture.get_definition(&"delivery_counter"), Vector2i(0, 6))


func _interval() -> float:
	return sim.delivery_config.order_interval


func test_the_delivery_config_and_counter_are_valid() -> void:
	var config: DeliveryConfig = load("res://data/config/delivery.tres")
	assert_true(config.is_valid())
	var broken: DeliveryConfig = config.duplicate()
	broken.max_servings = config.min_servings - 1
	assert_false(broken.is_valid(), "máximo menor que o mínimo")
	broken = config.duplicate()
	broken.gold_multiplier = 0.5
	assert_false(broken.is_valid(), "entrega pagando menos que o salão")
	var furniture := FurnitureCatalog.load_from().get_definition(&"delivery_counter")
	assert_true(furniture.is_valid() and furniture.delivery)


func test_orders_only_arrive_with_the_delivery_counter() -> void:
	_setup(false)
	sim.tick(0.1)
	clock.advance(_interval() * 3)
	sim.tick(0.1)
	assert_true(sim.delivery.orders.is_empty(), "sem o balcão, nenhum pedido")
	sim.layout.place(sim.furniture.get_definition(&"delivery_counter"), Vector2i(0, 6))
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), 1, "com o balcão, o primeiro pedido chega na hora")


func test_one_order_per_interval_up_to_the_limit_even_while_away() -> void:
	_setup()
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), 1)
	clock.advance(_interval() * 0.5)
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), 1, "antes do intervalo, nada")
	clock.advance(_interval() * 0.5 + 1.0)
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), 2, "um a cada intervalo")
	clock.advance(_interval() * 10)
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), sim.delivery_config.max_orders, "com o jogo fechado, enche até o limite")


func test_orders_use_unlocked_common_recipes_and_pay_more() -> void:
	_setup()
	clock.advance(_interval() * 10)
	sim.tick(0.1)
	for order in sim.delivery.orders:
		assert_true(order.recipe.unlock_level <= sim.progression.level and order.recipe.stove == &"",
			String(order.recipe.id))
		assert_true(order.servings >= sim.delivery_config.min_servings and order.servings <= sim.delivery_config.max_servings)
	var coffee := sim.recipes.get_definition(&"coffee")
	var order := sim.delivery.make_order(coffee, 4)
	assert_eq(order.gold, roundi(4 * coffee.sell_price * sim.delivery_config.gold_multiplier), "paga mais que no salão")
	assert_eq(order.xp, 4 * sim.delivery_config.xp_per_serving)


func test_sending_takes_the_servings_and_pays() -> void:
	_setup()
	sim.tick(0.1)
	sim.delivery.orders[0] = sim.delivery.make_order(sim.recipes.get_definition(&"coffee"), 3)
	var order: DeliveryBoard.Order = sim.delivery.orders[0]
	sim.kitchen.restore_counter(counter, order.recipe, order.servings - 1)
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.send_delivery(0), ServiceResult.NOT_ENOUGH_SERVINGS)
	assert_eq(sim.kitchen.servings_of(order.recipe), order.servings - 1, "nada sai do balcão")
	assert_eq(sim.delivery.orders.size(), 1)
	sim.kitchen.restore_counter(counter, order.recipe, 3)  # agora são 5 no balcão
	var xp := sim.progression.xp
	var sent := []
	sim.delivery_sent.connect(func(o: DeliveryBoard.Order) -> void: sent.append(o))
	assert_eq(sim.send_delivery(0), ServiceResult.OK)
	assert_eq(sim.kitchen.servings_of(order.recipe), 2, "as porções saíram do balcão")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + order.gold)
	assert_eq(sim.progression.xp, xp + order.xp)
	assert_true(sim.delivery.orders.is_empty(), "o pedido saiu do quadro")
	assert_eq(sent, [order])
	assert_eq(sim.send_delivery(0), ServiceResult.UNKNOWN_ITEM)


func test_without_the_counter_nothing_is_sent() -> void:
	_setup()
	sim.tick(0.1)
	var order: DeliveryBoard.Order = sim.delivery.orders[0]
	sim.kitchen.restore_counter(counter, order.recipe, order.servings)
	for placement in sim.layout.placements():
		if placement.definition.delivery:
			sim.layout.remove(placement.id)
	assert_eq(sim.send_delivery(0), ServiceResult.NO_DELIVERY_COUNTER)
	assert_eq(sim.kitchen.servings_of(order.recipe), order.servings)


func test_a_full_board_waits_an_interval_after_sending() -> void:
	_setup()
	sim.tick(0.1)
	clock.advance(_interval() * 10)
	sim.tick(0.1)
	var order: DeliveryBoard.Order = sim.delivery.orders[0]
	sim.kitchen.restore_counter(counter, order.recipe, order.servings)
	assert_eq(sim.send_delivery(0), ServiceResult.OK)
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), sim.delivery_config.max_orders - 1, "não chega outro na hora")
	assert_almost_eq(sim.delivery.seconds_until_next(clock.now()), _interval(), 1.0)
	clock.advance(_interval() + 1.0)
	sim.tick(0.1)
	assert_eq(sim.delivery.orders.size(), sim.delivery_config.max_orders)


func test_the_save_keeps_the_orders() -> void:
	_setup()
	clock.advance(_interval())
	sim.tick(0.1)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_eq(loaded.delivery.orders.size(), sim.delivery.orders.size())
	assert_eq(loaded.delivery.orders[0].recipe, sim.delivery.orders[0].recipe)
	assert_eq(loaded.delivery.orders[0].gold, sim.delivery.orders[0].gold)
	assert_almost_eq(loaded.delivery.next_at, sim.delivery.next_at, 0.01)
	var old := SaveCodec.encode(sim)
	old["save_version"] = 20
	old.erase("delivery")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["delivery"], {}, "a migração começa sem pedidos")


func test_the_menu_skips_theme_stove_and_night_recipes() -> void:
	_setup()
	sim.progression.add_xp(99999)
	var menu := sim.delivery_menu()
	var special := sim.recipes.all().filter(func(r: RecipeDefinition) -> bool: return r.stove != &"" or r.night_only)
	assert_false(special.is_empty(), "há receitas de fogão temático e da noite no jogo")
	for recipe in special:
		assert_false(menu.has(recipe), "fora das entregas: " + String(recipe.id))
	assert_true(menu.size() + special.size() == sim.recipes.all().size(), "no nível máximo, todas as outras entram")
