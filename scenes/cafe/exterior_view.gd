class_name ExteriorView
extends Node2D
## A cidade em volta do café (DT-048), atrás de tudo: o chão de concreto, as duas ruas da esquina com as
## faixas pintadas e o cruzamento, as calçadas, o parque do outro lado das ruas, os arranha-céus ao longe
## e os prédios atrás do café. O que fica na frente da mureta (enfeites da calçada, semáforos e carros)
## é o StreetView. Sem a arte da cidade, não desenha nada.
##
## Medidas em vértices do grid, as mesmas do CityPlan.

## Até onde o chão vai em volta do café, em pisos.
const GROUND_REACH := 60.0
const CURB_WIDTH := 0.14
const CURB_HEIGHT := 6.0
const PATH_END := 1.4
const PATH_WIDTH := 0.7
## Faixas pintadas: a linha amarela dupla (meia distância entre as duas e a grossura de cada uma, em
## pisos e em pixels), a faixa de pedestre (largura, listras) e a faixa de parada.
const YELLOW_GAP := 0.06
const YELLOW_WIDTH := 2.6
const CROSSWALK_WIDTH := 0.8
const CROSSWALK_GAP := 0.1
const ZEBRA_STRIPE := 0.22
const ZEBRA_STEP := 0.44
const STOP_LINE := 0.12

## Calçadas de concreto frio, cinza-azulado (Nova York, DT-080).
const SIDEWALK := Color("e1e5ea")
const SIDEWALK_LINE := Color("c3c9d2")
const FAR_SIDEWALK := Color("d6dbe2")
const CURB_TOP := Color("e8ecf1")
const CURB_SIDE := Color("b9c1cc")
const ROAD_YELLOW := Color("ffcf3f")
const ROAD_WHITE := Color(1, 1, 1, 0.92)
const PATH_STONE := Color("eceff3")
const PATH_LINE := Color("c3c9d2")
const ART_INK := Color("33283a")
## Arranha-céus ao longe, na névoa azulada: faces e janelas.
const SKYLINE_LEFT := Color("a9b8d0")
const SKYLINE_RIGHT := Color("8fa1bd")
const SKYLINE_TOP := Color("ccd5e3")
const SKYLINE_WINDOW := Color(1, 1, 1, 0.4)
const SKYLINE_WINDOW_STEP := 22.0
## À noite, parte das janelinhas dos arranha-céus acende (o resto fica apagado).
const SKYLINE_LIT := Color(1.0, 0.82, 0.5)
const SKYLINE_LIT_CHANCE := 0.4
const SKYLINE_LIT_SEGMENT := 0.5
const SKYLINE_SEED := 80
## Rua molhada (DT-080): poças que refletem o céu, a cada tantos pisos, e o brilho quente delas à noite.
const PUDDLE_SEED := 81
const PUDDLE_STEP := 2.6
const PUDDLE_COLOR := Color(0.84, 0.92, 1.0, 0.2)
const PUDDLE_SHINE := Color(1, 1, 1, 0.22)
const PUDDLE_GLINT := Color(1.0, 0.82, 0.55, 0.35)
const PUDDLE_POINTS := 18
## Passos da escuridão que redesenham a cidade (a noite muda devagar; redesenhar a cada frame seria à toa).
const NIGHT_STEPS := 32.0
## [canto (vértice, a partir do café), pegada em pisos, altura em pixels de mundo]: atrás das fileiras de prédios.
const SKYLINE: Array = [
	[Vector2(-15, -24), Vector2(4, 4), 720.0], [Vector2(-9, -22), Vector2(3, 3), 520.0], [Vector2(-4, -25), Vector2(5, 3), 860.0],
	[Vector2(3, -23), Vector2(3, 4), 600.0], [Vector2(8, -24), Vector2(4, 4), 980.0], [Vector2(14, -22), Vector2(3, 3), 560.0],
	[Vector2(19, -25), Vector2(4, 5), 760.0], [Vector2(-24, -14), Vector2(4, 4), 640.0], [Vector2(-22, -8), Vector2(3, 3), 880.0],
	[Vector2(-25, -2), Vector2(4, 4), 540.0], [Vector2(-23, 5), Vector2(3, 3), 700.0], [Vector2(-24, 11), Vector2(4, 4), 600.0],
	[Vector2(-22, 17), Vector2(3, 3), 820.0], [Vector2(-21, -21), Vector2(5, 5), 1100.0],
]

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var entrance := CafeGrid.NO_CELL:
	set(value):
		entrance = value
		queue_redraw()

var plan: CityPlan
## Escuridão (0 de dia, 1 no meio da noite) e a cor do NightTint: acendem as janelas e o brilho das poças.
var night := 0.0
var night_tint := Color.WHITE


