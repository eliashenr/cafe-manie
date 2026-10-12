class_name CafeStyle
extends RefCounted
## Revestimentos da cafeteria: o piso e a parede de base (que cobrem tudo) e o que o jogador pintou
## por cima, piso a piso e trecho a trecho de parede.
##
## Trecho de parede: "borda:índice". As paredes do fundo são "top" (ao longo de x, na borda y = 0) e
## "left" (ao longo de y, na borda x = 0); as da frente, baixas, são "bottom" (ao longo de x) e "right"
## (ao longo de y, onde fica a porta). O índice é a célula ao longo da borda.
## Itens de parede (janela, TV...) ficam um por trecho, só nas paredes do fundo.
## Revestimentos "possuídos" foram comprados inteiros antes da pintura por célula (saves antigos) e
## continuam pintando de graça.

signal changed

const EDGE_TOP := "top"
const EDGE_LEFT := "left"
const EDGE_BOTTOM := "bottom"
const EDGE_RIGHT := "right"

var floor_id: StringName = &""
var wall_id: StringName = &""
var _owned: Dictionary = {}  # StringName -> true
var _floor_cells: Dictionary = {}  # Vector2i -> StringName (só o que difere da base)
var _wall_cells: Dictionary = {}  # String "borda:índice" -> StringName (só o que difere da base)
var _wall_items: Dictionary = {}  # String "borda:índice" -> id do item pendurado


static func segment(edge: String, index: int) -> String:
	return "%s:%d" % [edge, index]


## Trechos das paredes do fundo de uma cafeteria deste tamanho.
static func back_wall_segments(grid_size: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for x in grid_size.x:
		result.append(segment(EDGE_TOP, x))
	for y in grid_size.y:
		result.append(segment(EDGE_LEFT, y))
	return result


## Trechos da mureta da frente (sem o da porta, que fica na borda "right", na fileira da entrada).
static func front_wall_segments(grid_size: Vector2i, entrance: Vector2i) -> Array[String]:
	var result: Array[String] = []
	for x in grid_size.x:
		result.append(segment(EDGE_BOTTOM, x))
	for y in grid_size.y:
		if not (entrance.x == grid_size.x - 1 and entrance.y == y):
			result.append(segment(EDGE_RIGHT, y))
	return result


func owns(id: StringName) -> bool:
	return _owned.has(id)


func own(id: StringName) -> void:
	if not _owned.has(id):
		_owned[id] = true
		changed.emit()


func owned() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_owned.keys())
	result.sort()
	return result


## Revestimento de base de um tipo (o que cobre o que não foi pintado).
func current(kind: SurfaceDefinition.Kind) -> StringName:
	return floor_id if kind == SurfaceDefinition.Kind.FLOOR else wall_id


func floor_at(cell: Vector2i) -> StringName:
	return _floor_cells.get(cell, floor_id)


func wall_at(wall_segment: String) -> StringName:
	return _wall_cells.get(wall_segment, wall_id)


## Pisos pintados por cima da base: {Vector2i: id}.
func painted_floor() -> Dictionary:
	return _floor_cells.duplicate()


## Trechos de parede pintados por cima da base: {"borda:índice": id}.
func painted_walls() -> Dictionary:
	return _wall_cells.duplicate()


## Item pendurado no trecho (&"" se nenhum).
func wall_item_at(wall_segment: String) -> StringName:
	return _wall_items.get(wall_segment, &"")


## Itens pendurados: {"borda:índice": id}.
func hung_items() -> Dictionary:
	return _wall_items.duplicate()


## Pendura o item nestes trechos (quem paga é a simulação); &"" tira o que estiver lá.
func hang(segments: Array[String], id: StringName) -> void:
	for wall_segment in segments:
		if id == &"":
			_wall_items.erase(wall_segment)
		else:
			_wall_items[wall_segment] = id
	changed.emit()


## Pinta estes pisos (quem paga é a simulação). Pintar com a base só apaga a pintura.
func paint_floor(cells: Array[Vector2i], id: StringName) -> void:
	for cell in cells:
		if id == floor_id:
			_floor_cells.erase(cell)
		else:
			_floor_cells[cell] = id
	changed.emit()


func paint_walls(segments: Array[String], id: StringName) -> void:
	for wall_segment in segments:
		if id == wall_id:
			_wall_cells.erase(wall_segment)
		else:
			_wall_cells[wall_segment] = id
	changed.emit()


## Aplica um revestimento que o jogador já possui na cafeteria inteira (vira a base e apaga a pintura).
func apply(definition: SurfaceDefinition) -> bool:
	if not owns(definition.id):
		return false
	if definition.kind == SurfaceDefinition.Kind.FLOOR:
		floor_id = definition.id
		_floor_cells.clear()
	else:
		wall_id = definition.id
		_wall_cells.clear()
	changed.emit()
	return true


func to_data() -> Dictionary:
	var floor_cells := []
	for cell: Vector2i in _floor_cells:
		floor_cells.append([cell.x, cell.y, String(_floor_cells[cell])])
	var wall_cells := []
	for wall_segment: String in _wall_cells:
		wall_cells.append([wall_segment, String(_wall_cells[wall_segment])])
	var wall_items := []
	for wall_segment: String in _wall_items:
		wall_items.append([wall_segment, String(_wall_items[wall_segment])])
	return {"floor": String(floor_id), "wall": String(wall_id), "owned": owned().map(func(id: StringName) -> String: return String(id)),
		"floor_cells": floor_cells, "wall_cells": wall_cells, "wall_items": wall_items}


func restore(data: Dictionary) -> void:
	_owned.clear()
	for id in data.get("owned", []):
		_owned[StringName(str(id))] = true
	floor_id = StringName(str(data.get("floor", "")))
	wall_id = StringName(str(data.get("wall", "")))
	_floor_cells.clear()
	for entry in data.get("floor_cells", []):
		if entry is Array and entry.size() == 3:
			_floor_cells[Vector2i(int(entry[0]), int(entry[1]))] = StringName(str(entry[2]))
	_wall_cells.clear()
	for entry in data.get("wall_cells", []):
		if entry is Array and entry.size() == 2:
			_wall_cells[str(entry[0])] = StringName(str(entry[1]))
	_wall_items.clear()
	for entry in data.get("wall_items", []):
		if entry is Array and entry.size() == 2:
			_wall_items[str(entry[0])] = StringName(str(entry[1]))
	changed.emit()
