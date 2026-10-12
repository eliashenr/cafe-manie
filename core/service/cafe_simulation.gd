class_name CafeSimulation
extends RefCounted
## O atendimento da cafeteria, sem nenhuma dependência de tela.
##
## Junta layout, cozinha, carteira, progressão e os personagens, e avança
## tudo com tick(delta). A cena só desenha o estado daqui e repassa as
## ações do jogador. Por ser pura, dá para simular um dia inteiro de
## atendimento num teste, com relógio manual.

signal customer_arrived(customer: Customer)
signal customer_left(customer: Customer)
signal payment_received(customer: Customer, amount: int)
signal dish_collected(stove_id: StringName, recipe: RecipeDefinition)
signal leveled_up(level: int)
signal popularity_changed(popularity: float)
## Um móvel foi comprado (não conta recolocar um guardado).
signal furniture_bought(definition: FurnitureDefinition)
signal cafe_expanded(new_size: Vector2i)
signal mission_completed(mission: MissionDefinition)
signal surface_bought(definition: SurfaceDefinition)
signal furniture_sold(definition: FurnitureDefinition, amount: int)
signal achievement_unlocked(achievement: AchievementDefinition, tier: int)
## [param day] começa em 1. [param reward] é o que foi entregue de fato
## (um revestimento que o jogador já tinha vira ouro).
signal daily_reward_claimed(day: int, reward: Dictionary)
signal cafe_name_changed(cafe_name: String)
## Um garçom foi contratado; [param count] é quantos a cafeteria tem agora.
signal waiter_hired(count: int)


## Um pedido: qual cliente, qual receita e de qual balcão sai a porção
## (&"" enquanto a receita não estiver em nenhum balcão: o jogador precisa cozinhar).
class Order:
	extends RefCounted
	var customer: Customer
	var recipe: RecipeDefinition
	var counter_id: StringName
	var picked_up := false


const CUSTOMERS_DIR := "res://data/customers"
const MISSIONS_DIR := "res://data/missions"
const ACHIEVEMENTS_DIR := "res://data/achievements"
const EXPANSIONS_PATH := "res://data/config/expansions.tres"
const ECONOMY_PATH := "res://data/config/economy.tres"
const DAILY_REWARDS_PATH := "res://data/config/daily_rewards.tres"
## Segundos até o primeiro cliente de um jogo novo.
const FIRST_ARRIVAL_DELAY := 3.0
## Limites do nome da cafeteria (em caracteres, depois de tirar espaços das pontas).
const CAFE_NAME_MIN := 2
const CAFE_NAME_MAX := 24
const DEFAULT_CAFE_NAME := "Minha Cafeteria"

var clock: GameClock
var layout: CafeLayout
var config: ServiceConfig
var furniture: FurnitureCatalog
var recipes: RecipeCatalog
var customer_types: Array[CustomerType] = []

var wallet := Wallet.new()
var progression: PlayerProgression
var kitchen: Kitchen
var navigation: Navigation
var popularity := 50.0
## Móveis guardados, que podem ser recolocados de graça.
var inventory := Inventory.new()
var missions: MissionTracker
var stats := PlayerStats.new()
## Nome escolhido pelo jogador. Vazio = ainda não escolheu (o jogo pergunta).
var cafe_name := ""
## Recompensa diária. Desligada (sem calendário) até with_game_data carregar os dados.
var daily := DailyRewards.new()
var achievements: AchievementTracker
var expansions := ExpansionPlan.new()
var economy: EconomyConfig = load(ECONOMY_PATH)
var surfaces: SurfaceCatalog
## Coleções da loja (estilos e culturas), para agrupar os itens.
var collections: CollectionCatalog
## Itens de pendurar na parede (janelas, quadros, TV, rádio...).
var wall_items: WallItemCatalog
var style := CafeStyle.new()
## Id do último móvel posicionado por acquire_and_place.
var last_placed_id: StringName = &""

var customers: Array[Customer] = []
var waiters: Array[Waiter] = []
var rng := RandomNumberGenerator.new()

var _orders: Array[Order] = []
var _spawn_timer := FIRST_ARRIVAL_DELAY
var _next_serial := 1


func _init(game_clock: GameClock, cafe_layout: CafeLayout, service_config: ServiceConfig,
		furniture_catalog: FurnitureCatalog, recipe_catalog: RecipeCatalog, level_table: LevelTable,
		types: Array[CustomerType], random_seed := 0) -> void:
	clock = game_clock
	layout = cafe_layout
	config = service_config
	furniture = furniture_catalog
	recipes = recipe_catalog
	customer_types = types
	progression = PlayerProgression.new(level_table)
	progression.leveled_up.connect(_on_leveled_up)
	kitchen = Kitchen.new(clock, layout, config.counter_capacity)
	# A navegação precisa ser reconstruída antes de os personagens recalcularem caminho,
	# então ela se conecta ao layout antes da simulação.
	navigation = Navigation.new(layout)
	layout.changed.connect(_on_layout_changed)
	layout.in_use_provider = is_in_use
	layout.agent_cells_provider = agent_cells
	popularity = config.popularity_start
	set_surfaces(SurfaceCatalog.load_from())
	collections = CollectionCatalog.load_from()
	wall_items = WallItemCatalog.load_from()
	var no_missions: Array[MissionDefinition] = []
	set_missions(no_missions)
	var no_achievements: Array[AchievementDefinition] = []
	set_achievements(no_achievements)
	if random_seed != 0:
		rng.seed = random_seed
	else:
		rng.randomize()
	_hire_waiter()


## Um jogo novo a partir dos dados em res://data.
static func create_new_game(game_clock: GameClock, random_seed := 0) -> CafeSimulation:
	var new_game: NewGameConfig = load("res://data/config/new_game.tres")
	var furniture_catalog := FurnitureCatalog.load_from()
	var cafe_layout := CafeLayout.new(new_game.grid_size, CafeLayout.default_entrance(new_game.grid_size))
	for item in new_game.starter_items:
		var definition := furniture_catalog.get_definition(item["id"])
		if definition == null or cafe_layout.place(definition, item["origin"], item["rotation"]) == &"":
			push_error("Móvel inicial inválido em new_game.tres: %s" % item)
	var simulation := with_game_data(game_clock, cafe_layout, furniture_catalog, random_seed)
	simulation.hang_legacy_wall_items()
	simulation.wallet.earn(Wallet.SOFT, new_game.starting_gold, "Ouro inicial")
	return simulation


