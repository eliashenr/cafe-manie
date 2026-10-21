extends TestCase
## Pausa (DT-049): com o jogo pausado nada anda (chegadas, clientes, paciência, garçons) e o tempo dos
## fogões para; ao continuar, cada preparo segue de onde parou. O jogador continua podendo jogar.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName
var counter: StringName


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	for placement in sim.layout.placements():
		if placement.origin == Vector2i(0, 0):
			stove = placement.id
		if placement.origin == Vector2i(3, 0):
			counter = placement.id
	sim.wallet.earn(Wallet.SOFT, 5000, "teste")


## Anda a simulação [param seconds] segundos, em passos de 0,1 s, com o relógio junto.
func _run(seconds: float) -> void:
	for i in roundi(seconds * 10.0):
		clock.advance(0.1)
		sim.tick(0.1)


func test_nobody_arrives_while_paused() -> void:
	_setup()
	sim.set_paused(true)
	_run(60.0)
	assert_eq(sim.customers.size(), 0, "pausado, ninguém chega")
	sim.set_paused(false)
	_run(30.0)
	assert_true(sim.customers.size() > 0, "ao continuar, os clientes voltam a chegar")


func test_customers_and_waiters_stand_still_and_keep_their_patience() -> void:
	_setup()
	while sim.customers.is_empty():
		_run(0.5)
	_run(1.0)
	var customer := sim.customers[0]
	var where := customer.position
	var patience := customer.patience_left
	var state := customer.state
	var waiter_at := sim.waiters[0].position
	sim.set_paused(true)
	_run(120.0)
	assert_eq(customer.position, where, "o cliente não anda")
	assert_eq(customer.patience_left, patience, "nem perde paciência")
	assert_eq(customer.state, state)
	assert_eq(sim.waiters[0].position, waiter_at, "o garçom também para")
	assert_eq(sim.customers.size(), 1, "e ninguém novo entra")


func test_stove_time_stops_while_paused_and_goes_on_after() -> void:
	_setup()
	assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK)
	clock.advance(5.0)
	sim.set_paused(true)
	clock.advance(600.0)
	assert_almost_eq(sim.kitchen.time_left(stove), 10.0, 0.001, "pausado, o café não cozinha")
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING)
	sim.set_paused(false)
	assert_almost_eq(sim.kitchen.time_left(stove), 10.0, 0.001, "continua de onde parou")
	clock.advance(9.0)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING)
	clock.advance(1.0)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY)


func test_cooking_started_while_paused_waits_for_the_game_to_go_on() -> void:
	_setup()
	sim.set_paused(true)
	clock.advance(100.0)  # já pausado há um tempo
	assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK, "dá para cozinhar com o jogo pausado")
	clock.advance(300.0)
	assert_almost_eq(sim.kitchen.progress(stove), 0.0, 0.001, "mas o tempo só corre depois")
	sim.set_paused(false)
	assert_almost_eq(sim.kitchen.time_left(stove), 15.0, 0.001, "ao continuar, falta o preparo inteiro")
	clock.advance(15.0)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY)


func test_saving_while_paused_keeps_the_time_left() -> void:
	_setup()
	sim.start_cooking(stove, &"coffee")
	clock.advance(5.0)
	sim.set_paused(true)
	clock.advance(600.0)
	assert_almost_eq(sim.kitchen.stove_ready_at(stove), clock.now() + 10.0, 0.001)
	var text := JSON.stringify(SaveCodec.encode(sim), "", true, true)
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_false(loaded.paused, "o jogo abre rodando")
	assert_almost_eq(loaded.kitchen.time_left(stove), 10.0, 0.01, "o tempo da pausa não conta como cozinhado")


func test_player_can_still_build_cook_and_collect_while_paused() -> void:
	_setup()
	sim.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	sim.set_paused(true)
	assert_eq(sim.collect(stove), ServiceResult.OK, "leva o prato pronto ao balcão")
	assert_eq(sim.kitchen.counter_stack(counter).servings, 6)
	var table := sim.furniture.get_definition(&"table_round")
	assert_eq(sim.acquire_and_place(table, Vector2i(5, 5), 0), ServiceResult.OK, "compra e põe a mesa")
	assert_true(sim.paused, "e o jogo continua pausado")


# --- Pausado, dá para mexer em tudo -------------------------------------------------------

