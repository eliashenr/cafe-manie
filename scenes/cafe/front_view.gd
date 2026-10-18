class_name FrontView
extends Node2D
## O que fica na frente do salão (arte v3): a mureta nas duas bordas da frente (a parte de baixo da
## parede, com o mesmo revestimento, baixa para o salão continuar à vista), a porta na entrada, os
## canteiros de flores na grama e os postes da calçada. Nada fica na frente deles, então este nó desenha
## por cima do piso, das paredes e do salão (z_index 1). Sem a arte, não desenha nada.

## Altura da mureta, em pixels de mundo: o lambri da parede, sem tampar o salão.
const FRONT_WALL_HEIGHT := 44.0
## Espessura do acabamento branco no alto da mureta (em pisos).
const CAP_DEPTH := 0.16
const CAP_TOP := Color("ffffff")
const ART_INK := Color("33283a")
const PAINT_LINE := Color("ffd23f")
## Esmaecimento perto de personagens e do piso escolhido (pixels de mundo) e o quanto sobra.
const FADE_RADIUS := 80.0
const FADE_MIN_ALPHA := 0.3
## Canteiros na grama da frente, em frações da largura e da profundidade do grid (mais um recuo em pisos).
const FLOWER_BEDS: Array[Vector3] = [Vector3(0.28, 1.0, 1.6), Vector3(0.74, 1.0, 1.75)]
## Postes na calçada (x a partir da borda da entrada; y em frações do comprimento, mais um recuo em pisos).
const LAMP_X := 1.65
const LAMPS: Array[Vector2] = [Vector2(0.0, -0.8), Vector2(1.0, 0.8)]

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var entrance := CafeGrid.NO_CELL:
	set(value):
		entrance = value
		queue_redraw()

## Revestimento de base da parede e os trechos pintados por cima ({"borda:índice": SurfaceDefinition}).
var wall_style: SurfaceDefinition:
	set(value):
		wall_style = value
		queue_redraw()
var painted: Dictionary = {}:
	set(value):
		painted = value
		queue_redraw()

var _focus := PackedVector2Array()

## Reforma em andamento nos trechos da mureta.
var paint_surface: SurfaceDefinition
var paint_segments: Array[String] = []


func _init() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material = FxMaterials.fade(FADE_RADIUS, FADE_MIN_ALPHA)


## Pontos (no mundo) perto dos quais a mureta fica transparente.
func set_focus(points: PackedVector2Array) -> void:
	if points == _focus:
		return
	_focus = points
	FxMaterials.set_focus(material, points)


func focus_points() -> PackedVector2Array:
	return _focus


func has_art() -> bool:
	return ArtSprites.get_sprite(ArtSprites.exterior().get("lawn", "")) != null


func set_paint_preview(surface: SurfaceDefinition, segments: Array[String]) -> void:
	paint_surface = surface
	paint_segments = segments.duplicate()
	queue_redraw()


func clear_paint_preview() -> void:
	paint_surface = null
	paint_segments = []
	queue_redraw()


## Trechos da mureta (as duas bordas da frente, menos o da porta).
func front_segments() -> Array[String]:
	return CafeStyle.front_wall_segments(grid_size, entrance)


## Revestimento que aparece no trecho (com a reforma em andamento por cima).
func surface_at(wall_segment: String) -> SurfaceDefinition:
	if paint_surface != null and paint_segments.has(wall_segment):
		return paint_surface
	return painted.get(wall_segment, wall_style)


## As duas pontas do trecho na malha: [a da esquerda na tela, a da direita].
func segment_ends(wall_segment: String) -> Array[Vector2]:
	var index := int(wall_segment.get_slice(":", 1))
	var n := Vector2(grid_size)
	if wall_segment.begins_with(CafeStyle.EDGE_BOTTOM):
		return [Vector2(index, n.y), Vector2(index + 1, n.y)]
	return [Vector2(n.x, index + 1), Vector2(n.x, index)]


