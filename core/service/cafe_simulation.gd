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
## Missão diária ou semanal concluída (a recompensa já foi entregue).
signal board_mission_completed(board: MissionBoard, entry: MissionBoard.Entry)
## O jogador serviu uma bebida (a energia já foi gasta; o cliente paga quando terminar de beber).
signal drink_served(customer: Customer, drink: DrinkDefinition)
## Uma receita ganhou uma estrela de domínio (DT-053); [param reward] é {"gold", "xp"}, já entregue.
signal recipe_mastered(recipe: RecipeDefinition, stars: int, reward: Dictionary)
## Começou um show no palco (DT-066): os clientes chegam mais rápido enquanto ele dura.
signal show_started
signal show_ended
## O jogador coletou o ouro de uma atração.
signal attraction_collected(attraction_id: StringName, amount: int)
## Um pé de fruta foi colhido: as frutas já estão no estoque (DT-065).
signal fruit_harvested(tree_id: StringName, fruit: FruitDefinition, amount: int)
## Anoiteceu ([param night] true) ou amanheceu: o cardápio noturno abriu ou fechou (DT-064).
signal night_changed(night: bool)
## Começou uma edição de um evento com prazo (DT-063).
signal event_started(event: EventDefinition)
## Uma missão do evento foi concluída; o ouro e o XP já foram entregues.
signal event_mission_completed(event: EventDefinition, entry: MissionBoard.Entry)
## O fogão de prêmio do evento chegou a um nível (1 = acabou de ganhar o fogão, guardado no inventário).
signal event_stove_upgraded(event: EventDefinition, level: int)
## Todas as missões do evento concluídas: o enfeite de prêmio já está no inventário.
signal event_finished(event: EventDefinition)
## O crítico gastronômico chegou e vai sentar (DT-061).
signal critic_arrived(customer: Customer)
## O crítico foi embora: [param star] = foi servido rápido e deixou a estrela na mesa.
signal critic_left(customer: Customer, star: bool)
## O jogador tocou na estrela do crítico: o prêmio (gold, xp, coupons) já foi entregue.
signal critic_star_collected(reward: Dictionary)
## Um multifogão ficou completo pela primeira vez; o prêmio dele já está no inventário (DT-060).
signal stove_set_completed(stove_set: StoveSetDefinition)
## O troféu gastou a última carga e parou de acelerar os fogões (DT-057).
signal trophy_worn_out(trophy_id: StringName)
## Um tempero da prateleira foi usado num fogão (DT-056).
signal spice_used(stove_id: StringName, spice: SpiceDefinition)
## Um prato pronto ficou tempo demais no fogão e estragou (DT-055). Avisa uma vez por prato.
signal dish_spoiled(stove_id: StringName, recipe: RecipeDefinition)


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
const DAILY_MISSIONS_DIR := "res://data/missions/daily"
const WEEKLY_MISSIONS_DIR := "res://data/missions/weekly"
## O dia 0 do relógio (1º/1/1970) foi uma quinta: somar 3 faz a semana começar na segunda.
const WEEK_DAY_OFFSET := 3
const ACHIEVEMENTS_DIR := "res://data/achievements"
const EXPANSIONS_PATH := "res://data/config/expansions.tres"
const ECONOMY_PATH := "res://data/config/economy.tres"
const DAILY_REWARDS_PATH := "res://data/config/daily_rewards.tres"
const ENERGY_PATH := "res://data/config/energy.tres"
const MASTERY_PATH := "res://data/config/mastery.tres"
const CRITIC_PATH := "res://data/config/critic.tres"
const EVENTS_DIR := "res://data/events"
const NIGHT_PATH := "res://data/config/night.tres"
const FRUITS_DIR := "res://data/fruits"
const STAGE_PATH := "res://data/config/stage.tres"
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
## Bebidas das máquinas (DT-052), de res://data/drinks.
var drinks: DrinkCatalog
## Temperos que existem (DT-056) e os que o jogador tem na prateleira.
var spices: SpiceCatalog
var spice_shelf := Inventory.new()
## Cargas dos troféus que aceleram os fogões (DT-057).
var trophies: StoveTrophies
## Multifogões em partes (DT-060).
var stove_sets: StoveSets
## Crítico gastronômico (DT-061).
var critic_config: CriticConfig
## Estrela que o crítico deixou na mesa, esperando o toque: {"cell", "gold", "xp", "coupons"}; vazio = nenhuma.
var critic_star := {}
## Atrações e palco (DT-066): o ouro guardado nas atrações, o show e o tempo até o próximo.
var attractions: Attractions
var stage_config: StageConfig
var show_left := 0.0
var _show_wait := 0.0
## Plantação (DT-065): as frutas que existem, os pés de fruta e o estoque de frutas colhidas.
var fruits: DefinitionStore
var orchard: Orchard
var fruit_stock := Inventory.new()
## Horário da noite (DT-064) e se o último passo foi de noite (para avisar quando muda).
var night_config: NightConfig
var _was_night := false
## Eventos com prazo (DT-063), o quadro de missões do que vale agora (null fora de evento) e o que já aconteceu.
var events: Array[EventDefinition] = []
var event_board: MissionBoard
## Nível de cada fogão de evento ganho (id do móvel -> nível).
var event_stove_levels := {}
## Edição em que a historinha de cada evento já foi vista, e em que o prêmio final já foi entregue (id -> ano).
var event_story_seen := {}
var _event_final_given := {}
var _event_id: StringName = &""
## Dia (local) da última visita do crítico; -1 = nunca veio.
var _critic_day := -1
## Segundos de café aberto, hoje, esperando o crítico.
var _critic_wait := 0.0
## Energia gasta pelas bebidas; recarrega sozinha com o tempo.
var energy: Energy
## Domínio das receitas: estrelas por cozinhar muitas vezes a mesma (DT-053).
var mastery: RecipeMastery
var customer_types: Array[CustomerType] = []

var wallet := Wallet.new()
var progression: PlayerProgression
var kitchen: Kitchen
var navigation: Navigation
var popularity := 50.0
## Jogo pausado: ninguém anda, ninguém perde paciência, ninguém chega e os fogões param.
## O jogador continua podendo comprar, mover, cozinhar e reformar, sem bloqueio nenhum: dá para mexer
## até no que está em uso e pôr móvel onde há gente em pé (as consequências são acertadas na hora).
var paused := false
## Café fechado (placa FECHADO na porta, DT-051): ninguém novo chega e a fila da calçada vai embora; quem
## já está lá dentro continua sendo atendido e sai sem tirar popularidade, mesmo se cansar de esperar.
var closed := false
## Móveis guardados, que podem ser recolocados de graça.
var inventory := Inventory.new()
var missions: MissionTracker
## Missões diárias e semanais: valem todas ao mesmo tempo e recomeçam a cada dia e a cada semana.
var daily_missions: MissionBoard
var weekly_missions: MissionBoard
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
## Pacotes de Café Ouro por dinheiro de verdade (o ouro só entra com o pagamento confirmado).
var coin_shop: CoinShop
var style := CafeStyle.new()
## Id do último móvel posicionado por acquire_and_place.
var last_placed_id: StringName = &""

