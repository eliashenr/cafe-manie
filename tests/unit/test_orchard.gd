extends TestCase
## Plantação e frozen yogurt (DT-065): os pés de fruta amadurecem pelo relógio e dão frutas ao serem colhidos; a
## máquina de frozen usa as frutas (e não energia), e o frozen só entra no cardápio com fruta no estoque. O save guarda
## os pés crescendo e as frutas.

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.progression.add_xp(1480)  # nível 8
	sim.wallet.earn(Wallet.SOFT, 10000, "teste")


func _tree(id := &"tree_strawberry", cell := Vector2i(5, 5)) -> StringName:
	assert_eq(sim.acquire_and_place(sim.furniture.get_definition(id), cell, 0), ServiceResult.OK)
	return sim.last_placed_id


func test_the_orchard_data_is_valid() -> void:
	var catalog := FurnitureCatalog.load_from()
	for id in [&"tree_strawberry", &"tree_mango", &"tree_blueberry"]:
		var tree := catalog.get_definition(id)
		assert_true(tree.is_valid() and tree.fruit != &"", String(id))
	var broken: FurnitureDefinition = catalog.get_definition(&"tree_mango").duplicate()
	broken.fruit_yield = 0
	assert_false(broken.is_valid(), "pé sem frutas")
	var frozen: DrinkDefinition = load("res://data/drinks/frozen_mango.tres")
	assert_true(frozen.is_valid() and frozen.energy_cost == 0 and frozen.fruit == &"mango", "frozen gasta fruta, não energia")
	var no_fruit: DrinkDefinition = frozen.duplicate()
	no_fruit.fruit = &""
	assert_false(no_fruit.is_valid(), "bebida sem energia e sem fruta")


func test_a_tree_ripens_and_gives_fruit() -> void:
	_setup()
	var tree := _tree()
	var definition := sim.furniture.get_definition(&"tree_strawberry")
	assert_false(sim.orchard.is_ripe(tree), "acabou de plantar")
	assert_eq(sim.harvest(tree), ServiceResult.NOT_RIPE)
	clock.advance(definition.fruit_grow_time - 1.0)
	assert_almost_eq(sim.orchard.seconds_left(tree), 1.0, 0.01)
	clock.advance(1.0)
	assert_true(sim.orchard.is_ripe(tree))
	var harvested: Array = []
	sim.fruit_harvested.connect(func(_id: StringName, fruit: FruitDefinition, amount: int) -> void: harvested.append([fruit.id, amount]))
	assert_eq(sim.harvest(tree), ServiceResult.OK)
	assert_eq(harvested, [[&"strawberry", definition.fruit_yield]])
	assert_eq(sim.fruit_stock.count(&"strawberry"), definition.fruit_yield)
	assert_false(sim.orchard.is_ripe(tree), "colhido, começa de novo")
	assert_eq(sim.harvest(sim.layout.placements()[0].id), ServiceResult.NOT_A_TREE)


func test_frozen_needs_the_machine_and_fruit_not_energy() -> void:
	_setup()
	sim.acquire_and_place(sim.furniture.get_definition(&"machine_frozen"), Vector2i(6, 6), 0)
	var frozen_ids := func() -> Array:
		return sim.drink_menu().filter(func(d: DrinkDefinition) -> bool: return d.fruit != &"").map(func(d: DrinkDefinition) -> StringName: return d.id)
	assert_true(frozen_ids.call().is_empty(), "sem fruta, ninguém pede frozen")
	sim.fruit_stock.add(&"strawberry", 2)
	assert_eq(frozen_ids.call(), [&"frozen_strawberry"], "com morango, o frozen de morango entra no cardápio")
	var customer := Customer.new()
	customer.type = load("res://data/customers/regular.tres")
	customer.state = Customer.State.WAITING_FOR_DRINK
	customer.drink = sim.drinks.get_definition(&"frozen_strawberry")
	customer.patience_total = 100.0
	customer.patience_left = 100.0
	var energy := sim.energy.amount(clock.now())
	assert_eq(sim.serve_drink(customer), ServiceResult.OK)
	assert_eq(sim.fruit_stock.count(&"strawberry"), 1, "gastou uma fruta")
	assert_eq(sim.energy.amount(clock.now()), energy, "e nenhuma energia")
	var second := Customer.new()
	second.type = customer.type
	second.state = Customer.State.WAITING_FOR_DRINK
	second.drink = sim.drinks.get_definition(&"frozen_mango")
	assert_eq(sim.serve_drink(second), ServiceResult.NO_FRUIT, "sem manga, não sai")


func test_the_save_keeps_the_orchard_and_the_fruits() -> void:
	_setup()
	var tree := _tree()
	clock.advance(100.0)
	sim.fruit_stock.add(&"mango", 4)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_almost_eq(loaded.orchard.seconds_left(tree), sim.orchard.seconds_left(tree), 0.01, "o pé continua crescendo de onde parou")
	assert_eq(loaded.fruit_stock.count(&"mango"), 4)
	var old := SaveCodec.encode(sim)
	old["save_version"] = 16
	old.erase("orchard")
	old.erase("fruits")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["fruits"], {}, "a migração acrescenta as frutas")
