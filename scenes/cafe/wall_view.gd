class_name WallView
extends Node2D
## Paredes do fundo com a arte v3 (ArtSprites): um painel do revestimento por
## célula, enfeites (janelas, quadros, relógio, prateleira), acabamento branco no
## alto e nas pontas, sombra junto à parede e a luz das janelas no chão.
## Revestimento sem arte cai no PLACEHOLDER_WALL, desenhado por código.
##
## A cafeteria tem duas paredes, nas bordas de trás do grid (a da coluna x = 0
## e a da linha y = 0). Elas ficam atrás de todos os móveis, então este nó é
## desenhado antes do WorldLayer.

## Altura da parede, em pixels de mundo. Com arte, vale a altura da arte.
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

## Espessura da parede vista de cima (em pisos) e cores do acabamento da arte v3.
const CAP_DEPTH := 0.16
const CAP_RIGHT := Color("ffffff")
const CAP_LEFT := Color("f3f6fa")
const END_RIGHT := Color("e6ebf2")
const END_LEFT := Color("dfe5ee")
const ART_INK := Color("33283a")
## Sombra no chão junto às paredes: até onde vai (em pisos) e a cor no pé da parede.
const FLOOR_SHADOW_REACH := 0.45
const FLOOR_SHADOW := Color(0.227, 0.165, 0.102, 0.21)
## Luz de cada janela no chão (como no canvas): cor, até onde entra e quanto escorrega (em pisos).
const WINDOW_LIGHT := Color(1.0, 0.984, 0.878, 0.35)
const WINDOW_LIGHT_REACH := 2.6
const WINDOW_LIGHT_SHIFT := 1.8


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var art_height := ArtSprites.wall_height()
	if art_height > 0.0:
		wall_height = art_height


## Há arte para o revestimento atual?
func has_art() -> bool:
	return wall_style != null and ArtSprites.wall_panel(wall_style.id, "R") != null \
		and ArtSprites.wall_panel(wall_style.id, "L") != null


func _draw() -> void:
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	if has_art():
		_draw_art_walls()
		return
	var top := IsoProjection.cell_top_vertex(Vector2i.ZERO)
	# Parede da esquerda: ao longo da coluna x = 0 (desce para a esquerda).
	var left_end := IsoProjection.cell_top_vertex(Vector2i(0, grid_size.y))
	_draw_wall(left_end, top, left_shade)
	# Parede da direita: ao longo da linha y = 0 (desce para a direita).
	var right_end := IsoProjection.cell_top_vertex(Vector2i(grid_size.x, 0))
	_draw_wall(top, right_end, 0.0)


## Sombra e luz no chão, painéis, enfeites e acabamento.
func _draw_art_walls() -> void:
	_draw_floor_light()
	var right := ArtSprites.wall_panel(wall_style.id, "R")
	var left := ArtSprites.wall_panel(wall_style.id, "L")
	for y in grid_size.y:
		draw_texture_rect(left.texture, left.rect_at(_left_anchor(y)), false)
	for x in grid_size.x:
		draw_texture_rect(right.texture, right.rect_at(_right_anchor(x)), false)
	for y in grid_size.y:
		var deco := ArtSprites.wall_decoration("L", y)
		if deco != null:
			draw_texture_rect(deco.texture, deco.rect_at(_left_anchor(y)), false)
	for x in grid_size.x:
		var deco := ArtSprites.wall_decoration("R", x)
		if deco != null:
			draw_texture_rect(deco.texture, deco.rect_at(_right_anchor(x)), false)
	_draw_caps()


## Ponta de baixo à esquerda (na tela) do painel da célula [param y] da parede da esquerda.
func _left_anchor(y: int) -> Vector2:
	return IsoProjection.cell_top_vertex(Vector2i(0, y + 1))


## Ponta de baixo à esquerda do painel da célula [param x] da parede da direita.
func _right_anchor(x: int) -> Vector2:
	return IsoProjection.cell_top_vertex(Vector2i(x, 0))