## Cliente sentado comendo numa cadeira do lado de uma mesa (o relógio parado o mantém ali), longe das
## mesas do jogo novo (em (4, 4) e (2, 6)).
func _seated_customer() -> Array:
	var table := sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(6, 6))
	var chair := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(5, 6), 3)
	var customer := Customer.new()
	customer.serial = 500
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(5, 6)
	customer.position = Vector2(5, 6)
	customer.state = Customer.State.EATING
	customer.eat_left = 999.0
	customer.order = load("res://data/recipes/coffee.tres")
	sim.customers.append(customer)
	return [customer, chair, table]


func test_paused_the_chair_of_a_seated_customer_moves_and_they_go_along() -> void:
	_setup()
	var setup := _seated_customer()
	var customer: Customer = setup[0]
	assert_eq(sim.layout.move(setup[1], Vector2i(6, 7), 2), CafeLayout.Check.IN_USE, "rodando, cadeira ocupada não sai")
	sim.set_paused(true)
	assert_eq(sim.layout.move(setup[1], Vector2i(6, 7), 2), CafeLayout.Check.OK, "pausado, sai")
	assert_eq(customer.seat_cell, Vector2i(6, 7), "o cliente vai junto")
	assert_eq(customer.position, Vector2(6, 7))
	assert_eq(customer.state, Customer.State.EATING, "e continua comendo")


func test_paused_a_chair_left_without_a_table_lets_the_customer_go_without_losing_popularity() -> void:
	_setup()
	var setup := _seated_customer()
	var customer: Customer = setup[0]
	var popularity := sim.popularity
	sim.set_paused(true)
	assert_eq(sim.layout.move(setup[1], Vector2i(6, 2), 0), CafeLayout.Check.OK, "longe de qualquer mesa")
	assert_eq(customer.state, Customer.State.LEAVING, "sem mesa, o cliente vai embora")
	assert_true(customer.happy, "sem reclamar")
	assert_eq(sim.popularity, popularity, "e sem tirar popularidade")


func test_paused_selling_an_occupied_table_works() -> void:
	_setup()
	var setup := _seated_customer()
	var customer: Customer = setup[0]
	assert_eq(sim.can_sell(setup[2]), ServiceResult.IN_USE, "rodando, mesa ocupada não sai")
	sim.set_paused(true)
	var popularity := sim.popularity
	assert_eq(sim.sell_furniture(setup[2]), ServiceResult.OK, "pausado, vende")
	assert_eq(customer.state, Customer.State.LEAVING)
	assert_eq(sim.popularity, popularity)


func test_paused_furniture_can_go_where_someone_stands_and_they_step_aside() -> void:
	_setup()
	var waiter := sim.waiters[0]
	waiter.stop()
	waiter.position = Vector2(5, 2)
	var plant := sim.furniture.get_definition(&"plant_pot")
	assert_eq(sim.layout.place(plant, Vector2i(5, 2)), &"", "rodando, não cai em cima do garçom")
	sim.set_paused(true)
	assert_true(sim.layout.place(plant, Vector2i(5, 2)) != &"", "pausado, cai")
	assert_true(waiter.cell() != Vector2i(5, 2), "o garçom vai para outro piso")
	assert_eq(sim.layout.grid.occupant_at(waiter.cell()), &"", "um piso livre")
	assert_true(waiter.position.distance_to(Vector2(5, 2)) <= 1.01, "o mais perto")


func test_paused_removing_a_counter_with_a_reserved_serving_frees_the_order_and_the_waiter() -> void:
	_setup()
	sim.config = sim.config.duplicate()
	sim.config.menu_order_chance = 0.0
	var setup := _seated_customer()
	var customer: Customer = setup[0]
	customer.state = Customer.State.WAITING_FOR_FOOD
	sim.kitchen.restore_counter(counter, load("res://data/recipes/coffee.tres"), 6)
	sim._place_order(customer)
	_run(0.5)
	var waiter := sim.waiters[0]
	assert_eq(waiter.state, Waiter.State.TO_COUNTER, "o garçom foi buscar a porção")
	sim.set_paused(true)
	assert_eq(sim.store_furniture(counter), CafeLayout.Check.OK, "pausado, guarda o balcão em uso")
	assert_eq(waiter.state, Waiter.State.IDLE, "o garçom fica livre")
	assert_eq(sim.pending_orders(), 1, "o pedido continua, esperando outra porção")


func test_paused_a_cooking_stove_can_move_and_keeps_cooking() -> void:
	_setup()
	sim.start_cooking(stove, &"coffee")
	sim.set_paused(true)
	assert_eq(sim.layout.move(stove, Vector2i(0, 3), 0), CafeLayout.Check.OK, "pausado, o fogão aceso muda de lugar")
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING, "e continua cozinhando")