## Simulação sobre um layout já montado, com o conteúdo padrão de res://data
## (receitas, clientes, níveis, parâmetros). Usada pelo jogo novo e pelo save.
static func with_game_data(game_clock: GameClock, cafe_layout: CafeLayout, furniture_catalog: FurnitureCatalog,
		random_seed := 0) -> CafeSimulation:
	var types_store := DefinitionStore.new(
		func(a: CustomerType, b: CustomerType) -> bool: return String(a.id) < String(b.id))
	types_store.load_dir(CUSTOMERS_DIR, CustomerType)
	var types: Array[CustomerType] = []
	types.assign(types_store.all())
	var simulation := CafeSimulation.new(game_clock, cafe_layout, load("res://data/config/service.tres"),
		furniture_catalog, RecipeCatalog.load_from(), load("res://data/progression/levels.tres"),
		types, random_seed)
	simulation.set_missions(default_missions())
	simulation.set_achievements(default_achievements())
	simulation.daily = DailyRewards.new(load(DAILY_REWARDS_PATH))
	simulation.record_progress_stats()
	simulation.expansions = load(EXPANSIONS_PATH)
	return simulation


## Conquistas de res://data/achievements, na ordem do campo [code]order[/code].
static func default_achievements() -> Array[AchievementDefinition]:
	var store := DefinitionStore.new(
		func(a: AchievementDefinition, b: AchievementDefinition) -> bool: return a.order < b.order)
	store.load_dir(ACHIEVEMENTS_DIR, AchievementDefinition)
	var list: Array[AchievementDefinition] = []
	list.assign(store.all())
	return list


## Missões iniciais de res://data/missions, na ordem do campo [code]order[/code].
static func default_missions() -> Array[MissionDefinition]:
	var store := DefinitionStore.new(
		func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.order < b.order)
	store.load_dir(MISSIONS_DIR, MissionDefinition)
	var mission_list: Array[MissionDefinition] = []
	mission_list.assign(store.all())
	return mission_list


## Troca o catálogo de revestimentos e aplica os iniciais (que já vêm comprados).
func set_surfaces(catalog: SurfaceCatalog) -> void:
	surfaces = catalog
	style = CafeStyle.new()
	style.changed.connect(_record_beauty)
	for kind in [SurfaceDefinition.Kind.FLOOR, SurfaceDefinition.Kind.WALL]:
		var start := surfaces.default_for(kind)
		if start != null:
			style.own(start.id)
			style.apply(start)


## Troca a lista de conquistas (os contadores continuam).
func set_achievements(list: Array[AchievementDefinition]) -> void:
	if achievements != null:
		achievements.detach()
	achievements = AchievementTracker.new(list, stats)
	achievements.achievement_unlocked.connect(_on_achievement_unlocked)
	achievements.refresh()


## Registra os contadores de "maior valor" (nível e beleza) com o estado atual.
func record_progress_stats() -> void:
	stats.record_max(PlayerStats.LEVEL, progression.level)
	stats.record_max(PlayerStats.BEAUTY, beauty())


## Troca a sequência de missões (começa da primeira).
func set_missions(mission_list: Array[MissionDefinition]) -> void:
	missions = MissionTracker.new(mission_list)
	missions.state_provider = _mission_state
	missions.mission_completed.connect(_on_mission_completed)
	missions.refresh()


# --- Ações do jogador ------------------------------------------------------

## Começa a preparar uma receita, cobrando os ingredientes.
func start_cooking(stove_id: StringName, recipe_id: StringName) -> int:
	var recipe := recipes.get_definition(recipe_id)
	if recipe == null:
		return ServiceResult.UNKNOWN_RECIPE
	if not kitchen.is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if kitchen.stove_status(stove_id) != Kitchen.StoveStatus.IDLE:
		return ServiceResult.STOVE_BUSY
	if recipe.unlock_level > progression.level:
		return ServiceResult.RECIPE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, recipe.ingredient_cost):
		return ServiceResult.NOT_ENOUGH_GOLD
	var result := kitchen.start_cooking(stove_id, recipe)
	if result == ServiceResult.OK and recipe.ingredient_cost > 0:
		wallet.spend(Wallet.SOFT, recipe.ingredient_cost, "Ingredientes: %s" % recipe.display_name)
	return result


## Leva o prato pronto do fogão para o balcão e dá o XP da receita.
func collect(stove_id: StringName) -> int:
	var recipe := kitchen.stove_recipe(stove_id)
	var result := kitchen.collect(stove_id)
	if result == ServiceResult.OK:
		progression.add_xp(recipe.xp_reward)
		dish_collected.emit(stove_id, recipe)
		missions.record(MissionDefinition.Kind.COLLECT_DISHES)
		stats.add(PlayerStats.DISHES_COOKED)
	return result


# --- Garçons ----------------------------------------------------------------

## Preço da próxima contratação (-1 se já tem todos os garçons possíveis).
func next_waiter_price() -> int:
	return economy.waiter_prices[waiters.size()] if waiters.size() < economy.max_waiters() else -1


## Nível que libera a próxima contratação (-1 se já tem todos).
func next_waiter_level() -> int:
	return economy.waiter_levels[waiters.size()] if waiters.size() < economy.max_waiters() else -1


func can_hire_waiter() -> int:
	if waiters.size() >= economy.max_waiters():
		return ServiceResult.NO_MORE_WAITERS
	if next_waiter_level() > progression.level:
		return ServiceResult.WAITER_LOCKED
	if not wallet.can_afford(Wallet.SOFT, next_waiter_price()):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Contrata mais um garçom, cobrando o preço. Ele chega pela entrada.
