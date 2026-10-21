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
