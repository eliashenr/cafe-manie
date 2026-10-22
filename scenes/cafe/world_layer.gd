class_name WorldLayer
extends Node2D
## Tudo que fica "no chão" da cafeteria: móveis, personagens e a prévia de
## construção, na mesma camada com y-sort para a profundidade sair certa
## (cliente atrás da mesa, garçom na frente do balcão...).
##
## Só desenha. Quem manda é o CafeLayout (móveis) e a CafeSimulation
## (estados e personagens).

var layout: CafeLayout

## Móvel escondido (o que está sendo movido; no lugar dele aparece o fantasma).
var hidden_id: StringName = &"":
	set(value):
		hidden_id = value
		sync()

## Móvel com contorno de seleção.
var selected_id: StringName = &"":
	set(value):
		selected_id = value
		sync()

var _views: Dictionary = {}  # id do móvel -> FurnitureView
var _agents: Dictionary = {}  # serial do personagem -> AgentView
## Clientes que já saíram e terminam a caminhada até a calçada (somem sozinhos).
var _exiting: Array[AgentView] = []
## O primeiro sync monta a cafeteria inteira (sem animação); depois, móvel novo surge crescendo.
var _synced_once := false
## Jogo pausado: personagens e vapor ficam parados (o resto do salão continua respondendo).
var frozen := false
var _ghost: FurnitureView


func _ready() -> void:
	y_sort_enabled = true
	_ghost = FurnitureView.new()
	_ghost.name = "Ghost"
	_ghost.z_index = 1  # a prévia fica sempre por cima, mesmo quando inválida
	_ghost.visible = false
	add_child(_ghost)


func bind(new_layout: CafeLayout) -> void:
	layout = new_layout
	layout.changed.connect(sync)
	sync()


## Cria, atualiza e remove as vistas dos móveis para bater com o layout.
func sync() -> void:
	if layout == null:
		return
	var alive: Dictionary = {}
	for placement in layout.placements():
		alive[placement.id] = true
		var view: FurnitureView = _views.get(placement.id)
		var created := view == null
		if view == null:
			view = FurnitureView.new()
			view.name = String(placement.id).replace("#", "_")
			add_child(view)
			view.set_frozen(frozen)
			_views[placement.id] = view
		var look := FurnitureView.Look.SELECTED if placement.id == selected_id else FurnitureView.Look.NORMAL
		view.configure(placement.definition, placement.origin, placement.rotation, look)
		view.visible = placement.id != hidden_id
		if created and _synced_once:
			Juice.pop_in(view)  # móvel novo surge crescendo do chão (ao abrir o jogo, já está lá)
	for id: StringName in _views.keys():
		if not alive.has(id):
			_views[id].queue_free()
			_views.erase(id)
	_synced_once = true


## O prato de quem come fica no piso da mesa, puxado este tanto para o lado da cadeira.
const DISH_TOWARD_SEAT := 0.3
## Onde os clientes aparecem e somem: na calçada, este tanto para fora da entrada (em pisos).
const SIDEWALK_OFFSET := Vector2(2.8, 0.0)
## Quem entra na fila chega andando pela calçada (deste tanto além do seu lugar), e quem desiste sai por ela.
const QUEUE_WALK := Vector2(0.0, 3.0)
## Texto do selo do fogão quando o prato fica pronto.
const READY_TEXT := "Pronto!"
const SPOILED_TEXT := "Estragou"
## Estrela do crítico (DT-061): quanto ela fica acima do piso, o tamanho, o raio do toque e o pulsar.
const CRITIC_STAR_LIFT := 70.0
const CRITIC_STAR_SIZE := 46.0
const CRITIC_STAR_TAP_RADIUS := 40.0
const CRITIC_STAR_PULSE := 1.15
const CRITIC_STAR_Z := 30


## Para (pausa) ou solta os personagens e o vapor dos fogões.
func set_frozen(value: bool) -> void:
	frozen = value
	for view: AgentView in _agents.values():
		view.set_frozen(value)
	for view in _exiting:
		if is_instance_valid(view):
			view.set_frozen(value)
	for view: FurnitureView in _views.values():
		view.set_frozen(value)


## Raio-X: só móvel desta altura (pixels de mundo) esconde alguém; mesas e cadeiras nunca.
const XRAY_MIN_HEIGHT := 64.0
## A mureta esmaece perto de quem está a até este tanto (em pisos) da borda da frente, em volta do meio
## do corpo (pixels de mundo acima dos pés).
const FRONT_FOCUS_REACH := 1.6
const FRONT_FOCUS_LIFT := 30.0


## Atualiza o que muda a cada frame: etiquetas de fogões e balcões, pratos nas mesas e os personagens.
func refresh(simulation: CafeSimulation) -> void:
	_refresh_furniture_status(simulation.kitchen)
	_refresh_trophies(simulation.trophies)
	_refresh_critic_star(simulation.critic_star)
	_refresh_table_dishes(simulation)
	_refresh_agents(simulation)
	_refresh_xray()