func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Há arte da cidade?
func has_art() -> bool:
	return ArtSprites.get_sprite(ArtSprites.city().get("concrete", "")) != null


func _draw() -> void:
	if grid_size == Vector2i.ZERO or not has_art():
		return
	plan = CityPlan.new(grid_size, entrance, ArtSprites.city_footprints())
	var city := ArtSprites.city()
	var center := Vector2(grid_size) / 2.0
	var reach := Vector2.ONE * GROUND_REACH
	_draw_tiled(_quad(center - reach, center + reach), ArtSprites.get_sprite(city["concrete"]).texture,
		float(city.get("concrete_world", 64.0)))
	_draw_park()
	_draw_sidewalks()
	_draw_streets()
	_draw_path()
	_draw_skyline()
	_draw_buildings()


## Noite (DT-080): redesenha só quando a escuridão muda de um passo para outro.
func set_night(amount: float, tint: Color) -> void:
	var stepped := roundf(clampf(amount, 0.0, 1.0) * NIGHT_STEPS) / NIGHT_STEPS
	if is_equal_approx(stepped, night):
		return
	night = stepped
	night_tint = tint
	queue_redraw()


func is_lit() -> bool:
	return night > CityLights.MIN_NIGHT


func _at(point: Vector2, height := 0.0) -> Vector2:
	return IsoProjection.vertex_to_world(point) - Vector2(0.0, height)


## Polígono do retângulo de vértices [a, b] no chão.
func _quad(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([_at(a), _at(Vector2(b.x, a.y)), _at(b), _at(Vector2(a.x, b.y))])


func _rect(rect: Rect2) -> PackedVector2Array:
	return _quad(rect.position, rect.end)


## Polígono com uma textura de repetir (período em pixels de mundo).
func _draw_tiled(points: PackedVector2Array, texture: Texture2D, period: float) -> void:
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / period)
	draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, texture)


## Grama do outro lado das duas ruas (um parque), com as árvores que são do StreetView.
func _draw_park() -> void:
	var exterior := ArtSprites.exterior()
	var lawn := ArtSprites.get_sprite(exterior.get("lawn", ""))
	if lawn == null:
		return
	for rect in plan.park_rects():
		_draw_tiled(_rect(rect), lawn.texture, float(exterior.get("lawn_world", 128.0)))


## Calçadas de placas claras: as do lado do café (com as juntas) e as do outro lado das ruas.
func _draw_sidewalks() -> void:
	for rect in plan.near_sidewalks():
		draw_colored_polygon(_rect(rect), SIDEWALK)
		var y := ceilf(rect.position.y)
		while y <= rect.end.y:
			draw_line(_at(Vector2(rect.position.x, y)), _at(Vector2(rect.end.x, y)), SIDEWALK_LINE, 1.5, true)
			y += 1.0
		var x := ceilf(rect.position.x)
		while x <= rect.end.x:
			draw_line(_at(Vector2(x, rect.position.y)), _at(Vector2(x, rect.end.y)), SIDEWALK_LINE, 1.5, true)
			x += 1.0
	for rect in plan.far_sidewalks():
		draw_colored_polygon(_rect(rect), FAR_SIDEWALK)


## As duas ruas: asfalto, meio-fio, a linha amarela dupla, as faixas de pedestre e as de parada.
func _draw_streets() -> void:
	var exterior := ArtSprites.exterior()
	var asphalt := ArtSprites.get_sprite(exterior.get("asphalt", ""))
	for street in 2:
		var rect := plan.street_rect(street)
		if asphalt != null:
			_draw_tiled(_rect(rect), asphalt.texture, float(exterior.get("asphalt_world", 64.0)))
		else:
			draw_colored_polygon(_rect(rect), Color("5f6673"))
		_draw_puddles(rect, street == 0)
	var cross := plan.crossing()
	for street in 2:
		var rect := plan.street_rect(street)
		var along_y := street == 0
		var middle := rect.get_center().x if along_y else rect.get_center().y
		var edges := [rect.position.x, rect.end.x] if along_y else [rect.position.y, rect.end.y]
		var before := cross.position.y if along_y else cross.position.x
		var after := cross.end.y if along_y else cross.end.x
		var start := rect.position.y if along_y else rect.position.x
		var finish := rect.end.y if along_y else rect.end.x
		var gap := CROSSWALK_WIDTH + CROSSWALK_GAP + STOP_LINE
		for span in [[start, before - gap], [after + gap, finish]]:
			for side in [-1.0, 1.0]:
				_line_along(along_y, middle + side * YELLOW_GAP, span[0], span[1], ROAD_YELLOW, YELLOW_WIDTH)
			for edge: float in edges:
				_curb(along_y, edge, span[0], span[1], edge == edges[0])
		# faixa de pedestre dos dois lados do cruzamento e a faixa de parada de quem chega
		_zebra(along_y, edges[0], edges[1], before - CROSSWALK_GAP - CROSSWALK_WIDTH, before - CROSSWALK_GAP)
		_zebra(along_y, edges[0], edges[1], after + CROSSWALK_GAP, after + CROSSWALK_GAP + CROSSWALK_WIDTH)
		var stop_a := before - gap
		var stop_b := after + gap
		_band(along_y, edges[0], middle, stop_a - STOP_LINE, stop_a, ROAD_WHITE)
		_band(along_y, middle, edges[1], stop_b, stop_b + STOP_LINE, ROAD_WHITE)


