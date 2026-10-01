class_name FrontView
extends Node2D
## O que fica na frente do salão (arte v3): a cerquinha branca nas duas bordas da
## frente, com uma abertura no caminho da entrada, os canteiros de flores na grama
## e os postes da calçada. Nada fica na frente deles, então este nó desenha por
## cima do piso, das paredes e do salão (z_index 1). Sem a arte, não desenha nada.

## Distância da cerca até a borda do piso, em pisos.
const FENCE_OFFSET := 0.55
## Estacas por piso de cerca.
const POSTS_PER_CELL := 4
## Medidas da estaca e das duas travessas, em pixels de mundo (as do canvas, na escala do jogo).
const POST_HALF_WIDTH := 3.66
const POST_HEIGHT := 30.5
const POST_TIP := 36.6
const RAIL_HEIGHTS: Array[float] = [10.7, 22.9]
const RAIL_WIDTH := 4.9
const POST_LIGHT := Color("ffffff")
const POST_SHADE := Color("dfe6ee")
const RAIL_SHADOW := Color("c9d2dc")
const ART_INK := Color("33283a")
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


func _init() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func has_art() -> bool:
	return ArtSprites.get_sprite(ArtSprites.exterior().get("lawn", "")) != null


func _draw() -> void:
	if grid_size == Vector2i.ZERO or not has_art():
		return
	var n := Vector2(grid_size)
	for segment: Array in fence_segments():
		_draw_fence(segment[0], segment[1])
	var items: Array = []
	var info := ArtSprites.exterior()
	var bed := ArtSprites.get_sprite(info.get("flower_bed", ""))
	if bed != null:
		for spot in FLOWER_BEDS:
			items.append([_at(Vector2(n.x * spot.x, n.y * spot.y + spot.z)), bed])
	var lamp := ArtSprites.get_sprite(info.get("lamp", ""))
	if lamp != null:
		for spot in LAMPS:
			items.append([_at(Vector2(n.x + FENCE_OFFSET + LAMP_X, n.y * spot.x + spot.y)), lamp])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	for item: Array in items:
		var sprite: ArtSprites.Sprite = item[1]
		draw_texture_rect(sprite.texture, sprite.rect_at(item[0]), false)


## Trechos de cerca, cada um [de, até] em pisos: a borda da frente à esquerda (y fixo)
## inteira e a da direita (x fixo) aberta na fileira da entrada, por onde passa o caminho.
func fence_segments() -> Array:
	var edge := Vector2(grid_size) + Vector2(FENCE_OFFSET, FENCE_OFFSET)
	var segments: Array = [[Vector2(-0.3, edge.y), Vector2(edge.x, edge.y)]]
	if entrance.x == grid_size.x - 1:
		segments.append([Vector2(edge.x, -0.3), Vector2(edge.x, entrance.y - 0.02)])
		segments.append([Vector2(edge.x, entrance.y + 1.02), Vector2(edge.x, edge.y)])
	else:
		segments.append([Vector2(edge.x, -0.3), Vector2(edge.x, edge.y)])
	return segments


func _at(point: Vector2, height := 0.0) -> Vector2:
	return IsoProjection.vertex_to_world(point) - Vector2(0.0, height)


## Cerca de estacas pontudas com duas travessas, de [param from] até [param to] (em pisos).
func _draw_fence(from: Vector2, to: Vector2) -> void:
	var length := from.distance_to(to)
	if length <= 0.0:
		return
	var count := maxi(int(length * POSTS_PER_CELL), 1)
	for i in count + 1:
		var base := _at(from.lerp(to, float(i) / count))
		var w := POST_HALF_WIDTH
		var post := PackedVector2Array([base + Vector2(-w, 0.0), base + Vector2(-w, -POST_HEIGHT), base + Vector2(0.0, -POST_TIP),
			base + Vector2(w, -POST_HEIGHT), base + Vector2(w, 0.0)])
		draw_polygon(post, PackedColorArray([POST_LIGHT, POST_LIGHT, POST_LIGHT, POST_SHADE, POST_SHADE]))
		var closed := post.duplicate()
		closed.append(post[0])
		draw_polyline(closed, ART_INK, 1.2, true)
	for height in RAIL_HEIGHTS:
		var a := _at(from, height)
		var b := _at(to, height)
		draw_line(a, b, POST_LIGHT, RAIL_WIDTH, true)
		draw_line(a + Vector2(0.0, 2.4), b + Vector2(0.0, 2.4), RAIL_SHADOW, 1.5, true)