var customers: Array[Customer] = []
var waiters: Array[Waiter] = []
var rng := RandomNumberGenerator.new()

var _orders: Array[Order] = []
var _spawn_timer := FIRST_ARRIVAL_DELAY
var _next_serial := 1
## Fogões cujo prato estragado já foi avisado (id -> true).
var _spoiled_seen := {}


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
	energy = Energy.new(load(ENERGY_PATH), clock.now(), progression.level)
	mastery = RecipeMastery.new(load(MASTERY_PATH))
	kitchen = Kitchen.new(clock, layout, config.counter_capacity)
	kitchen.spoil_factor = config.spoil_factor
	trophies = StoveTrophies.new(layout)
	stove_sets = StoveSets.new(layout)
	kitchen.min_spoil_time = config.min_spoil_time
	# A navegação precisa ser reconstruída antes de os personagens recalcularem caminho,
	# então ela se conecta ao layout antes da simulação.
	navigation = Navigation.new(layout)
	layout.changed.connect(_on_layout_changed)
	layout.in_use_provider = is_in_use
	layout.agent_cells_provider = agent_cells
	popularity = config.popularity_start
	set_surfaces(SurfaceCatalog.load_from())
	collections = CollectionCatalog.load_from()
	drinks = DrinkCatalog.load_from()
	spices = SpiceCatalog.load_from()
	critic_config = load(CRITIC_PATH)
	night_config = load(NIGHT_PATH)
	fruits = DefinitionStore.new(func(a: FruitDefinition, b: FruitDefinition) -> bool: return a.order < b.order)
	fruits.load_dir(FRUITS_DIR, FruitDefinition)
	orchard = Orchard.new(layout, clock)
	attractions = Attractions.new(layout)
	stage_config = load(STAGE_PATH)
	_was_night = is_night()
	var event_store := DefinitionStore.new(func(a: EventDefinition, b: EventDefinition) -> bool: return String(a.id) < String(b.id))
	event_store.load_dir(EVENTS_DIR, EventDefinition)
	events.assign(event_store.all())
	wall_items = WallItemCatalog.load_from()
	coin_shop = CoinShop.load_from(wallet)
	var no_missions: Array[MissionDefinition] = []
	set_missions(no_missions)
	set_mission_boards(no_missions, no_missions)
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
	simulation.set_mission_boards(load_missions(DAILY_MISSIONS_DIR), load_missions(WEEKLY_MISSIONS_DIR))
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
	return load_missions(MISSIONS_DIR)


## Missões de uma pasta (só os arquivos dela, sem as subpastas), na ordem do campo [code]order[/code].
static func load_missions(dir_path: String) -> Array[MissionDefinition]:
	var store := DefinitionStore.new(
		func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.order < b.order)
	store.load_dir(dir_path, MissionDefinition)
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


## Troca as missões diárias e semanais (começam no próximo refresh_mission_periods()).
func set_mission_boards(daily_list: Array[MissionDefinition], weekly_list: Array[MissionDefinition]) -> void:
	daily_missions = MissionBoard.new(daily_list)
	daily_missions.mission_completed.connect(_on_board_mission_completed.bind(daily_missions))
	weekly_missions = MissionBoard.new(weekly_list)
	weekly_missions.mission_completed.connect(_on_board_mission_completed.bind(weekly_missions))


## Semana do relógio local (muda toda segunda-feira à meia-noite).
func mission_week() -> int:
	return floori(float(clock.local_day() + WEEK_DAY_OFFSET) / 7.0)


## Segundos até as semanais recomeçarem (meia-noite da próxima segunda).
func seconds_until_new_week() -> float:
	var days_left := 6 - posmod(clock.local_day() + WEEK_DAY_OFFSET, 7)
	return clock.seconds_to_next_local_day() + days_left * 86400.0


## Começa as diárias de hoje e as semanais desta semana, se ainda não começaram (com as metas do
## nível atual). Chamado a cada tick e ao carregar.
func refresh_mission_periods() -> void:
	var unlocked := order_menu().size()
	var new_day := daily_missions.start_period(clock.local_day(), progression.level, unlocked)
	var new_week := weekly_missions.start_period(mission_week(), progression.level, unlocked)
	if new_day or new_week:
		_record(MissionDefinition.Kind.REACH_POPULARITY, roundi(popularity))


## Registra um evento nas missões iniciais e nas diárias e semanais.
func _record(kind: MissionDefinition.Kind, amount := 1, recipe: RecipeDefinition = null, furniture_category := -1) -> void:
	missions.record(kind, amount, furniture_category)
	daily_missions.record(kind, amount, recipe, furniture_category)
	weekly_missions.record(kind, amount, recipe, furniture_category)
	if event_board != null:
		event_board.record(kind, amount, recipe, furniture_category)


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
	if not fits_stove(stove_id, recipe):
		return ServiceResult.WRONG_STOVE
	if recipe.night_only and not is_night():
		return ServiceResult.NOT_NIGHT
	if not wallet.can_afford(Wallet.SOFT, recipe.ingredient_cost):
		return ServiceResult.NOT_ENOUGH_GOLD
	var booster := trophies.booster_for(stove_id)
	var result := kitchen.start_cooking(stove_id, recipe, cook_time_on(stove_id, recipe), bonus_servings_on(stove_id, recipe))
	if result == ServiceResult.OK and booster != &"" and trophies.use(booster):
		trophy_worn_out.emit(booster)
	if result == ServiceResult.OK and recipe.ingredient_cost > 0:
		wallet.spend(Wallet.SOFT, recipe.ingredient_cost, "Ingredientes: %s" % recipe.display_name)
		_record(MissionDefinition.Kind.SPEND_INGREDIENTS, recipe.ingredient_cost)
	return result


## Segundos que a receita leva neste fogão agora: o perfil do fogão (tempo máximo e corte, DT-058) e o troféu por perto
## (DT-057). Os cortes se somam, até config.max_speedup.
func cook_time_on(stove_id: StringName, recipe: RecipeDefinition) -> float:
	var base := recipe.cook_time
	var cut := trophies.speed_bonus(stove_id)
	var stove := _stove_definition(stove_id)
	if stove != null:
		if stove.stove_max_time > 0.0:
			base = minf(base, stove.stove_max_time)
		cut += stove.stove_time_cut
		var level := int(event_stove_levels.get(stove.id, 0))
		if level > 0 and level <= stove.stove_level_cuts.size():
			cut += stove.stove_level_cuts[level - 1]
	return base * maxf(1.0 - cut, 1.0 - config.max_speedup)


