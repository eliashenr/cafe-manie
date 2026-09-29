extends Node2D
## Cena principal do protótipo: a cafeteria.
##
## Dona do grid lógico. Liga a câmera (entrada do jogador) ao grid (regras)
## e à visualização do piso.

## Tamanho inicial da cafeteria em células. Parâmetro de balanceamento.
@export var initial_grid_size := Vector2i(8, 8)
## Folga, em pixels de mundo, que a câmera pode passar da borda do grid.
@export var camera_margin := 96.0

var grid: CafeGrid
var selected_cell := CafeGrid.NO_CELL

@onready var floor_view: FloorView = $FloorView
@onready var camera: CafeCamera = $CafeCamera


func _ready() -> void:
	grid = CafeGrid.new(initial_grid_size)
	floor_view.grid_size = grid.size
	var bounds := IsoProjection.grid_bounds(grid.size)
	camera.global_position = bounds.get_center()
	camera.set_bounds(bounds.grow(camera_margin))
	camera.tapped.connect(select_at_world)


## Seleciona a célula sob o ponto do mundo. Fora do grid, limpa a seleção.
func select_at_world(world_position: Vector2) -> void:
	var cell := IsoProjection.world_to_cell(world_position)
	selected_cell = cell if grid.is_inside(cell) else CafeGrid.NO_CELL
	floor_view.selected_cell = selected_cell
	EventBus.cell_selected.emit(selected_cell)
