extends TestCase
## Missões diárias e semanais (DT-047): os dados, as metas que crescem com o nível, o quadro que
## recomeça a cada período, os eventos do jogo que contam para cada uma, a recompensa e o save.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName
var counter: StringName


## Jogo novo com os dados reais; o relógio manual começa numa segunda-feira (dia 11 do calendário).
func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	for placement in sim.layout.placements():
		if placement.origin == Vector2i(0, 0):
			stove = placement.id
		if placement.origin == Vector2i(3, 0):
			counter = placement.id
	sim.refresh_mission_periods()


func _entry(board: MissionBoard, id: StringName) -> MissionBoard.Entry:
	for entry in board.entries():
		if entry.mission.id == id:
			return entry
	return null


func _mission(kind: MissionDefinition.Kind, goal := 3, per_level := 0.0) -> MissionDefinition:
	var mission := MissionDefinition.new()
	mission.id = StringName("t_%d_%d" % [kind, goal])
	mission.title = "Faça %d coisas"
	mission.kind = kind
	mission.target = goal
	mission.target_per_level = per_level
	mission.reward_gold = 40
	mission.reward_xp = 10
	return mission


func _board(list: Array[MissionDefinition], level := 1) -> MissionBoard:
	var board := MissionBoard.new(list)
	board.start_period(1, level, 6)
	return board


func _cook(recipe_id: StringName) -> void:
	sim.wallet.earn(Wallet.SOFT, 500, "teste")
	assert_eq(sim.start_cooking(stove, recipe_id), ServiceResult.OK)
	clock.advance(sim.recipes.get_definition(recipe_id).cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)
	sim.kitchen.restore_counter(counter, null, 0)  # esvazia o balcão para o próximo prato


# --- Dados -------------------------------------------------------------------

func test_ten_daily_and_twenty_weekly_missions_from_the_game_content() -> void:
	var daily := CafeSimulation.load_missions(CafeSimulation.DAILY_MISSIONS_DIR)
	var weekly := CafeSimulation.load_missions(CafeSimulation.WEEKLY_MISSIONS_DIR)
	assert_eq(daily.size(), 10, "o PO pediu 10 diárias")
	assert_eq(weekly.size(), 20, "e 20 semanais")
	var ids := {}
	for mission in daily + weekly:
		assert_true(mission.is_valid(), "%s inválida" % mission.id)
		assert_false(ids.has(mission.id), "id repetido: %s" % mission.id)
		ids[mission.id] = true
		assert_true(mission.reward_gold_at(1) > 0, "%s dá ouro" % mission.id)
		assert_true(mission.title.contains("%d") or mission.target == 1, "%s mostra a meta" % mission.id)
		assert_true(mission.min_level <= 30)
		assert_false(mission.hint.is_empty(), "%s tem dica" % mission.id)
	assert_eq(CafeSimulation.default_missions().size(), 6, "as do começo continuam 6 (as pastas não entram)")


func test_targets_and_rewards_grow_with_the_level_in_round_numbers() -> void:
	var sales := _mission(MissionDefinition.Kind.EARN_GOLD, 250, 40)
	assert_eq(sales.target_at(1), 250)
	assert_eq(sales.target_at(10), 610)
	assert_eq(sales.target_at(30), 1400, "acima de mil, de 50 em 50")
	var serve := _mission(MissionDefinition.Kind.SERVE_CUSTOMERS, 12, 0.6)
	assert_eq(serve.target_at(5), 14, "até 20, de 1 em 1")
	assert_eq(serve.target_at(20), 25, "até 100, de 5 em 5")
	var variety := _mission(MissionDefinition.Kind.COOK_DIFFERENT, 3)
	variety.limit_to_unlocked_recipes = true
	assert_eq(variety.target_at(1, 2), 2, "não pede mais receitas do que as liberadas")
	assert_eq(variety.target_at(9, 6), 3)
	sales.reward_gold_per_level = 3.0
	assert_eq(sales.reward_gold_at(11), 70)
	assert_eq(sales.title_for(610), "Faça 610 coisas")