## A receita sai neste fogão? As do fogão temático só saem nele (DT-059).
func fits_stove(stove_id: StringName, recipe: RecipeDefinition) -> bool:
	var stove := _stove_definition(stove_id)
	return recipe.stove == &"" or (stove != null and stove.id == recipe.stove)


## Receitas que os clientes podem pedir: liberadas no nível e que algum fogão do café sabe fazer.
func order_menu() -> Array[RecipeDefinition]:
	var night := is_night()
	return recipes.unlocked_at(progression.level).filter(
		func(r: RecipeDefinition) -> bool: return (r.stove == &"" or placed_count(r.stove) > 0) and (not r.night_only or night))


## Porções a mais que o perfil do fogão dá a esta receita (DT-058).
func bonus_servings_on(stove_id: StringName, recipe: RecipeDefinition) -> int:
	var bonus := 0
	var stove := _stove_definition(stove_id)
	if stove != null and stove.stove_servings_bonus > 0.0:
		bonus += maxi(1, roundi(recipe.servings * stove.stove_servings_bonus))
	var stove_set := stove_sets.complete_set_of(stove_id)
	if stove_set != null:
		bonus += roundi(recipe.servings * (stove_set.servings_multiplier - 1.0))
	return bonus


## XP de tirar esta receita deste fogão (com o bônus do perfil, DT-058).
func xp_on(stove_id: StringName, recipe: RecipeDefinition) -> int:
	var stove := _stove_definition(stove_id)
	return roundi(recipe.xp_reward * (1.0 + (stove.stove_xp_bonus if stove != null else 0.0)))


## Quantos desse móvel estão na cafeteria.
func placed_count(definition_id: StringName) -> int:
	var count := 0
	for placement in layout.placements():
		if placement.definition.id == definition_id:
			count += 1
	return count


func _stove_definition(stove_id: StringName) -> FurnitureDefinition:
	var placement := layout.get_placement(stove_id)
	return placement.definition if placement != null else null


## Renova o troféu com Café Ouro: ele volta a acelerar com as cargas cheias.
func renew_trophy(trophy_id: StringName) -> int:
	if not trophies.is_trophy(trophy_id):
		return ServiceResult.NOT_A_TROPHY
	var definition := layout.get_placement(trophy_id).definition
	if trophies.charges_left(trophy_id) >= definition.trophy_dishes:
		return ServiceResult.TROPHY_FULL
	if not wallet.can_afford(Wallet.SOFT, definition.renew_price):
		return ServiceResult.NOT_ENOUGH_GOLD
	if definition.renew_price > 0:
		wallet.spend(Wallet.SOFT, definition.renew_price, "Renovar: %s" % definition.display_name)
	trophies.renew(trophy_id)
	return ServiceResult.OK


## Leva o prato pronto do fogão para o balcão e dá o XP da receita.
func collect(stove_id: StringName) -> int:
	var recipe := kitchen.stove_recipe(stove_id)
	var xp := xp_on(stove_id, recipe) if recipe != null else 0
	var result := kitchen.collect(stove_id)
	if result == ServiceResult.OK:
		progression.add_xp(xp)
		dish_collected.emit(stove_id, recipe)
		_record(MissionDefinition.Kind.COLLECT_DISHES, 1, recipe)
		_record(MissionDefinition.Kind.COOK_DIFFERENT, 1, recipe)
		_record(MissionDefinition.Kind.COOK_SLOW, 1, recipe)
		_record(MissionDefinition.Kind.EARN_XP, xp)
		stats.add(PlayerStats.DISHES_COOKED)
		_record_mastery(recipe)
	return result


# --- Temperos (DT-056) -----------------------------------------------------

## O tempero serve agora para este fogão? OK, ou o motivo de não servir.
func can_use_spice(stove_id: StringName, spice_id: StringName) -> int:
	var spice := spices.get_definition(spice_id)
	if spice == null:
		return ServiceResult.UNKNOWN_ITEM
	if not kitchen.is_stove(stove_id):
		return ServiceResult.NOT_A_STOVE
	if not spice.works_on(kitchen.stove_status(stove_id)):
		return ServiceResult.NOT_SPOILED if spice.effect == SpiceDefinition.Effect.RECOVER else ServiceResult.NOT_COOKING
	if spice.effect == SpiceDefinition.Effect.EXTRA_SERVINGS and kitchen.is_seasoned(stove_id):
		return ServiceResult.ALREADY_SEASONED
	return ServiceResult.OK


## Usa no fogão um tempero da prateleira.
func use_spice(stove_id: StringName, spice_id: StringName) -> int:
	var check := can_use_spice(stove_id, spice_id)
	if check != ServiceResult.OK:
		return check
	if not spice_shelf.take(spice_id):
		return ServiceResult.NO_SPICE
	var spice := spices.get_definition(spice_id)
	match spice.effect:
		SpiceDefinition.Effect.EXTRA_SERVINGS:
			kitchen.add_servings(stove_id, spice.extra_servings(kitchen.stove_recipe(stove_id).servings))
		SpiceDefinition.Effect.CUT_TIME:
			kitchen.rush(stove_id, spice.amount)
		SpiceDefinition.Effect.INSTANT:
			kitchen.rush(stove_id, INF)
		SpiceDefinition.Effect.RECOVER:
			kitchen.recover(stove_id)
			_spoiled_seen.erase(stove_id)
	spice_used.emit(stove_id, spice)
	return ServiceResult.OK


## Compra um tempero com Café Ouro; ele vai para a prateleira.
func buy_spice(spice_id: StringName) -> int:
	var spice := spices.get_definition(spice_id)
	if spice == null or spice.price <= 0:
		return ServiceResult.UNKNOWN_ITEM
	if spice.unlock_level > progression.level:
		return ServiceResult.SPICE_LOCKED
	if not wallet.can_afford(Wallet.SOFT, spice.price):
		return ServiceResult.NOT_ENOUGH_GOLD
	wallet.spend(Wallet.SOFT, spice.price, "Tempero: %s" % spice.display_name)
	spice_shelf.add(spice_id)
	return ServiceResult.OK


## Compra e usa na hora. Não cobra nada se o tempero não servir para o fogão.
func buy_and_use_spice(stove_id: StringName, spice_id: StringName) -> int:
	var check := can_use_spice(stove_id, spice_id)
	if check != ServiceResult.OK:
		return check
	var bought := buy_spice(spice_id)
	if bought != ServiceResult.OK:
		return bought
	return use_spice(stove_id, spice_id)


