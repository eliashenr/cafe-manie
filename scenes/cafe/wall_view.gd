class_name WallView
extends Node2D
## PLACEHOLDER_WALL: paredes do fundo desenhadas por código até existir arte final.
##
## A cafeteria tem duas paredes, nas bordas de trás do grid (a da coluna x = 0
## e a da linha y = 0). Elas ficam atrás de todos os móveis, então este nó é
## desenhado antes do WorldLayer.

## Altura da parede, em pixels de mundo.
@export var wall_height := 110.0
## Altura do rodapé, em pixels de mundo.
@export var baseboard_height := 10.0
## Quanto a parede da esquerda fica mais escura (luz vindo da direita).
@export_range(0.0, 0.5) var left_shade := 0.12

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var wall_style: SurfaceDefinition:
	set(value):
		wall_style = value
		queue_redraw()


func _draw() -> void:
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	var top := IsoProjection.cell_top_vertex(Vector2i.ZERO)
	# Parede da esquerda: ao longo da coluna x = 0 (desce para a esquerda).
	var left_end := IsoProjection.cell_top_vertex(Vector2i(0, grid_size.y))
	_draw_wall(left_end, top, left_shade)
	# Parede da direita: ao longo da linha y = 0 (desce para a direita).
	var right_end := IsoProjection.cell_top_vertex(Vector2i(grid_size.x, 0))
	_draw_wall(top, right_end, 0.0)


## Uma parede com base de [param from] até [param to] (da esquerda para a direita na tela).
func _draw_wall(from: Vector2, to: Vector2, shade: float) -> void:
	var up := Vector2(0.0, -wall_height)
	var color_a := wall_style.color_a if wall_style != null else Color("f5e6c7")
	var color_b := wall_style.color_b if wall_style != null else Color("9e734d")
	var pattern := wall_style.pattern if wall_style != null else SurfaceDefinition.Pattern.PLAIN
	var face := PackedVector2Array([from, to, to + up, from + up])
	draw_colored_polygon(face, color_a.darkened(shade))

	match pattern:
		SurfaceDefinition.Pattern.BRICK:
			_draw_bricks(from, to, up, color_b.darkened(shade))
		SurfaceDefinition.Pattern.STRIPES:
			_draw_stripes(from, to, up, color_b.darkened(shade))

	var board := Vector2(0.0, -baseboard_height)
	var trim := color_b.darkened(0.3 + shade) if pattern != SurfaceDefinition.Pattern.PLAIN else color_b.darkened(shade)
	draw_colored_polygon(PackedVector2Array([from, to, to + board, from + board]), trim)
	draw_line(from + up, to + up, trim, 3.0, true)


## Fiadas de tijolos seguindo a inclinação da parede.
func _draw_bricks(from: Vector2, to: Vector2, up: Vector2, mortar: Color) -> void:
	var rows := 9
	var along := to - from
	var bricks_per_row := maxi(int(along.length() / 26.0), 1)
	for row in rows:
		var t0 := float(row) / rows
		var t1 := float(row + 1) / rows
		draw_line(from + up * t1, to + up * t1, mortar, 1.5, true)
		var offset := 0.5 if row % 2 == 1 else 0.0
		for i in bricks_per_row:
			var s := (float(i) + offset) / bricks_per_row
			if s <= 0.0 or s >= 1.0:
				continue
			var base := from + along * s
			draw_line(base + up * t0, base + up * t1, mortar, 1.5, true)


## Listras verticais.
func _draw_stripes(from: Vector2, to: Vector2, up: Vector2, stripe: Color) -> void:
	var along := to - from
	var count := maxi(int(along.length() / 22.0), 2)
	for i in count:
		if i % 2 == 0:
			continue
		var a := from + along * (float(i) / count)
		var b := from + along * (float(i + 1) / count)
		draw_colored_polygon(PackedVector2Array([a, b, b + up, a + up]), stripe)