# --- Quadro ------------------------------------------------------------------

func test_board_freezes_targets_for_the_period_and_restarts_on_the_next() -> void:
	var list: Array[MissionDefinition] = [_mission(MissionDefinition.Kind.SERVE_CUSTOMERS, 10, 1.0)]
	var board := MissionBoard.new(list)
	assert_true(board.start_period(5, 1, 6))
	assert_eq(board.entries()[0].target, 10)
	board.record(MissionDefinition.Kind.SERVE_CUSTOMERS, 4)
	assert_false(board.start_period(5, 9, 6), "mesmo dia: nada muda, nem com nível novo")
	assert_eq(board.entries()[0].progress, 4)
	assert_eq(board.entries()[0].target, 10)
	assert_true(board.start_period(6, 9, 6), "dia seguinte: tudo do zero, com a meta do nível")
	assert_eq(board.entries()[0].progress, 0)
	assert_eq(board.entries()[0].target, 18)


func test_completing_a_mission_signals_once_and_stops_counting() -> void:
	var list: Array[MissionDefinition] = [_mission(MissionDefinition.Kind.COLLECT_DISHES, 3)]
	var board := _board(list)
	var done := []
	board.mission_completed.connect(func(entry: MissionBoard.Entry) -> void: done.append(entry))
	board.record(MissionDefinition.Kind.SERVE_CUSTOMERS, 5)
	assert_eq(board.entries()[0].progress, 0, "outro tipo de evento não conta")
	board.record(MissionDefinition.Kind.COLLECT_DISHES, 2)
	assert_eq(done.size(), 0)
	board.record(MissionDefinition.Kind.COLLECT_DISHES, 5)
	assert_eq(done.size(), 1)
	assert_eq(board.entries()[0].progress, 3, "o progresso para na meta")
	board.record(MissionDefinition.Kind.COLLECT_DISHES)
	assert_eq(done.size(), 1, "concluída não conclui de novo")
	assert_eq(board.completed_count(), 1)


func test_locked_missions_do_not_count_until_a_new_period() -> void:
	var slow := _mission(MissionDefinition.Kind.COOK_SLOW, 2)
	slow.min_level = 3
	slow.min_cook_time = 180.0
	var list: Array[MissionDefinition] = [slow]
	var board := _board(list, 1)
	var cake: RecipeDefinition = load("res://data/recipes/carrot_cake.tres")
	assert_true(board.entries()[0].locked)
	board.record(MissionDefinition.Kind.COOK_SLOW, 1, cake)
	assert_eq(board.entries()[0].progress, 0, "com o cadeado não conta")
	board.start_period(2, 3, 6)
	assert_false(board.entries()[0].locked, "no período seguinte, já no nível 3, vale")
	board.record(MissionDefinition.Kind.COOK_SLOW, 1, load("res://data/recipes/coffee.tres"))
	assert_eq(board.entries()[0].progress, 0, "café é rápido demais")
	board.record(MissionDefinition.Kind.COOK_SLOW, 1, cake)
	assert_eq(board.entries()[0].progress, 1)


func test_different_dishes_furniture_category_and_popularity() -> void:
	var variety := _mission(MissionDefinition.Kind.COOK_DIFFERENT, 2)
	var tables := _mission(MissionDefinition.Kind.BUY_FURNITURE, 1)
	tables.furniture_category = FurnitureDefinition.Category.TABLE
	var popular := _mission(MissionDefinition.Kind.REACH_POPULARITY, 80)
	var list: Array[MissionDefinition] = [variety, tables, popular]
	var board := _board(list)
	var coffee: RecipeDefinition = load("res://data/recipes/coffee.tres")
	board.record(MissionDefinition.Kind.COOK_DIFFERENT, 1, coffee)
	board.record(MissionDefinition.Kind.COOK_DIFFERENT, 1, coffee)
	assert_eq(_entry(board, variety.id).progress, 1, "o mesmo prato conta uma vez")
	board.record(MissionDefinition.Kind.COOK_DIFFERENT, 1, load("res://data/recipes/cheese_bread.tres"))
	assert_true(_entry(board, variety.id).done())
	board.record(MissionDefinition.Kind.BUY_FURNITURE, 1, null, FurnitureDefinition.Category.SEATING)
	assert_eq(_entry(board, tables.id).progress, 0, "cadeira não é mesa")
	board.record(MissionDefinition.Kind.BUY_FURNITURE, 1, null, FurnitureDefinition.Category.TABLE)
	assert_true(_entry(board, tables.id).done())
	board.record(MissionDefinition.Kind.REACH_POPULARITY, 70)
	board.record(MissionDefinition.Kind.REACH_POPULARITY, 60)
	assert_eq(_entry(board, popular.id).progress, 70, "popularidade guarda o maior valor, não soma")