## Poças da rua molhada (DT-080), sempre nos mesmos lugares e fora do cruzamento: a mancha clara do céu refletido, um
## brilho em cima e, à noite, o reflexo quente das luzes.
func _draw_puddles(rect: Rect2, along_y: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PUDDLE_SEED + int(along_y)
	var length := rect.size.y if along_y else rect.size.x
	var width := rect.size.x if along_y else rect.size.y
	var cross := plan.crossing().grow(CROSSWALK_WIDTH + CROSSWALK_GAP + STOP_LINE)
	var glint := PUDDLE_GLINT * CityLights.glow_modulate(night, night_tint, 1.0)
	var t := rng.randf_range(0.0, PUDDLE_STEP)
	while t < length:
		var along := rng.randf_range(0.35, 0.8)
		var side := rng.randf_range(0.18, 0.34)
		var across := rng.randf_range(0.2, 0.8) * width
		var center := rect.position + (Vector2(across, t) if along_y else Vector2(t, across))
		var radius := Vector2(side, along) if along_y else Vector2(along, side)
		if not cross.has_point(center):
			draw_colored_polygon(_ellipse(center, radius), PUDDLE_COLOR)
			draw_colored_polygon(_ellipse(center - radius * 0.25, radius * 0.45), PUDDLE_SHINE)
			if is_lit():
				draw_colored_polygon(_ellipse(center + radius * 0.15, radius * 0.6), glint)
		t += rng.randf_range(PUDDLE_STEP * 0.6, PUDDLE_STEP * 1.4)


## Elipse deitada no chão (em pisos), já na tela.
func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in PUDDLE_POINTS:
		var angle := TAU * i / PUDDLE_POINTS
		points.append(_at(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)))
	return points


## Linha ao longo da rua: na rua A (ao longo de y), em x = [param fixed], de [param a] a [param b].
func _line_along(along_y: bool, fixed: float, a: float, b: float, color: Color, width: float) -> void:
	var p0 := Vector2(fixed, a) if along_y else Vector2(a, fixed)
	var p1 := Vector2(fixed, b) if along_y else Vector2(b, fixed)
	draw_line(_at(p0), _at(p1), color, width, true)


## Faixa pintada: na rua A vai de x0 a x1 na largura e de a a b ao longo dela.
func _band(along_y: bool, x0: float, x1: float, a: float, b: float, color: Color) -> void:
	var rect := Rect2(x0, a, x1 - x0, b - a) if along_y else Rect2(a, x0, b - a, x1 - x0)
	draw_colored_polygon(_rect(rect), color)


## Faixa de pedestre (zebra): listras paralelas à rua, uma ao lado da outra de uma calçada à outra.
func _zebra(along_y: bool, from_edge: float, to_edge: float, a: float, b: float) -> void:
	var x := from_edge + (ZEBRA_STEP - ZEBRA_STRIPE)
	while x + ZEBRA_STRIPE <= to_edge:
		_band(along_y, x, x + ZEBRA_STRIPE, a, b, ROAD_WHITE)
		x += ZEBRA_STEP


## Meio-fio ao longo da borda [param edge] da rua; [param near_side] diz de que lado fica a calçada.
func _curb(along_y: bool, edge: float, a: float, b: float, near_side: bool) -> void:
	var inward := -CURB_WIDTH if near_side else CURB_WIDTH
	var p0 := Vector2(edge, a) if along_y else Vector2(a, edge)
	var p1 := Vector2(edge, b) if along_y else Vector2(b, edge)
	var shift := Vector2(inward, 0.0) if along_y else Vector2(0.0, inward)
	var top := PackedVector2Array([_at(p0 + shift), _at(p0), _at(p1), _at(p1 + shift)])
	draw_colored_polygon(top, CURB_TOP)
	var side := PackedVector2Array([_at(p0), _at(p1), _at(p1, -CURB_HEIGHT), _at(p0, -CURB_HEIGHT)])
	if near_side:  # só a face voltada para a rua aparece
		draw_colored_polygon(side, CURB_SIDE)
	draw_line(_at(p0), _at(p1), ART_INK, 1.0, true)


