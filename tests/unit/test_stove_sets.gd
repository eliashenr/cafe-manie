extends TestCase
## Multifogão em partes (DT-060): as 3 peças do trem, lado a lado e na ordem, formam o conjunto; completo, cada peça
## rende o dobro de porções; a primeira vez dá o Relógio da Estação, que não se compra com ouro.

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), load("res://data/config/service.tres"),
		FurnitureCatalog.load_from(), RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.progression.add_xp(99999)  # nível 30
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(8, 8))
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(8, 6))


func _buy(id: StringName, cell: Vector2i) -> StringName:
	assert_eq(sim.acquire_and_place(sim.furniture.get_definition(id), cell, 0), ServiceResult.OK, "%s em %s" % [id, cell])
	return sim.last_placed_id


func test_the_train_set_is_valid() -> void:
	_setup()
	var train := sim.stove_sets.set_of_part(&"train_wagon")
	assert_true(train != null and train.is_valid())
	assert_eq(train.parts.size(), 3)
	for part in train.parts:
		assert_eq(sim.furniture.get_definition(part).category, FurnitureDefinition.Category.COOKING, "%s é um fogão" % part)
	var reward := sim.furniture.get_definition(train.reward)
	assert_true(reward != null and not reward.sold_for_gold, "o prêmio não se compra com ouro")
	assert_eq(sim.can_acquire(reward), ServiceResult.NOT_FOR_SALE)


func test_three_parts_in_a_row_and_in_order_complete_the_set() -> void:
	_setup()
	var locomotive := _buy(&"train_locomotive", Vector2i(1, 1))
	var dining := _buy(&"train_dining", Vector2i(3, 1))
	assert_true(sim.stove_sets.complete_set_of(locomotive) == null, "falta o vagão do meio")
	var wagon := _buy(&"train_wagon", Vector2i(2, 1))
	for id in [locomotive, wagon, dining]:
		assert_true(sim.stove_sets.complete_set_of(id) != null, "%s faz parte do trem completo" % id)
	sim.layout.move(dining, Vector2i(3, 3), 0)
	assert_true(sim.stove_sets.complete_set_of(wagon) == null, "separado, deixa de valer")
	sim.layout.move(dining, Vector2i(2, 2), 0)
	assert_true(sim.stove_sets.complete_set_of(wagon) == null, "em L não vale: tem de ser em linha reta")
	sim.layout.move(locomotive, Vector2i(2, 3), 0)
	assert_true(sim.stove_sets.complete_set_of(wagon) == null, "fora de ordem não vale")


func test_a_complete_set_doubles_the_servings() -> void:
	_setup()
	var locomotive := _buy(&"train_locomotive", Vector2i(1, 1))
	_buy(&"train_wagon", Vector2i(1, 2))
	var coffee := sim.recipes.get_definition(&"coffee")
	assert_eq(sim.bonus_servings_on(locomotive, coffee), 0, "incompleto, sem bônus")
	_buy(&"train_dining", Vector2i(1, 3))  # em coluna também vale
	sim.start_cooking(locomotive, &"coffee")
	assert_eq(sim.kitchen.stove_servings(locomotive), coffee.servings * 2, "o dobro de porções")


func test_completing_the_set_gives_the_reward_once() -> void:
	_setup()
	var completed: Array = []
	sim.stove_set_completed.connect(func(stove_set: StoveSetDefinition) -> void: completed.append(stove_set.id))
	var locomotive := _buy(&"train_locomotive", Vector2i(1, 1))
	_buy(&"train_wagon", Vector2i(2, 1))
	_buy(&"train_dining", Vector2i(3, 1))
	assert_eq(completed, [&"train"])
	assert_eq(sim.inventory.count(&"station_clock"), 1, "o relógio vai para o inventário")
	sim.store_furniture(locomotive)
	_buy(&"train_locomotive", Vector2i(1, 1))
	assert_eq(completed.size(), 1, "o prêmio é uma vez só")
	assert_eq(sim.inventory.count(&"station_clock"), 1)
	assert_eq(sim.acquire_and_place(sim.furniture.get_definition(&"station_clock"), Vector2i(5, 5), 0), ServiceResult.OK,
		"o guardado entra na cafeteria")


func test_the_save_remembers_the_reward() -> void:
	_setup()
	_buy(&"train_locomotive", Vector2i(1, 1))
	_buy(&"train_wagon", Vector2i(2, 1))
	_buy(&"train_dining", Vector2i(3, 1))
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 7).simulation
	assert_true(loaded.stove_sets.was_rewarded(&"train"))
	var old := SaveCodec.encode(sim)
	old["save_version"] = 13
	old.erase("stove_sets")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["stove_sets"], {}, "a migração acrescenta os prêmios vazios")
