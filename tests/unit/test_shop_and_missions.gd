extends TestCase
## Loja, inventário, expansão e missões, direto na simulação.

var clock: ManualClock
var sim: CafeSimulation


## Jogo com os dados reais (missões e expansões), mas cafeteria vazia e sem clientes.
func _setup(gold := 1000) -> void:
	clock = ManualClock.new()
	var furniture := FurnitureCatalog.load_from()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), furniture, 9)
	sim.customer_types.clear()
	# Conquistas pagam ouro e mudariam as contas destes testes (elas têm testes próprios).
	var no_achievements: Array[AchievementDefinition] = []
	sim.set_achievements(no_achievements)
	sim.wallet.earn(Wallet.SOFT, gold, "teste")


func _def(id: StringName) -> FurnitureDefinition:
	return sim.furniture.get_definition(id)


# --- Loja --------------------------------------------------------------------

func test_buying_charges_the_price_and_places() -> void:
	_setup(200)
	var bought := []
	sim.furniture_bought.connect(func(d: FurnitureDefinition) -> void: bought.append(d.id))
	assert_eq(sim.acquire_and_place(_def(&"table_round"), Vector2i(2, 2), 0), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 200 - _def(&"table_round").price)
	assert_true(sim.layout.get_placement(sim.last_placed_id) != null)
	assert_eq(bought, [&"table_round"])


func test_locked_or_unaffordable_furniture_is_refused_without_charging() -> void:
	_setup(50)
	assert_eq(sim.acquire_and_place(_def(&"table_long"), Vector2i(2, 2), 0), ServiceResult.FURNITURE_LOCKED, "Mesa longa é nível 3")
	assert_eq(sim.acquire_and_place(_def(&"stove_basic"), Vector2i(2, 2), 0), ServiceResult.NOT_ENOUGH_GOLD, "fogão custa 150")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 50)
	assert_eq(sim.layout.count(), 0)


func test_invalid_spot_never_charges() -> void:
	_setup(200)
	assert_eq(sim.acquire_and_place(_def(&"plant_pot"), sim.layout.entrance, 0), ServiceResult.INVALID_PLACEMENT)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 200)


# --- Inventário ----------------------------------------------------------------

func test_storing_keeps_the_item_and_placing_it_again_is_free() -> void:
	_setup(200)
	sim.acquire_and_place(_def(&"table_round"), Vector2i(2, 2), 0)
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.store_furniture(sim.last_placed_id), CafeLayout.Check.OK)
	assert_eq(sim.layout.count(), 0)
	assert_eq(sim.inventory.count(&"table_round"), 1, "foi para o inventário, não para o lixo")
	var bought := []
	sim.furniture_bought.connect(func(d: FurnitureDefinition) -> void: bought.append(d.id))
	assert_eq(sim.acquire_and_place(_def(&"table_round"), Vector2i(4, 4), 0), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold, "recolocar é grátis")
	assert_eq(sim.inventory.count(&"table_round"), 0)
	assert_eq(bought.size(), 0, "recolocar não conta como compra")


func test_inventory_skips_level_and_gold_requirements() -> void:
	_setup(0)
	sim.inventory.add(&"table_long")
	assert_eq(sim.can_acquire(_def(&"table_long")), ServiceResult.OK, "já é do jogador")


func test_furniture_in_use_cannot_be_stored() -> void:
	_setup()
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(0, 0), 0)
	var stove := sim.last_placed_id
	sim.start_cooking(stove, &"coffee")
	assert_eq(sim.store_furniture(stove), CafeLayout.Check.IN_USE)
	assert_eq(sim.inventory.total(), 0)


# --- Expansão --------------------------------------------------------------------

func test_expansion_plan_data_is_valid_and_grows() -> void:
	var plan: ExpansionPlan = load("res://data/config/expansions.tres")
	assert_true(plan.is_valid())
	assert_eq(plan.next_after(Vector2i(8, 8))["size"], Vector2i(10, 8))
	assert_eq(plan.next_after(Vector2i(12, 12)), {}, "tamanho máximo")


