class_name Cafe
extends Node2D
## Cena principal do protótipo: a cafeteria.
##
## Dona do layout (regras) e do catálogo (dados). Traduz a entrada do
## jogador em ações e mantém a visualização em dia. Tem dois modos:
## - VIEW: tocar num piso seleciona o piso e, se houver, o móvel em cima dele;
## - BUILD: posicionando um móvel novo ou movendo um existente.

## Emitido sempre que algo que a interface mostra muda (modo, seleção, prévia).
signal state_changed

enum Mode { VIEW, BUILD }

## Tamanho inicial da cafeteria em células. Parâmetro de balanceamento.
@export var initial_grid_size := Vector2i(8, 8)
## Folga, em pixels de mundo, que a câmera pode passar da borda do grid.
@export var camera_margin := 96.0
## Altura, em pixels de tela, ocupada pelo painel de cima (a câmera enquadra abaixo dele).
@export var ui_top_inset := 110.0
## Altura, em pixels de tela, ocupada pela barra de baixo.
@export var ui_bottom_inset := 140.0
## Espaço acima do grid reservado para a altura dos móveis da fileira de trás.
@export var furniture_headroom := 60.0

var layout: CafeLayout
var catalog: FurnitureCatalog
var mode := Mode.VIEW
## Sessão de construção em andamento (só no modo BUILD).
var session: PlacementSession
var selected_cell := CafeGrid.NO_CELL
## Móvel selecionado no modo VIEW, ou &"".
var selected_id: StringName = &""
## Resultado da última checagem de posição, para a interface explicar recusas.
var last_check := CafeLayout.Check.OK

var grid: CafeGrid:
	get:
		return layout.grid

@onready var floor_view: FloorView = $FloorView
@onready var furniture_layer: FurnitureLayer = $FurnitureLayer
@onready var camera: CafeCamera = $CafeCamera
@onready var build_bar: BuildBar = $BuildBar


func _ready() -> void:
	catalog = FurnitureCatalog.load_from()
	layout = CafeLayout.new(initial_grid_size, CafeLayout.default_entrance(initial_grid_size))
	floor_view.grid_size = layout.grid.size
	floor_view.entrance = layout.entrance
	furniture_layer.bind(layout)

	var bounds := IsoProjection.grid_bounds(layout.grid.size)
	camera.set_bounds(bounds.grow(camera_margin))
	camera.frame(bounds.grow_individual(0.0, furniture_headroom, 0.0, 0.0), ui_top_inset, ui_bottom_inset)
	camera.tapped.connect(_on_tapped)
	camera.hovered.connect(_on_hovered)

	build_bar.bind(self)


# --- Modo VIEW -------------------------------------------------------------

## Seleciona a célula sob o ponto do mundo (e o móvel sobre ela). Fora do grid, limpa tudo.
func select_at_world(world_position: Vector2) -> void:
	var cell := IsoProjection.world_to_cell(world_position)
	_set_selected_cell(cell if layout.grid.is_inside(cell) else CafeGrid.NO_CELL)
	var placement := layout.placement_at(selected_cell)
	_set_selected_id(placement.id if placement != null else &"")
	state_changed.emit()


func clear_selection() -> void:
	_set_selected_cell(CafeGrid.NO_CELL)
	_set_selected_id(&"")
	state_changed.emit()


## Gira o móvel selecionado no lugar. Retorna o resultado (pode ser recusado).
func rotate_selected() -> CafeLayout.Check:
	var placement := layout.get_placement(selected_id)
	if placement == null:
		return CafeLayout.Check.UNKNOWN_PLACEMENT
	last_check = layout.move(selected_id, placement.origin, placement.rotation + 1)
	state_changed.emit()
	return last_check


func remove_selected() -> bool:
	if not layout.remove(selected_id):
		return false
	clear_selection()
	return true


# --- Modo BUILD ------------------------------------------------------------

