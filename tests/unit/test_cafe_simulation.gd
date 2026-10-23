extends TestCase
## Atendimento de ponta a ponta, sem tela: relógio manual e sorteio com semente fixa.
##
## Cafeteria de teste (8x8, entrada em (7,4)):
##   fogão (0,0) · balcão (2,0)-(3,0) · mesa (4,4) · cadeira (3,4)
## Com uma só cadeira, cada cenário tem exatamente um cliente lá dentro por vez (os outros esperam na fila).
## Por padrão o cliente pede o que está no balcão (menu_order_chance = 0); os testes do cardápio ligam a chance.

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
	config.menu_order_chance = 0.0
	config.order_think_time = 0.0
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


func test_customer_leaves_and_waiter_goes_back_to_the_kitchen() -> void:
	_setup()
	_cook_and_collect()
	var left := []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	assert_true(_run_until(func() -> bool: return not left.is_empty(), 90.0))
	assert_true(left[0].happy)
	var waiter := sim.waiters[0]
	assert_true(_run_until(func() -> bool: return waiter.state == Waiter.State.IDLE and _near_kitchen(waiter.cell()), 20.0),
		"sem pedido, o garçom fica perto do fogão ou do balcão, não na porta")
	assert_eq(sim.pending_orders(), 0)


func _near_kitchen(cell: Vector2i) -> bool:
	return sim.navigation.access_cells(stove).has(cell) or sim.navigation.access_cells(counter).has(cell)


func test_idle_waiter_walks_around_the_kitchen_instead_of_standing_at_the_door() -> void:
	_setup(600.0, 1000.0)
	sim.customer_types.clear()  # sem clientes: só o garçom e a cozinha
	var waiter := sim.waiters[0]
	var spots := {}
	for i in 600:
		clock.advance(STEP)
		sim.tick(STEP)
		if waiter.state == Waiter.State.IDLE:
			spots[waiter.cell()] = true
	assert_false(spots.has(sim.layout.entrance), "não fica parado na entrada")
	assert_true(spots.size() >= 2, "circula entre fogões e balcões: %s" % [spots.keys()])
	for cell: Vector2i in spots:
		assert_true(_near_kitchen(cell), "parado sempre perto da cozinha: %s" % cell)


func test_waiter_takes_the_ready_dish_from_the_stove_to_the_counter() -> void:
	_setup(600.0, 1000.0)
	sim.customer_types.clear()  # sem clientes: só o garçom e a cozinha
	var coffee := sim.recipes.get_definition(&"coffee")
	assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK)
	clock.advance(coffee.cook_time)
	var waiter := sim.waiters[0]
	assert_true(_run_until(func() -> bool: return waiter.state == Waiter.State.TO_DROP, 20.0), "o garçom buscou no fogão")
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE, "o fogão fica livre para outro preparo")
	assert_eq(waiter.carrying, coffee, "leva o prato até o balcão")
	assert_eq(sim.progression.xp, coffee.xp_reward, "o XP do prato é do jogador")
	assert_true(_run_until(func() -> bool: return waiter.carrying == null, 20.0))
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings, "o prato está no balcão")


func test_waiter_never_starts_cooking() -> void:
	_setup(600.0, 1000.0)
	sim.customer_types.clear()  # sem clientes: só o garçom e a cozinha
	_run(60.0)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE, "cozinhar é com o jogador")


func test_player_tap_first_leaves_nothing_for_the_waiter() -> void:
	_setup(600.0, 1000.0)
	sim.customer_types.clear()  # sem clientes: só o garçom e a cozinha
	var coffee := sim.recipes.get_definition(&"coffee")
	sim.start_cooking(stove, &"coffee")
	clock.advance(coffee.cook_time)
	var waiter := sim.waiters[0]
	assert_true(_run_until(func() -> bool: return waiter.state == Waiter.State.TO_STOVE, 5.0))
	assert_eq(sim.collect(stove), ServiceResult.OK, "o jogador tocou antes")
	assert_true(_run_until(func() -> bool: return waiter.state in [Waiter.State.IDLE, Waiter.State.RETURNING], 20.0))
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings, "o prato foi para o balcão uma vez só")
	assert_eq(sim.progression.xp, coffee.xp_reward, "XP uma vez só")


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


