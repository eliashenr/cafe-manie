extends CafeTestCase
## Cidade em volta do café (DT-048): a arte existe; as ruas passam nas duas frentes; os prédios ficam
## atrás, sem encostar no café, nas ruas ou nas calçadas; os enfeites ficam longe da porta e da fila;
## o trânsito para no vermelho, anda no verde e não bate; a rua fica por cima da mureta da frente.


func _plan(size := Vector2i(8, 8), door := Vector2i(7, 4)) -> CityPlan:
	var clear: Array[Vector2] = []
	return CityPlan.new(size, door, ArtSprites.city_footprints(), clear)


func _rect_of(building: Array) -> Rect2:
	return Rect2(building[1], Vector2(building[2]))


func test_every_city_drawing_exists() -> void:
	var city := ArtSprites.city()
	assert_true(ArtSprites.get_sprite(city.get("concrete", "")) != null, "chão de concreto")
	var footprints := ArtSprites.city_footprints()
	assert_true(footprints.size() >= 6, "prédios variados")
	for name: String in footprints:
		assert_true(ArtSprites.get_sprite(name) != null, "falta o prédio " + name)
	for prop: String in city.get("props", []):
		assert_true(ArtSprites.get_sprite(prop) != null, "falta " + prop)
	for car: String in StreetView.CAR_MIX:
		for heading in ["+x", "-x", "+y", "-y"]:
			assert_true(ArtSprites.city_car(car, heading) != null, "falta %s %s" % [car, heading])
	for light: String in StreetView.LIGHT_SPRITES.values():
		assert_true(ArtSprites.get_sprite(light) != null, "falta " + light)


func test_streets_run_along_both_fronts_and_cross_at_the_corner() -> void:
	var plan := _plan()
	var a := plan.street_rect(0)
	var b := plan.street_rect(1)
	assert_almost_eq(a.position.x, 8.0 + CityPlan.SIDEWALK_END, 0.001, "a rua A passa na frente da entrada, depois da calçada")
	assert_almost_eq(b.position.y, 8.0 + CityPlan.SIDEWALK_END, 0.001, "a rua B passa do outro lado da frente")
	assert_true(a.size.y > 40.0 and b.size.x > 40.0, "as ruas seguem para os dois lados")
	var cross := plan.crossing()
	assert_vec_almost_eq(cross.size, Vector2.ONE * (CityPlan.STREET_END - CityPlan.SIDEWALK_END), 0.001)


func test_buildings_stand_behind_the_cafe_off_streets_and_sidewalks() -> void:
	for size in [Vector2i(8, 8), Vector2i(12, 10), Vector2i(16, 16)]:
		var plan := _plan(size, Vector2i(size.x - 1, size.y / 2))
		var cafe_lot := Rect2(Vector2.ZERO, Vector2(size)).grow(0.99)
		assert_true(plan.buildings.size() >= 8, "fileiras de prédios atrás (%s)" % size)
		var rects: Array[Rect2] = []
		for building: Array in plan.buildings:
			var rect := _rect_of(building)
			assert_true(rect.end.x <= 0.01 - CityPlan.ALLEY or rect.end.y <= 0.01 - CityPlan.ALLEY, "%s fica atrás" % building[0])
			assert_false(rect.intersects(cafe_lot), "%s não encosta no café (fica o beco)" % building[0])
			for street in 2:
				assert_false(rect.intersects(plan.street_rect(street)), "%s fora da rua" % building[0])
			for walk in plan.near_sidewalks():
				assert_false(rect.intersects(walk), "%s fora da calçada" % building[0])
			for other in rects:
				assert_false(rect.intersects(other), "prédios sem se sobrepor")
			rects.append(rect)
		var depth := func(b: Array) -> float: return (b[1] + Vector2(b[2])).x + (b[1] + Vector2(b[2])).y
		for i in range(1, plan.buildings.size()):
			assert_true(depth.call(plan.buildings[i]) >= depth.call(plan.buildings[i - 1]), "do fundo para a frente")


func test_sidewalk_props_keep_clear_of_the_door_and_the_queue() -> void:
	var cafe := await spawn_cafe()
	var plan := cafe.street_view.plan
	assert_true(plan != null and not plan.props.is_empty())
	var clear := cafe.street_keep_clear()
	assert_true(clear.size() >= cafe.simulation.config.queue_capacity, "a fila inteira fica livre")
	for prop: Array in plan.props:
		for spot in clear:
			assert_true((prop[1] as Vector2).distance_to(spot) >= 1.2, "%s em %s no caminho de %s" % [prop[0], prop[1], spot])
		for street in 2:
			assert_false(plan.street_rect(street).has_point(prop[1]), "%s fora da rua" % prop[0])


