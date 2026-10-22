class_name FrontView
extends Node2D
## O que fica na frente do salão (arte v3): a mureta nas duas bordas da frente (a parte de baixo da
## parede, com o mesmo revestimento, baixa para o salão continuar à vista) e a porta na entrada. Ela
## desenha por cima do piso, das paredes e do salão (z_index 1). Os enfeites da calçada são da cidade
## (StreetView, DT-048). Sem a arte, não desenha nada.

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

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var entrance := CafeGrid.NO_CELL:
	set(value):
		entrance = value
		queue_redraw()

## Café fechado: a plaquinha da porta diz FECHADO em vez de ABERTO (DT-051).
var closed := false:
	set(value):
		closed = value
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
	_draw_front_walls()


## A mureta, trecho a trecho, com a parte de baixo do painel da parede, o acabamento branco e a porta.
func _draw_front_walls() -> void:
	for wall_segment in front_segments():
		_draw_low_wall(wall_segment)
	var door := ArtSprites.get_sprite(door_sprite_name())
	if door != null and entrance.x == grid_size.x - 1:
		draw_texture_rect(door.texture, door.rect_at(_at(Vector2(grid_size.x, entrance.y + 1))), false)
	for wall_segment in paint_segments:
		var outline := segment_polygon(wall_segment)
		outline.append(outline[0])
		draw_polyline(outline, PAINT_LINE, 2.5, true)


## Desenho da porta: com a plaquinha ABERTO ou FECHADO.
func door_sprite_name() -> String:
	return "enfeite_porta_fechada_L" if closed else "enfeite_porta_L"


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