## Quem está atrás de um móvel alto ganha a silhueta no formato do móvel (sentado não: a mesa na frente é normal).
## Atrás é pela pegada no grid, a mesma regra das faixas do desenho do móvel.
func _refresh_xray() -> void:
	var views: Array[AgentView] = []
	views.assign(_agents.values())
	for view in views:
		var occluders: Array = []
		var body := view.body_rect()
		if body.size != Vector2.ZERO and not view.seated_on_screen():
			for furniture: FurnitureView in _views.values():
				if furniture.visible and furniture.sprite != null and not furniture.is_in_front(view.shown) \
						and furniture.definition.category not in [FurnitureDefinition.Category.TABLE, FurnitureDefinition.Category.SEATING] \
						and furniture.sprite.draw_rect().size.y >= XRAY_MIN_HEIGHT:
					var rect := furniture.sprite.draw_rect()
					if Rect2(furniture.position + rect.position, rect.size).intersects(body):
						occluders.append(furniture)
		view.set_occluders(occluders)


## Pontos onde a mureta da frente fica transparente: personagens perto da borda da frente (inclusive quem
## está saindo pela porta) e o piso escolhido.
func front_focus_points(selected_cell: Vector2i) -> PackedVector2Array:
	var points := PackedVector2Array()
	if layout == null:
		return points
	var size := Vector2(layout.grid.size)
	_prune_exiting()
	var everyone: Array[AgentView] = []
	everyone.assign(_agents.values())
	everyone.append_array(_exiting)
	for view in everyone:
		if view.agent == null:
			continue
		var at := view.shown
		if at.x >= size.x - FRONT_FOCUS_REACH or at.y >= size.y - FRONT_FOCUS_REACH:
			points.append(IsoProjection.grid_point_to_world(at) - Vector2(0.0, FRONT_FOCUS_LIFT))
	if layout.grid.is_inside(selected_cell):
		points.append(IsoProjection.cell_center(selected_cell))
	return points


func _refresh_furniture_status(kitchen: Kitchen) -> void:
	for id: StringName in _views:
		var view: FurnitureView = _views[id]
		if kitchen.is_stove(id):
			var recipe := kitchen.stove_recipe(id)
			match kitchen.stove_status(id):
				Kitchen.StoveStatus.COOKING:
					var time := format_time(kitchen.time_left(id))
					view.set_status("%s %s" % [recipe.display_name, time], kitchen.progress(id), false, recipe, time)
				Kitchen.StoveStatus.READY:
					view.set_status("%s pronto!" % recipe.display_name, -1.0, true, recipe, READY_TEXT)
				Kitchen.StoveStatus.SPOILED:
					view.set_status("%s estragou" % recipe.display_name, -1.0, false, recipe, SPOILED_TEXT, 0, true)
				_:
					view.set_status("")
		elif kitchen.is_counter(id):
			var stack := kitchen.counter_stack(id)
			if stack == null:
				view.set_status("")
			else:
				view.set_status("%s ×%d" % [stack.recipe.display_name, stack.servings], -1.0, false, stack.recipe, "",
					stack.servings)


var _critic_star: Sprite2D


## A estrela que o crítico deixou na mesa, pulsando até o jogador tocar (DT-061).
func _refresh_critic_star(star: Dictionary) -> void:
	if star.is_empty():
		if _critic_star != null:
			_critic_star.visible = false
		return
	if _critic_star == null:
		_critic_star = Sprite2D.new()
		_critic_star.name = "CriticStar"
		_critic_star.z_index = CRITIC_STAR_Z
		var art := ArtSprites.get_sprite("icone_estrela")
		if art != null:
			_critic_star.texture = art.texture
			_critic_star.scale = Vector2.ONE * CRITIC_STAR_SIZE / maxf(art.texture.get_width(), 1.0)
		add_child(_critic_star)
		var pulse := _critic_star.create_tween().set_loops()
		pulse.tween_property(_critic_star, "scale", _critic_star.scale * CRITIC_STAR_PULSE, 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_critic_star, "scale", _critic_star.scale, 0.5).set_trans(Tween.TRANS_SINE)
	_critic_star.visible = true
	_critic_star.position = IsoProjection.cell_center(star["cell"]) - Vector2(0.0, CRITIC_STAR_LIFT)


## A estrela do crítico está visível e o toque caiu nela?
func critic_star_hit(world_position: Vector2) -> bool:
	return _critic_star != null and _critic_star.visible \
		and world_position.distance_to(_critic_star.position) <= CRITIC_STAR_TAP_RADIUS


## Troféu gasto fica apagado (DT-057).
func _refresh_trophies(trophies: StoveTrophies) -> void:
	for id: StringName in _views:
		var view: FurnitureView = _views[id]
		if view.definition != null and view.definition.is_trophy():
			view.set_worn(trophies.is_worn_out(id))


