class_name Navigation
extends RefCounted
## Caminhos pelos pisos livres da cafeteria (A* em 4 direções).
##
## Usa exatamente a mesma malha da validação de acesso do CafeLayout: se o
## layout aceitou um móvel, existe caminho até ele. Reconstrói sozinho
## quando o layout muda.

const NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var layout: CafeLayout
var _astar := AStarGrid2D.new()


func _init(cafe_layout: CafeLayout) -> void:
	layout = cafe_layout
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	rebuild()
	layout.changed.connect(rebuild)


func rebuild() -> void:
	_astar.region = Rect2i(Vector2i.ZERO, layout.grid.size)
	_astar.update()
	for y in layout.grid.size.y:
		for x in layout.grid.size.x:
			var cell := Vector2i(x, y)
			_astar.set_point_solid(cell, not layout.grid.is_free(cell))


func is_walkable(cell: Vector2i) -> bool:
	return layout.grid.is_free(cell)


## Pisos livres vizinhos de um móvel: onde alguém fica em pé para usá-lo.
func access_cells(placement_id: StringName) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var placement := layout.get_placement(placement_id)
	if placement == null:
		return result
	var own := placement.cells()
	for cell in own:
		for step in NEIGHBORS:
			var next := cell + step
			if not own.has(next) and is_walkable(next) and not result.has(next):
				result.append(next)
	return result


## Menor caminho de [param from] até qualquer uma das metas, incluindo as duas
## pontas. Vazio se nenhuma meta for alcançável.
func path_to_any(from: Vector2i, goals: Array[Vector2i]) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	if not is_walkable(from):
		return best
	for goal in goals:
		if not is_walkable(goal):
			continue
		var path: Array[Vector2i] = _astar.get_id_path(from, goal)
		if not path.is_empty() and (best.is_empty() or path.size() < best.size()):
			best = path
	return best
