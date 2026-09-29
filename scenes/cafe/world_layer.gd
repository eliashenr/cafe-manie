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


## Atualiza o que muda a cada frame: etiquetas de fogões e balcões e os personagens.
func refresh(simulation: CafeSimulation) -> void:
	_refresh_furniture_status(simulation.kitchen)
	_refresh_agents(simulation)


func _refresh_furniture_status(kitchen: Kitchen) -> void:
	for id: StringName in _views:
		var view: FurnitureView = _views[id]
		if kitchen.is_stove(id):
			match kitchen.stove_status(id):
				Kitchen.StoveStatus.COOKING:
					view.set_status("%s %s" % [kitchen.stove_recipe(id).display_name,
						format_time(kitchen.time_left(id))], kitchen.progress(id))
				Kitchen.StoveStatus.READY:
					view.set_status("%s pronto!" % kitchen.stove_recipe(id).display_name, -1.0, true)
				_:
					view.set_status("")
		elif kitchen.is_counter(id):
			var stack := kitchen.counter_stack(id)
			view.set_status("" if stack == null else "%s ×%d" % [stack.recipe.display_name, stack.servings])


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
		view.refresh(agent)
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
