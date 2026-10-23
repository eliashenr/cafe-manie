extends SceneTree
## Relatório de balanceamento (FAÇA BALANCEAMENTO): um "jogador médio" robô joga um jogo novo de verdade, com os
## dados reais, e o relatório mede quanto tempo de jogo ativo leva para cada nível e quanto ouro entra por hora.
##
##   godot --headless -s res://tools/balance_report.gd -- <horas de jogo> [passo em segundos] [semente]
##
## O robô: cozinha o que os clientes pediram (senão a receita que mais lucra por minuto e fica pronta logo), deixa
## o garçom servir, expande o café, contrata garçons, compra fogões, balcões e mesas com cadeira conforme sobe de
## nível, e guarda uma reserva de ouro para os ingredientes. Junta ouro para a prioridade da vez, em vez de trocar
## por algo mais barato. Não compra enfeites nem itens de luxo: o relatório compara o preço deles com o ouro por
## hora de cada nível.

## Receita mais longa que o robô cozinha enquanto joga (receita longa é para quando o jogador sai).
const ROBOT_MAX_COOK_TIME := 180.0
## Fogões e mesas que um jogador médio põe por nível.
const STOVES_BASE := 3
const STOVES_PER_LEVELS := 3
const MAX_STOVES := 10
const TABLES_BASE := 3
const MAX_TABLES := 14

var sim: CafeSimulation
var clock: ManualClock
var elapsed := 0.0
var level_times := {}
var gold_earned := 0
var gold_spent := 0
var served := 0
var angry := 0
var _last_gold := 0
var _hourly: Array = []
var _xp_log: Array = []
var _angry_reasons := {}
var _events: Array[String] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var hours := float(args[0]) if args.size() > 0 else 2.0
	var step := float(args[1]) if args.size() > 1 else 0.25
	var random_seed := int(args[2]) if args.size() > 2 else 2026
	clock = ManualClock.new()
	clock.time = Time.get_unix_time_from_datetime_string("2026-03-03T09:00:00")  # sem evento, de dia
	sim = CafeSimulation.create_new_game(clock, random_seed)
	_last_gold = sim.wallet.balance(Wallet.SOFT)
	sim.wallet.balance_changed.connect(_on_gold)
	sim.leveled_up.connect(func(level: int) -> void: level_times[level] = elapsed)
	sim.customer_left.connect(func(c: Customer) -> void:
		if c.happy:
			served += 1
		elif not c.gave_up_in_line:
			angry += 1
			var reason := "critico" if c.critic else ("bebida" if c.drink != null else ("sem pedido" if c.order == null 				else "%s (%s)" % [c.order.id, "cardapio" if c.ordered_from_menu else "balcao"]))
			_angry_reasons[reason] = int(_angry_reasons.get(reason, 0)) + 1)
	sim.mission_completed.connect(func(m: MissionDefinition) -> void:
		_log("missão %s: %d ouro, %d XP" % [m.id, m.reward_gold, m.reward_xp]))
	sim.board_mission_completed.connect(func(_board: MissionBoard, _entry: MissionBoard.Entry) -> void:
		_log("missão de quadro concluída"))
	sim.achievement_unlocked.connect(func(a: AchievementDefinition, tier: int) -> void: _log("conquista %s %d" % [a.id, tier]))
	sim.recipe_mastered.connect(func(r: RecipeDefinition, stars: int, reward: Dictionary) -> void:
		_log("domínio %s %d %s" % [r.id, stars, reward]))
	sim.progression.xp_changed.connect(func(xp: int) -> void: _xp_log.append([elapsed, xp]))
	level_times[1] = 0.0
	var next_decision := 0.0
	var next_hour := 3600.0
	var hour_start := [0, 0]
	while elapsed < hours * 3600.0:
		if elapsed >= next_decision:
			_cook()
			_buy()
			next_decision += 1.0
		clock.advance(step)
		sim.tick(step)
		elapsed += step
		if elapsed >= next_hour:
			_hourly.append([roundi(next_hour / 3600.0), sim.progression.level, gold_earned - hour_start[0], served - hour_start[1],
				sim.wallet.balance(Wallet.SOFT), roundi(sim.popularity)])
			hour_start = [gold_earned, served]
			next_hour += 3600.0
	_report(hours)
	quit(0)


func _log(text: String) -> void:
	if elapsed < 600.0:
		_events.append("%5.0fs %s" % [elapsed, text])


func _on_gold(currency: StringName, balance: int) -> void:
	if currency != Wallet.SOFT:
		return
	var delta := balance - _last_gold
	if delta > 0:
		gold_earned += delta
	else:
		gold_spent -= delta
	_last_gold = balance


func _stoves() -> Array[StringName]:
	var stoves: Array[StringName] = []
	for placement in sim.layout.placements():
		if sim.kitchen.is_stove(placement.id):
			stoves.append(placement.id)
	return stoves


func _count(category: FurnitureDefinition.Category) -> int:
	return sim.layout.placements().filter(func(p: CafeLayout.Placement) -> bool: return p.definition.category == category).size()


