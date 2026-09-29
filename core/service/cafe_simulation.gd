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


## Um pedido: qual cliente, qual receita e de qual balcão sai a porção.
class Order:
	extends RefCounted
	var customer: Customer
	var recipe: RecipeDefinition
	var counter_id: StringName
	var picked_up := false


const CUSTOMERS_DIR := "res://data/customers"
const MISSIONS_DIR := "res://data/missions"
const EXPANSIONS_PATH := "res://data/config/expansions.tres"
## Segundos até o primeiro cliente de um jogo novo.
const FIRST_ARRIVAL_DELAY := 3.0

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
var expansions := ExpansionPlan.new()
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
	var no_missions: Array[MissionDefinition] = []
	set_missions(no_missions)
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
	simulation.expansions = load(EXPANSIONS_PATH)
	return simulation


## Missões iniciais de res://data/missions, na ordem do campo [code]order[/code].
static func default_missions() -> Array[MissionDefinition]:
	var store := DefinitionStore.new(
		func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.order < b.order)
	store.load_dir(MISSIONS_DIR, MissionDefinition)
	var mission_list: Array[MissionDefinition] = []
	mission_list.assign(store.all())
	return mission_list


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
	return result


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
	# A entrada pode ter mudado: garçom e quem já está saindo passam a usar a nova.
	var exit: Array[Vector2i] = [layout.entrance]
	for waiter in waiters:
		waiter.home = layout.entrance
	for customer in customers:
		if customer.state == Customer.State.LEAVING:
			customer.follow(navigation.path_to_any(customer.cell(), exit), exit)
	cafe_expanded.emit(layout.grid.size)
	missions.record(MissionDefinition.Kind.EXPAND_CAFE)
	return ServiceResult.OK


# --- Consultas -------------------------------------------------------------

## Cadeiras encostadas (lado a lado) em alguma mesa.
func seats() -> Array[StringName]:
	var result: Array[StringName] = []
	for placement in layout.placements():
		if placement.definition.category == FurnitureDefinition.Category.SEATING and not _tables_next_to(placement.id).is_empty():
			result.append(placement.id)
	return result


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
		result.append({"counter_id": order.counter_id, "recipe": order.recipe})
	return result


## Restaura a popularidade salva (limitada a 0–100).
func restore_popularity(value: float) -> void:
	popularity = clampf(value, 0.0, 100.0)
	popularity_changed.emit(popularity)


# --- Tick ------------------------------------------------------------------

func tick(delta: float) -> void:
	_update_arrivals(delta)
	for customer in customers.duplicate():
		_update_customer(customer, delta)
	for waiter in waiters:
		_update_waiter(waiter, delta)
	customers = customers.filter(func(c: Customer) -> bool: return c.state != Customer.State.GONE)


func _update_arrivals(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = config.spawn_interval_for(popularity) * rng.randf_range(1.0 - config.spawn_jitter, 1.0 + config.spawn_jitter)
	if customers.size() >= config.max_customers or customer_types.is_empty():
		return
	var candidates := free_seats()
	if candidates.is_empty():
		return
	var seat_id: StringName = candidates[rng.randi_range(0, candidates.size() - 1)]
	var path := navigation.path_to_any(layout.entrance, navigation.access_cells(seat_id))
	if path.is_empty():
		return

	var customer := Customer.new()
	customer.serial = _take_serial()
	customer.type = _pick_customer_type()
	customer.speed = config.customer_walk_speed
	customer.position = Vector2(layout.entrance)
	customer.seat_id = seat_id
	customer.seat_cell = layout.get_placement(seat_id).origin
	customer.patience_total = config.customer_patience * customer.type.patience_multiplier
	customer.patience_left = customer.patience_total
	customer.follow(path, navigation.access_cells(seat_id))
	customers.append(customer)
	customer_arrived.emit(customer)


func _update_customer(customer: Customer, delta: float) -> void:
	match customer.state:
		Customer.State.WALKING_IN:
			if customer.advance(delta):
				customer.position = Vector2(customer.seat_cell)
				customer.state = Customer.State.WAITING_TO_ORDER
		Customer.State.WAITING_TO_ORDER:
			_try_to_order(customer)
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


func _try_to_order(customer: Customer) -> void:
	var available := kitchen.available_recipes()
	if available.is_empty():
		return
	var recipe: RecipeDefinition = available[rng.randi_range(0, available.size() - 1)]
	var order := Order.new()
	order.customer = customer
	order.recipe = recipe
	order.counter_id = kitchen.take_serving(recipe)
	_orders.append(order)
	customer.order = recipe
	customer.state = Customer.State.WAITING_FOR_FOOD


func _lose_patience(customer: Customer, delta: float) -> void:
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
		if not order.picked_up:
			kitchen.return_serving(order.counter_id, order.recipe)
		var waiter := _waiter_of(order)
		if waiter != null:
			waiter.order = null
			waiter.carrying = null
			waiter.stop()
			waiter.state = Waiter.State.IDLE
		_orders.erase(order)


func _update_waiter(waiter: Waiter, delta: float) -> void:
	match waiter.state:
		Waiter.State.IDLE, Waiter.State.RETURNING:
			var order := _next_unassigned_order()
			if order != null and _send_waiter_to_counter(waiter, order):
				return
			if waiter.state == Waiter.State.IDLE and waiter.cell() != waiter.home:
				var home: Array[Vector2i] = [waiter.home]
				var path := navigation.path_to_any(waiter.cell(), home)
				if not path.is_empty():
					waiter.follow(path, home)
					waiter.state = Waiter.State.RETURNING
			if waiter.state == Waiter.State.RETURNING and waiter.advance(delta):
				waiter.state = Waiter.State.IDLE
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
		if _waiter_of(order) == null:
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
func _on_layout_changed() -> void:
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
	waiter.home = layout.entrance
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
