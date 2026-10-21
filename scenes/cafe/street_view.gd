class_name StreetView
extends Node2D
## A rua em volta do café (só tela, DT-048): enfeites das calçadas, semáforos, bueiros com vapor e os
## carros andando (TrafficModel). Fica acima da mureta da frente (z 2), porque tudo aqui está na frente
## dela, e ordena enfeites e carros entre si pela altura na tela (y-sort). Os enfeites ficam longe da
## porta e da fila (keep_clear), então nunca tampam um personagem que está na frente deles.

## Carros que circulam, na ordem em que aparecem nas faixas (mais táxis: é Nova York).
const CAR_MIX: Array[String] = ["taxi", "taxi", "carro_vermelho", "taxi", "carro_branco", "taxi", "carro_azul", "taxi"]
const LIGHT_SPRITES := {
	TrafficModel.Light.GREEN: "rua_semaforo_verde",
	TrafficModel.Light.YELLOW: "rua_semaforo_amarelo",
	TrafficModel.Light.RED: "rua_semaforo_vermelho",
}


## Uma figura da arte com a âncora no próprio nó (enfeite, semáforo ou carro).
class Figure:
	extends Node2D

	var sprite: ArtSprites.Sprite:
		set(value):
			if value != sprite:
				sprite = value
				queue_redraw()

	func _draw() -> void:
		if sprite != null:
			draw_texture_rect(sprite.texture, sprite.draw_rect(), false)


var plan: CityPlan
var traffic := TrafficModel.new()
var _cars: Array[Figure] = []
var _lights: Array = []  # [rua, Figure]


func _init() -> void:
	z_index = 2
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Há arte da cidade?
func has_art() -> bool:
	return not ArtSprites.city().is_empty()


## Monta a rua para o café deste tamanho; [param keep_clear] são pontos (vértices) sem enfeite por perto.
func configure(grid_size: Vector2i, entrance: Vector2i, keep_clear: Array[Vector2]) -> void:
	for child in get_children():
		child.queue_free()
	_cars.clear()
	_lights.clear()
	traffic = TrafficModel.new()
	plan = CityPlan.new(grid_size, entrance, ArtSprites.city_footprints(), keep_clear)
	if not has_art():
		return
	for prop: Array in plan.props:
		_figure("Prop", prop[0], prop[1])
	for spot: Array in plan.lights:
		_lights.append([spot[0], _figure("Light", LIGHT_SPRITES[TrafficModel.Light.RED], spot[1])])
	for at in plan.vents:
		var vent := _figure("Vent", "rua_bueiro", at)
		var steam := FxParticles.steam()
		steam.emitting = true
		vent.add_child(steam)
	plan.fill_traffic(traffic, CAR_MIX.size())
	for car in traffic.cars:
		_cars.append(_figure("Car", "", car.point()))
	_sync()


func _figure(kind: String, sprite_name: String, at: Vector2) -> Figure:
	var figure := Figure.new()
	figure.name = "%s%d" % [kind, get_child_count()]
	figure.sprite = ArtSprites.get_sprite(sprite_name)
	figure.position = IsoProjection.vertex_to_world(at)
	add_child(figure)
	return figure


func _process(delta: float) -> void:
	advance(delta)


## Anda o trânsito [param delta] segundos e atualiza carros e semáforos na tela.
func advance(delta: float) -> void:
	if plan == null:
		return
	traffic.step(delta)
	_sync()


func _sync() -> void:
	for i in _cars.size():
		var car: TrafficModel.Car = traffic.cars[i]
		_cars[i].position = IsoProjection.vertex_to_world(car.point())
		_cars[i].sprite = ArtSprites.city_car(CAR_MIX[car.kind], car.lane.heading())
	for entry: Array in _lights:
		(entry[1] as Figure).sprite = ArtSprites.get_sprite(LIGHT_SPRITES[traffic.light(entry[0])])


func car_figures() -> Array[Figure]:
	return _cars


func light_figure(street: int) -> Figure:
	for entry: Array in _lights:
		if entry[0] == street:
			return entry[1]
	return null