## Caminho de pedras da calçada até a porta.
func _draw_path() -> void:
	if entrance == CafeGrid.NO_CELL:
		return
	var n := float(grid_size.x)
	var y0 := entrance.y + (1.0 - PATH_WIDTH) / 2.0
	var y1 := y0 + PATH_WIDTH
	var stones := 3
	for i in stones:
		var x0 := n + PATH_END * float(i) / stones + 0.04
		var x1 := n + PATH_END * float(i + 1) / stones - 0.04
		var stone := _quad(Vector2(x0, y0), Vector2(x1, y1))
		draw_colored_polygon(stone, PATH_STONE)
		var closed := stone.duplicate()
		closed.append(stone[0])
		draw_polyline(closed, PATH_LINE, 1.5, true)


## Arranha-céus ao longe: caixas claras com janelinhas, do fundo para a frente.
func _draw_skyline() -> void:
	var towers := SKYLINE.duplicate()
	towers.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[0] + a[1]).x + (a[0] + a[1]).y < (b[0] + b[1]).x + (b[0] + b[1]).y)
	var rng := RandomNumberGenerator.new()
	rng.seed = SKYLINE_SEED
	var lit_color := SKYLINE_LIT * CityLights.glow_modulate(night, night_tint)
	for tower: Array in towers:
		var origin: Vector2 = tower[0]
		var size: Vector2 = tower[1]
		var height: float = tower[2]
		var left := PackedVector2Array([_at(origin + Vector2(0, size.y)), _at(origin + size), _at(origin + size, height),
			_at(origin + Vector2(0, size.y), height)])
		var right := PackedVector2Array([_at(origin + size), _at(origin + Vector2(size.x, 0)),
			_at(origin + Vector2(size.x, 0), height), _at(origin + size, height)])
		var top := PackedVector2Array([_at(origin, height), _at(origin + Vector2(size.x, 0), height), _at(origin + size, height),
			_at(origin + Vector2(0, size.y), height)])
		draw_colored_polygon(left, SKYLINE_LEFT)
		draw_colored_polygon(right, SKYLINE_RIGHT)
		draw_colored_polygon(top, SKYLINE_TOP)
		var z := SKYLINE_WINDOW_STEP
		while z < height - SKYLINE_WINDOW_STEP:
			draw_line(_at(origin + Vector2(0.15, size.y), z), _at(origin + Vector2(size.x - 0.15, size.y), z), SKYLINE_WINDOW, 2.0)
			draw_line(_at(origin + Vector2(size.x, size.y - 0.15), z), _at(origin + Vector2(size.x, 0.15), z), SKYLINE_WINDOW, 2.0)
			_draw_skyline_lights(rng, origin, size, z, lit_color)
			z += SKYLINE_WINDOW_STEP


## Janelinhas acesas de um andar de arranha-céu à noite (o sorteio é sempre o mesmo: as janelas não piscam).
func _draw_skyline_lights(rng: RandomNumberGenerator, origin: Vector2, size: Vector2, z: float, color: Color) -> void:
	for face in 2:
		var span := size.x if face == 0 else size.y
		var u := 0.15
		while u + SKYLINE_LIT_SEGMENT <= span - 0.15:
			var lit := rng.randf() < SKYLINE_LIT_CHANCE
			if lit and is_lit():
				var a := origin + (Vector2(u, size.y) if face == 0 else Vector2(size.x, size.y - u))
				var b := origin + (Vector2(u + SKYLINE_LIT_SEGMENT * 0.8, size.y) if face == 0
					else Vector2(size.x, size.y - u - SKYLINE_LIT_SEGMENT * 0.8))
				draw_line(_at(a, z), _at(b, z), color, 3.0)
			u += SKYLINE_LIT_SEGMENT


## Prédios atrás do café, do fundo para a frente (o plano já vem nessa ordem). À noite, cada um ganha a camada das
## janelas acesas logo depois dele (assim o prédio da frente cobre as luzes do de trás).
func _draw_buildings() -> void:
	var lights: Dictionary = ArtSprites.city().get("building_lights", {})
	var glow := CityLights.glow_modulate(night, night_tint)
	for building: Array in plan.buildings:
		var sprite := ArtSprites.get_sprite(building[0])
		if sprite != null:
			var anchor := _at(building[1] + Vector2(building[2]))
			draw_texture_rect(sprite.texture, Rect2(anchor + sprite.draw_rect().position, sprite.draw_rect().size), false)
			var lit := ArtSprites.get_sprite(lights.get(building[0], ""))
			if lit != null and is_lit():
				draw_texture_rect(lit.texture, Rect2(anchor + lit.draw_rect().position, lit.draw_rect().size), false, glow)