func test_arrivals_respect_free_seats_and_the_rest_wait_in_line() -> void:
	_setup(600.0, 1.0)
	sim.config.queue_patience = 600.0
	_run(30.0)
	assert_eq(sim.inside_count(), 1, "uma cadeira, um cliente lá dentro")
	assert_eq(sim.queued().size(), sim.config.queue_capacity, "os outros esperam na fila, até ela encher")
	assert_eq(sim.customers.size(), 1 + sim.config.queue_capacity, "fila cheia: quem chega passa direto")
	for i in sim.queued().size():
		assert_eq(sim.queued()[i].position, sim.queue_spot(i), "cada um no seu lugar da calçada")
		assert_false(sim.layout.grid.is_inside(sim.queued()[i].cell()), "a fila fica fora da cafeteria")


func test_tired_of_waiting_in_line_leaves_angry() -> void:
	_setup(600.0, 1.0)
	sim.config.queue_patience = 5.0
	var left := []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	assert_true(_run_until(func() -> bool: return not left.is_empty(), 30.0), "alguém desistiu da fila")
	assert_false(left[0].happy)
	assert_true(left[0].gave_up_in_line)
	assert_eq(left[0].paid, 0)
	assert_eq(left[0].seat_id, &"", "nunca chegou a sentar")
	assert_true(sim.popularity < sim.config.popularity_start, "fila longa custa popularidade")


func test_first_in_line_takes_the_seat_that_frees_up() -> void:
	_setup(600.0, 1.0)
	sim.config.queue_patience = 600.0
	_cook_and_collect()
	assert_true(_run_until(func() -> bool: return sim.queued().size() >= 2, 30.0))
	var first := sim.queued()[0]
	var second := sim.queued()[1]
	assert_true(_run_until(func() -> bool: return first.state != Customer.State.QUEUED, 90.0), "o primeiro da fila entrou")
	assert_eq(first.seat_id, chair)
	assert_eq(second, sim.queued()[0], "a fila andou")
	assert_eq(second.position, sim.queue_spot(0))


func test_customer_can_order_a_dish_that_is_not_on_the_counter() -> void:
	_setup(600.0)
	sim.config.menu_order_chance = 1.0
	assert_true(_run_until(func() -> bool: return not sim.customers.is_empty() \
		and sim.customers[0].state == Customer.State.WAITING_FOR_FOOD, 30.0), "pediu mesmo com o balcão vazio")
	var customer := sim.customers[0]
	assert_true(customer.order.unlock_level <= sim.progression.level, "pede do cardápio liberado")
	assert_eq(sim.waiting_demand(), {customer.order.id: 1}, "o jogo diz o que falta cozinhar")
	_cook_and_collect(customer.order.id)
	_run(STEP)
	assert_eq(sim.waiting_demand(), {}, "a porção chegou ao balcão e ficou com ele")
	var paid := []
	sim.payment_received.connect(func(c: Customer, amount: int) -> void: paid.append(c))
	assert_true(_run_until(func() -> bool: return paid.has(customer), 60.0), "servido depois que o jogador cozinhou")


func test_menu_orders_mix_counter_dishes_and_other_dishes() -> void:
	_setup(600.0)
	sim.config.menu_order_chance = 0.5
	sim.progression.add_xp(sim.progression.table.xp_for_next(1))  # nível 2: três receitas no cardápio
	_cook_and_collect()
	var coffee := sim.recipes.get_definition(&"coffee")
	var ordered := {}
	for i in 60:
		ordered[sim._choose_order()] = true
	assert_true(ordered.has(coffee), "às vezes pede o que está no balcão")
	assert_true(ordered.size() >= 2, "às vezes pede outra coisa do cardápio")
	for recipe: RecipeDefinition in ordered:
		assert_true(recipe.unlock_level <= sim.progression.level, "%s está no cardápio" % recipe.id)


## Do cardápio, só sai o que fica pronto enquanto o cliente espera (DT-075), e os pratos rápidos saem mais.
func test_menu_orders_only_dishes_that_fit_the_wait_and_favor_quick_ones() -> void:
	var shipped: ServiceConfig = load("res://data/config/service.tres")
	assert_true(shipped.menu_max_cook_time <= shipped.customer_patience / shipped.patience_drain_while_cooking,
		"o limite do cardápio cabe na paciência de quem espera o prato no fogão")
	_setup()
	sim.config = sim.config.duplicate()
	sim.progression.add_xp(99999)  # todas as receitas liberadas
	var counts := {}
	for i in 3000:
		var recipe := sim._pick_from_menu()
		assert_true(recipe.cook_time <= sim.config.menu_max_cook_time, "pedido demorado demais: %s" % recipe.id)
		counts[recipe.id] = int(counts.get(recipe.id, 0)) + 1
	assert_true(counts.has(&"coffee") and counts.has(&"cheese_bread"), "os rápidos aparecem: %s" % counts)
	assert_true(counts[&"coffee"] > counts[&"cheese_bread"] * 1.2, "café sai mais que pão de queijo: %s" % counts)
	sim.config.menu_max_cook_time = 999999.0
	counts.clear()
	for i in 3000:
		var recipe := sim._pick_from_menu()
		counts[recipe.id] = int(counts.get(recipe.id, 0)) + 1
	assert_eq(counts.size(), sim.order_menu().size(), "sem limite, todo o cardápio aparece (sem as do fogão temático)")
	assert_true(counts[&"coffee"] > counts[&"lasagna"] * 3, "café sai bem mais que lasanha: %s" % counts)
	sim.config.menu_cook_time_weight = 0.0
	counts.clear()
	for i in 3000:
		var recipe := sim._pick_from_menu()
		counts[recipe.id] = int(counts.get(recipe.id, 0)) + 1
	assert_true(absf(counts[&"coffee"] - counts[&"lasagna"]) < 200, "com peso 0, todos com a mesma chance: %s" % counts)
	sim.config.menu_max_cook_time = 1.0
	assert_eq(sim._pick_from_menu().id, &"coffee", "se nada couber no tempo, o mais rápido")


