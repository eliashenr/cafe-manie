extends CafeTestCase
## Arte v3 dos móveis: todo móvel do catálogo tem sprite nas 4 rotações, com
## a âncora no vértice da frente, e a cena desenha o sprite no lugar da caixa.


func test_every_catalog_furniture_has_a_sprite_for_each_rotation() -> void:
	for definition in FurnitureCatalog.load_from().all():
		for rotation in 4:
			var sprite := ArtSprites.furniture(definition.id, rotation)
			assert_true(sprite != null, "%s sem sprite na rotação %d" % [definition.id, rotation])
			if sprite == null:
				continue
			var size := sprite.texture.get_size()
			assert_true(sprite.anchor.x > 0.0 and sprite.anchor.x < size.x, "%s r%d: âncora fora na horizontal" % [definition.id, rotation])
			# O móvel não encosta na ponta da frente do piso: a âncora pode ficar um pouco abaixo do desenho.
			var below := IsoProjection.HALF_TILE.y * sprite.density
			assert_true(sprite.anchor.y > 0.0 and sprite.anchor.y <= size.y + below,
				"%s r%d: âncora fora na vertical" % [definition.id, rotation])


func test_sprite_covers_the_footprint_on_screen() -> void:
	# Pega erro de escala: o sprite não pode ser minúsculo nem passar das pontas da pegada.
	for definition in FurnitureCatalog.load_from().all():
		for rotation in 4:
			var sprite := ArtSprites.furniture(definition.id, rotation)
			if sprite == null:
				continue
			var footprint := CafeLayout.rotated_footprint(definition.footprint, rotation)
			var rect := sprite.draw_rect()
			var left := IsoProjection.cell_top_vertex(Vector2i(0, footprint.y)).x
			var right := IsoProjection.cell_top_vertex(Vector2i(footprint.x, 0)).x
			var front := IsoProjection.cell_top_vertex(footprint)
			var footprint_span := right - left
			var tolerance := IsoProjection.HALF_TILE.x * 0.25
			assert_true(rect.size.x >= footprint_span * 0.3,
				"%s r%d: sprite estreito demais para a pegada" % [definition.id, rotation])
			assert_true(rect.position.x >= left - front.x - tolerance and rect.end.x <= right - front.x + tolerance,
				"%s r%d: sprite sai da pegada" % [definition.id, rotation])


func test_unknown_furniture_has_no_sprite() -> void:
	assert_eq(ArtSprites.furniture(&"nao_existe", 0), null)


func test_scene_draws_furniture_with_its_rotated_sprite() -> void:
	var cafe := await spawn_cafe()
	var stove := cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(1, 1), 3)
	await settle()
	var view := cafe.world_layer.view_for(stove)
	assert_true(view.sprite != null, "o fogão usa a arte")
	assert_eq(view.sprite, ArtSprites.furniture(&"stove_basic", 3), "sprite da rotação certa")


func test_ghost_uses_the_sprite_too() -> void:
	var cafe := await spawn_cafe()
	cafe.world_layer.show_ghost(cafe.catalog.get_definition(&"table_long"), Vector2i(2, 2), 1, true)
	await settle()
	var ghost: FurnitureView = cafe.world_layer.get_node("Ghost")
	assert_eq(ghost.sprite, ArtSprites.furniture(&"table_long", 1))


func test_every_recipe_has_cookware_and_the_stove_glows_only_when_its_front_shows() -> void:
	for recipe in RecipeCatalog.load_from().all():
		assert_true(ArtSprites.cookware(recipe.id) != null, "%s sem panela" % recipe.id)
	assert_true(ArtSprites.stove_glow(0) != null and ArtSprites.stove_glow(3) != null, "forno aceso de frente")
	assert_eq(ArtSprites.stove_glow(1), null, "de costas não se vê o forno")
	assert_eq(ArtSprites.stove_glow(2), null)
	assert_true(ArtSprites.counter_top() > 0.0, "altura do tampo do balcão")


func test_kitchen_shows_pot_badge_and_plate_stack() -> void:
	var cafe := await spawn_cafe()
	var stove := cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0))
	var counter := cafe.layout.place(cafe.catalog.get_definition(&"counter_basic"), Vector2i(2, 0))
	cafe.simulation.start_cooking(stove, &"coffee")
	cafe.world_layer.refresh(cafe.simulation)
	var stove_view := cafe.world_layer.view_for(stove)
	assert_eq(stove_view.kitchen_recipe.id, &"coffee", "o fogão sabe o que cozinha")
	assert_true(stove_view.kitchen_detail.contains(":"), "o selo mostra o tempo: " + stove_view.kitchen_detail)
	assert_true(stove_view.shows_kitchen_art(), "panela e selo no lugar da etiqueta")
	clock.advance(1000.0)
	cafe.world_layer.refresh(cafe.simulation)
	assert_eq(stove_view.kitchen_detail, WorldLayer.READY_TEXT, "pronto")
	assert_true(stove_view.status_ready)
	cafe.simulation.collect(stove)
	cafe.world_layer.refresh(cafe.simulation)
	assert_eq(stove_view.kitchen_recipe, null, "fogão livre, sem panela")
	var counter_view := cafe.world_layer.view_for(counter)
	assert_eq(counter_view.kitchen_recipe.id, &"coffee", "o prato foi para o balcão")
	assert_true(counter_view.kitchen_count > 0 and counter_view.shows_kitchen_art(), "pilha de pratos com o número")
	var overlay: Node2D = counter_view.get_node("Overlay")
	assert_true(overlay.z_index > 0, "selos por cima do salão")
