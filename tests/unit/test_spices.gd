extends TestCase
## Temperos (DT-056): a prateleira com Sal da Fartura (mais porções), Pimenta-Relâmpago e Páprica-Foguete (menos
## tempo), Tempero Instantâneo (pronto na hora) e Ervas Salva-Prato (recupera o estragado). Ganhos no presente diário
## e nas missões semanais, ou comprados com Café Ouro. O save guarda a prateleira e o tempero no fogão.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName


func _setup(xp := 0) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.progression.add_xp(xp)
	for placement in sim.layout.placements():
		if sim.kitchen.is_stove(placement.id):
			stove = placement.id
			break
	sim.wallet.earn(Wallet.SOFT, 50000, "teste")


func test_catalog_is_valid_and_ordered() -> void:
	var catalog := SpiceCatalog.load_from()
	assert_eq(catalog.size(), 5)
	var last := -1
	for spice in catalog.all():
		assert_true(spice.is_valid(), String(spice.id))
		assert_true(spice.price > 0, "%s se compra" % spice.id)
		assert_true(spice.order > last, "na ordem da prateleira")
		last = spice.order
		assert_true(ArtSprites.spice(spice.id) != null, "ícone de %s" % spice.id)
	assert_eq(catalog.get_definition(&"salt").extra_servings(2), 1, "fornada pequena ganha pelo menos 1 porção")
	var broken: SpiceDefinition = catalog.get_definition(&"salt").duplicate()
	broken.amount = 0.0
	assert_false(broken.is_valid(), "tempero de porções sem porções")


func test_salt_adds_servings_once_per_dish() -> void:
	_setup()
	sim.spice_shelf.add(&"salt", 2)
	var coffee := sim.recipes.get_definition(&"coffee")
	sim.start_cooking(stove, &"coffee")
	assert_eq(sim.use_spice(stove, &"salt"), ServiceResult.OK)
	var extra := sim.spices.get_definition(&"salt").extra_servings(coffee.servings)
	assert_true(extra >= 1, "pelo menos uma porção a mais")
	assert_eq(sim.kitchen.stove_servings(stove), coffee.servings + extra)
	assert_eq(sim.use_spice(stove, &"salt"), ServiceResult.ALREADY_SEASONED, "um tempero de porções por prato")
	assert_eq(sim.spice_shelf.count(&"salt"), 1, "o recusado não gasta")
	clock.advance(coffee.cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)
	assert_eq(sim.kitchen.servings_of(coffee), coffee.servings + extra, "as porções a mais chegam ao balcão")


func test_a_seasoned_full_batch_spreads_over_two_counters() -> void:
	clock = ManualClock.new()
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	var furniture := FurnitureCatalog.load_from()
	var kitchen_stove := layout.place(furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	var first := layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	var kitchen := Kitchen.new(clock, layout, 40)
	var big := RecipeDefinition.new()
	big.id = &"grande"
	big.cook_time = 60.0
	big.servings = 40
	kitchen.start_cooking(kitchen_stove, big)
	assert_eq(kitchen.add_servings(kitchen_stove, 8), ServiceResult.OK)
	assert_eq(kitchen.add_servings(kitchen_stove, 8), ServiceResult.ALREADY_SEASONED, "a cozinha também só aceita um")
	clock.advance(60.0)
	assert_eq(kitchen.collect(kitchen_stove), ServiceResult.NO_COUNTER_SPACE, "48 porções não cabem num balcão só")
	var second := layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 2))
	assert_eq(kitchen.collect_destination(kitchen_stove), first)
	assert_eq(kitchen.collect(kitchen_stove), ServiceResult.OK)
	assert_eq(kitchen.counter_stack(first).servings, 40)
	assert_eq(kitchen.counter_stack(second).servings, 8, "o resto vai para o outro balcão")


func test_time_spices_rush_the_dish_but_never_spoil_it() -> void:
	_setup(99999)  # nível 30
	sim.spice_shelf.add(&"pepper")
	sim.spice_shelf.add(&"paprika")
	var lobster := sim.recipes.get_definition(&"lobster")
	sim.start_cooking(stove, &"lobster")
	assert_eq(sim.use_spice(stove, &"paprika"), ServiceResult.OK)
	assert_almost_eq(sim.kitchen.time_left(stove), lobster.cook_time - 21600.0, 0.01, "6 horas a menos")
	assert_eq(sim.use_spice(stove, &"pepper"), ServiceResult.OK)
	assert_almost_eq(sim.kitchen.time_left(stove), lobster.cook_time - 25200.0, 0.01, "mais 1 hora a menos")
	var coffee_stove := _second_stove()
	sim.start_cooking(coffee_stove, &"coffee")
	sim.spice_shelf.add(&"pepper")
	assert_eq(sim.use_spice(coffee_stove, &"pepper"), ServiceResult.OK)
	assert_eq(sim.kitchen.stove_status(coffee_stove), Kitchen.StoveStatus.READY, "o que falta menos fica pronto na hora")
	var coffee := sim.recipes.get_definition(&"coffee")
	assert_almost_eq(sim.kitchen.time_to_spoil(coffee_stove), sim.kitchen.spoil_time(coffee), 0.01, "e não passa do ponto")


func test_instant_spice_makes_it_ready_now() -> void:
	_setup()
	sim.spice_shelf.add(&"instant")
	sim.start_cooking(stove, &"cheese_bread")
	assert_eq(sim.use_spice(stove, &"instant"), ServiceResult.OK)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY)


