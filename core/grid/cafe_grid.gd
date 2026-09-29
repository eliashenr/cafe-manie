class_name CafeGrid
extends RefCounted
## Grid lógico da cafeteria: fonte da verdade sobre quais células existem
## e quem ocupa cada uma.
##
## Não conhece renderização nem nós da cena. Trabalha só com coordenadas
## inteiras (Vector2i), o que permite testar sem tela e, no futuro, validar
## as mesmas regras no servidor.

## Valor usado para "nenhuma célula" (ex.: seleção vazia).
const NO_CELL := Vector2i(-1, -1)

## Tamanho atual do grid em células (largura x profundidade).
var size: Vector2i:
	get:
		return _size

var _size: Vector2i
var _cell_to_id: Dictionary = {}  # Vector2i -> StringName
var _id_to_cells: Dictionary = {}  # StringName -> Array[Vector2i]


func _init(initial_size: Vector2i) -> void:
	assert(initial_size.x > 0 and initial_size.y > 0, "O grid precisa ter tamanho positivo.")
	_size = initial_size


## Todas as células cobertas por um objeto com esse tamanho a partir de [param origin].
static func footprint_cells(origin: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in footprint.y:
		for dx in footprint.x:
			cells.append(origin + Vector2i(dx, dy))
	return cells


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


func is_free(cell: Vector2i) -> bool:
	return is_inside(cell) and not _cell_to_id.has(cell)


## Id do objeto que ocupa a célula, ou &"" se estiver livre.
func occupant_at(cell: Vector2i) -> StringName:
	return _cell_to_id.get(cell, &"")


func has_object(id: StringName) -> bool:
	return _id_to_cells.has(id)


func object_count() -> int:
	return _id_to_cells.size()


func can_place(origin: Vector2i, footprint: Vector2i) -> bool:
	if footprint.x <= 0 or footprint.y <= 0:
		return false
	for cell in footprint_cells(origin, footprint):
		if not is_free(cell):
			return false
	return true


## Ocupa as células do objeto. Retorna false, sem alterar nada, se o id já
## existir ou se alguma célula estiver fora do grid ou ocupada.
func place(id: StringName, origin: Vector2i, footprint: Vector2i) -> bool:
	if id == &"" or has_object(id) or not can_place(origin, footprint):
		return false
	var cells := footprint_cells(origin, footprint)
	for cell in cells:
		_cell_to_id[cell] = id
	_id_to_cells[id] = cells
	return true


## Libera as células do objeto. Retorna false se o id não existir.
func remove(id: StringName) -> bool:
	if not has_object(id):
		return false
	for cell: Vector2i in _id_to_cells[id]:
		_cell_to_id.erase(cell)
	_id_to_cells.erase(id)
	return true


## Muda o tamanho do grid (expansão). Recusa, sem alterar nada, se algum
## objeto já posicionado ficaria fora da nova área.
func resize(new_size: Vector2i) -> bool:
	if new_size.x <= 0 or new_size.y <= 0:
		return false
	for cell: Vector2i in _cell_to_id:
		if cell.x >= new_size.x or cell.y >= new_size.y:
			return false
	_size = new_size
	return true
