extends TestCase
## Bebidas (DT-052): com uma máquina no café, às vezes o cliente pede uma bebida liberada no nível; o jogador
## toca nele e ela sai na hora, gastando energia; o cliente bebe e paga. Sem máquina, nada muda no atendimento.

var clock: ManualClock
var sim: CafeSimulation


func _setup(level_xp := 30) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.config = sim.config.duplicate()
	sim.progression.add_xp(level_xp)


func _place_machine(id: StringName, cell := Vector2i(0, 6)) -> StringName:
	var placed := sim.layout.place(sim.furniture.get_definition(id), cell)
	assert_true(placed != &"", "a máquina %s coube" % id)
	return placed


## Cliente sentado pronto para pedir, numa cadeira do lado de uma mesa longe das do jogo novo.
func _seated_customer(state := Customer.State.WAITING_TO_ORDER) -> Customer:
	sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(6, 6))
	var chair := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(5, 6), 3)
	var customer := Customer.new()
	customer.serial = 500
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(5, 6)
	customer.position = Vector2(5, 6)
	customer.state = state
	customer.patience_total = 60.0
	customer.patience_left = 60.0
	sim.customers.append(customer)
	return customer


func _thirsty(drink_id: StringName) -> Customer:
	var customer := _seated_customer(Customer.State.WAITING_FOR_DRINK)
	customer.drink = sim.drinks.get_definition(drink_id)
	return customer


func test_drink_data_is_valid_and_every_drink_has_its_machine() -> void:
	_setup()
	assert_eq(sim.drinks.size(), 9, "6 bebidas e 3 frozen yogurts (DT-065)")
	var machines := {}
	for definition in sim.furniture.all():
		if definition.category == FurnitureDefinition.Category.MACHINE:
			# a mais fácil de cada tipo (a Máquina de Café Inteligente, DT-082, faz o mesmo café num nível maior)
			var known: FurnitureDefinition = machines.get(definition.machine)
			if known == null or definition.min_level < known.min_level:
				machines[definition.machine] = definition
	assert_eq(machines.size(), 3, "máquinas de café, de sucos e de frozen")
	for drink in sim.drinks.all():
		assert_true(drink.is_valid(), String(drink.id))
		assert_true(machines.has(drink.machine), "a bebida %s tem máquina" % drink.id)
		assert_true(drink.unlock_level >= machines[drink.machine].min_level, "não pede antes de dar para comprar a máquina")
		assert_true(ArtSprites.drink(drink.id) != null, "a bebida %s tem desenho" % drink.id)


func test_a_machine_needs_its_drink_kind_and_only_machines_have_one() -> void:
	var machine := FurnitureDefinition.new()
	machine.id = &"teste"
	machine.category = FurnitureDefinition.Category.MACHINE
	assert_false(machine.is_valid(), "máquina sem bebida")
	machine.machine = &"coffee"
	assert_true(machine.is_valid())
	machine.category = FurnitureDefinition.Category.DECOR
	assert_false(machine.is_valid(), "enfeite com bebida")


func test_without_a_machine_nobody_orders_a_drink() -> void:
	_setup()
	sim.config.drink_order_chance = 1.0
	var customer := _seated_customer()
	sim._place_order(customer)
	assert_eq(customer.state, Customer.State.WAITING_FOR_FOOD, "sem máquina, pede prato como sempre")
	assert_eq(customer.drink, null)
	assert_false(sim.has_drink_machine())


func test_with_a_machine_customers_order_drinks() -> void:
	_setup()
	sim.config.drink_order_chance = 1.0
	_place_machine(&"machine_coffee")
	var customer := _seated_customer()
	sim._place_order(customer)
	assert_eq(customer.state, Customer.State.WAITING_FOR_DRINK, "pede uma bebida")
	assert_eq(customer.drink.machine, &"coffee", "da máquina que existe")
	assert_true(customer.drink.unlock_level <= sim.progression.level, "e já liberada")
	assert_true(sim.has_drink_machine())


func test_locked_drinks_are_not_ordered() -> void:
	_setup(30)  # nível 2: as bebidas da máquina de sucos ainda não saem
	sim.config.drink_order_chance = 1.0
	_place_machine(&"machine_juice")
	assert_eq(sim.drink_menu().size(), 0)
	var customer := _seated_customer()
	sim._place_order(customer)
	assert_eq(customer.state, Customer.State.WAITING_FOR_FOOD, "bebida bloqueada: pede prato")


func test_serving_a_drink_spends_energy_and_the_customer_pays_after_drinking() -> void:
	_setup()
	_place_machine(&"machine_coffee")
	var customer := _thirsty(&"espresso")
	var drink := customer.drink
	var energy := sim.energy.amount(clock.now())
	var xp := sim.progression.xp
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.serve_drink(customer), ServiceResult.OK)
	assert_eq(sim.energy.amount(clock.now()), energy - drink.energy_cost, "gastou energia")
	assert_eq(customer.state, Customer.State.EATING, "está bebendo")
	assert_eq(sim.progression.xp, xp + drink.xp_reward, "XP da bebida na hora")
	for i in roundi((sim.config.drink_time + 0.5) * 10.0):
		clock.advance(0.1)
		sim.tick(0.1)
	var price := maxi(1, roundi(drink.sell_price * customer.type.pay_multiplier))
	assert_eq(customer.paid, price, "pagou o preço da bebida")
	assert_true(sim.wallet.balance(Wallet.SOFT) >= gold + price, "o ouro entrou (e alguma missão pode ter pago junto)")
	assert_eq(customer.state, Customer.State.LEAVING)
	assert_true(customer.happy)