func test_herbs_save_a_spoiled_dish() -> void:
	_setup()
	sim.spice_shelf.add(&"herbs")
	var coffee := sim.recipes.get_definition(&"coffee")
	sim.start_cooking(stove, &"coffee")
	clock.advance(coffee.cook_time + sim.kitchen.spoil_time(coffee))
	sim.tick(0.1)
	assert_eq(sim.use_spice(stove, &"herbs"), ServiceResult.OK)
	assert_eq(sim.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "volta a ficar pronto")
	assert_almost_eq(sim.kitchen.time_to_spoil(stove), sim.kitchen.spoil_time(coffee), 0.01, "fresquinho")
	var warned: Array = []
	sim.dish_spoiled.connect(func(_id: StringName, recipe: RecipeDefinition) -> void: warned.append(recipe))
	clock.advance(sim.kitchen.spoil_time(coffee))
	sim.tick(0.1)
	assert_eq(warned.size(), 1, "se estragar de novo, avisa de novo")


func test_spices_only_fit_the_right_moment() -> void:
	_setup(14500)  # nível 16: todos à venda
	assert_eq(sim.can_use_spice(stove, &"salt"), ServiceResult.NOT_COOKING, "fogão livre")
	assert_eq(sim.can_use_spice(stove, &"nada"), ServiceResult.UNKNOWN_ITEM)
	sim.start_cooking(stove, &"coffee")
	assert_eq(sim.can_use_spice(stove, &"herbs"), ServiceResult.NOT_SPOILED, "ervas só salvam o estragado")
	assert_eq(sim.use_spice(stove, &"salt"), ServiceResult.NO_SPICE, "sem tempero na prateleira")
	clock.advance(15.0)
	assert_eq(sim.can_use_spice(stove, &"pepper"), ServiceResult.NOT_COOKING, "pronto não precisa de pressa")


func test_buying_spices() -> void:
	_setup()
	var salt := sim.spices.get_definition(&"salt")
	assert_eq(sim.buy_spice(&"salt"), ServiceResult.SPICE_LOCKED, "nível 1: ainda não está à venda")
	var table: LevelTable = load("res://data/progression/levels.tres")
	sim.progression.add_xp(table.xp_to_reach[salt.unlock_level - 1])
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.buy_spice(&"salt"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - salt.price)
	assert_eq(sim.spice_shelf.count(&"salt"), 1)
	gold = sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.buy_and_use_spice(stove, &"salt"), ServiceResult.NOT_COOKING, "não serve agora")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold, "e não cobra")
	sim.start_cooking(stove, &"coffee")
	sim.spice_shelf.take(&"salt")
	gold = sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.buy_and_use_spice(stove, &"salt"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - salt.price)
	assert_true(sim.kitchen.is_seasoned(stove))
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "teste")
	assert_eq(sim.buy_spice(&"salt"), ServiceResult.NOT_ENOUGH_GOLD)


func test_the_daily_gift_and_missions_give_spices() -> void:
	_setup()
	var calendar: DailyRewardCalendar = load("res://data/config/daily_rewards.tres")
	assert_true(calendar.is_valid())
	var gifted := 0
	for day in calendar.days:
		if StringName(day.get("spice", &"")) != &"":
			assert_true(sim.spices.get_definition(StringName(day["spice"])) != null, "tempero do presente existe")
			gifted += 1
	assert_true(gifted >= 2, "o presente diário dá temperos")
	var spice_day := -1
	for i in calendar.days.size():
		if StringName(calendar.days[i].get("spice", &"")) != &"" and spice_day < 0:
			spice_day = i
	for i in spice_day:
		sim.claim_daily()
		clock.advance(86400.0)
	var delivered := sim.claim_daily()
	var spice_id := StringName(calendar.days[spice_day]["spice"])
	assert_eq(delivered.get("spice"), spice_id)
	assert_eq(sim.spice_shelf.count(spice_id), 1, "chegou na prateleira")
	var weekly := 0
	for mission in CafeSimulation.load_missions("res://data/missions/weekly"):
		if mission.reward_spice != &"":
			assert_true(sim.spices.get_definition(mission.reward_spice) != null, "%s dá um tempero que existe" % mission.id)
			weekly += 1
	assert_true(weekly >= 3, "missões semanais dão temperos")
	var mission := MissionDefinition.new()
	mission.id = &"teste"
	mission.title = "Teste"
	mission.target = 1
	mission.reward_spice = &"instant"
	mission.reward_spice_amount = 2
	sim._on_mission_completed(mission)
	assert_eq(sim.spice_shelf.count(&"instant"), 2, "a missão entrega o tempero")


func test_the_save_keeps_the_shelf_and_the_seasoning() -> void:
	_setup()
	sim.spice_shelf.add(&"herbs", 3)
	sim.spice_shelf.add(&"salt")
	sim.start_cooking(stove, &"coffee")
	sim.use_spice(stove, &"salt")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_eq(loaded.spice_shelf.count(&"herbs"), 3)
	assert_eq(loaded.spice_shelf.count(&"salt"), 0)
	assert_true(loaded.kitchen.is_seasoned(stove), "o tempero no fogão continua lá")
	assert_eq(loaded.kitchen.stove_servings(stove), sim.kitchen.stove_servings(stove))
	var old := SaveCodec.encode(sim)
	old["save_version"] = 11
	old.erase("spices")
	var migrated_data := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated_data["spices"], {}, "a migração acrescenta a prateleira vazia")
	var migrated := SaveCodec.decode(migrated_data, clock, 11).simulation
	assert_eq(migrated.spice_shelf.total(), 0, "save antigo começa sem temperos")


## Põe mais um fogão no primeiro lugar livre.
func _second_stove() -> StringName:
	var definition := sim.furniture.get_definition(&"stove_basic")
	for y in sim.layout.grid.size.y:
		for x in sim.layout.grid.size.x:
			if sim.layout.check_placement(definition, Vector2i(x, y), 0) == CafeLayout.Check.OK:
				return sim.layout.place(definition, Vector2i(x, y))
	return &""