## Tempero de presente (presente diário ou missão). Retorna se entregou.
func _gift_spice(spice_id: StringName, amount: int) -> bool:
	if spices.get_definition(spice_id) == null or amount <= 0:
		return false
	spice_shelf.add(spice_id, amount)
	return true


## Multifogão completo pela primeira vez: o enfeite de prêmio vai para o inventário (DT-060).
func _reward_stove_sets() -> void:
	for stove_set in stove_sets.claim_new_rewards():
		if furniture.get_definition(stove_set.reward) != null:
			inventory.add(stove_set.reward)
		stove_set_completed.emit(stove_set)


# --- Atrações e palco (DT-066) ----------------------------------------------

## Tira o ouro que os clientes deixaram na atração.
func collect_attraction(attraction_id: StringName) -> int:
	if not attractions.is_attraction(attraction_id):
		return ServiceResult.NOT_AN_ATTRACTION
	var amount := attractions.collect(attraction_id)
	if amount <= 0:
		return ServiceResult.NOTHING_TO_COLLECT
	wallet.earn(Wallet.SOFT, amount, "Atração: %s" % layout.get_placement(attraction_id).definition.display_name)
	_record(MissionDefinition.Kind.EARN_GOLD, amount)
	attraction_collected.emit(attraction_id, amount)
	return ServiceResult.OK


## O café tem palco?
func has_stage() -> bool:
	return layout.placements().any(func(p: CafeLayout.Placement) -> bool: return p.definition.stage)


## Tem show agora?
func show_running() -> bool:
	return show_left > 0.0


## Segundos até o próximo show (com palco e café aberto); 0 durante o show.
func seconds_until_show() -> float:
	return 0.0 if show_running() else maxf(stage_config.show_interval - _show_wait, 0.0)


## Com palco e café aberto, o tempo corre até o show; o show dura um tempo e acaba.
func _update_show(delta: float) -> void:
	if show_running():
		show_left -= delta
		if show_left <= 0.0 or not has_stage():
			show_left = 0.0
			show_ended.emit()
		return
	if closed or not has_stage():
		return
	_show_wait += delta
	if _show_wait >= stage_config.show_interval:
		_show_wait = 0.0
		show_left = stage_config.show_duration
		show_started.emit()


## Às vezes quem pagou vai brincar numa atração com lugar, livre e alcançável. Retorna se foi.
func _go_play(customer: Customer) -> bool:
	if customer.critic or rng.randf() >= config.attraction_visit_chance:
		return false
	var busy := {}
	for other in customers:
		if other.attraction_id != &"":
			busy[other.attraction_id] = true
	var options: Array[StringName] = []
	for placement in layout.placements():
		if attractions.has_room(placement.id) and not busy.has(placement.id):
			options.append(placement.id)
	if options.is_empty():
		return false
	var target: StringName = options[rng.randi_range(0, options.size() - 1)]
	var goals := navigation.access_cells(target)
	var stand_at := navigation.access_cells(customer.seat_id)
	var start := stand_at[0] if not stand_at.is_empty() else customer.cell()
	var path := navigation.path_to_any(start, goals)
	if path.is_empty():
		return false
	_cancel_order_of(customer)
	customer.seat_id = &""
	customer.position = Vector2(start)
	customer.attraction_id = target
	customer.follow(path, goals)
	customer.state = Customer.State.WALKING_TO_PLAY
	return true


# --- Plantação (DT-065) -----------------------------------------------------

## Colhe o pé de fruta maduro: as frutas vão para o estoque.
func harvest(tree_id: StringName) -> int:
	if not orchard.is_tree(tree_id):
		return ServiceResult.NOT_A_TREE
	if not orchard.is_ripe(tree_id):
		return ServiceResult.NOT_RIPE
	var fruit_id := layout.get_placement(tree_id).definition.fruit
	var amount := orchard.harvest(tree_id)
	fruit_stock.add(fruit_id, amount)
	fruit_harvested.emit(tree_id, fruits.get_definition(fruit_id) as FruitDefinition, amount)
	return ServiceResult.OK


## "Morango ×3, Manga ×0": o estoque de frutas, na ordem.
func fruit_stock_text() -> String:
	var parts: Array[String] = []
	for fruit: FruitDefinition in fruits.all():
		parts.append("%s ×%d" % [fruit.display_name, fruit_stock.count(fruit.id)])
	return ", ".join(parts)


# --- Noite no café (DT-064) -----------------------------------------------

## É noite agora (cardápio noturno aberto)?
func is_night() -> bool:
	return night_config.is_night(clock.local_hour())


## Quanto escuro está agora (0 de dia, 1 no meio da noite).
func darkness() -> float:
	return night_config.darkness(clock.local_hour())


func _watch_night() -> void:
	var night := is_night()
	if night != _was_night:
		_was_night = night
		night_changed.emit(night)


# --- Eventos com prazo (DT-063) -------------------------------------------

## O evento que vale hoje, ou null.
func current_event() -> EventDefinition:
	var today := clock.local_date()
	for event in events:
		if event.is_active_on(today):
			return event
	return null


## Dias que o evento atual ainda dura depois de hoje (0 = acaba hoje; -1 = sem evento).
func event_days_left() -> int:
	var event := current_event()
	if event == null:
		return -1
	var days := 0
	while days < 366 and event.is_active_on(clock.local_date(days + 1)):
		days += 1
	return days


## A historinha do evento atual ainda não foi vista nesta edição?
func event_story_pending() -> bool:
	var event := current_event()
	return event != null and int(event_story_seen.get(event.id, -1)) != event.edition_for(clock.local_date())


func mark_event_story_seen() -> void:
	var event := current_event()
	if event != null:
		event_story_seen[event.id] = event.edition_for(clock.local_date())


## Liga o quadro de missões do evento que vale hoje (cada edição começa do zero) ou desliga fora do evento.
func refresh_event() -> void:
	var event := current_event()
	if event == null:
		event_board = null
		_event_id = &""
		return
	var edition := event.edition_for(clock.local_date())
	if event_board == null or _event_id != event.id:
		event_board = MissionBoard.new(CafeSimulation.load_missions(event.missions_dir))
		event_board.mission_completed.connect(_on_event_mission_completed)
		_event_id = event.id
	if event_board.start_period(edition, progression.level, order_menu().size()):
		event_started.emit(event)


