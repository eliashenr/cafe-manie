extends TestCase
## Troféus aceleradores (DT-057): o troféu deixa mais rápidos os fogões nas 8 casas em volta; cada prato acelerado
## gasta uma carga; gasto, ele para de acelerar até ser renovado com ouro. Guardado, lembra as cargas; o save guarda
## as cargas e o tempo de cada prato no fogão.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), load("res://data/config/service.tres"),
		FurnitureCatalog.load_from(), RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.progression.add_xp(20000)  # nível 22: os três troféus à venda
	stove = _place(&"stove_basic", Vector2i(2, 2))
	_place(&"counter_basic", Vector2i(6, 6))


func _place(id: StringName, cell: Vector2i) -> StringName:
	return sim.layout.place(sim.furniture.get_definition(id), cell)


func _definition(id: StringName) -> FurnitureDefinition:
	return sim.furniture.get_definition(id)


func test_the_three_trophies_are_valid_and_get_stronger() -> void:
	var catalog := FurnitureCatalog.load_from()
	var trophies := catalog.all().filter(func(d: FurnitureDefinition) -> bool: return d.is_trophy())
	assert_eq(trophies.size(), 3, "bronze, prata e ouro")
	trophies.sort_custom(func(a: FurnitureDefinition, b: FurnitureDefinition) -> bool: return a.min_level < b.min_level)
	for i in trophies.size():
		var trophy: FurnitureDefinition = trophies[i]
		assert_true(trophy.is_valid(), String(trophy.id))
		assert_true(trophy.renew_price > 0 and trophy.renew_price < trophy.price, "renovar sai mais barato que comprar")
		if i > 0:
			assert_true(trophy.stove_speed_bonus > trophies[i - 1].stove_speed_bonus, "o de nível maior acelera mais")
	var broken: FurnitureDefinition = catalog.get_definition(&"trophy_bronze").duplicate()
	broken.trophy_dishes = 0
	assert_false(broken.is_valid(), "troféu sem cargas")


func test_only_stoves_around_the_trophy_get_faster() -> void:
	_setup()
	var trophy := _place(&"trophy_bronze", Vector2i(3, 3))  # na diagonal do fogão
	assert_eq(sim.trophies.booster_for(stove), trophy, "a diagonal conta: são as 8 casas em volta")
	assert_almost_eq(sim.trophies.speed_bonus(stove), _definition(&"trophy_bronze").stove_speed_bonus, 0.0001)
	var far := _place(&"stove_basic", Vector2i(5, 3))  # a 2 casas do troféu
	assert_eq(sim.trophies.booster_for(far), &"", "duas casas longe não acelera")
	var gold := _place(&"trophy_gold", Vector2i(1, 2))
	assert_eq(sim.trophies.booster_for(stove), gold, "vale o mais forte, sem somar")


func test_a_boosted_dish_cooks_faster_and_spends_a_charge() -> void:
	_setup()
	var trophy := _place(&"trophy_bronze", Vector2i(2, 3))
	var definition := _definition(&"trophy_bronze")
	var lasagna := sim.recipes.get_definition(&"lasagna")
	assert_almost_eq(sim.cook_time_on(stove, lasagna), lasagna.cook_time * (1.0 - definition.stove_speed_bonus), 0.01)
	assert_eq(sim.start_cooking(stove, &"lasagna"), ServiceResult.OK)
	assert_almost_eq(sim.kitchen.time_left(stove), lasagna.cook_time * (1.0 - definition.stove_speed_bonus), 0.01)
	assert_eq(sim.trophies.charges_left(trophy), definition.trophy_dishes - 1, "gastou uma carga")
	clock.advance(sim.kitchen.stove_duration(stove))
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "pronto antes do tempo da receita")
	assert_almost_eq(sim.kitchen.time_to_spoil(stove), sim.kitchen.spoil_time(lasagna), 0.01, "e aguenta o tempo de sempre")