func hire_waiter() -> int:
	var result := can_hire_waiter()
	if result != ServiceResult.OK:
		return result
	var price := next_waiter_price()
	if price > 0:
		wallet.spend(Wallet.SOFT, price, "Contratação de garçom")
	_hire_waiter()
	waiter_hired.emit(waiters.size())
	return ServiceResult.OK


## Garçons de um save (sem cobrar): completa até [param count], dentro do máximo.
func restore_waiter_count(count: int) -> void:
	while waiters.size() < mini(count, economy.max_waiters()):
		_hire_waiter()


# --- Loja, inventário e expansão --------------------------------------------

## Se dá para conseguir um móvel novo agora: guardado no inventário (grátis)
## ou comprado (exige nível e ouro).
func can_acquire(definition: FurnitureDefinition) -> int:
	if inventory.count(definition.id) > 0:
		return ServiceResult.OK
	if definition.min_level > progression.level:
		return ServiceResult.FURNITURE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, definition.price):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Posiciona um móvel novo: usa um guardado, se houver; senão compra.
## Nada é cobrado se a posição for inválida.
func acquire_and_place(definition: FurnitureDefinition, origin: Vector2i, rotation: int) -> int:
	var availability := can_acquire(definition)
	if availability != ServiceResult.OK:
		return availability
	if layout.check_placement(definition, origin, rotation) != CafeLayout.Check.OK:
		return ServiceResult.INVALID_PLACEMENT
	var from_inventory := inventory.count(definition.id) > 0
	last_placed_id = layout.place(definition, origin, rotation)
	if from_inventory:
		inventory.take(definition.id)
		return ServiceResult.OK
	if definition.price > 0:
		wallet.spend(Wallet.SOFT, definition.price, "Compra: %s" % definition.display_name)
	furniture_bought.emit(definition)
	missions.record(MissionDefinition.Kind.BUY_FURNITURE, 1, definition.category)
	stats.add(PlayerStats.FURNITURE_BOUGHT)
	return ServiceResult.OK


## Tira o móvel da cafeteria e guarda no inventário (não perde o que pagou).
func store_furniture(id: StringName) -> CafeLayout.Check:
	var check := layout.can_remove(id)
	if check != CafeLayout.Check.OK:
		return check
	var definition := layout.get_placement(id).definition
	layout.remove(id)
	inventory.add(definition.id)
	return CafeLayout.Check.OK


## Preço de pintar um piso ou trecho de parede com este revestimento (0 se o jogador já o tem inteiro).
func paint_price(definition: SurfaceDefinition) -> int:
	return 0 if style.owns(definition.id) else definition.tile_price


## Pode pintar [param count] células com este revestimento?
func can_paint(definition: SurfaceDefinition, count: int) -> int:
	if not style.owns(definition.id) and definition.min_level > progression.level:
		return ServiceResult.SURFACE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, paint_price(definition) * count):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Pisos que mudariam de revestimento (dentro da cafeteria e com outro revestimento hoje).
func floor_cells_to_paint(definition: SurfaceDefinition, cells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in cells:
		if layout.grid.is_inside(cell) and style.floor_at(cell) != definition.id and not result.has(cell):
			result.append(cell)
	return result


## Trechos de parede que mudariam de revestimento.
func wall_segments_to_paint(definition: SurfaceDefinition, segments: Array[String]) -> Array[String]:
	var valid := wall_segments()
	var result: Array[String] = []
	for wall_segment in segments:
		if valid.has(wall_segment) and style.wall_at(wall_segment) != definition.id and not result.has(wall_segment):
			result.append(wall_segment)
	return result


## Enfeites que as paredes do fundo tinham antes de os itens de parede serem do jogador (o ciclo
## que a arte repetia ao longo de cada parede): jogo novo e saves antigos começam com eles.
const LEGACY_WALL_ITEMS := {
	"top": [&"relogio", &"", &"janela", &"prateleira", &"quadro_cupcake", &"", &"janela", &""],
	"left": [&"", &"quadro_paisagem", &"janela", &"", &"prateleira", &"janela", &"", &"quadro_cupcake"],
}


## Trechos de parede que podem ser pintados: as do fundo e a mureta da frente (menos a porta).
func wall_segments() -> Array[String]:
	var result := CafeStyle.back_wall_segments(layout.grid.size)
	result.append_array(CafeStyle.front_wall_segments(layout.grid.size, layout.entrance))
	return result


## Trechos onde se pendura item: só as paredes do fundo (a mureta da frente é baixa).
func item_segments() -> Array[String]:
	return CafeStyle.back_wall_segments(layout.grid.size)


## Pendura os enfeites de sempre ao longo das paredes do fundo (o ciclo se repete em paredes compridas).
func hang_legacy_wall_items() -> void:
	for edge: String in LEGACY_WALL_ITEMS:
		var cycle: Array = LEGACY_WALL_ITEMS[edge]
		var length := layout.grid.size.x if edge == CafeStyle.EDGE_TOP else layout.grid.size.y
		for i in length:
			var id: StringName = cycle[i % cycle.size()]
			if id != &"" and wall_items.get_definition(id) != null:
				style.hang([CafeStyle.segment(edge, i)] as Array[String], id)


## Trechos em que o item (null = tirar o enfeite) mudaria algo.
func item_segments_to_change(item: WallItemDefinition, segments: Array[String]) -> Array[String]:
	var valid := item_segments()
	var target: StringName = item.id if item != null else &""
	var result: Array[String] = []
	for wall_segment in segments:
		if valid.has(wall_segment) and style.wall_item_at(wall_segment) != target and not result.has(wall_segment):
			result.append(wall_segment)
	return result


func can_hang(item: WallItemDefinition, count: int) -> int:
	if item == null:
		return ServiceResult.OK
	if item.min_level > progression.level:
		return ServiceResult.FURNITURE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, item.price * count):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Pendura o item nos trechos, cobrando o preço por trecho que muda (o que estava lá sai sem reembolso).