## Estado dos eventos em tipos simples (para o save).
func events_to_data() -> Dictionary:
	var levels := {}
	for id: StringName in event_stove_levels:
		levels[String(id)] = event_stove_levels[id]
	var seen := {}
	for id: StringName in event_story_seen:
		seen[String(id)] = event_story_seen[id]
	var given := {}
	for id: StringName in _event_final_given:
		given[String(id)] = _event_final_given[id]
	return {"id": String(_event_id), "board": event_board.to_data() if event_board != null else {}, "stove_levels": levels,
		"story_seen": seen, "final_given": given}


func restore_events(data: Dictionary) -> void:
	event_stove_levels.clear()
	event_story_seen.clear()
	_event_final_given.clear()
	for key in ["stove_levels", "story_seen", "final_given"]:
		var target: Dictionary = {"stove_levels": event_stove_levels, "story_seen": event_story_seen,
			"final_given": _event_final_given}[key]
		var saved: Dictionary = data.get(key, {}) if data.get(key) is Dictionary else {}
		for id in saved:
			target[StringName(id)] = int(saved[id])
	event_board = null
	refresh_event()
	var board: Dictionary = data.get("board", {}) if data.get("board") is Dictionary else {}
	if event_board != null and StringName(str(data.get("id", ""))) == _event_id and not board.is_empty():
		event_board.restore(board, progression.level, order_menu().size())


## Missão do evento concluída: entrega o ouro e o XP e confere o fogão de prêmio e o prêmio final.
func _on_event_mission_completed(entry: MissionBoard.Entry) -> void:
	var event := current_event()
	if event == null:
		return
	if entry.reward_gold > 0:
		wallet.earn(Wallet.SOFT, entry.reward_gold, "Evento %s: %s" % [event.title, entry.title()])
	event_mission_completed.emit(event, entry)
	if entry.reward_xp > 0:
		progression.add_xp(entry.reward_xp)
	var completed := event_board.completed_count()
	var level := event.stove_level_for(completed)
	var before := int(event_stove_levels.get(event.prize_stove, 0))
	if level > before and furniture.get_definition(event.prize_stove) != null:
		if before == 0 and placed_count(event.prize_stove) == 0 and inventory.count(event.prize_stove) == 0:
			inventory.add(event.prize_stove)
		event_stove_levels[event.prize_stove] = level
		event_stove_upgraded.emit(event, level)
	var edition := event.edition_for(clock.local_date())
	if completed >= event_board.size() and int(_event_final_given.get(event.id, -1)) != edition:
		_event_final_given[event.id] = edition
		if furniture.get_definition(event.final_prize) != null:
			inventory.add(event.final_prize)
		event_finished.emit(event)


# --- Crítico gastronômico (DT-061) -----------------------------------------

## Temporada atual da loja de troca (DT-062).
func coupon_season() -> int:
	return critic_config.season_for_week(mission_week())


## Itens que a loja de troca oferece nesta temporada.
func coupon_shop_items() -> Array[FurnitureDefinition]:
	var season := coupon_season()
	return furniture.all().filter(func(d: FurnitureDefinition) -> bool:
		return d.coupon_price > 0 and (d.coupon_season < 0 or d.coupon_season == season))


## Segundos até a loja de troca mudar de temporada (meia-noite da segunda em que ela muda).
func seconds_until_new_season() -> float:
	var weeks_left := critic_config.weeks_per_season - 1 - posmod(mission_week(), critic_config.weeks_per_season)
	return seconds_until_new_week() + weeks_left * 7 * 86400.0


## A aba do livro que o crítico avalia nesta semana.
func critic_theme() -> StringName:
	return critic_config.theme_for_week(mission_week())


## O crítico está no café agora (chegando ou sentado; quem já está saindo não conta)?
func critic_present() -> bool:
	return customers.any(func(c: Customer) -> bool:
		return c.critic and c.state not in [Customer.State.LEAVING, Customer.State.GONE])


## Ele ainda vem hoje? (café com clientes, no nível dele e sem visita hoje)
func critic_due() -> bool:
	return not customer_types.is_empty() and progression.level >= critic_config.first_level \
		and _critic_day != clock.local_day()


## Toque na estrela do crítico: entrega ouro, XP e cupons. Retorna o prêmio, ou {} se não há estrela.
func collect_critic_star() -> Dictionary:
	if critic_star.is_empty():
		return {}
	var reward := critic_star.duplicate()
	critic_star = {}
	wallet.earn(Wallet.SOFT, reward["gold"], "Estrela do crítico")
	wallet.earn(Wallet.COUPONS, reward["coupons"], "Estrela do crítico")
	progression.add_xp(reward["xp"])
	_record(MissionDefinition.Kind.EARN_GOLD, reward["gold"])
	_record(MissionDefinition.Kind.EARN_XP, reward["xp"])
	critic_star_collected.emit(reward)
	return reward


## Visita, estrela pendente e dia, em tipos simples (para o save).
func critic_to_data() -> Dictionary:
	var data := {"day": _critic_day}
	if not critic_star.is_empty():
		var cell: Vector2i = critic_star["cell"]
		data["star"] = {"cell": [cell.x, cell.y], "gold": critic_star["gold"], "xp": critic_star["xp"], "coupons": critic_star["coupons"]}
	return data


func restore_critic(data: Dictionary) -> void:
	_critic_day = int(data.get("day", -1))
	critic_star = {}
	var star: Dictionary = data.get("star", {}) if data.get("star") is Dictionary else {}
	var cell: Array = star.get("cell", []) if star.get("cell") is Array else []
	if cell.size() == 2:
		critic_star = {"cell": Vector2i(int(cell[0]), int(cell[1])), "gold": maxi(int(star.get("gold", 0)), 0),
			"xp": maxi(int(star.get("xp", 0)), 0), "coupons": maxi(int(star.get("coupons", 0)), 0)}


## Com o café aberto e o crítico ainda por vir hoje, conta o tempo; na hora, ele entra se houver cadeira.
func _update_critic(delta: float) -> void:
	if closed or not critic_due() or critic_present():
		return
	_critic_wait += delta
	if _critic_wait < critic_config.arrival_delay:
		return
	var critic := Customer.new()
	critic.critic = true
	critic.type = CustomerType.new()
	critic.type.id = &"critic"
	critic.type.display_name = "Crítico"
	critic.type.patience_multiplier = critic_config.patience_multiplier
	critic.speed = config.customer_walk_speed
	if not _walk_in(critic):
		return  # sem cadeira agora: tenta de novo no próximo passo
	critic.serial = _take_serial()
	customers.append(critic)
	_critic_day = clock.local_day()
	_critic_wait = 0.0
	customer_arrived.emit(critic)
	critic_arrived.emit(critic)