func test_patience_drains_slower_while_the_dish_is_cooking() -> void:
	_setup(20.0)
	sim.config.menu_order_chance = 1.0
	assert_true(_run_until(func() -> bool: return not sim.customers.is_empty() \
		and sim.customers[0].state == Customer.State.WAITING_FOR_FOOD, 30.0))
	var customer := sim.customers[0]
	var before := customer.patience_left
	_run(2.0)
	var idle_drain := before - customer.patience_left
	assert_eq(sim.start_cooking(stove, customer.order.id), ServiceResult.OK)
	before = customer.patience_left
	_run(2.0)
	var cooking_drain := before - customer.patience_left
	assert_almost_eq(cooking_drain, idle_drain * sim.config.patience_drain_while_cooking, 0.05,
		"vendo o prato no fogão, o cliente espera com mais calma")


func test_higher_levels_bring_more_customers() -> void:
	_setup()
	var level_1 := sim.spawn_interval_now()
	var max_1 := sim.config.max_customers_at(1)
	sim.progression.add_xp(sim.progression.table.xp_for_next(1) + sim.progression.table.xp_for_next(2))
	assert_eq(sim.progression.level, 3)
	assert_true(sim.spawn_interval_now() < level_1, "nível maior, clientes chegando mais rápido")
	assert_true(sim.config.max_customers_at(3) > max_1, "e mais gente cabe lá dentro")
	assert_true(sim.config.level_spawn_factor(99) >= sim.config.spawn_level_floor, "até um limite")


func test_hiring_waiters_needs_level_and_gold_and_has_a_limit() -> void:
	_setup()
	assert_eq(sim.waiters.size(), 1)
	assert_eq(sim.can_hire_waiter(), ServiceResult.WAITER_LOCKED, "o segundo garçom libera no nível %d" % sim.next_waiter_level())
	while sim.progression.level < sim.next_waiter_level():
		sim.progression.add_xp(sim.progression.table.xp_for_next(sim.progression.level))
	var price := sim.next_waiter_price()
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "zerar")
	assert_eq(sim.hire_waiter(), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.waiters.size(), 1, "recusa não contrata")
	sim.wallet.earn(Wallet.SOFT, price, "teste")
	var hired := []
	sim.waiter_hired.connect(func(count: int) -> void: hired.append(count))
	assert_eq(sim.hire_waiter(), ServiceResult.OK)
	assert_eq(sim.waiters.size(), 2)
	assert_eq(hired, [2])
	assert_eq(sim.wallet.balance(Wallet.SOFT), 0, "cobrou o preço")
	assert_eq(sim.waiters[1].position, Vector2(sim.layout.entrance), "chega pela entrada")
	while sim.waiters.size() < sim.economy.max_waiters():
		sim.restore_waiter_count(sim.waiters.size() + 1)
	assert_eq(sim.can_hire_waiter(), ServiceResult.NO_MORE_WAITERS)
	assert_eq(sim.next_waiter_price(), -1)


func test_two_waiters_share_the_work() -> void:
	_setup(600.0, 1000.0)
	sim.customer_types.clear()  # sem clientes: só o garçom e a cozinha
	sim.restore_waiter_count(2)
	var coffee := sim.recipes.get_definition(&"coffee")
	sim.start_cooking(stove, &"coffee")
	clock.advance(coffee.cook_time)
	_run(0.2)
	var going := sim.waiters.filter(func(w: Waiter) -> bool: return w.state == Waiter.State.TO_STOVE)
	assert_eq(going.size(), 1, "só um garçom vai buscar o mesmo prato")


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