func test_expansion_needs_level_and_gold() -> void:
	_setup(100)
	assert_eq(sim.can_expand(), ServiceResult.EXPANSION_LOCKED)
	sim.progression.add_xp(30)
	assert_eq(sim.can_expand(), ServiceResult.NOT_ENOUGH_GOLD)
	sim.wallet.earn(Wallet.SOFT, 50, "teste")
	assert_eq(sim.can_expand(), ServiceResult.OK)


func test_expanding_grows_the_grid_moves_the_entrance_and_charges() -> void:
	_setup(1000)
	sim.progression.add_xp(30)
	sim.acquire_and_place(_def(&"table_round"), Vector2i(6, 4), 0)
	var expanded := []
	sim.cafe_expanded.connect(func(size: Vector2i) -> void: expanded.append(size))
	assert_eq(sim.expand(), ServiceResult.OK)
	assert_eq(sim.layout.grid.size, Vector2i(10, 8))
	assert_eq(sim.layout.entrance, Vector2i(9, 4), "entrada acompanha a borda da frente")
	assert_true(sim.layout.grid.is_free(sim.layout.entrance))
	assert_eq(sim.waiters[0].home, sim.layout.entrance, "o garçom usa a nova entrada")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 1000 - _def(&"table_round").price - 150)
	assert_eq(expanded, [Vector2i(10, 8)])
	var goals := sim.navigation.access_cells(sim.last_placed_id)
	assert_false(sim.navigation.path_to_any(sim.layout.entrance, goals).is_empty(), "a mesa continua acessível")


func test_expanding_all_the_way_then_stop() -> void:
	_setup(100000)
	sim.progression.add_xp(5000)
	for i in 4:
		assert_eq(sim.expand(), ServiceResult.OK, "etapa %d" % (i + 1))
	assert_eq(sim.layout.grid.size, Vector2i(12, 12))
	assert_eq(sim.expand(), ServiceResult.NO_MORE_EXPANSIONS)


func test_layout_never_shrinks() -> void:
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	assert_false(layout.expand_to(Vector2i(6, 8)))
	assert_false(layout.expand_to(Vector2i(8, 8)))
	assert_true(layout.expand_to(Vector2i(8, 10)))
	assert_eq(layout.entrance, Vector2i(7, 4), "largura igual: entrada não muda")


# --- Missões -----------------------------------------------------------------------

func test_starter_missions_follow_section_143() -> void:
	_setup()
	var titles := sim.missions.missions.map(func(m: MissionDefinition) -> String: return m.title)
	assert_eq(titles, ["Prepare 3 pratos", "Sirva 3 clientes", "Ganhe 100 Café Ouro em vendas",
		"Compre uma mesa", "Chegue ao nível 2", "Expanda a cafeteria"])
	for mission in sim.missions.missions:
		assert_true(mission.is_valid(), "%s inválida" % mission.id)
		assert_false(mission.hint.is_empty(), "%s sem dica (as missões são o tutorial)" % mission.id)


func test_mission_completes_pays_reward_and_advances() -> void:
	_setup(0)
	sim.inventory.add(&"counter_basic")
	sim.inventory.add(&"stove_basic")
	sim.acquire_and_place(_def(&"counter_basic"), Vector2i(2, 0), 0)
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(0, 0), 0)
	var stove := sim.last_placed_id
	sim.wallet.earn(Wallet.SOFT, 100, "teste")
	var done := []
	sim.mission_completed.connect(func(m: MissionDefinition) -> void: done.append(m.id))
	for i in 3:
		assert_eq(sim.start_cooking(stove, &"coffee"), ServiceResult.OK)
		clock.advance(15.0)
		assert_eq(sim.collect(stove), ServiceResult.OK)
	assert_eq(done, [&"m01_prepare_dishes"])
	var first: MissionDefinition = sim.missions.missions[0]
	var cost := sim.recipes.get_definition(&"coffee").ingredient_cost * 3
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100 - cost + first.reward_gold, "recompensa em ouro")
	assert_eq(sim.missions.current().id, &"m02_serve_customers")
	assert_eq(sim.missions.progress(), 0, "a próxima começa do zero")