## O crítico pede um prato da aba da semana que o café sabe fazer (sem nenhum, qualquer um do cardápio).
func _place_critic_order(customer: Customer) -> void:
	var theme := critic_theme()
	var candidates := order_menu().filter(func(r: RecipeDefinition) -> bool: return r.book == theme)
	var recipe: RecipeDefinition = candidates[rng.randi_range(0, candidates.size() - 1)] if not candidates.is_empty() \
		else _pick_from_menu()
	if recipe == null:
		return
	var order := Order.new()
	order.customer = customer
	order.recipe = recipe
	order.counter_id = kitchen.take_serving(recipe)
	_orders.append(order)
	customer.order = recipe
	customer.ordered_from_menu = order.counter_id == &""
	customer.state = Customer.State.WAITING_FOR_FOOD


## Servido rápido, o crítico deixa a estrela na mesa; senão, só volta outro dia.
func _critic_leaves(customer: Customer, happy: bool) -> void:
	var star := happy and customer.patience_when_served >= critic_config.quick_service
	if star:
		critic_star = {"cell": customer.seat_cell, "gold": critic_config.gold_at(progression.level),
			"xp": critic_config.xp_at(progression.level), "coupons": critic_config.coupons_at(popularity)}
	critic_left.emit(customer, star)


## Joga fora o prato estragado do fogão, que fica livre para cozinhar de novo.
func discard_spoiled(stove_id: StringName) -> int:
	var result := kitchen.discard(stove_id)
	if result == ServiceResult.OK:
		_spoiled_seen.erase(stove_id)
	return result


## Pratos que estragaram enquanto o jogo estava fechado: conta quantos e não avisa um por um.
func forget_spoiled_while_away() -> int:
	var spoiled := kitchen.spoiled_stoves()
	for stove in spoiled:
		_spoiled_seen[stove] = true
	return spoiled.size()


## Avisa (uma vez) cada prato que acabou de estragar no fogão.
func _watch_spoilage() -> void:
	var spoiled := kitchen.spoiled_stoves()
	for stove: StringName in _spoiled_seen.keys():
		if not spoiled.has(stove):
			_spoiled_seen.erase(stove)
	for stove in spoiled:
		if not _spoiled_seen.has(stove):
			_spoiled_seen[stove] = true
			dish_spoiled.emit(stove, kitchen.stove_recipe(stove))


## Mais um prato pronto conta para o domínio da receita; uma estrela nova paga o prêmio dela na hora.
func _record_mastery(recipe: RecipeDefinition) -> void:
	if mastery.record(recipe.id) <= 0:
		return
	var star := mastery.stars(recipe.id)
	var prize := mastery.reward(recipe, star)
	wallet.earn(Wallet.SOFT, prize["gold"], "Domínio: %s" % recipe.display_name)
	progression.add_xp(prize["xp"])
	_record(MissionDefinition.Kind.EARN_GOLD, prize["gold"])
	_record(MissionDefinition.Kind.EARN_XP, prize["xp"])
	recipe_mastered.emit(recipe, star, prize)


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
	if definition.max_per_cafe > 0 and placed_count(definition.id) >= definition.max_per_cafe:
		return ServiceResult.FURNITURE_LIMIT
	if inventory.count(definition.id) > 0:
		return ServiceResult.OK
	if definition.coupon_price > 0:
		if not coupon_shop_items().has(definition):
			return ServiceResult.NOT_IN_SEASON
		if wallet.balance(Wallet.COUPONS) < definition.coupon_price:
			return ServiceResult.NOT_ENOUGH_COUPONS
		return ServiceResult.OK
	if not definition.sold_for_gold:
		return ServiceResult.NOT_FOR_SALE
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
		trophies.place_stored(last_placed_id)
		return ServiceResult.OK
	if definition.coupon_price > 0:
		wallet.spend(Wallet.COUPONS, definition.coupon_price, "Troca: %s" % definition.display_name)
	elif definition.price > 0:
		wallet.spend(Wallet.SOFT, definition.price, "Compra: %s" % definition.display_name)
	furniture_bought.emit(definition)
	_record(MissionDefinition.Kind.BUY_FURNITURE, 1, null, definition.category)
	stats.add(PlayerStats.FURNITURE_BOUGHT)
	return ServiceResult.OK


## Tira o móvel da cafeteria e guarda no inventário (não perde o que pagou).
func store_furniture(id: StringName) -> CafeLayout.Check:
	var check := layout.can_remove(id)
	if check != CafeLayout.Check.OK:
		return check
	var definition := layout.get_placement(id).definition
	trophies.store(id)
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
	if item != null:
		_record(MissionDefinition.Kind.HANG_WALL_ITEMS, targets.size())
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
		_record(MissionDefinition.Kind.PAINT_FLOOR, targets.size())
	return result


func paint_walls(definition: SurfaceDefinition, segments: Array[String]) -> int:
	if definition.kind != SurfaceDefinition.Kind.WALL:
		return ServiceResult.UNKNOWN_ITEM
	var targets := wall_segments_to_paint(definition, segments)
	var result := can_paint(definition, targets.size())
	if result == ServiceResult.OK and not targets.is_empty():
		_charge_paint(definition, targets.size())
		style.paint_walls(targets, definition.id)
		_record(MissionDefinition.Kind.PAINT_WALL, targets.size())
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
	var spice_id := StringName(reward.get("spice", &""))
	if _gift_spice(spice_id, int(reward.get("spice_amount", 1))):
		delivered["spice"] = spice_id
		delivered["spice_amount"] = int(reward.get("spice_amount", 1))
	if delivered["gold"] > 0:
		wallet.earn(Wallet.SOFT, delivered["gold"], "Recompensa diária (dia %d)" % day)
	if delivered["xp"] > 0:
		progression.add_xp(delivered["xp"])
	daily_reward_claimed.emit(day, delivered)
	_record(MissionDefinition.Kind.CLAIM_DAILY_GIFT)
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
	_record(MissionDefinition.Kind.EXPAND_CAFE)
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
		* config.level_spawn_factor(progression.level) * (stage_config.spawn_multiplier if show_left > 0.0 else 1.0)


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
	if paused:
		return false  # pausado, mexe em tudo (_settle_after_layout_change acerta clientes e garçons)
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
	if paused:
		return cells  # pausado, móvel pode cair onde há gente em pé (ela vai para o piso livre mais perto)
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

## Pausa ou continua o jogo (o tempo dos fogões para junto).
func set_paused(value: bool) -> void:
	paused = value
	kitchen.set_paused(value)