## item null tira os enfeites, de graça.
func hang_items(item: WallItemDefinition, segments: Array[String]) -> int:
	var targets := item_segments_to_change(item, segments)
	var result := can_hang(item, targets.size())
	if result != ServiceResult.OK or targets.is_empty():
		return result
	if item != null and item.price > 0:
		wallet.spend(Wallet.SOFT, item.price * targets.size(), "Parede: %s (%d)" % [item.display_name, targets.size()])
	style.hang(targets, item.id if item != null else &"")
	return ServiceResult.OK


## Pinta pisos com o revestimento, cobrando paint_price por piso que muda. Nada é cobrado se recusar.
func paint_floor(definition: SurfaceDefinition, cells: Array[Vector2i]) -> int:
	if definition.kind != SurfaceDefinition.Kind.FLOOR:
		return ServiceResult.UNKNOWN_ITEM
	var targets := floor_cells_to_paint(definition, cells)
	var result := can_paint(definition, targets.size())
	if result == ServiceResult.OK and not targets.is_empty():
		_charge_paint(definition, targets.size())
		style.paint_floor(targets, definition.id)
	return result


func paint_walls(definition: SurfaceDefinition, segments: Array[String]) -> int:
	if definition.kind != SurfaceDefinition.Kind.WALL:
		return ServiceResult.UNKNOWN_ITEM
	var targets := wall_segments_to_paint(definition, segments)
	var result := can_paint(definition, targets.size())
	if result == ServiceResult.OK and not targets.is_empty():
		_charge_paint(definition, targets.size())
		style.paint_walls(targets, definition.id)
	return result


func _charge_paint(definition: SurfaceDefinition, count: int) -> void:
	var cost := paint_price(definition) * count
	if cost > 0:
		wallet.spend(Wallet.SOFT, cost, "Reforma: %s (%d)" % [definition.display_name, count])
	surface_bought.emit(definition)


## Pode aplicar este revestimento? Os já comprados sempre podem.
func can_use_surface(definition: SurfaceDefinition) -> int:
	if style.owns(definition.id):
		return ServiceResult.OK
	if definition.min_level > progression.level:
		return ServiceResult.SURFACE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, definition.price):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Aplica um revestimento, comprando antes se ainda não for do jogador.
func use_surface(definition: SurfaceDefinition) -> int:
	var result := can_use_surface(definition)
	if result != ServiceResult.OK:
		return result
	if not style.owns(definition.id):
		if definition.price > 0:
			wallet.spend(Wallet.SOFT, definition.price, "Compra: %s" % definition.display_name)
		style.own(definition.id)
		surface_bought.emit(definition)
	style.apply(definition)
	return ServiceResult.OK


## Beleza total: móveis posicionados mais o piso e a parede (seção 35). Piso e parede valem a média
## das células: o piso inteiro com um revestimento vale a beleza dele; metade, a metade.
func beauty() -> int:
	var total := 0
	for placement in layout.placements():
		total += placement.definition.beauty
	if surfaces == null:
		return total
	var floor_sum := 0.0
	var size := layout.grid.size
	for y in size.y:
		for x in size.x:
			floor_sum += _surface_beauty(style.floor_at(Vector2i(x, y)))
	var wall_sum := 0.0
	var segments := wall_segments()
	for wall_segment in segments:
		wall_sum += _surface_beauty(style.wall_at(wall_segment))
	var items := style.hung_items()
	for wall_segment: String in items:
		var item := wall_items.get_definition(items[wall_segment]) if wall_items != null else null
		if item != null:
			total += item.beauty
	return total + roundi(floor_sum / maxi(size.x * size.y, 1) + wall_sum / maxi(segments.size(), 1))


func _surface_beauty(id: StringName) -> int:
	var surface := surfaces.get_definition(id)
	return surface.beauty if surface != null else 0


## De 0 a 1: quanto do bônus máximo de beleza a cafeteria já alcançou.
func beauty_factor() -> float:
	return clampf(beauty() / config.beauty_for_max_bonus, 0.0, 1.0)


# --- Nome ------------------------------------------------------------------------

## Nome aceito? Tira espaços das pontas e junta espaços repetidos. Retorna "" se inválido.
static func clean_cafe_name(text: String) -> String:
	var cleaned := text.strip_edges()
	cleaned = cleaned.replace("\n", " ").replace("\t", " ")
	while cleaned.contains("  "):
		cleaned = cleaned.replace("  ", " ")
	if cleaned.length() < CAFE_NAME_MIN or cleaned.length() > CAFE_NAME_MAX:
		return ""
	return cleaned


func set_cafe_name(text: String) -> bool:
	var cleaned := clean_cafe_name(text)
	if cleaned.is_empty():
		return false
	cafe_name = cleaned
	cafe_name_changed.emit(cafe_name)
	return true


# --- Recompensa diária -------------------------------------------------------

func can_claim_daily() -> bool:
	return daily.can_claim(clock.local_day())


## Segundos até poder receber a próxima recompensa diária (0 se já pode agora).
func seconds_until_daily() -> float:
	return 0.0 if can_claim_daily() else clock.seconds_to_next_local_day()


## Dia da sequência (1 a 7) que seria recebido hoje.
func daily_day_number() -> int:
	return daily.index_for(clock.local_day()) + 1


## Entrega a recompensa de hoje. Retorna o que foi entregue, ou {} se já recebeu.
func claim_daily() -> Dictionary:
	var today := clock.local_day()
	var day := daily.index_for(today) + 1
	var reward := daily.claim(today)
	if reward.is_empty():
		return {}
	var delivered := {"gold": int(reward.get("gold", 0)), "xp": int(reward.get("xp", 0))}
	var furniture_id := StringName(reward.get("furniture", &""))
	if furniture.get_definition(furniture_id) != null:
		inventory.add(furniture_id)
		delivered["furniture"] = furniture_id
	var surface := surfaces.get_definition(StringName(reward.get("surface", &"")))
	if surface != null:
		if style.owns(surface.id):
			delivered["gold"] += surface.price
		else:
			style.own(surface.id)
			delivered["surface"] = surface.id
	if delivered["gold"] > 0:
		wallet.earn(Wallet.SOFT, delivered["gold"], "Recompensa diária (dia %d)" % day)
	if delivered["xp"] > 0:
		progression.add_xp(delivered["xp"])
	daily_reward_claimed.emit(day, delivered)
	return delivered


