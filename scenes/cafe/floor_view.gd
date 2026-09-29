class_name FloorView
extends Node2D
## PLACEHOLDER_FLOOR: piso desenhado por código até existir arte final.
##
## Só desenha. Não guarda regra de jogo; recebe do dono da cena o tamanho
## do grid e a célula selecionada.

const COLOR_TILE_A := Color("e9d6b8")
const COLOR_TILE_B := Color("dcc5a0")
const COLOR_TILE_LINE := Color(0.36, 0.25, 0.15, 0.35)
const COLOR_SELECTED_FILL := Color(1.0, 0.82, 0.3, 0.5)
const COLOR_SELECTED_LINE := Color("f29f1f")

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var selected_cell := CafeGrid.NO_CELL:
	set(value):
		selected_cell = value
		queue_redraw()


func _draw() -> void:
	for y in grid_size.y:
		for x in grid_size.x:
			var cell := Vector2i(x, y)
			var polygon := IsoProjection.cell_polygon(cell)
			var fill := COLOR_TILE_A if (x + y) % 2 == 0 else COLOR_TILE_B
			draw_colored_polygon(polygon, fill)
			draw_polyline(_closed(polygon), COLOR_TILE_LINE, 1.0, true)

	if _is_inside(selected_cell):
		var polygon := IsoProjection.cell_polygon(selected_cell)
		draw_colored_polygon(polygon, COLOR_SELECTED_FILL)
		draw_polyline(_closed(polygon), COLOR_SELECTED_LINE, 3.0, true)


func _is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func _closed(polygon: PackedVector2Array) -> PackedVector2Array:
	var result := polygon.duplicate()
	result.append(polygon[0])
	return result
