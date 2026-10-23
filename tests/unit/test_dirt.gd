extends TestCase
## Chão sujo (DT-068): às vezes quem termina de comer deixa uma mancha num piso livre do lado da cadeira; limpar dá
## ouro e XP; com o café aberto e o chão sujo, a popularidade cai aos poucos; móvel em cima cobre a mancha.

var clock: ManualClock
var sim: CafeSimulation
var chair: StringName


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	var config: ServiceConfig = load("res://data/config/service.tres").duplicate()
	config.attraction_visit_chance = 0.0
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), config, FurnitureCatalog.load_from(),
		RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.dirt_config = sim.dirt_config.duplicate()
	sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(4, 4))
	chair = sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(3, 4), 3)


## Um cliente sentado que acabou de comer e vai pagar no próximo passo.
func _done_eating(serial := 50) -> Customer:
	var customer := Customer.new()
	customer.serial = serial
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


func test_the_dirt_config_is_valid() -> void:
	var config: DirtConfig = load("res://data/config/dirt.tres")
	assert_true(config.is_valid())
	var broken: DirtConfig = config.duplicate()
	broken.max_spots = 0
	assert_false(broken.is_valid(), "sem lugar para manchas")
	broken = config.duplicate()
	broken.popularity_interval = 0.0
	assert_false(broken.is_valid(), "intervalo zero")


func test_a_customer_who_finished_eating_may_leave_a_spot_next_to_the_chair() -> void:
	_setup()
	sim.dirt_config.spot_chance = 0.0
	_done_eating()
	sim.tick(0.01)
	assert_eq(sim.dirt.count(), 0, "sem chance, sem mancha")
	sim.dirt_config.spot_chance = 1.0
	_done_eating(51)
	sim.tick(0.01)
	assert_eq(sim.dirt.count(), 1, "deixou uma mancha")
	var cell: Vector2i = sim.dirt.spots()[0]
	assert_true(sim.navigation.access_cells(chair).has(cell), "do lado da cadeira")
	assert_eq(sim.layout.placement_at(cell), null, "num piso livre")


func test_spots_stop_at_the_limit_and_only_on_free_floor() -> void:
	_setup()
	assert_false(sim.dirt.add(Vector2i(4, 4)), "em cima da mesa não")
	assert_false(sim.dirt.add(Vector2i(20, 20)), "fora do café não")
	for i in sim.dirt_config.max_spots:
		assert_true(sim.dirt.add(Vector2i(i, 0)))
	assert_false(sim.dirt.add(Vector2i(0, 0)), "a mesma célula não suja duas vezes")
	sim.dirt_config.spot_chance = 1.0
	_done_eating()
	sim.tick(0.01)
	assert_eq(sim.dirt.count(), sim.dirt_config.max_spots, "no limite, ninguém suja mais")


func test_furniture_placed_on_a_spot_covers_it() -> void:
	_setup()
	sim.dirt.add(Vector2i(7, 7))
	sim.dirt.add(Vector2i(1, 1))
	sim.layout.place(sim.furniture.get_definition(&"plant_pot"), Vector2i(7, 7))
	assert_false(sim.dirt.has_spot(Vector2i(7, 7)), "o vaso cobriu a mancha")
	assert_true(sim.dirt.has_spot(Vector2i(1, 1)), "a outra continua")


func test_cleaning_gives_gold_and_xp() -> void:
	_setup()
	sim.dirt.add(Vector2i(1, 1))
	var gold := sim.wallet.balance(Wallet.SOFT)
	var xp := sim.progression.xp
	var cleaned := []
	sim.floor_cleaned.connect(func(cell: Vector2i, _gold: int, _xp: int) -> void: cleaned.append(cell))
	assert_eq(sim.clean_floor(Vector2i(1, 1)), ServiceResult.OK)
	assert_false(sim.dirt.has_spot(Vector2i(1, 1)), "limpou")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + sim.dirt_config.clean_gold)
	assert_eq(sim.progression.xp, xp + sim.dirt_config.clean_xp)
	assert_eq(cleaned, [Vector2i(1, 1)])
	assert_eq(sim.clean_floor(Vector2i(1, 1)), ServiceResult.NOT_DIRTY, "já está limpo")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + sim.dirt_config.clean_gold, "limpar o limpo não dá nada")


func test_a_dirty_floor_slowly_drops_popularity() -> void:
	_setup()
	var interval := sim.dirt_config.popularity_interval
	sim.restore_popularity(50.0)
	sim.tick(interval + 1.0)
	assert_almost_eq(sim.popularity, 50.0, 0.001, "chão limpo segura a popularidade")
	sim.tick(interval * 0.8)
	sim.dirt.add(Vector2i(1, 1))
	sim.dirt.add(Vector2i(2, 1))
	sim.tick(interval * 0.5)
	assert_almost_eq(sim.popularity, 50.0, 0.001, "o tempo só conta depois que o chão sujou")
	sim.tick(interval * 0.5 + 0.1)
	assert_almost_eq(sim.popularity, 50.0 - 2 * sim.dirt_config.popularity_loss_per_spot, 0.001, "perde por mancha")
	sim.set_closed(true)
	sim.tick(interval + 1.0)
	assert_almost_eq(sim.popularity, 50.0 - 2 * sim.dirt_config.popularity_loss_per_spot, 0.001, "fechado não perde")


func test_the_save_keeps_the_spots() -> void:
	_setup()
	sim.dirt.add(Vector2i(1, 1))
	sim.dirt.add(Vector2i(6, 2))
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_true(loaded.dirt.has_spot(Vector2i(1, 1)) and loaded.dirt.has_spot(Vector2i(6, 2)))
	assert_eq(loaded.dirt.count(), 2)
	var old := SaveCodec.encode(sim)
	old["save_version"] = 18
	old.erase("dirt")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["dirt"], [], "a migração começa com o chão limpo")
