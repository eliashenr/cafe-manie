extends CafeTestCase
## Nova York à noite (DT-080): de dia nada aceso; à noite as janelas dos prédios, os arranha-céus, as poças, os
## postes, os faróis e a luz quente do salão acendem, e a luz desenhada vem compensada pelo NightTint.

## Quanto o halo das janelas acesas pode passar da beirada do prédio (pixels de mundo).
const HALO := 6.0


func _cafe_at(hour: float) -> Cafe:
	var simulation := quiet_simulation()
	clock.offset = 0
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T00:00:00") + hour * 3600.0
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_glow_color_cancels_the_night_tint() -> void:
	var tint := NightTint.NIGHT_COLOR
	var glow := CityLights.glow_modulate(1.0, tint, 1.0)
	assert_true((glow * tint).is_equal_approx(Color(1, 1, 1, tint.a)), "a cor da luz, vezes o escuro, volta a ser a dela")
	assert_almost_eq(CityLights.glow_modulate(0.5, tint, 1.0).a, 0.5, 0.001, "a luz aparece junto com a noite")
	assert_eq(CityLights.glow_modulate(0.0, Color.WHITE).a, 0.0, "de dia, invisível")


func test_lights_turn_on_and_off_with_the_night() -> void:
	var light := CityLights.lamp_light()
	assert_false(light.enabled, "nasce apagada")
	CityLights.set_light(light, 1.0, 2.0)
	assert_true(light.enabled)
	assert_almost_eq(light.energy, 2.0, 0.001)
	CityLights.set_light(light, 0.0, 2.0)
	assert_false(light.enabled)
	light.free()


func test_interior_glow_covers_the_cafe_and_follows_expansions() -> void:
	var glow := CityLights.interior_glow(Vector2i(8, 8))
	var bounds := IsoProjection.grid_bounds(Vector2i(8, 8))
	assert_true(glow.position.is_equal_approx(bounds.get_center()), "no meio do salão")
	var small_scale := glow.texture_scale
	CityLights.fit_interior_glow(glow, Vector2i(12, 12))
	assert_true(glow.texture_scale > small_scale, "o café cresce, a luz também")
	assert_true(glow.position.is_equal_approx(IsoProjection.grid_bounds(Vector2i(12, 12)).get_center()))
	glow.free()


func test_every_building_has_its_night_windows() -> void:
	var lights: Dictionary = ArtSprites.city().get("building_lights", {})
	var buildings: Dictionary = ArtSprites.city().get("buildings", {})
	assert_false(buildings.is_empty())
	for building_name: String in buildings:
		assert_true(lights.has(building_name), "%s tem a camada das janelas acesas" % building_name)
		var lit := ArtSprites.get_sprite(lights.get(building_name, ""))
		var day := ArtSprites.get_sprite(building_name)
		assert_true(lit != null and day != null, building_name)
		if lit != null and day != null:
			# o halo das janelas da beirada pode passar alguns pixels da parede (a luz "vaza")
			assert_true(day.draw_rect().grow(HALO).encloses(lit.draw_rect()), "as luzes caem no prédio: " + building_name)
	assert_eq((ArtSprites.city().get("lamp_head", []) as Array).size(), 2, "a lanterna do poste tem lugar")


func test_by_day_nothing_is_lit() -> void:
	var cafe := await _cafe_at(12.0)
	assert_false(cafe.exterior_view.is_lit(), "de dia, as janelas não acendem")
	assert_false(cafe.interior_glow.enabled)
	var lamps := cafe.street_view.lamp_lights()
	assert_false(lamps.is_empty(), "a calçada tem postes")
	for lamp in lamps:
		assert_false(lamp.enabled)
	for car in cafe.street_view.car_figures():
		assert_false((car.get_node("Headlights") as Sprite2D).visible, "de dia, faróis apagados")


func test_at_night_the_city_and_the_cafe_light_up() -> void:
	var cafe := await _cafe_at(23.0)
	assert_true(cafe.exterior_view.is_lit(), "à noite, as janelas dos prédios acendem")
	assert_true(cafe.interior_glow.enabled and cafe.interior_glow.energy > 0.0, "o salão ganha a luz quente")
	assert_true(cafe.interior_glow.color.r > cafe.interior_glow.color.b, "luz quente")
	for lamp in cafe.street_view.lamp_lights():
		assert_true(lamp.enabled, "os postes acendem")
		assert_true((lamp.get_parent().get_node("LightPool") as Sprite2D).visible, "com a poça de luz no chão")
	var cars := cafe.street_view.car_figures()
	assert_false(cars.is_empty())
	for car in cars:
		var beam := car.get_node("Headlights") as Sprite2D
		assert_true(beam.visible, "faróis acesos")
		assert_true(beam.position.length() > 0.0, "a luz vai à frente do carro")


func test_dusk_redraws_the_city_in_steps() -> void:
	var cafe := await _cafe_at(12.0)
	var view := cafe.exterior_view
	view.set_night(0.5, NightTint.NIGHT_COLOR)
	assert_almost_eq(view.night, 0.5, 0.001)
	view.set_night(0.5 + 0.2 / ExteriorView.NIGHT_STEPS, NightTint.NIGHT_COLOR)
	assert_almost_eq(view.night, 0.5, 0.001, "uma mudança pequena não redesenha")
	view.set_night(0.75, NightTint.NIGHT_COLOR)
	assert_almost_eq(view.night, 0.75, 0.001)