# --- Venda ---------------------------------------------------------------------

## Quanto o jogador recebe ao vender este móvel.
func sell_price(definition: FurnitureDefinition) -> int:
	return floori(definition.price * economy.sell_fraction)


## Pode vender o móvel posicionado? Não se estiver em uso nem se for o último
## fogão ou balcão (contando os guardados): sem eles não há como ganhar ouro.
func can_sell(id: StringName) -> int:
	var placement := layout.get_placement(id)
	if placement == null:
		return ServiceResult.UNKNOWN_ITEM
	if is_in_use(id):
		return ServiceResult.IN_USE
	var category := placement.definition.category
	if category in economy.essential_categories and _count_of_category(category) <= 1:
		return ServiceResult.LAST_ESSENTIAL
	return ServiceResult.OK


## Vende o móvel posicionado. Recebe [method sell_price] em Café Ouro.
func sell_furniture(id: StringName) -> int:
	var result := can_sell(id)
	if result != ServiceResult.OK:
		return result
	var definition := layout.get_placement(id).definition
	layout.remove(id)
	var amount := sell_price(definition)
	if amount > 0:
		wallet.earn(Wallet.SOFT, amount, "Venda: %s" % definition.display_name)
	furniture_sold.emit(definition, amount)
	return ServiceResult.OK


## Móveis de uma categoria, posicionados ou guardados.
func _count_of_category(category: FurnitureDefinition.Category) -> int:
	var total := 0
	for placement in layout.placements():
		if placement.definition.category == category:
			total += 1
	for definition in furniture.all():
		if definition.category == category:
			total += inventory.count(definition.id)
	return total


## Próxima etapa de expansão ({size, level, price}) ou {} se já está no máximo.
func next_expansion() -> Dictionary:
	return expansions.next_after(layout.grid.size)


func can_expand() -> int:
	var step := next_expansion()
	if step.is_empty():
		return ServiceResult.NO_MORE_EXPANSIONS
	if int(step["level"]) > progression.level:
		return ServiceResult.EXPANSION_LOCKED
	if not wallet.can_afford(Wallet.SOFT, int(step["price"])):
		return ServiceResult.NOT_ENOUGH_GOLD
	return ServiceResult.OK


## Aumenta a cafeteria para a próxima etapa, cobrando o preço.
func expand() -> int:
	var result := can_expand()
	if result != ServiceResult.OK:
		return result
	var step := next_expansion()
	if not layout.expand_to(step["size"]):
		return ServiceResult.NO_MORE_EXPANSIONS
	if int(step["price"]) > 0:
		wallet.spend(Wallet.SOFT, int(step["price"]), "Expansão para %dx%d" % [step["size"].x, step["size"].y])
	# A entrada pode ter mudado: quem já está saindo passa a usar a nova.
	var exit: Array[Vector2i] = [layout.entrance]
	for customer in customers:
		if customer.state == Customer.State.LEAVING:
			customer.follow(navigation.path_to_any(customer.cell(), exit), exit)
	cafe_expanded.emit(layout.grid.size)
	missions.record(MissionDefinition.Kind.EXPAND_CAFE)
	stats.add(PlayerStats.EXPANSIONS)
	return ServiceResult.OK


# --- Consultas -------------------------------------------------------------

## Cadeiras encostadas (lado a lado) em alguma mesa.
func seats() -> Array[StringName]:
	var result: Array[StringName] = []
	for placement in layout.placements():
		if placement.definition.category == FurnitureDefinition.Category.SEATING and not _tables_next_to(placement.id).is_empty():
			result.append(placement.id)
	return result


## Clientes na fila da calçada, do primeiro ao último.
func queued() -> Array[Customer]:
	return customers.filter(func(c: Customer) -> bool: return c.state == Customer.State.QUEUED)


## Clientes dentro da cafeteria (fora da fila e ainda não saíram).
func inside_count() -> int:
	var total := 0
	for customer in customers:
		if customer.state not in [Customer.State.QUEUED, Customer.State.GONE]:
			total += 1
	return total


## Onde fica, na calçada, quem está na posição [param index] da fila (0 = o primeiro).
func queue_spot(index: int) -> Vector2:
	return Vector2(layout.entrance) + config.queue_offset + config.queue_spacing * index


## Intervalo médio entre chegadas agora: popularidade, beleza e nível.
func spawn_interval_now() -> float:
	return config.spawn_interval_for(popularity) * (1.0 - beauty_factor() * config.beauty_spawn_bonus) \
		* config.level_spawn_factor(progression.level)


## Pedidos esperando um prato que não está em nenhum balcão: {id da receita: quantos}.
## É o que o jogador precisa cozinhar.
func waiting_demand() -> Dictionary:
	var demand := {}
	for order in _orders:
		if order.counter_id == &"":
			demand[order.recipe.id] = int(demand.get(order.recipe.id, 0)) + 1
	return demand


func free_seats() -> Array[StringName]:
	var claimed := {}
	for customer in customers:
		if customer.state != Customer.State.GONE and customer.seat_id != &"":
			claimed[customer.seat_id] = true
	return seats().filter(func(id: StringName) -> bool: return not claimed.has(id))


## Um móvel está em uso se a cozinha está usando, se é a cadeira de um cliente,
## a mesa dessa cadeira ou um balcão de onde o garçom ainda vai tirar um prato.
func is_in_use(id: StringName) -> bool:
	if kitchen.is_in_use(id):
		return true
	for customer in customers:
		if customer.seat_id == &"" or customer.state in [Customer.State.LEAVING, Customer.State.GONE]:
			continue
		if customer.seat_id == id or _tables_next_to(customer.seat_id).has(id):
			return true
	for order in _orders:
		if order.counter_id == id and not order.picked_up:
			return true
	return false