## Fecha (ou abre) o café. Ao fechar, a fila da calçada vai embora sem tirar popularidade. Ao abrir,
## o próximo cliente chega logo, como na abertura do jogo.
func set_closed(value: bool) -> void:
	if closed == value:
		return
	closed = value
	if not closed:
		_spawn_timer = minf(_spawn_timer, FIRST_ARRIVAL_DELAY)
		return
	for customer in queued():
		customer.happy = true
		customer.gave_up_in_line = true  # sai da fila andando pela calçada, como quem desiste
		customer.state = Customer.State.GONE
		customer_left.emit(customer)
	customers = customers.filter(func(c: Customer) -> bool: return c.state != Customer.State.GONE)


func tick(delta: float) -> void:
	if paused:
		return
	refresh_mission_periods()
	refresh_event()
	_watch_night()
	_watch_spoilage()
	_update_arrivals(delta)
	_update_critic(delta)
	_update_show(delta)
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
	if closed:
		return
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
		_record(MissionDefinition.Kind.QUEUE_SEATED)
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
		Customer.State.WAITING_FOR_FOOD, Customer.State.WAITING_FOR_DRINK:
			_lose_patience(customer, delta)
		Customer.State.EATING:
			customer.eat_left -= delta
			if customer.eat_left <= 0.0:
				_pay(customer)
				if not _go_play(customer):
					_send_away(customer, true)
		Customer.State.WALKING_TO_PLAY:
			if customer.advance(delta):
				customer.state = Customer.State.PLAYING
				customer.play_left = layout.get_placement(customer.attraction_id).definition.attraction_time
		Customer.State.PLAYING:
			customer.play_left -= delta
			if customer.play_left <= 0.0:
				attractions.add_play(customer.attraction_id)
				customer.attraction_id = &""
				_send_away(customer, true)
		Customer.State.LEAVING:
			if customer.advance(delta):
				customer.state = Customer.State.GONE
				customer_left.emit(customer)


## O cliente pede: às vezes o que está no balcão, às vezes qualquer prato do cardápio.
## O que não está no balcão espera o jogador cozinhar.
func _place_order(customer: Customer) -> void:
	if customer.critic:
		_place_critic_order(customer)
		return
	var drink := _choose_drink()
	if drink != null:
		customer.drink = drink
		customer.state = Customer.State.WAITING_FOR_DRINK
		return
	var recipe := _choose_order()
	if recipe == null:
		return
	var order := Order.new()
	order.customer = customer
	order.recipe = recipe
	order.counter_id = kitchen.take_serving(recipe)
	_orders.append(order)
	customer.order = recipe
	customer.ordered_from_menu = order.counter_id == &""
	customer.state = Customer.State.WAITING_FOR_FOOD


## Às vezes o cliente pede uma bebida: só se o café tiver máquina para alguma bebida já liberada (sem máquina,
## nem sorteia, e o resto do atendimento continua igual).
func _choose_drink() -> DrinkDefinition:
	var menu := drink_menu()
	if menu.is_empty() or rng.randf() >= config.drink_order_chance:
		return null
	return menu[rng.randi_range(0, menu.size() - 1)]


## Bebidas que os clientes podem pedir agora: liberadas no nível e com a máquina delas no café.
func drink_menu() -> Array[DrinkDefinition]:
	var menu: Array[DrinkDefinition] = []
	var seen := {}
	for placement in layout.placements():
		var machine := placement.definition.machine
		if machine != &"" and not seen.has(machine):
			seen[machine] = true
			menu.append_array(drinks.for_machine(machine, progression.level))
	# frozen yogurt (DT-065) só entra no cardápio com fruta no estoque
	return menu.filter(func(d: DrinkDefinition) -> bool: return d.fruit == &"" or fruit_stock.count(d.fruit) >= d.fruit_cost)


## O café tem alguma máquina de bebida?
func has_drink_machine() -> bool:
	for placement in layout.placements():
		if placement.definition.machine != &"":
			return true
	return false


## O café tem uma máquina que prepara a bebida?
func has_machine_for(drink: DrinkDefinition) -> bool:
	for placement in layout.placements():
		if placement.definition.machine == drink.machine:
			return true
	return false


## O jogador tocou no cliente que pediu uma bebida: ela sai na hora da máquina, gastando energia, e o cliente
## bebe e paga (DT-052). Recusa sem máquina, sem energia ou se o cliente não está esperando bebida.
func serve_drink(customer: Customer) -> int:
	if customer == null or customer.state != Customer.State.WAITING_FOR_DRINK or customer.drink == null:
		return ServiceResult.NOT_WAITING_FOR_DRINK
	if not has_machine_for(customer.drink):
		return ServiceResult.NO_MACHINE
	var drink := customer.drink
	if drink.fruit != &"" and fruit_stock.count(drink.fruit) < drink.fruit_cost:
		return ServiceResult.NO_FRUIT
	if drink.energy_cost > 0 and not energy.spend(drink.energy_cost, clock.now()):
		return ServiceResult.NOT_ENOUGH_ENERGY
	for i in (drink.fruit_cost if drink.fruit != &"" else 0):
		fruit_stock.take(drink.fruit)
	customer.patience_when_served = customer.patience_fraction()
	customer.state = Customer.State.EATING
	customer.eat_left = config.drink_time
	progression.add_xp(customer.drink.xp_reward)
	_record(MissionDefinition.Kind.EARN_XP, customer.drink.xp_reward)
	drink_served.emit(customer, customer.drink)
	return ServiceResult.OK


func _choose_order() -> RecipeDefinition:
	var available := kitchen.available_recipes()
	if available.is_empty() or rng.randf() < config.menu_order_chance:
		return _pick_from_menu()
	return available[rng.randi_range(0, available.size() - 1)]


## Uma receita liberada, sorteada com mais chance para as rápidas (café sai mais que lasanha).
func _pick_from_menu() -> RecipeDefinition:
	var menu := order_menu()
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
	var price := customer.drink.sell_price if customer.drink != null else customer.order.sell_price
	var item_name := customer.drink.display_name if customer.drink != null else customer.order.display_name
	var amount := maxi(1, roundi(price * customer.type.pay_multiplier))
	customer.paid = amount
	wallet.earn(Wallet.SOFT, amount, "Venda: %s" % item_name)
	progression.add_xp(config.customer_xp)
	_change_popularity(config.popularity_gain * lerpf(0.5, 1.0, customer.patience_when_served))
	payment_received.emit(customer, amount)
	_record(MissionDefinition.Kind.SERVE_CUSTOMERS)
	_record(MissionDefinition.Kind.EARN_GOLD, amount)
	_record(MissionDefinition.Kind.EARN_XP, config.customer_xp)
	if customer.patience_when_served >= config.happy_patience:
		_record(MissionDefinition.Kind.HAPPY_CUSTOMERS)
	if customer.ordered_from_menu:
		_record(MissionDefinition.Kind.MENU_ORDERS)
	stats.add(PlayerStats.CUSTOMERS_SERVED)
	stats.add(PlayerStats.GOLD_EARNED, amount)