func test_wrong_events_do_not_count() -> void:
	_setup()
	sim.missions.record(MissionDefinition.Kind.SERVE_CUSTOMERS, 5)
	assert_eq(sim.missions.progress(), 0, "a missão ativa é preparar pratos")


func test_buy_mission_only_counts_its_category() -> void:
	_setup()
	sim.missions.restore({"index": 3, "progress": 0})  # "Compre uma mesa"
	sim.acquire_and_place(_def(&"plant_pot"), Vector2i(0, 7), 0)
	assert_eq(sim.missions.current().id, &"m04_buy_table", "planta não é mesa")
	sim.acquire_and_place(_def(&"table_round"), Vector2i(2, 2), 0)
	assert_eq(sim.missions.current().id, &"m05_reach_level_2")


func test_level_mission_already_satisfied_completes_on_arrival() -> void:
	_setup()
	sim.progression.add_xp(100)  # já no nível 3
	var done := []
	sim.mission_completed.connect(func(m: MissionDefinition) -> void: done.append(m.id))
	sim.missions.restore({"index": 3, "progress": 0})
	sim.acquire_and_place(_def(&"table_round"), Vector2i(2, 2), 0)
	assert_eq(done, [&"m04_buy_table", &"m05_reach_level_2"], "nível 2 já estava feito: conclui na hora")
	assert_eq(sim.missions.current().id, &"m06_expand")


func test_all_missions_done() -> void:
	_setup()
	sim.missions.restore({"index": 6, "progress": 0})
	assert_true(sim.missions.all_done())
	assert_eq(sim.missions.current(), null)
	sim.missions.record(MissionDefinition.Kind.COLLECT_DISHES)  # não quebra


# --- Venda -----------------------------------------------------------------------

func test_selling_returns_half_the_price_and_removes() -> void:
	_setup(200)
	var sold := []
	sim.furniture_sold.connect(func(d: FurnitureDefinition, amount: int) -> void: sold.append([d.id, amount]))
	sim.acquire_and_place(_def(&"table_round"), Vector2i(2, 2), 0)
	var id := sim.last_placed_id
	assert_eq(sim.sell_price(_def(&"table_round")), 30)
	assert_eq(sim.sell_furniture(id), ServiceResult.OK)
	assert_eq(sim.layout.get_placement(id), null)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 200 - 60 + 30)
	assert_eq(sim.inventory.total(), 0, "vendido não vai para o inventário")
	assert_eq(sold, [[&"table_round", 30]])


func test_cannot_sell_the_last_stove_or_counter() -> void:
	_setup()
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(0, 0), 0)
	var first := sim.last_placed_id
	assert_eq(sim.sell_furniture(first), ServiceResult.LAST_ESSENTIAL, "sem fogão não há como ganhar ouro")
	sim.inventory.add(&"stove_basic")
	assert_eq(sim.can_sell(first), ServiceResult.OK, "um guardado conta")
	sim.inventory.take(&"stove_basic")
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(2, 0), 0)
	assert_eq(sim.sell_furniture(first), ServiceResult.OK, "com outro fogão, pode")


func test_furniture_in_use_cannot_be_sold() -> void:
	_setup()
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(0, 0), 0)
	var stove := sim.last_placed_id
	sim.acquire_and_place(_def(&"stove_basic"), Vector2i(2, 0), 0)
	sim.start_cooking(stove, &"coffee")
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.sell_furniture(stove), ServiceResult.IN_USE)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold)


func test_economy_data_is_valid() -> void:
	var economy: EconomyConfig = load(CafeSimulation.ECONOMY_PATH)
	assert_true(economy.is_valid())
	assert_true(economy.sell_fraction < 1.0, "vender nunca dá lucro sobre a compra")
