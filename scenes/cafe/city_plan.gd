class_name CityPlan
extends RefCounted
## Onde fica cada coisa da cidade em volta do café (só tela), a partir do tamanho do grid e da entrada.
## Medidas em vértices do grid (o canto de cima da célula (x, y) é Vector2(x, y)), como no ExteriorView.
##
## O café ocupa um lote de esquina: a rua A passa na frente da entrada (lado +x) e a rua B no outro lado
## da frente (+y), com calçada dos dois lados e um cruzamento na esquina. Atrás (lados -x e -y) ficam
## os prédios, depois de um beco de um piso, e mais longe o contorno dos arranha-céus.

## Faixas a partir da borda do café, em pisos (iguais nas duas ruas).
const SIDEWALK_END := 3.2
const STREET_END := 7.6
const FAR_SIDEWALK_END := 10.4
## Até onde as ruas vão para cada lado, em pisos.
const ROAD_REACH := 40.0
## Faixas de carro, a partir da borda do café: a de perto anda num sentido, a de longe no outro.
const NEAR_LANE := 4.5
const FAR_LANE := 6.3
## Enfeites da calçada: junto do meio-fio, um a cada tantos pisos.
const CURB_PROPS := 2.85
const PROP_SPACING := 3.0
## O beco atrás do café e onde começam as fileiras de prédios.
const ALLEY := 1.0
const ROW_START := -4.0
## Quantos pisos de prédios depois de cada rua.
const ROW_BEYOND := 9.0
## Prédios na ordem em que se repetem nas fileiras.
const BUILDING_CYCLE: Array[String] = ["predio_deco", "predio_brownstone", "predio_deli", "predio_tijolo",
	"predio_azul", "predio_pizza", "predio_vidro"]
const NEAR_PROPS_A: Array[String] = ["rua_arvore", "rua_poste", "rua_hidrante", "rua_arvore", "rua_banco", "rua_poste"]
const NEAR_PROPS_B: Array[String] = ["rua_arvore", "rua_poste", "rua_lixeira", "rua_arvore", "rua_correio", "rua_poste"]
const FAR_PROPS: Array[String] = ["rua_arvore", "rua_poste", "rua_arvore", "rua_vaso"]
const PARK_PROPS: Array[String] = ["rua_arvore", "rua_arvore", "rua_banco", "rua_arvore"]
## O parque ganha árvores só perto das ruas (o resto fica longe da câmera), a cada tantos pisos.
const PARK_DEPTH := 9.0
const PARK_SPACING := 3.0

var grid_size := Vector2i.ZERO
var entrance := Vector2i.ZERO
## [nome do prédio, origem (vértice de cima da pegada), pegada], do fundo para a frente.
var buildings: Array = []
## [nome do enfeite, ponto no chão].
var props: Array = []
## Semáforos: [rua, ponto] (0 = o que mostra o sinal da rua A, 1 = o da rua B).
var lights: Array = []
## Bueiros com vapor: pontos no meio das ruas.
var vents: Array[Vector2] = []


## [param footprints]: nome do prédio -> pegada (Vector2i), do manifesto da arte.
## [param keep_clear]: pontos do grid (vértices) onde não pode ter enfeite (porta, fila).
func _init(size: Vector2i, door: Vector2i, footprints: Dictionary, keep_clear: Array[Vector2] = []) -> void:
	grid_size = size
	entrance = door
	_plan_buildings(footprints)
	_plan_props(keep_clear)
	var n := float(size.x)
	var m := float(size.y)
	lights = [[0, Vector2(n + CURB_PROPS, m + CURB_PROPS)], [1, Vector2(n + CURB_PROPS, m + STREET_END + 0.3)]]
	vents = [Vector2(n + (SIDEWALK_END + STREET_END) / 2.0, -3.5), Vector2(-3.5, m + (SIDEWALK_END + STREET_END) / 2.0)]


## Retângulo de uma rua (em vértices): a A ao longo de y, a B ao longo de x.
func street_rect(street: int) -> Rect2:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	if street == 0:
		return Rect2(n + SIDEWALK_END, -ROAD_REACH, STREET_END - SIDEWALK_END, m + 2.0 * ROAD_REACH)
	return Rect2(-ROAD_REACH, m + SIDEWALK_END, n + 2.0 * ROAD_REACH, STREET_END - SIDEWALK_END)


## O cruzamento das duas ruas.
func crossing() -> Rect2:
	return street_rect(0).intersection(street_rect(1))


## Calçadas do lado do café: ao longo da rua A (também atrás dele) e da rua B, com a esquina.
func near_sidewalks() -> Array[Rect2]:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	return [Rect2(n, -ROAD_REACH, SIDEWALK_END, m + ROAD_REACH + SIDEWALK_END),
		Rect2(-ROAD_REACH, m, n + ROAD_REACH, SIDEWALK_END)]


## Calçadas do outro lado das ruas (sem passar por cima da outra rua).
func far_sidewalks() -> Array[Rect2]:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	var width := FAR_SIDEWALK_END - STREET_END
	return [Rect2(n + STREET_END, -ROAD_REACH, width, m + ROAD_REACH + SIDEWALK_END),
		Rect2(n + STREET_END, m + STREET_END, width, ROAD_REACH),
		Rect2(-ROAD_REACH, m + STREET_END, n + ROAD_REACH + SIDEWALK_END, width),
		Rect2(n + FAR_SIDEWALK_END, m + STREET_END, ROAD_REACH, width)]