## Tira o cliente da mesa e manda para a saída. Pedido não entregue é cancelado. Com o café fechado,
## quem sai bravo não tira popularidade (o café avisou que estava fechando).
func _send_away(customer: Customer, happy: bool) -> void:
	if customer.critic:
		_critic_leaves(customer, happy)
	customer.happy = happy
	_cancel_order_of(customer)
	if not happy and not closed:
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
	_reward_stove_sets()
	_record_beauty()
	_settle_after_layout_change()
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


## Acerta clientes e garçons depois de o layout mudar. Com o jogo pausado dá para mexer até no que está
## em uso, então: cadeira que mudou de lugar leva o cliente junto; cliente cuja cadeira sumiu ou ficou sem
## mesa vai embora sem tirar popularidade (a porção volta ao balcão); garçom que ia a um móvel que mudou
## refaz o caminho e, se o móvel saiu, fica livre; quem ficou em cima de um móvel vai para o piso livre
## mais perto. Sem a pausa, nada disso acontece (o que está em uso não sai do lugar).
func _settle_after_layout_change() -> void:
	for customer in customers.duplicate():
		if customer.state in [Customer.State.WALKING_TO_PLAY, Customer.State.PLAYING] \
				and not attractions.is_attraction(customer.attraction_id):
			customer.attraction_id = &""
			_send_away(customer, true)  # a atração saiu: vai embora sem reclamar
			continue
		if customer.seat_id == &"" or customer.state in [Customer.State.LEAVING, Customer.State.GONE, Customer.State.QUEUED]:
			continue
		var seat := layout.get_placement(customer.seat_id)
		var no_machine: bool = customer.state == Customer.State.WAITING_FOR_DRINK and not has_machine_for(customer.drink)
		if seat == null or _tables_next_to(customer.seat_id).is_empty() or no_machine:
			_send_away(customer, true)  # sai sem reclamar: não tira popularidade
			continue
		if seat.origin != customer.seat_cell:
			customer.seat_cell = seat.origin
			if customer.is_seated():
				customer.position = Vector2(seat.origin)
			else:
				customer.goals = navigation.access_cells(seat.id)
	for order in _orders:
		if order.counter_id != &"" and not order.picked_up and layout.get_placement(order.counter_id) == null:
			order.counter_id = &""  # a porção foi junto com o balcão; o pedido espera outra
	for waiter in waiters:
		_retarget_waiter(waiter)
	_rescue_agents()


## O garçom refaz o destino da tarefa (o móvel pode ter mudado de lugar) ou fica livre se o móvel saiu.
func _retarget_waiter(waiter: Waiter) -> void:
	var order: Order = waiter.order
	match waiter.state:
		Waiter.State.TO_COUNTER, Waiter.State.PICKING_UP:
			if order == null or order.counter_id == &"":
				_free_waiter(waiter)
			elif waiter.state == Waiter.State.TO_COUNTER:
				waiter.goals = navigation.access_cells(order.counter_id)
		Waiter.State.TO_TABLE:
			if order != null and order.customer.seat_id != &"":
				waiter.goals = navigation.access_cells(order.customer.seat_id)
		Waiter.State.TO_STOVE, Waiter.State.COLLECTING:
			if layout.get_placement(waiter.stove_id) == null:
				_free_waiter(waiter)
			elif waiter.state == Waiter.State.TO_STOVE:
				waiter.goals = navigation.access_cells(waiter.stove_id)
		Waiter.State.TO_DROP, Waiter.State.DROPPING:
			if layout.get_placement(waiter.drop_counter) == null:
				_free_waiter(waiter)
			elif waiter.state == Waiter.State.TO_DROP:
				waiter.goals = navigation.access_cells(waiter.drop_counter)


func _free_waiter(waiter: Waiter) -> void:
	waiter.order = null
	waiter.carrying = null
	waiter.stove_id = &""
	waiter.drop_counter = &""
	waiter.stop()
	waiter.state = Waiter.State.IDLE
	waiter.timer = 0.0


## Quem está em pé em cima de um móvel (posto com o jogo pausado) vai para o piso livre mais perto.
func _rescue_agents() -> void:
	var standing: Array[Agent] = []
	for customer in customers:
		if not customer.is_seated() and customer.state not in [Customer.State.GONE, Customer.State.QUEUED]:
			standing.append(customer)
	standing.append_array(waiters)
	for agent in standing:
		var cell := agent.cell()
		if not layout.grid.is_inside(cell) or layout.grid.occupant_at(cell) == &"":
			continue
		var free := _nearest_free_cell(cell)
		if free != CafeGrid.NO_CELL:
			agent.position = Vector2(free)


## Piso livre mais perto (busca em largura pelos vizinhos), ou NO_CELL se não há nenhum.
func _nearest_free_cell(from: Vector2i) -> Vector2i:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if layout.grid.is_inside(cell) and layout.grid.occupant_at(cell) == &"":
			return cell
		for step in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next: Vector2i = cell + step
			if layout.grid.is_inside(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return CafeGrid.NO_CELL


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
	var gold := progression.table.gold_for(level)
	if gold > 0:
		wallet.earn(Wallet.SOFT, gold, "Nível %d" % level)
	energy.set_level(level, clock.now())
	energy.refill(clock.now())  # nível novo enche a energia
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
	_gift_spice(mission.reward_spice, mission.reward_spice_amount)
	mission_completed.emit(mission)
	if mission.reward_xp > 0:
		progression.add_xp(mission.reward_xp)


func _change_popularity(delta: float) -> void:
	var previous := popularity
	popularity = clampf(popularity + delta, 0.0, 100.0)
	if popularity != previous:
		popularity_changed.emit(popularity)
		_record(MissionDefinition.Kind.REACH_POPULARITY, roundi(popularity))


## Missão diária ou semanal concluída: entrega o ouro e o XP, e a diária conta para a semanal.
func _on_board_mission_completed(entry: MissionBoard.Entry, board: MissionBoard) -> void:
	var period := "diária" if board == daily_missions else "semanal"
	if entry.reward_gold > 0:
		wallet.earn(Wallet.SOFT, entry.reward_gold, "Missão %s: %s" % [period, entry.title()])
	_gift_spice(entry.mission.reward_spice, entry.mission.reward_spice_amount)
	board_mission_completed.emit(board, entry)
	if entry.reward_xp > 0:
		progression.add_xp(entry.reward_xp)
	if board == daily_missions:
		weekly_missions.record(MissionDefinition.Kind.COMPLETE_DAILY)


func _take_serial() -> int:
	_next_serial += 1
	return _next_serial - 1