## Põe na mesa o prato de cada cliente que está comendo, do lado da cadeira dele.
func _refresh_table_dishes(simulation: CafeSimulation) -> void:
	var by_table := {}
	for customer in simulation.customers:
		if customer.state != Customer.State.EATING or customer.order == null:
			continue
		var table := _table_cell_for(customer)
		if table.is_empty():
			continue
		var point := Vector2(table[1]).lerp(Vector2(customer.seat_cell), DISH_TOWARD_SEAT)
		if not by_table.has(table[0]):
			by_table[table[0]] = []
		by_table[table[0]].append([point, customer.order])
	for id: StringName in _views:
		var view: FurnitureView = _views[id]
		if view.definition.category == FurnitureDefinition.Category.TABLE:
			view.set_dishes(by_table.get(id, []))


## [id da mesa, piso da mesa] encostado na cadeira do cliente: primeiro o piso para
## onde a cadeira está virada, depois os outros vizinhos. Vazio se não há mesa.
func _table_cell_for(customer: Customer) -> Array:
	var seat := layout.get_placement(customer.seat_id)
	if seat == null:
		return []
	var steps: Array[Vector2i] = [CafeLayout.front_direction(seat.rotation)]
	for step in Navigation.NEIGHBORS:
		if not steps.has(step):
			steps.append(step)
	for step in steps:
		var cell := customer.seat_cell + step
		var neighbor := layout.placement_at(cell)
		if neighbor != null and neighbor.definition.category == FurnitureDefinition.Category.TABLE:
			return [neighbor.id, cell]
	return []


func _refresh_agents(simulation: CafeSimulation) -> void:
	var alive: Dictionary = {}
	var everyone: Array[Agent] = []
	everyone.append_array(simulation.customers)
	everyone.append_array(simulation.waiters)
	for agent in everyone:
		alive[agent.serial] = true
		var view: AgentView = _agents.get(agent.serial)
		if view == null:
			view = AgentView.new()
			view.name = "Agent_%d" % agent.serial
			add_child(view)
			_agents[agent.serial] = view
			view.set_frozen(frozen)
			if agent is Customer and (agent as Customer).state == Customer.State.WALKING_IN:
				view.refresh(agent)
				view.arrive_from(_sidewalk_point())
			elif agent is Customer and (agent as Customer).state == Customer.State.QUEUED:
				view.refresh(agent)
				view.arrive_from(agent.position + QUEUE_WALK)
		var seat_rotation := -1
		var seat_furniture: StringName = &""
		if agent is Customer and (agent as Customer).is_seated():
			var seat := layout.get_placement((agent as Customer).seat_id)
			if seat != null:
				seat_rotation = seat.rotation
				seat_furniture = seat.definition.id
		view.refresh(agent, seat_rotation, seat_furniture)
	for serial: int in _agents.keys():
		if not alive.has(serial):
			var gone: AgentView = _agents[serial]
			_agents.erase(serial)
			if gone.agent is Customer:
				var gave_up := (gone.agent as Customer).gave_up_in_line
				gone.begin_exit(gone.agent.position + QUEUE_WALK if gave_up else _sidewalk_point())
				_exiting.append(gone)
			else:
				gone.queue_free()
	_prune_exiting()


## Ponto da calçada na frente da entrada (de onde os clientes vêm e para onde vão).
func _sidewalk_point() -> Vector2:
	return Vector2(layout.entrance) + SIDEWALK_OFFSET


## Cliente esperando uma bebida sob este ponto do mundo (o da frente, se houver vários), ou null (DT-052).
func drink_customer_at(world_point: Vector2) -> Customer:
	var found: Customer = null
	var front := -INF
	for view: AgentView in _agents.values():
		var customer := view.agent as Customer
		if customer == null or customer.state != Customer.State.WAITING_FOR_DRINK:
			continue
		if view.tap_rect().has_point(world_point) and view.position.y > front:
			front = view.position.y
			found = customer
	return found


## Clientes que já saíram e ainda terminam a caminhada na tela.
func exiting_count() -> int:
	_prune_exiting()
	return _exiting.size()


## Tira da lista quem já terminou a caminhada e se apagou.
func _prune_exiting() -> void:
	var still: Array[AgentView] = []
	for view in _exiting:
		if is_instance_valid(view) and not view.is_queued_for_deletion():
			still.append(view)
	_exiting = still


## "0:45", "3:05", "1:02:10".
static func format_time(seconds: float) -> String:
	var total := ceili(seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]


func show_ghost(definition: FurnitureDefinition, origin: Vector2i, rotation_steps: int, valid: bool) -> void:
	var look := FurnitureView.Look.GHOST_VALID if valid else FurnitureView.Look.GHOST_INVALID
	_ghost.configure(definition, origin, rotation_steps, look)
	_ghost.visible = true


func hide_ghost() -> void:
	_ghost.visible = false


func is_ghost_visible() -> bool:
	return _ghost.visible


func ghost_look() -> FurnitureView.Look:
	return _ghost.look


func view_for(id: StringName) -> FurnitureView:
	return _views.get(id)


func view_count() -> int:
	return _views.size()


func agent_view_count() -> int:
	return _agents.size()