func test_moving_the_trophy_does_not_change_a_dish_already_cooking() -> void:
	_setup()
	var trophy := _place(&"trophy_bronze", Vector2i(2, 3))
	sim.start_cooking(stove, &"coffee")
	var duration := sim.kitchen.stove_duration(stove)
	sim.layout.move(trophy, Vector2i(8, 8), 0)
	assert_eq(sim.kitchen.stove_duration(stove), duration, "o tempo foi decidido ao começar")


func test_a_trophy_wears_out_and_can_be_renewed() -> void:
	_setup()
	var trophy := _place(&"trophy_bronze", Vector2i(2, 3))
	var definition := _definition(&"trophy_bronze")
	var worn: Array = []
	sim.trophy_worn_out.connect(func(id: StringName) -> void: worn.append(id))
	assert_eq(sim.renew_trophy(trophy), ServiceResult.TROPHY_FULL, "cheio não precisa renovar")
	var coffee := sim.recipes.get_definition(&"coffee")
	for i in definition.trophy_dishes:
		assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK)
		clock.advance(sim.kitchen.stove_duration(stove))
		sim.collect(stove)
		while sim.kitchen.take_serving(coffee) != &"":  # esvazia o balcão para o próximo prato
			pass
	assert_eq(worn, [trophy], "avisa uma vez, quando se gasta")
	assert_true(sim.trophies.is_worn_out(trophy))
	assert_eq(sim.cook_time_on(stove, coffee), coffee.cook_time, "gasto não acelera")
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.renew_trophy(trophy), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - definition.renew_price)
	assert_eq(sim.trophies.charges_left(trophy), definition.trophy_dishes, "cargas cheias de novo")
	assert_eq(sim.renew_trophy(stove), ServiceResult.NOT_A_TROPHY)
	sim.trophies.use(trophy)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "teste")
	assert_eq(sim.renew_trophy(trophy), ServiceResult.NOT_ENOUGH_GOLD)


func test_a_stored_trophy_keeps_its_charges_and_a_sold_one_loses_them() -> void:
	_setup()
	var trophy := _place(&"trophy_bronze", Vector2i(2, 3))
	for i in 3:
		sim.trophies.use(trophy)
	var left := sim.trophies.charges_left(trophy)
	assert_eq(sim.store_furniture(trophy), CafeLayout.Check.OK)
	assert_eq(sim.acquire_and_place(_definition(&"trophy_bronze"), Vector2i(3, 2), 0), ServiceResult.OK)
	assert_eq(sim.trophies.charges_left(sim.last_placed_id), left, "guardar não renova de graça")
	sim.sell_furniture(sim.last_placed_id)
	sim.acquire_and_place(_definition(&"trophy_bronze"), Vector2i(3, 2), 0)
	assert_eq(sim.trophies.charges_left(sim.last_placed_id), _definition(&"trophy_bronze").trophy_dishes, "um novo vem cheio")


func test_the_save_keeps_charges_and_the_boosted_time() -> void:
	_setup()
	var trophy := _place(&"trophy_silver", Vector2i(2, 3))
	sim.start_cooking(stove, &"cheese_bread")
	var extra := _place(&"trophy_bronze", Vector2i(8, 8))
	sim.trophies.use(extra)
	sim.store_furniture(extra)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_eq(loaded.trophies.charges_left(trophy), sim.trophies.charges_left(trophy))
	assert_almost_eq(loaded.kitchen.stove_duration(stove), sim.kitchen.stove_duration(stove), 0.01, "o prato segue acelerado")
	loaded.acquire_and_place(loaded.furniture.get_definition(&"trophy_bronze"), Vector2i(8, 8), 0)
	assert_eq(loaded.trophies.charges_left(loaded.last_placed_id), sim.furniture.get_definition(&"trophy_bronze").trophy_dishes - 1,
		"o guardado volta com as cargas que tinha")
	var old := SaveCodec.encode(sim)
	old["save_version"] = 12
	old.erase("trophies")
	var migrated_data := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated_data["trophies"], {}, "a migração acrescenta os troféus vazios")
	var migrated := SaveCodec.decode(migrated_data, clock, 7).simulation
	assert_eq(migrated.trophies.charges_left(trophy), sim.furniture.get_definition(&"trophy_silver").trophy_dishes,
		"save antigo: troféus cheios")