func test_board_save_round_trip() -> void:
	var variety := _mission(MissionDefinition.Kind.COOK_DIFFERENT, 3)
	var serve := _mission(MissionDefinition.Kind.SERVE_CUSTOMERS, 10, 2.0)
	var list: Array[MissionDefinition] = [variety, serve]
	var board := MissionBoard.new(list)
	board.start_period(7, 4, 6)
	board.record(MissionDefinition.Kind.COOK_DIFFERENT, 1, load("res://data/recipes/coffee.tres"))
	board.record(MissionDefinition.Kind.SERVE_CUSTOMERS, 6)
	var data: Dictionary = JSON.parse_string(JSON.stringify(board.to_data()))
	var loaded := MissionBoard.new(list)
	loaded.restore(data, 20, 6)
	assert_eq(loaded.period, 7)
	assert_eq(_entry(loaded, serve.id).progress, 6)
	assert_eq(_entry(loaded, serve.id).target, 16, "a meta congelada volta (não a do nível novo)")
	loaded.record(MissionDefinition.Kind.COOK_DIFFERENT, 1, load("res://data/recipes/coffee.tres"))
	assert_eq(_entry(loaded, variety.id).progress, 1, "o café já tinha contado neste período")


# --- No jogo -----------------------------------------------------------------

func test_new_game_starts_today_and_this_week() -> void:
	_setup()
	assert_eq(sim.daily_missions.size(), 10)
	assert_eq(sim.weekly_missions.size(), 20)
	assert_eq(sim.daily_missions.period, clock.local_day())
	assert_eq(sim.weekly_missions.period, sim.mission_week())
	assert_true(_entry(sim.weekly_missions, &"w20_slow").locked, "pratos demorados só a partir do nível 3")


func test_cooking_counts_dishes_variety_ingredients_and_xp() -> void:
	_setup()
	_cook(&"coffee")
	_cook(&"coffee")
	_cook(&"cheese_bread")
	assert_eq(_entry(sim.daily_missions, &"d01_cook").progress, 3)
	assert_eq(_entry(sim.daily_missions, &"d05_variety").progress, 2, "café e pão de queijo")
	assert_true(_entry(sim.daily_missions, &"d05_variety").done(), "no nível 1 só há 2 receitas: a meta é 2")
	assert_eq(_entry(sim.daily_missions, &"d09_ingredients").progress, 6 + 6 + 15)
	var xp_from_food := 2 + 2 + 4
	assert_true(_entry(sim.daily_missions, &"d06_xp").progress >= xp_from_food)


func test_serving_counts_customers_sales_happiness_and_menu_orders() -> void:
	_setup()
	var customer := Customer.new()
	customer.type = load("res://data/customers/regular.tres")
	customer.order = load("res://data/recipes/coffee.tres")
	customer.patience_when_served = 0.9
	customer.ordered_from_menu = true
	sim._pay(customer)
	var sad := Customer.new()
	sad.type = customer.type
	sad.order = customer.order
	sad.patience_when_served = 0.2
	sim._pay(sad)
	assert_eq(_entry(sim.daily_missions, &"d02_serve").progress, 2)
	assert_eq(_entry(sim.daily_missions, &"d03_sales").progress, customer.paid + sad.paid)
	assert_eq(_entry(sim.daily_missions, &"d04_happy").progress, 1, "servido já impaciente não conta como satisfeito")
	assert_eq(_entry(sim.daily_missions, &"d08_menu").progress, 1, "só o que o jogador teve que cozinhar")