## Pisos ocupados por personagens em pé ou andando. Chaves de um Dictionary.
func agent_cells() -> Dictionary:
	var cells := {}
	for customer in customers:
		if customer.state == Customer.State.GONE or customer.is_seated():
			continue
		for cell in customer.occupied_cells():
			cells[cell] = true
	for waiter in waiters:
		for cell in waiter.occupied_cells():
			cells[cell] = true
	return cells


func pending_orders() -> int:
	return _orders.size()


## Porções tiradas do balcão para pedidos ainda não entregues: {counter_id, recipe}.
## O save devolve essas porções ao balcão, já que os clientes não são salvos.
func reserved_servings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in _orders:
		if order.counter_id != &"":
			result.append({"counter_id": order.counter_id, "recipe": order.recipe})
	return result


## Restaura a popularidade salva (limitada a 0–100).
func restore_popularity(value: float) -> void:
	popularity = clampf(value, 0.0, 100.0)
	popularity_changed.emit(popularity)


# --- Tick ------------------------------------------------------------------

func tick(delta: float) -> void:
	_update_arrivals(delta)
	_update_queue(delta)
	_assign_servings()
	for customer in customers.duplicate():
		_update_customer(customer, delta)
	for waiter in waiters:
		_update_waiter(waiter, delta)
	customers = customers.filter(func(c: Customer) -> bool: return c.state != Customer.State.GONE)