## Mesma lógica do robô do turno longo: o que foi pedido primeiro, senão o que mais lucra por minuto.
func _cook() -> void:
	var demand := sim.waiting_demand()
	for stove in _stoves():
		if sim.kitchen.stove_status(stove) != Kitchen.StoveStatus.IDLE:
			continue
		var best: RecipeDefinition = null
		for recipe in sim.recipes.unlocked_at(sim.progression.level):
			if recipe.stove != &"" or not sim.wallet.can_afford(Wallet.SOFT, recipe.ingredient_cost) \
					or recipe.cook_time > ROBOT_MAX_COOK_TIME:
				continue
			var wanted: bool = demand.has(recipe.id) and not sim.kitchen.is_preparing(recipe)
			var best_wanted: bool = best != null and demand.has(best.id) and not sim.kitchen.is_preparing(best)
			if best == null or (wanted and not best_wanted) or (wanted == best_wanted \
					and recipe.batch_profit() / recipe.cook_time > best.batch_profit() / best.cook_time):
				best = recipe
		if best != null:
			sim.start_cooking(stove, best.id)


## Compra na ordem de um jogador médio: a primeira coisa da lista que está liberada; se ainda não dá, junta ouro
## para ela (não troca por uma mais barata). Sempre guarda ouro para os ingredientes.
func _buy() -> void:
	var level := sim.progression.level
	var gold := sim.wallet.balance(Wallet.SOFT) - (60 + level * 10)
	var table_target := mini(TABLES_BASE + level, MAX_TABLES)
	var stove_target := mini(STOVES_BASE + level / STOVES_PER_LEVELS, MAX_STOVES)
	# 1. o básico para atender: mesas, fogões e balcões (se não houver lugar, passa para a expansão)
	if _count(FurnitureDefinition.Category.TABLE) < table_target and _has_table_room():
		if gold >= 90:
			_place_table()
		return
	if _count(FurnitureDefinition.Category.COOKING) < stove_target:
		if gold >= 150:
			_place(&"stove_basic")
		return
	if _count(FurnitureDefinition.Category.COUNTER) < ceili(_count(FurnitureDefinition.Category.COOKING) / 2.0):
		if gold >= 120:
			_place(&"counter_basic")
		return
	# 2. um garçom para cada 4 mesas
	var waiter := sim.can_hire_waiter()
	if sim.waiters.size() * 4 < _count(FurnitureDefinition.Category.TABLE) \
			and (waiter == ServiceResult.OK or waiter == ServiceResult.NOT_ENOUGH_GOLD):
		if gold >= sim.next_waiter_price():
			sim.hire_waiter()
		return
	# 3. crescer o café
	var expansion := sim.next_expansion()
	if not expansion.is_empty() and int(expansion["level"]) <= level and gold >= int(expansion["price"]):
		sim.expand()


func _has_table_room() -> bool:
	var size := sim.layout.grid.size
	for y in range(2, size.y - 1, 2):
		for x in range(2, size.x - 1, 3):
			if sim.layout.grid.is_free(Vector2i(x, y)) and sim.layout.grid.is_free(Vector2i(x - 1, y)):
				return true
	return false


func _place(id: StringName) -> bool:
	var definition := sim.furniture.get_definition(id)
	var size := sim.layout.grid.size
	for y in range(0, size.y):
		for x in range(0, size.x):
			for rotation in [0, 3]:
				if sim.acquire_and_place(definition, Vector2i(x, y), rotation) == ServiceResult.OK:
					return true
	return false


func _place_table() -> bool:
	var table := sim.furniture.get_definition(&"table_round")
	var chair := sim.furniture.get_definition(&"chair_wood")
	var size := sim.layout.grid.size
	for y in range(2, size.y - 1, 2):
		for x in range(2, size.x - 1, 3):
			var cell := Vector2i(x, y)
			if sim.layout.grid.is_free(cell) and sim.layout.grid.is_free(cell + Vector2i(-1, 0)):
				if sim.acquire_and_place(table, cell, 0) == ServiceResult.OK:
					sim.acquire_and_place(chair, cell + Vector2i(-1, 0), 3)
					return true
	return false


func _report(hours: float) -> void:
	print("=== Balanceamento: %.1f h de jogo ativo ===" % hours)
	print("primeiros 10 minutos:")
	for line in _events:
		print("  " + line)
	var shown := 0
	var last := 0
	for entry in _xp_log:
		if entry[0] < 120.0 and shown < 40:
			print("  %5.1fs XP %d (+%d)" % [entry[0], entry[1], entry[1] - last])
			shown += 1
		last = entry[1]
	print("nível | minutos até chegar | XP total")
	var table: LevelTable = sim.progression.table
	for level in range(2, table.max_level() + 1):
		if level_times.has(level):
			print("%5d | %8.1f | %d" % [level, level_times[level] / 60.0, table.xp_to_reach[level - 1]])
	print("hora | nível | ouro ganho na hora | clientes servidos | saldo | popularidade")
	for row in _hourly:
		print("%4d | %5d | %6d | %4d | %6d | %d%%" % row)
	print("final: nível %d, XP %d, ouro ganho %d, gasto %d, saldo %d, servidos %d, irritados %d, popularidade %d%%" % [
		sim.progression.level, sim.progression.xp, gold_earned, gold_spent, sim.wallet.balance(Wallet.SOFT), served, angry,
		roundi(sim.popularity)])
	var reasons := _angry_reasons.keys()
	reasons.sort_custom(func(a: String, b: String) -> bool: return _angry_reasons[a] > _angry_reasons[b])
	print("irritados por motivo: %s" % ", ".join(reasons.slice(0, 12).map(func(r: String) -> String: return "%s %d" % [r, _angry_reasons[r]])))
	print("café: %s, fogões %d, balcões %d, mesas %d, garçons %d" % [sim.layout.grid.size, _count(FurnitureDefinition.Category.COOKING),
		_count(FurnitureDefinition.Category.COUNTER), _count(FurnitureDefinition.Category.TABLE), sim.waiters.size()])
