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
		if view == null:
			view = FurnitureView.new()
			view.name = String(placement.id).replace("#", "_")
			add_child(view)
			_views[placement.id] = view
		var look := FurnitureView.Look.SELECTED if placement.id == selected_id else FurnitureView.Look.NORMAL
		view.configure(placement.definition, placement.origin, placement.rotation, look)
		view.visible = placement.id != hidden_id
	for id: StringName in _views.keys():
		if not alive.has(id):
			_views[id].queue_free()
			_views.erase(id)


## O prato de quem come fica no piso da mesa, puxado este tanto para o lado da cadeira.
const DISH_TOWARD_SEAT := 0.3
## Texto do selo do fogão quando o prato fica pronto.
const READY_TEXT := "Pronto!"


## Atualiza o que muda a cada frame: etiquetas de fogões e balcões, pratos nas mesas e os personagens.
func refresh(simulation: CafeSimulation) -> void:
	_refresh_furniture_status(simulation.kitchen)
	_refresh_table_dishes(simulation)
	_refresh_agents(simulation)


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
				_:
					view.set_status("")
		elif kitchen.is_counter(id):
			var stack := kitchen.counter_stack(id)
			if stack == null:
				view.set_status("")
			else:
				view.set_status("%s ×%d" % [stack.recipe.display_name, stack.servings], -1.0, false, stack.recipe, "",
					stack.servings)


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
		var seat_rotation := -1
		if agent is Customer and (agent as Customer).is_seated():
			var seat := layout.get_placement((agent as Customer).seat_id)
			if seat != null:
				seat_rotation = seat.rotation
		view.refresh(agent, seat_rotation)
	for serial: int in _agents.keys():
		if not alive.has(serial):
			_agents[serial].queue_free()
			_agents.erase(serial)


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