## Ponto da malha erguido [param height] pixels (z para cima).
func _at(point: Vector2, height := 0.0) -> Vector2:
	return IsoProjection.vertex_to_world(point) - Vector2(0.0, height)


func _draw_floor_light() -> void:
	var n := Vector2(grid_size)
	var reach := FLOOR_SHADOW_REACH
	var clear := Color(FLOOR_SHADOW, 0.0)
	draw_polygon(PackedVector2Array([_at(Vector2.ZERO), _at(Vector2(n.x, 0.0)), _at(Vector2(n.x, reach)),
		_at(Vector2(reach, reach))]), PackedColorArray([FLOOR_SHADOW, FLOOR_SHADOW, clear, clear]))
	draw_polygon(PackedVector2Array([_at(Vector2.ZERO), _at(Vector2(reach, reach)), _at(Vector2(reach, n.y)),
		_at(Vector2(0.0, n.y))]), PackedColorArray([FLOOR_SHADOW, clear, clear, FLOOR_SHADOW]))
	# A janela ocupa o meio da célula (como na arte); a luz entra em diagonal e para no fim do piso.
	for x in grid_size.x:
		if ArtSprites.wall_decoration_name("R", x) == "janela":
			var a := x + 0.21
			var b := x + 0.79
			_draw_light(PackedVector2Array([Vector2(a + 0.4, 0.05), Vector2(b + 0.4, 0.05),
				Vector2(b + 0.4 + WINDOW_LIGHT_SHIFT, WINDOW_LIGHT_REACH),
				Vector2(a + 0.4 + WINDOW_LIGHT_SHIFT, WINDOW_LIGHT_REACH)]), n)
	for y in grid_size.y:
		if ArtSprites.wall_decoration_name("L", y) == "janela":
			var a := y + 0.21
			var b := y + 0.79
			_draw_light(PackedVector2Array([Vector2(0.05, a + 0.4), Vector2(0.05, b + 0.4),
				Vector2(WINDOW_LIGHT_REACH, b + 0.4 + WINDOW_LIGHT_SHIFT),
				Vector2(WINDOW_LIGHT_REACH, a + 0.4 + WINDOW_LIGHT_SHIFT)]), n)


## Mancha de luz em pisos, cortada na borda do piso.
func _draw_light(points: PackedVector2Array, n: Vector2) -> void:
	var world := PackedVector2Array()
	for point in points:
		world.append(_at(Vector2(minf(point.x, n.x), minf(point.y, n.y))))
	draw_colored_polygon(world, WINDOW_LIGHT)


## Espessura branca no alto das paredes e as duas pontas da frente.
func _draw_caps() -> void:
	var n := Vector2(grid_size)
	var h := wall_height
	var t := CAP_DEPTH
	var right_cap := PackedVector2Array([_at(Vector2(-t, -t), h), _at(Vector2(n.x, -t), h), _at(Vector2(n.x, 0.0), h),
		_at(Vector2.ZERO, h)])
	var left_cap := PackedVector2Array([_at(Vector2(-t, -t), h), _at(Vector2.ZERO, h), _at(Vector2(0.0, n.y), h),
		_at(Vector2(-t, n.y), h)])
	var right_end := PackedVector2Array([_at(Vector2(n.x, -t)), _at(Vector2(n.x, 0.0)), _at(Vector2(n.x, 0.0), h),
		_at(Vector2(n.x, -t), h)])
	var left_end := PackedVector2Array([_at(Vector2(-t, n.y)), _at(Vector2(0.0, n.y)), _at(Vector2(0.0, n.y), h),
		_at(Vector2(-t, n.y), h)])
	for piece: Array in [[right_end, END_RIGHT], [left_end, END_LEFT], [right_cap, CAP_RIGHT], [left_cap, CAP_LEFT]]:
		var polygon: PackedVector2Array = piece[0]
		draw_colored_polygon(polygon, piece[1])
		var closed := polygon.duplicate()
		closed.append(polygon[0])
		draw_polyline(closed, ART_INK, 1.5, true)


## PLACEHOLDER_WALL: uma parede com base de [param from] até [param to] (da esquerda para a direita na tela).
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