## Parque (grama) do outro lado das ruas, na frente do café.
func park_rects() -> Array[Rect2]:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	return [Rect2(n + FAR_SIDEWALK_END, 0.0, ROAD_REACH, m + SIDEWALK_END),
		Rect2(0.0, m + FAR_SIDEWALK_END, n + SIDEWALK_END, ROAD_REACH),
		Rect2(n + FAR_SIDEWALK_END, m + FAR_SIDEWALK_END, ROAD_REACH, ROAD_REACH)]


## Monta as faixas de carro e uns carros espalhados no modelo de trânsito.
func fill_traffic(model: TrafficModel, car_kinds: int) -> void:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	var cross := crossing()
	var a_start := -ROAD_REACH * 0.5
	var a_end := m + ROAD_REACH * 0.5
	var b_start := -ROAD_REACH * 0.5
	var b_end := n + ROAD_REACH * 0.5
	var specs := [
		[0, 1, n + NEAR_LANE, a_start, a_end, cross.position.y, cross.end.y],
		[0, -1, n + FAR_LANE, a_end, a_start, cross.end.y, cross.position.y],
		[1, 1, m + NEAR_LANE, b_start, b_end, cross.position.x, cross.end.x],
		[1, -1, m + FAR_LANE, b_end, b_start, cross.end.x, cross.position.x],
	]
	var kind := 0
	for spec: Array in specs:
		var lane := model.add_lane(spec[0], spec[1], spec[2], spec[3], spec[4], spec[5], spec[6])
		for i in 2:
			var along: float = lerpf(lane.start, lane.end, 0.15 + 0.4 * i)
			model.add_car(lane, along, kind % car_kinds)
			kind += 1


func _plan_buildings(footprints: Dictionary) -> void:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	var cycle := 0
	# fileira atrás do lado -y (de x = ROW_START até a calçada da rua A) e depois da rua A
	for span in [[ROW_START, n], [n + FAR_SIDEWALK_END, n + FAR_SIDEWALK_END + ROW_BEYOND]]:
		var x: float = span[0]
		while true:
			var name := BUILDING_CYCLE[cycle % BUILDING_CYCLE.size()]
			var fp: Vector2i = footprints.get(name, Vector2i(2, 2))
			if x + fp.x > span[1] + 0.01:
				break
			buildings.append([name, Vector2(x, -ALLEY - fp.y), fp])
			x += fp.x
			cycle += 1
	# fileira atrás do lado -x (de y = 0 até a calçada da rua B) e depois da rua B
	for span in [[0.0, m], [m + FAR_SIDEWALK_END, m + FAR_SIDEWALK_END + ROW_BEYOND]]:
		var y: float = span[0]
		while true:
			var name := BUILDING_CYCLE[cycle % BUILDING_CYCLE.size()]
			var fp: Vector2i = footprints.get(name, Vector2i(2, 2))
			if y + fp.y > span[1] + 0.01:
				break
			buildings.append([name, Vector2(-ALLEY - fp.x, y), fp])
			y += fp.y
			cycle += 1
	buildings.sort_custom(func(a: Array, b: Array) -> bool:
		return (a[1] + Vector2(a[2])).x + (a[1] + Vector2(a[2])).y < (b[1] + Vector2(b[2])).x + (b[1] + Vector2(b[2])).y)


func _plan_props(keep_clear: Array[Vector2]) -> void:
	var n := float(grid_size.x)
	var m := float(grid_size.y)
	var i := 0
	var y := -5.0
	while y < m + SIDEWALK_END - 0.5:
		_add_prop(NEAR_PROPS_A[i % NEAR_PROPS_A.size()], Vector2(n + CURB_PROPS, y), keep_clear)
		i += 1
		y += PROP_SPACING
	i = 0
	var x := 1.0
	while x < n + SIDEWALK_END - 0.5:
		_add_prop(NEAR_PROPS_B[i % NEAR_PROPS_B.size()], Vector2(x, m + CURB_PROPS), keep_clear)
		i += 1
		x += PROP_SPACING
	props.append(["rua_carrinho", Vector2(n - 2.5, m + 1.4)])
	i = 0
	y = -6.0
	while y < m + FAR_SIDEWALK_END:
		if y < m + SIDEWALK_END or y > m + STREET_END:
			props.append([FAR_PROPS[i % FAR_PROPS.size()], Vector2(n + STREET_END + 0.4, y)])
		i += 1
		y += PROP_SPACING
	i = 0
	x = -6.0
	while x < n + SIDEWALK_END:
		props.append([FAR_PROPS[i % FAR_PROPS.size()], Vector2(x, m + STREET_END + 0.4)])
		i += 1
		x += PROP_SPACING
	# árvores e bancos no parque
	for rect in park_rects():
		var row := 0
		var py := rect.position.y + 1.5
		while py < minf(rect.end.y, rect.position.y + PARK_DEPTH):
			var px := rect.position.x + 1.5 + (row % 2) * 1.5
			while px < minf(rect.end.x, rect.position.x + PARK_DEPTH):
				props.append([PARK_PROPS[(row + roundi(px)) % PARK_PROPS.size()], Vector2(px, py)])
				px += PARK_SPACING
			row += 1
			py += PARK_SPACING


## Enfeite da calçada de perto, se não fica no caminho de ninguém (a menos de 1,2 piso da porta ou da fila).
func _add_prop(prop: String, at: Vector2, keep_clear: Array[Vector2]) -> void:
	for spot in keep_clear:
		if at.distance_to(spot) < 1.2:
			return
	props.append([prop, at])
