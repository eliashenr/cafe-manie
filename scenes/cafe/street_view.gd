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


## O poste da calçada: à noite acende a lanterna e a poça de luz no chão (DT-080).
const LAMP_PROP := "rua_poste"
## Faróis dos carros à noite: a mancha de luz no asfalto, à frente do carro (em pisos), o tamanho e a cor.
const HEADLIGHT_REACH := 0.8
const HEADLIGHT_SIZE := Vector2(130.0, 44.0)
const HEADLIGHT_COLOR := Color(1.0, 0.95, 0.82, 0.5)

var plan: CityPlan
var traffic := TrafficModel.new()
var _cars: Array[Figure] = []
var _lights: Array = []  # [rua, Figure]
var _lamp_lights: Array[PointLight2D] = []
var _lamp_pools: Array[Sprite2D] = []
var _headlights: Array[Sprite2D] = []


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
	_lamp_lights.clear()
	_lamp_pools.clear()
	_headlights.clear()
	traffic = TrafficModel.new()
	plan = CityPlan.new(grid_size, entrance, ArtSprites.city_footprints(), keep_clear)
	if not has_art():
		return
	for prop: Array in plan.props:
		var figure := _figure("Prop", prop[0], prop[1])
		if prop[0] == LAMP_PROP:
			_add_lamp_glow(figure)
	for spot: Array in plan.lights:
		_lights.append([spot[0], _figure("Light", LIGHT_SPRITES[TrafficModel.Light.RED], spot[1])])
	for at in plan.vents:
		var vent := _figure("Vent", "rua_bueiro", at)
		var steam := FxParticles.steam()
		steam.emitting = true
		vent.add_child(steam)
	plan.fill_traffic(traffic, CAR_MIX.size())
	for car in traffic.cars:
		var figure := _figure("Car", "", car.point())
		_cars.append(figure)
		_headlights.append(_add_headlight(figure))
	_sync()


## Luz da lanterna e a poça de luz no chão embaixo dela (as duas apagadas até a noite).
func _add_lamp_glow(lamp: Figure) -> void:
	var head_offset: Array = ArtSprites.city().get("lamp_head", [0.0, 0.0])
	var head := Vector2(float(head_offset[0]), float(head_offset[1]))
	var light := CityLights.lamp_light()
	light.position = head
	lamp.add_child(light)
	_lamp_lights.append(light)
	var pool := Sprite2D.new()
	pool.name = "LightPool"
	pool.texture = FxParticles.soft_dot()
	pool.scale = CityLights.POOL_SIZE / Vector2(FxParticles.soft_dot().get_size())
	pool.position = Vector2(head.x, 0.0)
	pool.self_modulate = CityLights.POOL_COLOR
	pool.show_behind_parent = true
	pool.visible = false
	lamp.add_child(pool)
	_lamp_pools.append(pool)


## Mancha dos faróis no asfalto, embaixo do carro (apagada até a noite); o _sync aponta para onde o carro vai.
func _add_headlight(car: Figure) -> Sprite2D:
	var beam := Sprite2D.new()
	beam.name = "Headlights"
	beam.texture = FxParticles.soft_dot()
	beam.scale = HEADLIGHT_SIZE / Vector2(FxParticles.soft_dot().get_size())
	beam.self_modulate = HEADLIGHT_COLOR
	beam.show_behind_parent = true
	beam.visible = false
	car.add_child(beam)
	return beam


## Noite (DT-080): acende os postes e os faróis conforme a escuridão; o que é desenhado (poças de luz e faróis) vem
## compensado pelo NightTint.
func set_night(amount: float, tint: Color) -> void:
	for light in _lamp_lights:
		CityLights.set_light(light, amount, CityLights.LAMP_ENERGY)
	var glow := CityLights.glow_modulate(amount, tint, 1.0)
	for sprite: Sprite2D in _lamp_pools + _headlights:
		sprite.visible = amount > CityLights.MIN_NIGHT
		sprite.modulate = glow


func lamp_lights() -> Array[PointLight2D]:
	return _lamp_lights


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
		var ahead := Vector2(0.0, car.lane.direction) if car.lane.street == 0 else Vector2(car.lane.direction, 0.0)
		var offset := IsoProjection.vertex_to_world(ahead * HEADLIGHT_REACH) - IsoProjection.vertex_to_world(Vector2.ZERO)
		_headlights[i].position = offset
		_headlights[i].rotation = offset.angle()
	for entry: Array in _lights:
		(entry[1] as Figure).sprite = ArtSprites.get_sprite(LIGHT_SPRITES[traffic.light(entry[0])])


func car_figures() -> Array[Figure]:
	return _cars


func light_figure(street: int) -> Figure:
	for entry: Array in _lights:
		if entry[0] == street:
			return entry[1]
	return null
