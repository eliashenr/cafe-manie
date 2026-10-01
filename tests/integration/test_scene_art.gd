extends CafeTestCase
## Arte v3 do cenário: todo revestimento tem peças de piso e de parede, o xadrez
## alterna, as variações são estáveis, a parede tem enfeites e a altura da arte,
## e o exterior (gramado, calçada, cerca) acompanha o tamanho do grid e a entrada.


func test_every_surface_in_the_catalog_has_art() -> void:
	for surface in SurfaceCatalog.load_from().all():
		if surface.kind == SurfaceDefinition.Kind.FLOOR:
			for cell in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(3, 5)]:
				assert_true(ArtSprites.floor_tile(surface.id, cell) != null, "%s sem piso em %s" % [surface.id, cell])
		else:
			for side in ["R", "L"]:
				assert_true(ArtSprites.wall_panel(surface.id, side) != null, "%s sem painel %s" % [surface.id, side])
	assert_true(ArtSprites.floor_entrance() != null, "tapete da entrada")


func test_checker_floor_alternates_and_variations_are_stable() -> void:
	var a := ArtSprites.floor_tile(&"floor_beige", Vector2i(0, 0))
	var b := ArtSprites.floor_tile(&"floor_beige", Vector2i(1, 0))
	assert_true(a != b, "vizinhos do xadrez têm cores diferentes")
	assert_eq(ArtSprites.floor_tile(&"floor_beige", Vector2i(1, 1)), a, "na diagonal, a mesma cor")
	var seen := {}
	for x in 6:
		for y in 6:
			var tile := ArtSprites.floor_tile(&"floor_wood", Vector2i(x, y))
			assert_eq(ArtSprites.floor_tile(&"floor_wood", Vector2i(x, y)), tile, "a mesma célula sempre igual")
			seen[tile] = true
	assert_true(seen.size() > 1, "o assoalho mistura tábuas diferentes")


func test_walls_have_windows_and_the_cycle_repeats() -> void:
	var windows := 0
	for index in 8:
		if ArtSprites.wall_decoration_name("R", index) == "janela":
			windows += 1
			assert_true(ArtSprites.wall_decoration("R", index) != null)
	assert_true(windows >= 1, "a parede tem janela")
	assert_eq(ArtSprites.wall_decoration_name("L", 9), ArtSprites.wall_decoration_name("L", 1), "o ciclo se repete")


func test_scene_uses_the_art_and_frames_the_taller_walls() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.floor_view.has_art(), "piso com arte")
	assert_true(cafe.wall_view.has_art(), "parede com arte")
	assert_eq(cafe.wall_view.wall_height, ArtSprites.wall_height(), "a altura da parede é a da arte")
	assert_true(cafe.exterior_view.has_art() and cafe.front_view.has_art(), "exterior com arte")
	assert_true(cafe.front_view.z_index > cafe.world_layer.z_index, "a cerca da frente fica por cima do salão")


func test_fence_opens_only_at_the_entrance_row() -> void:
	var cafe := await spawn_cafe()
	var entrance := cafe.layout.entrance
	var middle := entrance.y + 0.5
	var edge_x := float(cafe.layout.grid.size.x) + FrontView.FENCE_OFFSET
	for segment: Array in cafe.front_view.fence_segments():
		var from: Vector2 = segment[0]
		var to: Vector2 = segment[1]
		if is_equal_approx(from.x, edge_x) and is_equal_approx(to.x, edge_x):
			assert_false(middle > minf(from.y, to.y) and middle < maxf(from.y, to.y), "a cerca não fecha a entrada")
	assert_eq(cafe.front_view.fence_segments().size(), 3, "frente esquerda inteira e direita em dois trechos")


func test_outside_follows_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(30)
	simulation.wallet.earn(Wallet.SOFT, 1000, "teste")
	var cafe := await spawn_cafe(simulation)
	assert_eq(cafe.expand_cafe(), ServiceResult.OK)
	assert_eq(cafe.exterior_view.grid_size, cafe.layout.grid.size, "a calçada acompanha")
	assert_eq(cafe.front_view.grid_size, cafe.layout.grid.size, "a cerca acompanha")
	assert_eq(cafe.front_view.entrance, cafe.layout.entrance, "a abertura acompanha a entrada")
	assert_eq(cafe.exterior_view.entrance, cafe.layout.entrance, "o caminho acompanha a entrada")