func test_no_prop_on_the_way_of_customers_who_give_up_the_queue() -> void:
	var cafe := await spawn_cafe()
	var center := Vector2(0.5, 0.5)  # personagens usam o centro da célula; a cidade, os vértices
	for i in cafe.simulation.config.queue_capacity:
		var spot := cafe.simulation.queue_spot(i) + center
		for step in 13:
			var walking := spot + WorldLayer.QUEUE_WALK * (step / 12.0)
			for prop: Array in cafe.street_view.plan.props:
				assert_true((prop[1] as Vector2).distance_to(walking) >= 1.0,
					"%s em %s no caminho de quem sai da fila (%s)" % [prop[0], prop[1], walking])


func test_traffic_light_cycles_and_cars_stop_at_red_then_go() -> void:
	var model := TrafficModel.new()
	var lane := model.add_lane(0, 1, 12.5, -20.0, 30.0, 11.2, 15.6)
	var car := model.add_car(lane, 6.0)
	model.phase = TrafficModel.Phase.B_GREEN
	assert_eq(model.light(0), TrafficModel.Light.RED)
	assert_eq(model.light(1), TrafficModel.Light.GREEN)
	for i in 60:
		model.step(0.05)
	assert_almost_eq(car.along, lane.stop_at(), 0.001, "parou na faixa de parada")
	assert_true(car.stopped)
	for i in 400:
		model.step(0.05)
		if model.light(0) == TrafficModel.Light.GREEN:
			break
	assert_eq(model.light(0), TrafficModel.Light.GREEN, "o semáforo alterna")
	for i in 40:
		model.step(0.05)
	assert_true(lane.past(car.along, lane.cross_from), "no verde, atravessa")


func test_car_inside_the_crossing_does_not_stop_when_the_light_changes() -> void:
	var model := TrafficModel.new()
	var lane := model.add_lane(1, -1, 13.0, 40.0, -20.0, 15.6, 11.2)
	var car := model.add_car(lane, 14.0)  # já dentro do cruzamento
	model.phase = TrafficModel.Phase.A_GREEN
	assert_eq(model.light(1), TrafficModel.Light.RED)
	model.step(0.5)
	assert_true(car.along < 14.0, "quem já entrou termina de atravessar")


func test_cars_keep_their_distance_and_come_back_around() -> void:
	var model := TrafficModel.new()
	var lane := model.add_lane(0, 1, 12.5, -20.0, 30.0, 11.2, 15.6)
	model.phase = TrafficModel.Phase.B_GREEN
	var front := model.add_car(lane, 9.0)
	var back := model.add_car(lane, 7.0)
	for i in 100:
		model.step(0.05)
		assert_true(front.along - back.along >= TrafficModel.GAP - 0.001, "não encosta no da frente")
	var free_lane := model.add_lane(1, 1, 13.0, -20.0, 30.0, 100.0, 104.0)
	var runner := model.add_car(free_lane, 29.9)
	model.step(0.1)
	assert_almost_eq(runner.along, free_lane.start, 0.001, "no fim da rua, volta pelo começo")


func test_street_view_moves_the_cars_and_shows_the_lights() -> void:
	var cafe := await spawn_cafe()
	var street := cafe.street_view
	assert_true(street.z_index > cafe.front_view.z_index, "a rua fica na frente da mureta")
	assert_true(street.y_sort_enabled, "enfeites e carros se ordenam pela altura")
	assert_true(street.car_figures().size() >= 4)
	var before := street.car_figures().map(func(f: StreetView.Figure) -> Vector2: return f.position)
	street.advance(1.0)
	var after := street.car_figures().map(func(f: StreetView.Figure) -> Vector2: return f.position)
	assert_true(before != after, "os carros andam")
	for car in street.car_figures():
		assert_true(car.sprite != null, "todo carro tem desenho")
	for road in 2:
		var expected: String = StreetView.LIGHT_SPRITES[street.traffic.light(road)]
		assert_eq(street.light_figure(road).sprite, ArtSprites.get_sprite(expected), "semáforo da rua %d" % road)


func test_city_follows_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	var cafe := await spawn_cafe(simulation)
	cafe.simulation.wallet.earn(Wallet.SOFT, 10000, "teste")
	cafe.simulation.progression.add_xp(1000)
	assert_eq(cafe.simulation.expand(), ServiceResult.OK)
	await settle()
	assert_eq(cafe.street_view.plan.grid_size, cafe.layout.grid.size, "a rua acompanha o café")
	assert_eq(cafe.exterior_view.grid_size, cafe.layout.grid.size)
