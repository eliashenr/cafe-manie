class_name FloorView
extends Node2D
## PLACEHOLDER_FLOOR: piso desenhado por código até existir arte final.
##
## Só desenha. Não guarda regra de jogo; recebe do dono da cena o tamanho
## do grid, a entrada, a célula selecionada e a prévia de construção.

const COLOR_TILE_A := Color("e9d6b8")
const COLOR_TILE_B := Color("dcc5a0")
const COLOR_TILE_LINE := Color(0.36, 0.25, 0.15, 0.35)
## Tábuas por piso no padrão PLANKS.
const PLANKS_PER_TILE := 3
const COLOR_ENTRANCE := Color("8fb8c9")
const COLOR_ENTRANCE_MARK := Color(0.1, 0.2, 0.28, 0.85)
const COLOR_SELECTED_FILL := Color(1.0, 0.82, 0.3, 0.5)
const COLOR_SELECTED_LINE := Color("f29f1f")
const COLOR_PREVIEW_VALID := Color(0.3, 0.8, 0.35, 0.45)
const COLOR_PREVIEW_INVALID := Color(0.9, 0.25, 0.2, 0.45)

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var entrance := CafeGrid.NO_CELL:
	set(value):
		entrance = value
		queue_redraw()

## Revestimento do piso (padrão e cores). Sem ele, xadrez bege.
var floor_style: SurfaceDefinition:
	set(value):
		floor_style = value
		queue_redraw()

var selected_cell := CafeGrid.NO_CELL:
	set(value):
		selected_cell = value
		queue_redraw()

var _preview_cells: Array[Vector2i] = []
var _preview_valid := false


## Pinta as células que o móvel em construção ocuparia (verde ou vermelho).
func set_preview(cells: Array[Vector2i], valid: bool) -> void:
	_preview_cells = cells
	_preview_valid = valid
	queue_redraw()


func clear_preview() -> void:
	_preview_cells = []
	queue_redraw()


func preview_cells() -> Array[Vector2i]:
	return _preview_cells


func _draw() -> void:
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			if cell == entrance:
				var polygon := IsoProjection.cell_polygon(cell)
				draw_colored_polygon(polygon, COLOR_ENTRANCE)
				draw_polyline(_closed(polygon), COLOR_TILE_LINE, 1.0, true)
			else:
				_draw_tile(cell)

	if _is_inside(entrance):
		_draw_entrance_arrow()

	var preview_color := COLOR_PREVIEW_VALID if _preview_valid else COLOR_PREVIEW_INVALID
	for cell in _preview_cells:
		if _is_inside(cell):
			draw_colored_polygon(IsoProjection.cell_polygon(cell), preview_color)

	if _is_inside(selected_cell):
		var polygon := IsoProjection.cell_polygon(selected_cell)
		draw_colored_polygon(polygon, COLOR_SELECTED_FILL)
		draw_polyline(_closed(polygon), COLOR_SELECTED_LINE, 3.0, true)


## PLACEHOLDER_SURFACE: um piso no padrão do revestimento.
func _draw_tile(cell: Vector2i) -> void:
	var polygon := IsoProjection.cell_polygon(cell)
	var pattern := SurfaceDefinition.Pattern.CHECKER
	var color_a := COLOR_TILE_A
	var color_b := COLOR_TILE_B
	if floor_style != null:
		pattern = floor_style.pattern
		color_a = floor_style.color_a
		color_b = floor_style.color_b
	match pattern:
		SurfaceDefinition.Pattern.PLANKS:
			# Tábuas correndo ao longo do eixo x, com leve variação de tom.
			var shade := 0.04 * float((cell.x * 7 + cell.y * 3) % 3)
			draw_colored_polygon(polygon, color_a.darkened(shade))
			var top := polygon[0]
			var left := polygon[3]
			var along := polygon[1] - polygon[0]
			for i in range(1, PLANKS_PER_TILE):
				var start := top.lerp(left, float(i) / PLANKS_PER_TILE)
				draw_line(start, start + along, color_b, 1.5, true)
			draw_polyline(_closed(polygon), color_b, 1.5, true)
		SurfaceDefinition.Pattern.TILES:
			draw_colored_polygon(polygon, color_a)
			var inner := PackedVector2Array()
			var center := IsoProjection.cell_center(cell)
			for point in polygon:
				inner.append(center + (point - center) * 0.5)
			draw_polyline(_closed(inner), color_a.darkened(0.08), 1.0, true)
			draw_polyline(_closed(polygon), color_b, 3.0, true)
		_:
			draw_colored_polygon(polygon, color_a if (cell.x + cell.y) % 2 == 0 else color_b)
			draw_polyline(_closed(polygon), COLOR_TILE_LINE, 1.0, true)


## Seta apontando para dentro da cafeteria, entrando pela borda da frente.
func _draw_entrance_arrow() -> void:
	var center := IsoProjection.cell_center(entrance)
	var inward := (IsoProjection.cell_center(entrance - Vector2i(1, 0)) - center).normalized()
	var side := Vector2(-inward.y, inward.x)
	var tip := center + inward * 18.0
	var tail := center - inward * 14.0
	draw_line(tail, tip, COLOR_ENTRANCE_MARK, 4.0, true)
	draw_colored_polygon(PackedVector2Array([
		tip + inward * 8.0, tip - inward * 4.0 + side * 9.0, tip - inward * 4.0 - side * 9.0,
	]), COLOR_ENTRANCE_MARK)


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var result := polygon.duplicate()
	result.append(polygon[0])
	return result
