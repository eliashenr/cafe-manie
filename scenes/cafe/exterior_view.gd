class_name ExteriorView
extends Node2D
## Fora da cafeteria, atrás de tudo (arte v3): gramado, a calçada e a rua do lado
## da entrada e o caminho de pedras até a porta. O que fica na frente do salão
## (cerca, canteiros, postes) é o FrontView. Sem a arte, não desenha nada.
##
## As faixas são medidas em pisos a partir da borda da entrada (x = largura do grid).

## Até onde o gramado vai em volta da cafeteria, em pixels de mundo.
const LAWN_REACH := 4000.0
## Comprimento da calçada e da rua para cada lado, em pisos.
const ROAD_REACH := 40.0
const PATH_END := 1.4
const SIDEWALK_END := 3.2
const STREET_END := 7.6
const CURB_WIDTH := 0.14
const CURB_HEIGHT := 6.0
const PATH_WIDTH := 0.7

const SIDEWALK := Color("efe9df")
const SIDEWALK_LINE := Color("d3cabd")
const CURB_TOP := Color("e6ebf0")
const CURB_SIDE := Color("c9d0d8")
const ROAD_MARK := Color("ffffff")
const PATH_STONE := Color("f4efe6")
const PATH_LINE := Color("cfc4b4")
const ART_INK := Color("33283a")

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var entrance := CafeGrid.NO_CELL:
	set(value):
		entrance = value
		queue_redraw()


func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Há arte do exterior?
func has_art() -> bool:
	return ArtSprites.get_sprite(ArtSprites.exterior().get("lawn", "")) != null


func _draw() -> void:
	if grid_size == Vector2i.ZERO or not has_art():
		return
	var info := ArtSprites.exterior()
	var center := IsoProjection.vertex_to_world(Vector2(grid_size) / 2.0)
	var reach := Vector2(LAWN_REACH, LAWN_REACH)
	var lawn := PackedVector2Array([center - reach, center + Vector2(reach.x, -reach.y), center + reach,
		center + Vector2(-reach.x, reach.y)])
	_draw_tiled(lawn, ArtSprites.get_sprite(info["lawn"]).texture, float(info.get("lawn_world", 128.0)))
	var n := float(grid_size.x)
	var asphalt := ArtSprites.get_sprite(info.get("asphalt", ""))
	if asphalt != null:
		_draw_tiled(_band(n + SIDEWALK_END, n + STREET_END), asphalt.texture, float(info.get("asphalt_world", 64.0)))
		_draw_road_marks(n + (SIDEWALK_END + STREET_END) / 2.0)
	_draw_sidewalk(n)
	_draw_path(n)


## Faixa ao longo do grid, de x0 a x1 (em pisos), com ROAD_REACH para cada lado.
func _band(x0: float, x1: float) -> PackedVector2Array:
	var y0 := -ROAD_REACH
	var y1 := float(grid_size.y) + ROAD_REACH
	return PackedVector2Array([_at(Vector2(x0, y0)), _at(Vector2(x1, y0)), _at(Vector2(x1, y1)), _at(Vector2(x0, y1))])


func _at(point: Vector2, height := 0.0) -> Vector2:
	return IsoProjection.vertex_to_world(point) - Vector2(0.0, height)


## Polígono com uma textura de repetir (período em pixels de mundo).
func _draw_tiled(points: PackedVector2Array, texture: Texture2D, period: float) -> void:
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / period)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)


## Faixa branca tracejada no meio da rua.
func _draw_road_marks(x: float) -> void:
	var y := -ROAD_REACH
	while y < grid_size.y + ROAD_REACH:
		draw_line(_at(Vector2(x, y + 0.1)), _at(Vector2(x, y + 0.6)), ROAD_MARK, 4.9, true)
		y += 1.0


## Calçada de placas claras e o meio-fio do lado da rua.
func _draw_sidewalk(n: float) -> void:
	draw_colored_polygon(_band(n + PATH_END, n + SIDEWALK_END), SIDEWALK)
	var y := -ROAD_REACH
	while y <= grid_size.y + ROAD_REACH:
		draw_line(_at(Vector2(n + PATH_END, y)), _at(Vector2(n + SIDEWALK_END, y)), SIDEWALK_LINE, 1.5, true)
		y += 1.0
	var middle := n + (PATH_END + SIDEWALK_END) / 2.0
	draw_line(_at(Vector2(middle, -ROAD_REACH)), _at(Vector2(middle, grid_size.y + ROAD_REACH)), SIDEWALK_LINE, 1.5, true)
	var curb_x := n + SIDEWALK_END
	var y0 := -ROAD_REACH
	var y1 := float(grid_size.y) + ROAD_REACH
	var side := PackedVector2Array([_at(Vector2(curb_x, y0)), _at(Vector2(curb_x, y1)), _at(Vector2(curb_x, y1), -CURB_HEIGHT),
		_at(Vector2(curb_x, y0), -CURB_HEIGHT)])
	draw_colored_polygon(side, CURB_SIDE)
	var top := PackedVector2Array([_at(Vector2(curb_x - CURB_WIDTH, y0)), _at(Vector2(curb_x, y0)), _at(Vector2(curb_x, y1)),
		_at(Vector2(curb_x - CURB_WIDTH, y1))])
	draw_colored_polygon(top, CURB_TOP)
	draw_line(_at(Vector2(curb_x, y0)), _at(Vector2(curb_x, y1)), ART_INK, 1.0, true)


## Caminho de pedras da calçada até a entrada.
func _draw_path(n: float) -> void:
	if entrance == CafeGrid.NO_CELL:
		return
	var y0 := entrance.y + (1.0 - PATH_WIDTH) / 2.0
	var y1 := y0 + PATH_WIDTH
	var stones := 3
	for i in stones:
		var x0 := n + PATH_END * float(i) / stones + 0.04
		var x1 := n + PATH_END * float(i + 1) / stones - 0.04
		var stone := PackedVector2Array([_at(Vector2(x0, y0)), _at(Vector2(x1, y0)), _at(Vector2(x1, y1)), _at(Vector2(x0, y1))])
		draw_colored_polygon(stone, PATH_STONE)
		var closed := stone.duplicate()
		closed.append(stone[0])
		draw_polyline(closed, PATH_LINE, 1.5, true)