func test_no_energy_no_drink() -> void:
	_setup()
	_place_machine(&"machine_coffee")
	var customer := _thirsty(&"espresso")
	sim.energy.spend(sim.energy.amount(clock.now()), clock.now())
	assert_eq(sim.serve_drink(customer), ServiceResult.NOT_ENOUGH_ENERGY)
	assert_eq(customer.state, Customer.State.WAITING_FOR_DRINK, "continua esperando")
	assert_eq(sim.energy.amount(clock.now()), 0)


func test_only_customers_waiting_for_a_drink_can_be_served_one() -> void:
	_setup()
	_place_machine(&"machine_coffee")
	var customer := _seated_customer(Customer.State.WAITING_FOR_FOOD)
	customer.order = load("res://data/recipes/coffee.tres")
	var energy := sim.energy.amount(clock.now())
	assert_eq(sim.serve_drink(customer), ServiceResult.NOT_WAITING_FOR_DRINK)
	assert_eq(sim.serve_drink(null), ServiceResult.NOT_WAITING_FOR_DRINK)
	assert_eq(sim.energy.amount(clock.now()), energy, "nada gasto")


func test_a_served_drink_cannot_be_served_again() -> void:
	_setup()
	_place_machine(&"machine_coffee")
	var customer := _thirsty(&"espresso")
	assert_eq(sim.serve_drink(customer), ServiceResult.OK)
	var energy := sim.energy.amount(clock.now())
	assert_eq(sim.serve_drink(customer), ServiceResult.NOT_WAITING_FOR_DRINK, "já está bebendo")
	assert_eq(sim.energy.amount(clock.now()), energy, "a energia sai uma vez só")


func test_a_drink_needs_its_own_machine() -> void:
	_setup(160)
	_place_machine(&"machine_coffee")
	var customer := _thirsty(&"orange_juice")  # pedido antes de a máquina de sucos sair
	var energy := sim.energy.amount(clock.now())
	assert_eq(sim.serve_drink(customer), ServiceResult.NO_MACHINE)
	assert_eq(customer.state, Customer.State.WAITING_FOR_DRINK)
	assert_eq(sim.energy.amount(clock.now()), energy)


func test_removing_the_machine_lets_drink_customers_go_without_losing_popularity() -> void:
	_setup()
	var machine := _place_machine(&"machine_coffee")
	var customer := _thirsty(&"espresso")
	var popularity := sim.popularity
	assert_eq(sim.sell_furniture(machine), ServiceResult.OK, "a máquina não fica presa")
	assert_eq(customer.state, Customer.State.LEAVING, "sem máquina, o cliente vai embora")
	assert_true(customer.happy, "sem reclamar")
	assert_eq(sim.popularity, popularity)


func test_a_drink_customer_who_gives_up_costs_popularity_like_any_other() -> void:
	_setup()
	_place_machine(&"machine_coffee")
	var customer := _thirsty(&"espresso")
	customer.patience_left = 0.5
	var popularity := sim.popularity
	for i in 10:
		clock.advance(0.1)
		sim.tick(0.1)
	assert_eq(customer.state, Customer.State.LEAVING)
	assert_false(customer.happy)
	assert_true(sim.popularity < popularity)


func test_leveling_up_refills_and_grows_the_energy() -> void:
	_setup(0)
	sim.energy.spend(5, clock.now())
	sim.progression.add_xp(30)
	assert_eq(sim.progression.level, 2)
	assert_eq(sim.energy.maximum(), sim.energy.config.max_at(2))
	assert_eq(sim.energy.amount(clock.now()), sim.energy.maximum(), "nível novo enche a energia")


func test_the_save_keeps_the_energy_and_it_recharges_while_away() -> void:
	_setup(160)  # nível 4: o máximo já é maior que o do nível 1
	sim.energy.spend(4, clock.now())
	var text := JSON.stringify(SaveCodec.encode(sim))
	clock.advance(sim.energy.config.seconds_per_point * 2.0)
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_true(sim.energy.maximum() > sim.energy.config.max_at(1))
	assert_eq(loaded.energy.maximum(), sim.energy.maximum(), "o máximo do nível salvo")
	assert_eq(loaded.energy.amount(clock.now()), sim.energy.maximum() - 2, "2 pontos voltaram com o jogo fechado")


func test_an_old_save_opens_with_full_energy() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["save_version"] = 9
	data.erase("energy")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(data)))
	assert_eq(migrated["save_version"], SaveCodec.CURRENT_VERSION)
	assert_eq(migrated["energy"], {}, "a migração acrescenta a energia")
	var loaded := SaveCodec.decode(migrated, clock, 11).simulation
	assert_eq(loaded.energy.amount(clock.now()), loaded.energy.maximum(), "começa cheia")
