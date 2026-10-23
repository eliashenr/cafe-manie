extends TestCase
## Fogões com perfil (DT-058): cada modelo tem uma função (mais rápido, tempo máximo, mais porções ou mais XP) e os
## mais fortes são só 1 por café. Os cortes de tempo do fogão e do troféu se somam até um limite.

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), load("res://data/config/service.tres"),
		FurnitureCatalog.load_from(), RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.progression.add_xp(99999)  # nível 30: tudo liberado
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(6, 6))
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(6, 8))


func _stove(id: StringName, cell := Vector2i(2, 2)) -> StringName:
	return sim.layout.place(sim.furniture.get_definition(id), cell)


func test_every_special_stove_has_a_profile() -> void:
	var catalog := FurnitureCatalog.load_from()
	var sets := StoveSets.new(CafeLayout.new(Vector2i(4, 4), Vector2i(3, 2)))
	for definition in catalog.all():
		if definition.category != FurnitureDefinition.Category.COOKING or definition.id in [&"stove_basic", &"stove_blue"]:
			continue
		if sets.set_of_part(definition.id) != null:
			continue  # a função das peças do multifogão é o conjunto (DT-060)
		assert_true(definition.has_stove_profile(), "%s tem uma função" % definition.id)
		assert_true(definition.is_valid(), String(definition.id))
		if definition.stove_max_time > 0.0:
			assert_eq(definition.max_per_cafe, 1, "%s com tempo máximo é só 1 por café" % definition.id)
	var broken: FurnitureDefinition = catalog.get_definition(&"plant_pot").duplicate()
	broken.stove_time_cut = 0.2
	assert_false(broken.is_valid(), "perfil de fogão só em fogão")
	var config: ServiceConfig = load("res://data/config/service.tres")
	assert_true(config.max_speedup > 0.0 and config.max_speedup < 1.0)
	var no_limit: ServiceConfig = config.duplicate()
	no_limit.max_speedup = 1.0
	assert_false(no_limit.is_valid(), "corte de 100% deixaria o prato pronto sem cozinhar")


func test_a_faster_stove_cuts_the_time() -> void:
	_setup()
	var stove := _stove(&"stove_steel")
	var cut := sim.furniture.get_definition(&"stove_steel").stove_time_cut
	var pizza := sim.recipes.get_definition(&"pizza")
	assert_almost_eq(sim.cook_time_on(stove, pizza), pizza.cook_time * (1.0 - cut), 0.01)
	sim.start_cooking(stove, &"pizza")
	assert_almost_eq(sim.kitchen.stove_duration(stove), pizza.cook_time * (1.0 - cut), 0.01)


func test_a_max_time_stove_makes_long_dishes_quick() -> void:
	_setup()
	var stove := _stove(&"stove_copper")
	var limit := sim.furniture.get_definition(&"stove_copper").stove_max_time
	var lobster := sim.recipes.get_definition(&"lobster")
	var coffee := sim.recipes.get_definition(&"coffee")
	assert_eq(sim.cook_time_on(stove, lobster), limit, "a lagosta fica pronta no tempo máximo")
	assert_eq(sim.cook_time_on(stove, coffee), coffee.cook_time, "o café já era mais rápido")
	sim.start_cooking(stove, &"lobster")
	clock.advance(limit)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY)
	assert_almost_eq(sim.kitchen.time_to_spoil(stove), sim.kitchen.spoil_time(lobster), 0.01, "e aguenta o tempo de sempre para estragar")


func test_stove_and_trophy_cuts_add_up_to_a_limit() -> void:
	_setup()
	var stove := _stove(&"stove_steel")
	sim.layout.place(sim.furniture.get_definition(&"trophy_gold"), Vector2i(3, 2))
	var pizza := sim.recipes.get_definition(&"pizza")
	assert_almost_eq(sim.cook_time_on(stove, pizza), pizza.cook_time * (1.0 - sim.config.max_speedup), 0.01,
		"25% do fogão e 65% do troféu passam do limite")


func test_a_bonus_stove_gives_more_servings_and_still_takes_salt() -> void:
	_setup()
	var stove := _stove(&"stove_cream")
	var coffee := sim.recipes.get_definition(&"coffee")
	var bonus := sim.bonus_servings_on(stove, coffee)
	assert_true(bonus >= 1)
	sim.start_cooking(stove, &"coffee")
	assert_eq(sim.kitchen.stove_servings(stove), coffee.servings + bonus)
	sim.spice_shelf.add(&"salt")
	assert_eq(sim.use_spice(stove, &"salt"), ServiceResult.OK, "o sal soma com o fogão")
	var total := sim.kitchen.stove_servings(stove)
	assert_true(total > coffee.servings + bonus)
	clock.advance(coffee.cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)
	assert_eq(sim.kitchen.servings_of(coffee), total)


func test_an_xp_stove_gives_more_xp() -> void:
	_setup()
	var stove := _stove(&"stove_yellow")
	var lasagna := sim.recipes.get_definition(&"lasagna")
	var expected := roundi(lasagna.xp_reward * (1.0 + sim.furniture.get_definition(&"stove_yellow").stove_xp_bonus))
	assert_eq(sim.xp_on(stove, lasagna), expected)
	sim.start_cooking(stove, &"lasagna")
	clock.advance(lasagna.cook_time)
	var xp := sim.progression.xp
	assert_eq(sim.collect(stove), ServiceResult.OK)
	assert_true(sim.progression.xp - xp >= expected, "o XP a mais entra (mais o prêmio de alguma missão)")


func test_limited_stoves_are_one_per_cafe() -> void:
	_setup()
	var copper := sim.furniture.get_definition(&"stove_copper")
	assert_eq(sim.can_acquire(copper), ServiceResult.OK)
	var first := _stove(&"stove_copper")
	assert_eq(sim.can_acquire(copper), ServiceResult.FURNITURE_LIMIT, "o segundo não entra")
	assert_eq(sim.acquire_and_place(copper, Vector2i(2, 5), 0), ServiceResult.FURNITURE_LIMIT)
	sim.store_furniture(first)
	assert_eq(sim.can_acquire(copper), ServiceResult.OK, "guardado, abre a vaga")


func test_the_save_keeps_the_stove_bonus_servings() -> void:
	_setup()
	var stove := _stove(&"stove_cream")
	sim.start_cooking(stove, &"lasagna")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_eq(loaded.kitchen.stove_servings(stove), sim.kitchen.stove_servings(stove))
