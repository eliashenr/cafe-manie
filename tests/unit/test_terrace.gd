extends TestCase
## Terraço ao ar livre (DT-069): uma compra que transforma a fileira da frente num terraço; de dia, quem senta lá
## paga mais; à noite, o normal. O terraço acompanha a expansão e fica no save.

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	clock.time = _at_hour(12)
	var no_customers: Array[CustomerType] = []
	var config: ServiceConfig = load("res://data/config/service.tres").duplicate()
	config.attraction_visit_chance = 0.0
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), config, FurnitureCatalog.load_from(),
		RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.dirt_config = sim.dirt_config.duplicate()
	sim.dirt_config.spot_chance = 0.0


func _at_hour(hour: int) -> int:
	return Time.get_unix_time_from_datetime_string("2026-10-20T%02d:00:00" % hour) - ManualClock.new().utc_offset_seconds()


## Constrói o terraço sem passar pela loja (nível e ouro de sobra).
func _build() -> void:
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, sim.terrace_config.price, "teste")
	assert_eq(sim.build_terrace(), ServiceResult.OK)


## Quanto paga quem acabou de comer na cadeira posta em [param chair_cell] (mesa do lado).
func _paid_at(chair_cell: Vector2i) -> int:
	var table := sim.layout.place(sim.furniture.get_definition(&"table_round"), chair_cell + Vector2i(1, 0))
	var chair := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), chair_cell, 3)
	var customer := Customer.new()
	customer.serial = 50
	customer.type = load("res://data/customers/regular.tres")
	customer.speed = sim.config.customer_walk_speed
	customer.seat_id = chair
	customer.seat_cell = chair_cell
	customer.position = Vector2(chair_cell)
	customer.order = sim.recipes.get_definition(&"lasagna")
	customer.state = Customer.State.EATING
	customer.eat_left = 0.0
	sim.customers.append(customer)
	sim.tick(0.01)
	sim.customers.clear()
	sim.layout.remove(chair)
	sim.layout.remove(table)
	return customer.paid


func test_the_terrace_config_is_valid() -> void:
	var config: TerraceConfig = load("res://data/config/terrace.tres")
	assert_true(config.is_valid())
	var broken: TerraceConfig = config.duplicate()
	broken.price = -1
	assert_false(broken.is_valid(), "preço negativo")
	broken = config.duplicate()
	broken.display_name = ""
	assert_false(broken.is_valid(), "sem nome")


func test_building_checks_level_and_gold_and_charges_once() -> void:
	_setup()
	assert_false(sim.has_terrace())
	assert_true(sim.terrace_cells().is_empty(), "sem terraço, nenhum piso dele")
	assert_eq(sim.build_terrace(), ServiceResult.TERRACE_LOCKED)
	sim.progression.add_xp(99999)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "teste")
	assert_eq(sim.build_terrace(), ServiceResult.NOT_ENOUGH_GOLD)
	assert_false(sim.has_terrace())
	sim.wallet.earn(Wallet.SOFT, sim.terrace_config.price + 10, "teste")
	assert_eq(sim.build_terrace(), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 10, "cobrou o preço")
	assert_true(sim.has_terrace())
	assert_eq(sim.build_terrace(), ServiceResult.ALREADY_BUILT)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 10, "não cobra duas vezes")


func test_the_terrace_is_the_front_row_and_follows_the_expansion() -> void:
	_setup()
	_build()
	var cells := sim.terrace_cells()
	assert_eq(cells.size(), 10)
	assert_true(cells.all(func(cell: Vector2i) -> bool: return cell.y == 9), "a fileira da frente")
	assert_true(sim.is_terrace(Vector2i(0, 9)) and not sim.is_terrace(Vector2i(0, 8)))
	assert_false(sim.is_terrace(Vector2i(0, 10)), "fora do café não")
	sim.layout.expand_to(Vector2i(12, 12))
	assert_eq(sim.terrace_cells().size(), 12)
	assert_true(sim.is_terrace(Vector2i(3, 11)) and not sim.is_terrace(Vector2i(3, 9)), "o terraço vai para a frente nova")


func test_customers_on_the_terrace_pay_more_by_day() -> void:
	_setup()
	var inside := _paid_at(Vector2i(3, 4))
	var front_before := _paid_at(Vector2i(3, 9))
	assert_eq(front_before, inside, "sem terraço, a frente paga o normal")
	_build()
	var on_terrace := _paid_at(Vector2i(3, 9))
	assert_eq(on_terrace, roundi(inside * (1.0 + sim.terrace_config.day_pay_bonus)), "de dia, o terraço paga mais")
	assert_eq(_paid_at(Vector2i(3, 4)), inside, "lá dentro, o normal")
	clock.time = _at_hour(23)
	assert_true(sim.is_night())
	assert_eq(_paid_at(Vector2i(3, 9)), inside, "à noite, o normal")


func test_the_terrace_adds_beauty() -> void:
	_setup()
	var before := sim.beauty()
	_build()
	assert_eq(sim.beauty(), before + sim.terrace_config.beauty)


func test_the_save_keeps_the_terrace() -> void:
	_setup()
	_build()
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_true(loaded.has_terrace())
	var old := SaveCodec.encode(sim)
	old["style"].erase("terrace")
	var restored := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(old))), clock, 7).simulation
	assert_false(restored.has_terrace(), "save antigo: sem terraço")
