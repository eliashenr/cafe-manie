extends CafeTestCase
## Amostra visual da direção A (DT-090): a arte nova não muda o contrato dos itens, e comprar, aplicar e reabrir funciona
## com ela. Usa um save de teste numa pasta própria.

## O que a arte não pode mudar: preço, nível, pegada e beleza dos móveis da amostra.
const FURNITURE := {
	&"chair_wood": [30, 1, Vector2i(1, 1), 3],
	&"table_round": [60, 1, Vector2i(1, 1), 5],
	&"stove_basic": [150, 1, Vector2i(1, 1), 0],
	&"counter_basic": [120, 1, Vector2i(1, 1), 2],
}
## Preço cheio, preço por piso, nível e beleza dos revestimentos da amostra.
const SURFACES := {
	&"floor_beige": [0, 0, 1, 0],
	&"floor_wood": [90, 6, 1, 10],
	&"wall_cream": [0, 0, 1, 0],
	&"wall_brick": [120, 30, 1, 10],
}

var dir := ""


func _save_path() -> String:
	if dir.is_empty():
		dir = "user://test_saves/art_%d_%d" % [Time.get_ticks_usec(), randi()]
		DirAccess.make_dir_recursive_absolute(dir)
	return dir.path_join("save.json")


func cleanup() -> void:
	super.cleanup()
	if dir.is_empty():
		return
	for file_name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file_name))
	DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(dir.get_base_dir())


func _open_game(game_clock: GameClock) -> Cafe:
	var cafe: Cafe = CafeScene.instantiate()
	cafe.save_service = SaveService.new(_save_path())
	cafe.game_clock = game_clock
	add_to_tree(cafe)
	await tree.process_frame
	return cafe


func _close_game(cafe: Cafe) -> void:
	cafe.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	cafe.get_parent().remove_child(cafe)
	cafe.queue_free()


func test_sample_items_keep_ids_prices_levels_and_footprints() -> void:
	var catalog := FurnitureCatalog.load_from()
	for id: StringName in FURNITURE:
		var item := catalog.get_definition(id)
		assert_eq([item.price, item.min_level, item.footprint, item.beauty], FURNITURE[id], String(id))
	var surfaces: Array = []
	var simulation := quiet_simulation()
	for id: StringName in SURFACES:
		var surface: SurfaceDefinition = simulation.surfaces.get_definition(id)
		surfaces.append(surface)
		assert_eq([surface.price, surface.tile_price, surface.min_level, surface.beauty], SURFACES[id], String(id))
	assert_eq(surfaces.size(), SURFACES.size())


## As medidas do que o jogo desenha por cima: pratos na mesa e no balcão, panela e quem senta.
func test_sample_art_keeps_the_sprite_contract() -> void:
	assert_almost_eq(ArtSprites.table_top(&"table_round"), 45.33, 0.01)
	assert_almost_eq(ArtSprites.counter_top(), 62.67, 0.01)
	assert_almost_eq(ArtSprites.wall_height(), 152.38, 0.01)
	for rotation in 4:
		for id: StringName in FURNITURE:
			var sprite := ArtSprites.furniture(id, rotation)
			assert_true(sprite != null, "%s na rotação %d" % [id, rotation])
			assert_almost_eq(sprite.density, 2.0, 0.001)
	for rotation in [1, 2]:
		assert_true(ArtSprites.chair_backrest(&"chair_wood", rotation) != null, "encosto de quem senta de costas")
	for side in ["R", "L"]:
		assert_true(ArtSprites.wall_panel(&"wall_cream", side) != null)
		assert_true(ArtSprites.wall_panel(&"wall_brick", side) != null)
	assert_true(ArtSprites.floor_tile(&"floor_beige", Vector2i.ZERO) != null)
	assert_true(ArtSprites.floor_tile(&"floor_wood", Vector2i.ZERO) != null)


## O encosto cobre só o encosto: se a foto dele trouxer a cadeira inteira, o assento cobre quem senta de costas.
func test_chair_backrest_is_smaller_than_the_chair() -> void:
	for rotation in [1, 2]:
		var backrest := ArtSprites.chair_backrest(&"chair_wood", rotation).world_size()
		var chair := ArtSprites.furniture(&"chair_wood", rotation).world_size()
		assert_true(backrest.y < chair.y * 0.75, "encosto %s, cadeira %s" % [backrest, chair])


func test_buying_and_applying_survive_a_reopen() -> void:
	var clock_a := ManualClock.new()
	var first := await _open_game(clock_a)
	first.simulation.wallet.earn(Wallet.SOFT, 5000, "teste")
	var gold_before: int = first.simulation.wallet.balance(Wallet.SOFT)

	assert_true(first.start_painting(&"floor_wood"))
	var floor_cell := Vector2i(6, 6)
	first.toggle_paint_at(IsoProjection.cell_center(floor_cell))
	assert_eq(first.confirm_paint(), ServiceResult.OK)
	assert_eq(first.simulation.wallet.balance(Wallet.SOFT), gold_before - 6, "um piso de madeira custa 6")

	assert_true(first.start_painting(&"wall_brick"))
	var wall_segments: Array = first.simulation.wall_segments()
	first.paint_targets = [wall_segments[0]]
	assert_eq(first.confirm_paint(), ServiceResult.OK)

	assert_true(first.start_placing(&"chair_wood"))
	first._on_tapped(IsoProjection.cell_center(Vector2i(6, 2)))
	assert_true(first.confirm_placement(), "comprou a cadeira")
	var chair := first.layout.placement_at(Vector2i(6, 2)).id
	var gold: int = first.simulation.wallet.balance(Wallet.SOFT)
	var owned: Array = first.simulation.style.owned()
	_close_game(first)

	var clock_b := ManualClock.new()
	clock_b.time = clock_a.time + 10.0
	var second := await _open_game(clock_b)
	await settle()
	assert_eq(second.simulation.wallet.balance(Wallet.SOFT), gold, "o ouro continua igual")
	assert_eq(second.floor_view.surface_at(floor_cell).id, &"floor_wood", "o piso comprado continua lá")
	assert_eq(second.floor_view.surface_at(Vector2i(0, 0)).id, &"floor_beige", "e o resto segue no piso inicial")
	assert_eq(second.simulation.style.wall_at(wall_segments[0]), &"wall_brick", "a parede comprada continua lá")
	assert_true(second.layout.get_placement(chair) != null, "a cadeira comprada continua lá")
	assert_eq(second.layout.get_placement(chair).definition.id, &"chair_wood", "com o mesmo id")
	assert_eq(second.simulation.style.owned(), owned, "os revestimentos possuídos continuam os mesmos")