## Começa a posicionar um móvel novo do catálogo.
func start_placing(definition_id: StringName) -> bool:
	var definition := catalog.get_definition(definition_id)
	if definition == null:
		return false
	clear_selection()
	_begin_session(PlacementSession.for_new(layout, definition))
	return true


## Começa a mover o móvel selecionado.
func start_moving_selected() -> bool:
	var moving := PlacementSession.for_move(layout, selected_id)
	if moving == null:
		return false
	_set_selected_cell(CafeGrid.NO_CELL)
	_begin_session(moving)
	return true


func rotate_placement() -> void:
	if session == null:
		return
	session.rotate_clockwise()
	_refresh_preview()


## Confirma a posição atual. Retorna false (e mantém o modo) se for inválida.
func confirm_placement() -> bool:
	if session == null:
		return false
	var placed_id := session.confirm()
	if placed_id == &"":
		_refresh_preview()
		return false
	var was_moving := session.is_moving()
	_end_session()
	if was_moving:
		_set_selected_id(placed_id)
		state_changed.emit()
	return true


func cancel_placement() -> void:
	if session != null:
		_end_session()


func _begin_session(new_session: PlacementSession) -> void:
	session = new_session
	mode = Mode.BUILD
	furniture_layer.hidden_id = session.moving_id
	_refresh_preview()


func _end_session() -> void:
	session = null
	mode = Mode.VIEW
	last_check = CafeLayout.Check.OK
	furniture_layer.hidden_id = &""
	furniture_layer.hide_ghost()
	floor_view.clear_preview()
	state_changed.emit()


func _refresh_preview() -> void:
	last_check = session.check()
	if session.target == CafeGrid.NO_CELL:
		furniture_layer.hide_ghost()
		floor_view.clear_preview()
	else:
		var valid := last_check == CafeLayout.Check.OK
		furniture_layer.show_ghost(session.definition, session.target, session.rotation, valid)
		floor_view.set_preview(CafeGrid.footprint_cells(session.target, session.footprint()), valid)
	state_changed.emit()


# --- Entrada ---------------------------------------------------------------

func _on_tapped(world_position: Vector2) -> void:
	if mode == Mode.VIEW:
		select_at_world(world_position)
		return
	var cell := IsoProjection.world_to_cell(world_position)
	if not layout.grid.is_inside(cell):
		return
	# Tocar de novo no mesmo lugar confirma; no mouse, o hover já levou a prévia até lá,
	# então um clique só basta.
	if cell == session.target and session.can_confirm():
		confirm_placement()
	else:
		session.set_target(cell)
		_refresh_preview()


func _on_hovered(world_position: Vector2) -> void:
	if mode != Mode.BUILD:
		return
	var cell := IsoProjection.world_to_cell(world_position)
	if layout.grid.is_inside(cell) and cell != session.target:
		session.set_target(cell)
		_refresh_preview()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			if mode == Mode.BUILD:
				rotate_placement()
			elif selected_id != &"":
				rotate_selected()
		KEY_ENTER, KEY_KP_ENTER:
			confirm_placement()
		KEY_ESCAPE:
			if mode == Mode.BUILD:
				cancel_placement()
			else:
				clear_selection()
		KEY_DELETE, KEY_BACKSPACE:
			if mode == Mode.VIEW:
				remove_selected()
		_:
			return
	get_viewport().set_input_as_handled()


## Atualiza a célula selecionada e avisa o EventBus só quando ela muda,
## para quem escuta (como o HUD) nunca ficar com informação velha.
func _set_selected_cell(cell: Vector2i) -> void:
	var changed_cell := cell != selected_cell
	selected_cell = cell
	floor_view.selected_cell = cell
	if changed_cell:
		EventBus.cell_selected.emit(cell)


func _set_selected_id(id: StringName) -> void:
	selected_id = id
	last_check = CafeLayout.Check.OK
	furniture_layer.selected_id = id
