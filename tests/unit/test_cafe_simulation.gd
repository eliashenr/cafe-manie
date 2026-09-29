extends TestCase
## Atendimento de ponta a ponta, sem tela: relógio manual e sorteio com semente fixa.
##
## Cafeteria de teste (8x8, entrada em (7,4)):
##   fogão (0,0) · balcão (2,0)-(3,0) · mesa (4,4) · cadeira (3,4)
## Com uma só cadeira, cada cenário tem exatamente um cliente por vez.

const STEP := 0.1

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName
var counter: StringName
var table: StringName
var chair: StringName


func _setup(patience := 60.0, spawn_interval := 2.0) -> void:
	clock = ManualClock.new()
	var furniture := FurnitureCatalog.load_from()
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	stove = layout.place(furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	counter = layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	table = layout.place(furniture.get_definition(&"table_round"), Vector2i(4, 4))
	chair = layout.place(furniture.get_definition(&"chair_wood"), Vector2i(3, 4))

	var config: ServiceConfig = load("res://data/config/service.tres").duplicate()
	config.customer_patience = patience
	config.spawn_interval = spawn_interval
	config.spawn_jitter = 0.0
	var regular: CustomerType = load("res://data/customers/regular.tres")
	var types: Array[CustomerType] = [regular]
	sim = CafeSimulation.new(clock, layout, config, furniture, RecipeCatalog.load_from(),
		load("res://data/progression/levels.tres"), types, 12345)
	sim.wallet.earn(Wallet.SOFT, 100, "teste")


func _run(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		clock.advance(STEP)
		sim.tick(STEP)
		elapsed += STEP


## Roda até a condição ser verdadeira. Retorna false se o tempo acabar.
func _run_until(condition: Callable, max_seconds: float) -> bool:
	var elapsed := 0.0
	while elapsed < max_seconds:
		if condition.call():
			return true
		clock.advance(STEP)
		sim.tick(STEP)
		elapsed += STEP
	return condition.call()


func _cook_and_collect(recipe_id := &"coffee") -> void:
	assert_eq(sim.start_cooking(stove, recipe_id), ServiceResult.OK)
	clock.advance(sim.recipes.get_definition(recipe_id).cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)


func test_new_game_comes_from_data_files() -> void:
	var game := CafeSimulation.create_new_game(ManualClock.new(), 1)
	var new_game: NewGameConfig = load("res://data/config/new_game.tres")
	assert_eq(game.wallet.balance(Wallet.SOFT), new_game.starting_gold)
	assert_eq(game.layout.count(), new_game.starter_items.size())
	assert_eq(game.progression.level, 1)
	assert_eq(game.waiters.size(), 1, "começa com um garçom")
	assert_true(game.seats().size() >= 2, "o jogo novo já tem onde sentar")
	assert_eq(game.customer_types.size(), 2)


func test_cooking_charges_ingredients_and_collect_gives_xp() -> void:
	_setup()
	var coffee := sim.recipes.get_definition(&"coffee")
	assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100 - coffee.ingredient_cost)
	clock.advance(coffee.cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)
	assert_eq(sim.progression.xp, coffee.xp_reward)
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings)


func test_cooking_refusals_do_not_charge() -> void:
	_setup()
	assert_eq(sim.start_cooking(stove, &"lasagna"), ServiceResult.RECIPE_LOCKED)
	assert_eq(sim.start_cooking(stove, &"nao_existe"), ServiceResult.UNKNOWN_RECIPE)
	assert_eq(sim.start_cooking(counter, &"coffee"), ServiceResult.NOT_A_STOVE)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "zerar")
	assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE)


func test_seats_are_chairs_next_to_a_table() -> void:
	_setup()
	assert_eq(sim.seats(), [chair] as Array[StringName])
	var lonely := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(0, 6))
	assert_false(sim.seats().has(lonely), "cadeira sem mesa não é assento")


func test_customer_walks_in_and_sits_on_the_free_seat() -> void:
	_setup()
	assert_true(_run_until(func() -> bool: return not sim.customers.is_empty(), 10.0), "chegou alguém")
	var customer := sim.customers[0]
	assert_eq(customer.seat_id, chair)
	assert_true(sim.free_seats().is_empty(), "o assento fica reservado")
	assert_true(_run_until(func() -> bool: return customer.is_seated(), 20.0), "sentou")
	assert_eq(customer.cell(), Vector2i(3, 4))


func test_full_service_loop_pays_gives_xp_and_popularity() -> void:
	_setup()
	_cook_and_collect()
	var coffee := sim.recipes.get_definition(&"coffee")
	var gold_before := sim.wallet.balance(Wallet.SOFT)
	var xp_before := sim.progression.xp
	var popularity_before := sim.popularity
	var paid := []
	sim.payment_received.connect(func(c: Customer, amount: int) -> void: paid.append(amount))

	assert_true(_run_until(func() -> bool: return not paid.is_empty(), 60.0), "o cliente pagou")
	assert_eq(paid[0], coffee.sell_price)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold_before + coffee.sell_price)
	assert_eq(sim.progression.xp, xp_before + sim.config.customer_xp)
	assert_true(sim.popularity > popularity_before, "cliente satisfeito aumenta a popularidade")
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings - 1, "uma porção saiu do balcão")


