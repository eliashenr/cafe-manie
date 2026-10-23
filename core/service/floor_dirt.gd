class_name FloorDirt
extends RefCounted
## Chão sujo (DT-068): manchas que os clientes deixam no chão ao terminar de comer, até o jogador limpar.
## Só fica mancha em piso livre: móvel posto em cima a cobre (ela some).

signal changed

var layout: CafeLayout
## Célula -> true.
var _spots := {}


func _init(cafe_layout: CafeLayout) -> void:
	layout = cafe_layout
	layout.changed.connect(_forget_covered)


func has_spot(cell: Vector2i) -> bool:
	return _spots.has(cell)


func spots() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_spots.keys())
	return result


func count() -> int:
	return _spots.size()


## Suja a célula, se for piso livre e ainda estiver limpa. Retorna se sujou.
func add(cell: Vector2i) -> bool:
	if has_spot(cell) or not _is_free_floor(cell):
		return false
	_spots[cell] = true
	changed.emit()
	return true


## Limpa a célula. Retorna se havia mancha.
func clean(cell: Vector2i) -> bool:
	if not _spots.erase(cell):
		return false
	changed.emit()
	return true


func to_data() -> Array:
	return spots().map(func(cell: Vector2i) -> Array: return [cell.x, cell.y])


func restore(data: Array) -> void:
	_spots.clear()
	for entry in data:
		if entry is Array and entry.size() == 2:
			var cell := Vector2i(SafeValue.to_int(entry[0], -1), SafeValue.to_int(entry[1], -1))
			if _is_free_floor(cell):
				_spots[cell] = true
	changed.emit()


func _is_free_floor(cell: Vector2i) -> bool:
	return layout.grid.is_inside(cell) and layout.placement_at(cell) == null


func _forget_covered() -> void:
	var covered := spots().filter(func(cell: Vector2i) -> bool: return not _is_free_floor(cell))
	for cell: Vector2i in covered:
		_spots.erase(cell)
	if not covered.is_empty():
		changed.emit()
