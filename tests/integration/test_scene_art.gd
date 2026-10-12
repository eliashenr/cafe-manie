extends CafeTestCase
## Arte v3 do cenário: todo revestimento tem peças de piso e de parede, o xadrez
## alterna, as variações são estáveis, a parede tem enfeites e a altura da arte,
## os itens de parede têm desenho, e o exterior (gramado, calçada, mureta e porta) acompanha o tamanho
## do grid e a entrada.


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


func test_every_wall_item_has_art_on_both_walls_and_the_door_exists() -> void:
	var catalog := WallItemCatalog.load_from()
	assert_true(catalog.size() >= 13, "janelas, quadros, relógio, prateleira, TV, rádio...")
	for item in catalog.all():
		for side in ["R", "L"]:
			assert_true(ArtSprites.get_sprite("enfeite_%s_%s" % [item.art, side]) != null, "%s sem desenho %s" % [item.id, side])
	assert_true(ArtSprites.get_sprite("enfeite_porta_L") != null, "a porta da entrada")


func test_scene_uses_the_art_and_frames_the_taller_walls() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.floor_view.has_art(), "piso com arte")
	assert_true(cafe.wall_view.has_art(), "parede com arte")
	assert_eq(cafe.wall_view.wall_height, ArtSprites.wall_height(), "a altura da parede é a da arte")
	assert_true(cafe.exterior_view.has_art() and cafe.front_view.has_art(), "exterior com arte")
	assert_true(cafe.front_view.z_index > cafe.world_layer.z_index, "a mureta da frente fica por cima do salão")


func test_front_walls_close_the_cafe_except_the_door_and_stay_low() -> void:
	var cafe := await spawn_cafe()
	var segments := cafe.front_view.front_segments()
	assert_eq(segments.size(), 8 + 7, "a frente da esquerda inteira e a da direita sem o trecho da porta")
	var door := CafeStyle.segment(CafeStyle.EDGE_RIGHT, cafe.layout.entrance.y)
	assert_false(segments.has(door), "a entrada fica livre")
	assert_true(FrontView.FRONT_WALL_HEIGHT < cafe.wall_view.wall_height * 0.5, "baixa: o salão continua à vista")
	var stretch := CafeStyle.segment(CafeStyle.EDGE_BOTTOM, 3)
	var center := Vector2.ZERO
	for point in cafe.front_view.segment_polygon(stretch):
		center += point / 4.0
	assert_eq(cafe.front_view.segment_at(center), stretch, "dá para tocar na mureta")
	assert_eq(cafe.front_view.wall_style.id, &"wall_cream", "a mureta usa o revestimento da parede")


func test_outside_follows_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(30)
	simulation.wallet.earn(Wallet.SOFT, 1000, "teste")
	var cafe := await spawn_cafe(simulation)
	assert_eq(cafe.expand_cafe(), ServiceResult.OK)
	assert_eq(cafe.exterior_view.grid_size, cafe.layout.grid.size, "a calçada acompanha")
	assert_eq(cafe.front_view.grid_size, cafe.layout.grid.size, "a mureta acompanha")
	assert_eq(cafe.front_view.entrance, cafe.layout.entrance, "a porta acompanha a entrada")
	assert_eq(cafe.exterior_view.entrance, cafe.layout.entrance, "o caminho acompanha a entrada")