## Chega um cliente de tempos em tempos. Com cadeira livre (e ninguém na frente dele na fila),
## ele entra; senão espera na fila da calçada, se houver lugar nela.
func _update_arrivals(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = spawn_interval_now() * rng.randf_range(1.0 - config.spawn_jitter, 1.0 + config.spawn_jitter)
	if customer_types.is_empty():
		return
	var customer := Customer.new()
	customer.type = _pick_customer_type()
	customer.speed = config.customer_walk_speed
	if queued().is_empty() and _walk_in(customer):
		pass
	elif queued().size() < config.queue_capacity:
		customer.state = Customer.State.QUEUED
		customer.patience_total = config.queue_patience * customer.type.patience_multiplier
		customer.patience_left = customer.patience_total
		customer.position = queue_spot(queued().size())
		customer.facing = Vector2(-1, 0)
	else:
		return  # fila cheia: o cliente passa direto
	customer.serial = _take_serial()
	customers.append(customer)
	customer_arrived.emit(customer)


## Leva o cliente da entrada até uma cadeira livre. False se não há cadeira, caminho ou lugar lá dentro.
func _walk_in(customer: Customer) -> bool:
	if inside_count() >= config.max_customers_at(progression.level):
		return false
	var candidates := free_seats()
	if candidates.is_empty():
		return false
	var seat_id: StringName = candidates[rng.randi_range(0, candidates.size() - 1)]
	var goals := navigation.access_cells(seat_id)
	var path := navigation.path_to_any(layout.entrance, goals)
	if path.is_empty():
		return false
	customer.state = Customer.State.WALKING_IN
	customer.position = Vector2(layout.entrance)
	customer.seat_id = seat_id
	customer.seat_cell = layout.get_placement(seat_id).origin
	customer.patience_total = config.customer_patience * customer.type.patience_multiplier \
		* (1.0 + beauty_factor() * config.beauty_patience_bonus)
	customer.patience_left = customer.patience_total
	customer.follow(path, goals)
	return true


## A fila anda: o primeiro entra quando vaga uma cadeira; quem cansa de esperar vai embora.
func _update_queue(delta: float) -> void:
	var line := queued()
	while not line.is_empty() and _walk_in(line[0]):
		line.remove_at(0)
	for i in line.size():
		var customer := line[i]
		customer.position = queue_spot(i)
		customer.facing = Vector2(-1, 0)
		customer.patience_left -= delta
		if customer.patience_left <= 0.0:
			customer.happy = false
			customer.gave_up_in_line = true
			customer.state = Customer.State.GONE
			_change_popularity(-config.queue_popularity_loss)
			customer_left.emit(customer)


## Pedidos que esperavam um prato pegam a porção assim que ela chega a um balcão (por ordem de pedido).
func _assign_servings() -> void:
	for order in _orders:
		if order.counter_id == &"":
			order.counter_id = kitchen.take_serving(order.recipe)


func _update_customer(customer: Customer, delta: float) -> void:
	match customer.state:
		Customer.State.WALKING_IN:
			if customer.advance(delta):
				customer.position = Vector2(customer.seat_cell)
				customer.state = Customer.State.WAITING_TO_ORDER
				customer.think_left = config.order_think_time
		Customer.State.WAITING_TO_ORDER:
			customer.think_left -= delta
			if customer.think_left <= 0.0:
				_place_order(customer)
			_lose_patience(customer, delta)
		Customer.State.WAITING_FOR_FOOD:
			_lose_patience(customer, delta)
		Customer.State.EATING:
			customer.eat_left -= delta
			if customer.eat_left <= 0.0:
				_pay(customer)
				_send_away(customer, true)
		Customer.State.LEAVING:
			if customer.advance(delta):
				customer.state = Customer.State.GONE
				customer_left.emit(customer)


## O cliente pede: às vezes o que está no balcão, às vezes qualquer prato do cardápio.
## O que não está no balcão espera o jogador cozinhar.
func _place_order(customer: Customer) -> void:
	var recipe := _choose_order()
	if recipe == null:
		return
	var order := Order.new()
	order.customer = customer
	order.recipe = recipe
	order.counter_id = kitchen.take_serving(recipe)
	_orders.append(order)
	customer.order = recipe
	customer.state = Customer.State.WAITING_FOR_FOOD


func _choose_order() -> RecipeDefinition:
	var available := kitchen.available_recipes()
	if available.is_empty() or rng.randf() < config.menu_order_chance:
		return _pick_from_menu()
	return available[rng.randi_range(0, available.size() - 1)]


## Uma receita liberada, sorteada com mais chance para as rápidas (café sai mais que lasanha).
func _pick_from_menu() -> RecipeDefinition:
	var menu := recipes.unlocked_at(progression.level)
	var weights: Array[float] = []
	var total := 0.0
	for recipe in menu:
		var weight := 1.0 / pow(maxf(recipe.cook_time, 1.0), config.menu_cook_time_weight)
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	for i in menu.size():
		roll -= weights[i]
		if roll <= 0.0:
			return menu[i]
	return menu[-1] if not menu.is_empty() else null


## A paciência gasta mais devagar quando o prato pedido ainda não está no balcão,
## mas já está no fogão: o cliente vê que estão preparando.
func _lose_patience(customer: Customer, delta: float) -> void:
	var order := _order_of(customer)
	if order != null and order.counter_id == &"" and kitchen.is_preparing(order.recipe):
		delta *= config.patience_drain_while_cooking
	customer.patience_left -= delta
	if customer.patience_left <= 0.0:
		_send_away(customer, false)


func _pay(customer: Customer) -> void:
	var amount := maxi(1, roundi(customer.order.sell_price * customer.type.pay_multiplier))
	customer.paid = amount
	wallet.earn(Wallet.SOFT, amount, "Venda: %s" % customer.order.display_name)
	progression.add_xp(config.customer_xp)
	_change_popularity(config.popularity_gain * lerpf(0.5, 1.0, customer.patience_when_served))
	payment_received.emit(customer, amount)
	missions.record(MissionDefinition.Kind.SERVE_CUSTOMERS)
	missions.record(MissionDefinition.Kind.EARN_GOLD, amount)
	stats.add(PlayerStats.CUSTOMERS_SERVED)
	stats.add(PlayerStats.GOLD_EARNED, amount)


## Tira o cliente da mesa e manda para a saída. Pedido não entregue é cancelado.
func _send_away(customer: Customer, happy: bool) -> void:
	customer.happy = happy
	_cancel_order_of(customer)
	if not happy:
		_change_popularity(-config.popularity_loss)
	var stand_at := navigation.access_cells(customer.seat_id)
	customer.seat_id = &""
	customer.state = Customer.State.LEAVING
	if not stand_at.is_empty():
		customer.position = Vector2(stand_at[0])
	var exit: Array[Vector2i] = [layout.entrance]
	var path := navigation.path_to_any(customer.cell(), exit)
	if path.is_empty():
		customer.state = Customer.State.GONE
		customer_left.emit(customer)
	else:
		customer.follow(path, exit)


func _cancel_order_of(customer: Customer) -> void:
	for order in _orders.duplicate():
		if order.customer != customer:
			continue
		if not order.picked_up and order.counter_id != &"":
			kitchen.return_serving(order.counter_id, order.recipe)
		var waiter := _waiter_of(order)
		if waiter != null:
			waiter.order = null
			waiter.carrying = null
			waiter.stop()
			waiter.state = Waiter.State.IDLE
			waiter.timer = 0.0
		_orders.erase(order)


func _update_waiter(waiter: Waiter, delta: float) -> void:
	match waiter.state:
		Waiter.State.IDLE, Waiter.State.RETURNING:
			if _give_task(waiter):
				return
			if waiter.state == Waiter.State.RETURNING:
				if waiter.advance(delta):
					waiter.state = Waiter.State.IDLE
					waiter.timer = config.waiter_idle_pause * rng.randf_range(0.6, 1.4)
			else:
				waiter.timer -= delta
				if waiter.timer <= 0.0:
					_walk_to_post(waiter)
		Waiter.State.TO_COUNTER:
			if waiter.advance(delta):
				waiter.state = Waiter.State.PICKING_UP
				waiter.timer = config.handling_time
		Waiter.State.PICKING_UP:
			waiter.timer -= delta
			if waiter.timer <= 0.0:
				var order: Order = waiter.order
				order.picked_up = true
				waiter.carrying = order.recipe
				var goals := navigation.access_cells(order.customer.seat_id)
				waiter.follow(navigation.path_to_any(waiter.cell(), goals), goals)
				waiter.state = Waiter.State.TO_TABLE
		Waiter.State.TO_TABLE:
			if waiter.advance(delta):
				waiter.state = Waiter.State.DELIVERING
				waiter.timer = config.handling_time
		Waiter.State.DELIVERING:
			waiter.timer -= delta
			if waiter.timer <= 0.0:
				_deliver(waiter)
		Waiter.State.TO_STOVE:
			if waiter.advance(delta):
				waiter.state = Waiter.State.COLLECTING
				waiter.timer = config.handling_time
		Waiter.State.COLLECTING:
			waiter.timer -= delta
			if waiter.timer <= 0.0:
				_collect_for_player(waiter)
		Waiter.State.TO_DROP:
			if waiter.advance(delta):
				waiter.state = Waiter.State.DROPPING
				waiter.timer = config.handling_time
		Waiter.State.DROPPING:
			waiter.timer -= delta
			if waiter.timer <= 0.0:
				waiter.carrying = null
				waiter.drop_counter = &""
				waiter.state = Waiter.State.IDLE


## Tarefa para um garçom livre: primeiro servir um pedido que já tem porção no balcão;
## depois buscar um prato pronto num fogão (se couber em algum balcão).
func _give_task(waiter: Waiter) -> bool:
	var order := _next_unassigned_order()
	if order != null and _send_waiter_to_counter(waiter, order):
		return true
	for stove in kitchen.ready_stoves():
		if _stove_taken(stove) or kitchen.collect_destination(stove) == &"":
			continue
		var goals := navigation.access_cells(stove)
		var path := navigation.path_to_any(waiter.cell(), goals)
		if path.is_empty():
			continue
		waiter.stove_id = stove
		waiter.follow(path, goals)
		waiter.state = Waiter.State.TO_STOVE
		return true
	return false


func _stove_taken(stove: StringName) -> bool:
	for waiter in waiters:
		if waiter.stove_id == stove:
			return true
	return false


## O garçom tira o prato pronto do fogão (como o toque do jogador: o prato vai para o balcão
## e o XP sai) e leva até o balcão. Se o jogador já tinha tocado no fogão, não há o que levar.
func _collect_for_player(waiter: Waiter) -> void:
	var stove := waiter.stove_id
	waiter.stove_id = &""
	waiter.state = Waiter.State.IDLE
	waiter.timer = 0.0
	var counter := kitchen.collect_destination(stove)
	var recipe := kitchen.stove_recipe(stove)
	if counter == &"" or collect(stove) != ServiceResult.OK:
		return
	var goals := navigation.access_cells(counter)
	var path := navigation.path_to_any(waiter.cell(), goals)
	if path.is_empty():
		return
	waiter.carrying = recipe
	waiter.drop_counter = counter
	waiter.follow(path, goals)
	waiter.state = Waiter.State.TO_DROP


## Sem tarefa, o garçom vai para perto de outro fogão ou balcão (em vez de ficar na porta).
func _walk_to_post(waiter: Waiter) -> void:
	var posts: Array[Vector2i] = []
	for placement in layout.placements():
		if placement.definition.category in [FurnitureDefinition.Category.COOKING, FurnitureDefinition.Category.COUNTER]:
			for cell in navigation.access_cells(placement.id):
				if cell != waiter.cell() and not posts.has(cell):
					posts.append(cell)
	waiter.timer = config.waiter_idle_pause
	if posts.is_empty():
		return
	var goal: Array[Vector2i] = [posts[rng.randi_range(0, posts.size() - 1)]]
	var path := navigation.path_to_any(waiter.cell(), goal)
	if path.is_empty():
		return
	waiter.follow(path, goal)
	waiter.state = Waiter.State.RETURNING


func _send_waiter_to_counter(waiter: Waiter, order: Order) -> bool:
	var goals := navigation.access_cells(order.counter_id)
	var path := navigation.path_to_any(waiter.cell(), goals)
	if path.is_empty():
		return false
	waiter.order = order
	waiter.follow(path, goals)
	waiter.state = Waiter.State.TO_COUNTER
	return true


func _deliver(waiter: Waiter) -> void:
	var order: Order = waiter.order
	var customer := order.customer
	if customer.state == Customer.State.WAITING_FOR_FOOD:
		customer.patience_when_served = customer.patience_fraction()
		customer.state = Customer.State.EATING
		customer.eat_left = config.eat_time
	_orders.erase(order)
	waiter.order = null
	waiter.carrying = null
	waiter.state = Waiter.State.IDLE


func _next_unassigned_order() -> Order:
	for order in _orders:
		if order.counter_id != &"" and _waiter_of(order) == null:
			return order
	return null


func _order_of(customer: Customer) -> Order:
	for order in _orders:
		if order.customer == customer:
			return order
	return null


## Só o garçom aponta para o pedido (e não o contrário), para não criar
## referência circular que impediria a memória de ser liberada.
func _waiter_of(order: Order) -> Waiter:
	for waiter in waiters:
		if waiter.order == order:
			return waiter
	return null


## Quando o layout muda, quem está andando recalcula o caminho até a mesma meta.
## Se a meta ficou inalcançável (caso raro: o personagem foi cercado), ele
## volta para a entrada em vez de ficar preso.
func _record_beauty() -> void:
	stats.record_max(PlayerStats.BEAUTY, beauty())


func _on_layout_changed() -> void:
	_record_beauty()
	var agents: Array[Agent] = []
	agents.append_array(customers)
	agents.append_array(waiters)
	for agent in agents:
		if not agent.is_moving():
			continue
		var path := navigation.path_to_any(agent.cell(), agent.goals)
		if path.is_empty():
			agent.position = Vector2(layout.entrance)
			path = navigation.path_to_any(agent.cell(), agent.goals)
		agent.follow(path, agent.goals)


# --- Interno ---------------------------------------------------------------

func _hire_waiter() -> void:
	var waiter := Waiter.new()
	waiter.serial = _take_serial()
	waiter.speed = config.waiter_walk_speed
	waiter.position = Vector2(layout.entrance)
	waiters.append(waiter)


func _tables_next_to(chair_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var chair := layout.get_placement(chair_id)
	if chair == null:
		return result
	for cell in chair.cells():
		for step in Navigation.NEIGHBORS:
			var neighbor := layout.placement_at(cell + step)
			if neighbor != null and neighbor.definition.category == FurnitureDefinition.Category.TABLE \
					and not result.has(neighbor.id):
				result.append(neighbor.id)
	return result


func _pick_customer_type() -> CustomerType:
	var total := 0.0
	for customer_type in customer_types:
		total += customer_type.spawn_weight
	var roll := rng.randf() * total
	for customer_type in customer_types:
		roll -= customer_type.spawn_weight
		if roll <= 0.0:
			return customer_type
	return customer_types[-1]


func _on_leveled_up(level: int) -> void:
	leveled_up.emit(level)
	missions.record(MissionDefinition.Kind.REACH_LEVEL, level)
	stats.record_max(PlayerStats.LEVEL, level)


## Degrau de conquista desbloqueado: paga a recompensa e avisa.
func _on_achievement_unlocked(achievement: AchievementDefinition, tier: int) -> void:
	var reward: int = achievement.tier_rewards[tier]
	if reward > 0:
		wallet.earn(Wallet.SOFT, reward, "Conquista: %s" % achievement.tier_titles[tier])
	achievement_unlocked.emit(achievement, tier)


func _mission_state(kind: MissionDefinition.Kind) -> int:
	return progression.level if kind == MissionDefinition.Kind.REACH_LEVEL else 0


func _on_mission_completed(mission: MissionDefinition) -> void:
	if mission.reward_gold > 0:
		wallet.earn(Wallet.SOFT, mission.reward_gold, "Missão: %s" % mission.title)
	mission_completed.emit(mission)
	if mission.reward_xp > 0:
		progression.add_xp(mission.reward_xp)


func _change_popularity(delta: float) -> void:
	var previous := popularity
	popularity = clampf(popularity + delta, 0.0, 100.0)
	if popularity != previous:
		popularity_changed.emit(popularity)


func _take_serial() -> int:
	_next_serial += 1
	return _next_serial - 1