func test_an_order_is_from_the_menu_only_when_the_dish_was_not_on_the_counter() -> void:
	_setup()
	sim.config = sim.config.duplicate()  # o recurso carregado é compartilhado entre os testes
	sim.config.menu_order_chance = 0.0
	var hungry := Customer.new()
	hungry.type = load("res://data/customers/regular.tres")
	sim._place_order(hungry)
	assert_true(hungry.ordered_from_menu, "balcão vazio: o jogador vai ter que cozinhar")
	sim.kitchen.restore_counter(counter, load("res://data/recipes/coffee.tres"), 6)
	var lucky := Customer.new()
	lucky.type = hungry.type
	sim._place_order(lucky)
	assert_eq(lucky.order.id, &"coffee")
	assert_false(lucky.ordered_from_menu, "já estava no balcão")


func test_gift_renovation_and_wall_items_count() -> void:
	_setup()
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.claim_daily()
	assert_true(_entry(sim.daily_missions, &"d07_gift").done())
	assert_eq(_entry(sim.weekly_missions, &"w07_gifts").progress, 1)
	var floor := sim.surfaces.get_definition(&"floor_wood")
	var cells: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5), Vector2i(5, 6)]
	sim.progression.add_xp(5000)
	assert_eq(sim.paint_floor(floor, cells), ServiceResult.OK)
	assert_eq(_entry(sim.weekly_missions, &"w14_floor").progress, 3)
	var tv := sim.wall_items.get_definition(&"tv")
	var spots: Array[String] = ["top:2"]
	assert_eq(sim.hang_items(tv, spots), ServiceResult.OK)
	assert_true(_entry(sim.weekly_missions, &"w16_hang").done())


func test_completed_mission_pays_and_counts_for_the_weekly() -> void:
	_setup()
	var gold := sim.wallet.balance(Wallet.SOFT)
	var xp := sim.progression.xp
	var done := []
	sim.board_mission_completed.connect(func(board: MissionBoard, entry: MissionBoard.Entry) -> void: done.append(entry))
	sim.claim_daily()  # o presente do dia 1 também dá ouro e XP
	var gift_entry := _entry(sim.daily_missions, &"d07_gift")
	assert_eq(done, [gift_entry])
	var reward: Dictionary = sim.daily.calendar.days[0]
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + int(reward.get("gold", 0)) + gift_entry.reward_gold)
	assert_eq(sim.progression.xp, xp + int(reward.get("xp", 0)) + gift_entry.reward_xp)
	assert_eq(_entry(sim.weekly_missions, &"w17_dailies").progress, 1, "diária concluída conta para a semanal")


func test_new_day_restarts_the_dailies_and_monday_restarts_the_weeklies() -> void:
	_setup()
	sim.claim_daily()
	_cook(&"coffee")
	assert_eq(_entry(sim.daily_missions, &"d01_cook").progress, 1)
	assert_eq(_entry(sim.weekly_missions, &"w01_cook").progress, 1)
	clock.advance(86400.0)  # terça
	sim.tick(0.0)
	assert_eq(_entry(sim.daily_missions, &"d01_cook").progress, 0, "dia novo, diárias do zero")
	assert_eq(_entry(sim.weekly_missions, &"w01_cook").progress, 1, "a semana continua")
	assert_almost_eq(sim.seconds_until_new_week(), 6 * 86400.0 - fposmod(clock.time, 86400.0), 0.01)
	clock.advance(5 * 86400.0)  # domingo
	sim.tick(0.0)
	assert_eq(_entry(sim.weekly_missions, &"w01_cook").progress, 1, "domingo ainda é a mesma semana")
	clock.advance(86400.0)  # segunda seguinte
	sim.tick(0.0)
	assert_eq(_entry(sim.weekly_missions, &"w01_cook").progress, 0, "semana nova, semanais do zero")
