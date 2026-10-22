extends TestCase
## Placa ABERTO/FECHADO (DT-051): fechado, ninguém novo chega e a fila da calçada vai embora sem tirar
## popularidade; quem já está lá dentro é atendido e sai sem tirar popularidade, mesmo se cansar. Ao abrir,
## o próximo cliente chega logo. A placa fica gravada no save.

var clock: ManualClock
var sim: CafeSimulation
## Quantos clientes chegaram (numa lista, para a função ligada ao sinal não prender o teste).
var arrivals: Array[int] = []


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.config = sim.config.duplicate()
	sim.config.spawn_interval = 60.0  # depois de uma chegada, a próxima demora: o teste vê a reabertura
	var counter: Array[int] = [0]
	arrivals = counter
	sim.customer_arrived.connect(func(_c: Customer) -> void: counter[0] += 1)


## Anda a simulação [param seconds] segundos, em passos de 0,1 s, com o relógio junto.
func _run(seconds: float) -> void:
	for i in roundi(seconds * 10.0):
		clock.advance(0.1)
		sim.tick(0.1)


func _queued(serial: int) -> Customer:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	customer.state = Customer.State.QUEUED
	customer.patience_total = 999.0
	customer.patience_left = 999.0
	sim.customers.append(customer)
	return customer


## Cliente sentado numa cadeira do lado de uma mesa, longe das mesas do jogo novo (em (4, 4) e (2, 6)).
func _seated(state: Customer.State) -> Customer:
	sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(6, 6))
	var chair := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(5, 6), 3)
	var customer := Customer.new()
	customer.serial = 500
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(5, 6)
	customer.position = Vector2(5, 6)
	customer.state = state
	customer.order = load("res://data/recipes/coffee.tres")
	sim.customers.append(customer)
	return customer


func test_nobody_arrives_while_closed() -> void:
	_setup()
	sim.set_closed(true)
	_run(180.0)
	assert_eq(arrivals[0], 0, "fechado, ninguém chega")
	assert_eq(sim.customers.size(), 0)


func test_opening_brings_the_next_customer_soon() -> void:
	_setup()
	while arrivals[0] == 0:
		_run(0.5)
	sim.set_closed(true)  # a próxima chegada estava a quase um minuto
	_run(5.0)
	sim.set_closed(false)
	_run(CafeSimulation.FIRST_ARRIVAL_DELAY + 0.5)
	assert_eq(arrivals[0], 2, "ao abrir, o próximo cliente chega logo, como na abertura do jogo")


func test_closing_sends_the_sidewalk_line_away_without_losing_popularity() -> void:
	_setup()
	var first := _queued(70)
	var second := _queued(71)
	var popularity := sim.popularity
	var left: Array[Customer] = []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	sim.set_closed(true)
	assert_eq(sim.queued().size(), 0, "a fila da calçada vai embora")
	assert_eq(left.size(), 2)
	assert_true(first.happy and second.happy, "sem reclamar")
	assert_true(first.gave_up_in_line, "sai andando pela calçada")
	assert_false(sim.customers.has(first), "e sai da lista na hora")
	assert_eq(sim.popularity, popularity, "e sem tirar popularidade")


func test_customers_inside_are_still_served_while_closed() -> void:
	_setup()
	var customer := _seated(Customer.State.EATING)
	customer.eat_left = 1.0
	var gold := sim.wallet.balance(Wallet.SOFT)
	sim.set_closed(true)
	_run(1.5)
	assert_true(customer.paid > 0, "quem está comendo termina e paga")
	assert_true(sim.wallet.balance(Wallet.SOFT) > gold)
	assert_eq(customer.state, Customer.State.LEAVING, "e vai embora")


func test_a_customer_who_gives_up_while_closed_does_not_cost_popularity() -> void:
	_setup()
	var customer := _seated(Customer.State.WAITING_FOR_FOOD)
	customer.patience_total = 1.0
	customer.patience_left = 1.0
	var popularity := sim.popularity
	sim.set_closed(true)
	_run(2.0)
	assert_eq(customer.state, Customer.State.LEAVING, "cansou de esperar e foi embora")
	assert_false(customer.happy)
	assert_eq(sim.popularity, popularity, "mas o café avisou que estava fechando: a popularidade fica")


func test_giving_up_while_open_still_costs_popularity() -> void:
	_setup()
	var customer := _seated(Customer.State.WAITING_FOR_FOOD)
	customer.patience_total = 1.0
	customer.patience_left = 1.0
	var popularity := sim.popularity
	_run(2.0)
	assert_eq(customer.state, Customer.State.LEAVING)
	assert_true(sim.popularity < popularity, "aberto, quem desiste tira popularidade, como sempre")


func test_closing_twice_changes_nothing_and_reopening_keeps_the_line_empty() -> void:
	_setup()
	sim.set_closed(true)
	var left: Array[Customer] = []
	sim.customer_left.connect(func(c: Customer) -> void: left.append(c))
	_queued(80)  # alguém que já estava na fila quando o café fechou de novo
	sim.set_closed(true)
	assert_eq(left.size(), 0, "fechar o que já está fechado não faz nada")
	sim.set_closed(false)
	assert_false(sim.closed)


func test_the_save_keeps_the_sign() -> void:
	_setup()
	sim.set_closed(true)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_true(loaded.closed, "o café abre fechado, como ficou")
	sim.set_closed(false)
	text = JSON.stringify(SaveCodec.encode(sim))
	loaded = SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_false(loaded.closed)


func test_an_old_save_opens_with_the_cafe_open() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["save_version"] = 8
	data.erase("closed")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(data)))
	assert_eq(migrated["save_version"], SaveCodec.CURRENT_VERSION)
	assert_eq(migrated["closed"], false)
	assert_false(SaveCodec.decode(migrated, clock, 11).simulation.closed)