func test_customer_leaves_and_waiter_goes_back_to_post() -> void:
	_setup()
	_cook_and_collect()
	var left := []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	assert_true(_run_until(func() -> bool: return not left.is_empty(), 90.0))
	assert_true(left[0].happy)
	var waiter := sim.waiters[0]
	assert_true(_run_until(func() -> bool: return waiter.state == Waiter.State.IDLE and waiter.cell() == waiter.home, 20.0),
		"o garçom volta para o posto")
	assert_eq(sim.pending_orders(), 0)


func test_no_food_means_angry_customer_and_popularity_drop() -> void:
	_setup(8.0)
	var left := []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	var popularity_before := sim.popularity
	var gold_before := sim.wallet.balance(Wallet.SOFT)
	assert_true(_run_until(func() -> bool: return not left.is_empty(), 60.0))
	assert_false(left[0].happy)
	assert_eq(left[0].paid, 0)
	assert_almost_eq(sim.popularity, popularity_before - sim.config.popularity_loss, 0.001)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold_before, "ninguém paga sem comer")


func test_unserved_order_returns_the_serving_to_the_counter() -> void:
	_setup(4.0)
	sim.waiters[0].speed = 0.01  # garçom lento demais para chegar a tempo
	_cook_and_collect()
	var coffee := sim.recipes.get_definition(&"coffee")
	var gave_up := func() -> bool:
		return not sim.customers.is_empty() and sim.customers[0].state == Customer.State.LEAVING
	assert_true(_run_until(gave_up, 60.0), "o cliente desistiu")
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings, "a porção reservada voltou para o balcão")
	assert_eq(sim.pending_orders(), 0)
	assert_eq(sim.waiters[0].order, null, "o garçom desistiu do pedido")


func test_arrivals_respect_free_seats() -> void:
	_setup(600.0, 1.0)
	_run(30.0)
	assert_eq(sim.customers.size(), 1, "uma cadeira, um cliente")


func test_popularity_speeds_up_arrivals() -> void:
	_setup()
	assert_true(sim.config.spawn_interval_for(90.0) < sim.config.spawn_interval_for(10.0))


func test_furniture_in_use_cannot_be_moved_or_removed() -> void:
	_setup(600.0)
	sim.start_cooking(stove, &"coffee")
	assert_eq(sim.layout.can_remove(stove), CafeLayout.Check.IN_USE, "fogão cozinhando")
	assert_eq(sim.layout.move(stove, Vector2i(0, 2), 0), CafeLayout.Check.IN_USE)
	assert_true(_run_until(func() -> bool: return not sim.customers.is_empty() and sim.customers[0].is_seated(), 30.0))
	assert_eq(sim.layout.can_remove(chair), CafeLayout.Check.IN_USE, "cadeira com cliente")
	assert_eq(sim.layout.can_remove(table), CafeLayout.Check.IN_USE, "mesa do cliente")
	assert_false(sim.layout.remove(chair))


func test_furniture_is_free_again_after_service() -> void:
	_setup()
	_cook_and_collect()
	sim.config.max_customers = 1
	var left := []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	assert_true(_run_until(func() -> bool: return not left.is_empty(), 90.0))
	sim.customers.clear()  # garante que ninguém mais chegou nesse meio-tempo
	assert_eq(sim.layout.can_remove(chair), CafeLayout.Check.OK)
	assert_eq(sim.layout.can_remove(stove), CafeLayout.Check.OK)


func test_cannot_drop_furniture_on_someone_walking() -> void:
	_setup()
	var waiter := sim.waiters[0]
	waiter.position = Vector2(5, 6)
	var plant := sim.furniture.get_definition(&"plant_pot")
	assert_eq(sim.layout.check_placement(plant, Vector2i(5, 6), 0), CafeLayout.Check.AGENT_IN_THE_WAY)


func test_walkers_reroute_when_the_layout_changes() -> void:
	_setup()
	assert_true(_run_until(func() -> bool: return not sim.customers.is_empty(), 10.0))
	var customer := sim.customers[0]
	# Coloca uma planta num piso livre do caminho que não seja onde ele está pisando.
	var plant := sim.furniture.get_definition(&"plant_pot")
	for cell in customer.path.slice(2):
		if sim.layout.place(plant, cell, 0) != &"":
			break
	for step in customer.path:
		assert_true(sim.layout.grid.is_free(step), "o novo caminho não atravessa móveis")
	assert_true(_run_until(func() -> bool: return customer.is_seated(), 30.0), "chegou mesmo assim")


func test_leveling_up_unlocks_recipes() -> void:
	_setup()
	var levels := []
	sim.leveled_up.connect(func(l: int) -> void: levels.append(l))
	assert_eq(sim.start_cooking(stove, &"toasted_sandwich"), ServiceResult.RECIPE_LOCKED)
	sim.progression.add_xp(sim.progression.table.xp_for_next(1))
	assert_eq(levels, [2])
	assert_eq(sim.start_cooking(stove, &"toasted_sandwich"), ServiceResult.OK)


func test_same_seed_gives_the_same_shift() -> void:
	var results := []
	for i in 2:
		_setup()
		_cook_and_collect()
		_run(45.0)
		results.append([sim.wallet.balance(Wallet.SOFT), sim.progression.xp, sim.customers.size()])
	assert_eq(results[0], results[1], "simulação determinística com a mesma semente")
