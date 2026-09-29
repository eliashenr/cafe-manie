class_name FurnitureLayer
extends Node2D
## Mostra os móveis do layout em ordem de profundidade (y-sort) e a prévia
## ("fantasma") do modo de construção. Só desenha: quem manda é o CafeLayout.

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

var _views: Dictionary = {}  # StringName -> FurnitureView
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


## Cria, atualiza e remove as vistas para bater com o layout.
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