## Contorno na tela do trecho da mureta.
func segment_polygon(wall_segment: String) -> PackedVector2Array:
	var ends := segment_ends(wall_segment)
	return PackedVector2Array([_at(ends[0]), _at(ends[1]), _at(ends[1], FRONT_WALL_HEIGHT), _at(ends[0], FRONT_WALL_HEIGHT)])


## Trecho da mureta sob este ponto do mundo ("" se nenhum).
func segment_at(world_point: Vector2) -> String:
	for wall_segment in front_segments():
		if Geometry2D.is_point_in_polygon(world_point, segment_polygon(wall_segment)):
			return wall_segment
	return ""


func _draw() -> void:
	if grid_size == Vector2i.ZERO or not has_art():
		return
	var n := Vector2(grid_size)
	_draw_front_walls()
	var items: Array = []
	var info := ArtSprites.exterior()
	var bed := ArtSprites.get_sprite(info.get("flower_bed", ""))
	if bed != null:
		for spot in FLOWER_BEDS:
			items.append([_at(Vector2(n.x * spot.x, n.y * spot.y + spot.z)), bed])
	var lamp := ArtSprites.get_sprite(info.get("lamp", ""))
	if lamp != null:
		for spot in LAMPS:
			items.append([_at(Vector2(n.x + LAMP_X, n.y * spot.x + spot.y)), lamp])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	for item: Array in items:
		var sprite: ArtSprites.Sprite = item[1]
		draw_texture_rect(sprite.texture, sprite.rect_at(item[0]), false)


## A mureta, trecho a trecho, com a parte de baixo do painel da parede, o acabamento branco e a porta.
func _draw_front_walls() -> void:
	for wall_segment in front_segments():
		_draw_low_wall(wall_segment)
	var door := ArtSprites.get_sprite("enfeite_porta_L")
	if door != null and entrance.x == grid_size.x - 1:
		draw_texture_rect(door.texture, door.rect_at(_at(Vector2(grid_size.x, entrance.y + 1))), false)
	for wall_segment in paint_segments:
		var outline := segment_polygon(wall_segment)
		outline.append(outline[0])
		draw_polyline(outline, PAINT_LINE, 2.5, true)


func _draw_low_wall(wall_segment: String) -> void:
	var side := "R" if wall_segment.begins_with(CafeStyle.EDGE_BOTTOM) else "L"
	var surface := surface_at(wall_segment)
	var panel := ArtSprites.wall_panel(surface.id, side) if surface != null else null
	if panel == null and wall_style != null:
		panel = ArtSprites.wall_panel(wall_style.id, side)
	var ends := segment_ends(wall_segment)
	var band := segment_polygon(wall_segment)
	if panel != null:
		# Só a faixa de baixo do painel: o mesmo desenho da parede do fundo, cortado na altura da mureta.
		var rect := panel.rect_at(band[0])
		var uvs := PackedVector2Array()
		for point in band:
			uvs.append((point - rect.position) / rect.size)
		draw_polygon(band, PackedColorArray([Color.WHITE]), uvs, panel.texture)
	var inward := Vector2(0.0, -CAP_DEPTH) if side == "R" else Vector2(-CAP_DEPTH, 0.0)
	var cap := PackedVector2Array([_at(ends[0], FRONT_WALL_HEIGHT), _at(ends[1], FRONT_WALL_HEIGHT),
		_at(ends[1] + inward, FRONT_WALL_HEIGHT), _at(ends[0] + inward, FRONT_WALL_HEIGHT)])
	draw_colored_polygon(cap, CAP_TOP)
	draw_polyline(PackedVector2Array([cap[3], cap[0], cap[1], cap[2]]), ART_INK, 1.2, true)
	draw_line(band[0], band[1], ART_INK, 1.2, true)


func _at(point: Vector2, height := 0.0) -> Vector2:
	return IsoProjection.vertex_to_world(point) - Vector2(0.0, height)
