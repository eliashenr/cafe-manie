extends TestCase
## Atrações e palco (DT-066): às vezes quem pagou vai brincar numa atração com lugar e deixa ouro nela (até a
## capacidade); o jogador coleta; com palco, de tempos em tempos tem show e os clientes chegam mais rápido.

var clock: ManualClock
var sim: CafeSimulation
var chair: StringName
var arcade: StringName


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	var config: ServiceConfig = load("res://data/config/service.tres").duplicate()
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), config, FurnitureCatalog.load_from(),
		RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(4, 4))
	chair = sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	arcade = sim.layout.place(sim.furniture.get_definition(&"arcade"), Vector2i(7, 7))


## Um cliente sentado que acabou de comer e vai pagar no próximo passo.
func _done_eating() -> Customer:
	var customer := Customer.new()
	customer.serial = 50
	customer.type = load("res://data/customers/regular.tres")
	customer.speed = sim.config.customer_walk_speed
	customer.seat_id = chair
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	customer.order = sim.recipes.get_definition(&"coffee")
	customer.state = Customer.State.EATING
	customer.eat_left = 0.0
	sim.customers.append(customer)
	return customer


func _run(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		sim.tick(0.25)
		left -= 0.25


func test_the_attractions_and_the_stage_are_valid() -> void:
	var catalog := FurnitureCatalog.load_from()
	for id in [&"jukebox", &"arcade", &"claw_machine", &"ring_toss"]:
		var attraction := catalog.get_definition(id)
		assert_true(attraction.is_valid() and attraction.attraction_gold > 0, String(id))
	assert_true(catalog.get_definition(&"stage").stage)
	var stage_config: StageConfig = load("res://data/config/stage.tres")
	assert_true(stage_config.is_valid())
	var broken: FurnitureDefinition = catalog.get_definition(&"arcade").duplicate()
	broken.attraction_capacity = 1
	assert_false(broken.is_valid(), "capacidade menor que uma brincadeira")


func test_a_customer_plays_and_leaves_gold() -> void:
	_setup()
	sim.config.attraction_visit_chance = 1.0
	var customer := _done_eating()
	sim.tick(0.01)
	assert_eq(customer.state, Customer.State.WALKING_TO_PLAY, "depois de pagar, vai brincar")
	assert_eq(customer.seat_id, &"", "e libera a cadeira")
	assert_eq(customer.attraction_id, arcade)
	_run(30.0)
	assert_eq(sim.attractions.gold(arcade), sim.furniture.get_definition(&"arcade").attraction_gold, "deixou o ouro")
	assert_true(customer.state in [Customer.State.LEAVING, Customer.State.GONE], "e foi embora")


func test_without_chance_or_room_the_customer_just_leaves() -> void:
	_setup()
	sim.config.attraction_visit_chance = 0.0
	var first := _done_eating()
	sim.tick(0.01)
	assert_true(first.state in [Customer.State.LEAVING, Customer.State.GONE])
	assert_eq(sim.attractions.gold(arcade), 0)
	sim.config.attraction_visit_chance = 1.0
	var definition := sim.furniture.get_definition(&"arcade")
	for i in definition.attraction_capacity:  # no máximo uma brincadeira por moeda de capacidade
		if not sim.attractions.has_room(arcade):
			break
		sim.attractions.add_play(arcade)
	assert_false(sim.attractions.has_room(arcade), "encheu")
	sim.attractions.add_play(arcade)
	assert_eq(sim.attractions.gold(arcade), definition.attraction_capacity, "cheia, não passa da capacidade")
	var second := _done_eating()
	second.serial = 51
	sim.tick(0.01)
	assert_true(second.state in [Customer.State.LEAVING, Customer.State.GONE], "atração cheia: vai embora direto")


func test_collecting_the_gold() -> void:
	_setup()
	assert_eq(sim.collect_attraction(arcade), ServiceResult.NOTHING_TO_COLLECT)
	assert_eq(sim.collect_attraction(chair), ServiceResult.NOT_AN_ATTRACTION)
	sim.attractions.add_play(arcade)
	sim.attractions.add_play(arcade)
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.collect_attraction(arcade), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + 2 * sim.furniture.get_definition(&"arcade").attraction_gold)
	assert_eq(sim.attractions.gold(arcade), 0, "esvaziou")


func test_removing_the_attraction_sends_the_player_away() -> void:
	_setup()
	sim.config.attraction_visit_chance = 1.0
	var customer := _done_eating()
	sim.tick(0.01)
	sim.layout.remove(arcade)
	assert_true(customer.state in [Customer.State.LEAVING, Customer.State.GONE], "a atração sumiu: vai embora")


func test_the_stage_runs_shows_that_speed_up_arrivals() -> void:
	_setup()
	var started: Array = []
	sim.show_started.connect(func() -> void: started.append(true))
	_run(sim.stage_config.show_interval + 1.0)
	assert_true(started.is_empty(), "sem palco, sem show")
	sim.layout.place(sim.furniture.get_definition(&"stage"), Vector2i(1, 7))
	var normal := sim.spawn_interval_now()
	_run(sim.stage_config.show_interval + 0.5)
	assert_eq(started.size(), 1, "com palco, o show começa")
	assert_true(sim.show_running())
	assert_almost_eq(sim.spawn_interval_now(), normal * sim.stage_config.spawn_multiplier, 0.01, "os clientes chegam mais rápido")
	_run(sim.stage_config.show_duration + 0.5)
	assert_false(sim.show_running(), "o show acaba")
	assert_almost_eq(sim.spawn_interval_now(), normal, 0.01)
	sim.set_closed(true)
	_run(sim.stage_config.show_interval + 1.0)
	assert_eq(started.size(), 1, "com o café fechado, não tem show")


func test_the_save_keeps_the_attraction_gold() -> void:
	_setup()
	sim.attractions.add_play(arcade)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_eq(loaded.attractions.gold(arcade), sim.attractions.gold(arcade))
	var old := SaveCodec.encode(sim)
	old["save_version"] = 17
	old.erase("attractions")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["attractions"], {}, "a migração acrescenta as atrações")
