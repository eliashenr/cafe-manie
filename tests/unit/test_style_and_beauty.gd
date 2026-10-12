extends TestCase
## Revestimentos de piso e parede, beleza da cafeteria e o efeito dela nos clientes.

var clock: ManualClock
var sim: CafeSimulation


func _setup(gold := 1000) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 5)
	sim.customer_types.clear()
	sim.wallet.earn(Wallet.SOFT, gold, "teste")


func _surface(id: StringName) -> SurfaceDefinition:
	return sim.surfaces.get_definition(id)


# --- Dados -------------------------------------------------------------------

func test_surface_data_has_one_default_per_kind() -> void:
	var catalog := SurfaceCatalog.load_from()
	assert_true(catalog.size() >= 4)
	for kind in [SurfaceDefinition.Kind.FLOOR, SurfaceDefinition.Kind.WALL]:
		var defaults := catalog.all(kind).filter(func(s: SurfaceDefinition) -> bool: return s.is_default)
		assert_eq(defaults.size(), 1, "um revestimento inicial por tipo")
		assert_eq(defaults[0].price, 0, "o inicial é grátis")
		assert_true(catalog.all(kind).size() >= 3, "opções para escolher")


# --- Comprar e aplicar ---------------------------------------------------------

func test_new_cafe_starts_with_default_surfaces_owned_and_applied() -> void:
	_setup()
	assert_eq(sim.style.floor_id, &"floor_beige")
	assert_eq(sim.style.wall_id, &"wall_cream")
	assert_true(sim.style.owns(&"floor_beige") and sim.style.owns(&"wall_cream"))


func test_buying_a_surface_charges_once_and_switching_back_is_free() -> void:
	_setup(200)
	var bought := []
	sim.surface_bought.connect(func(s: SurfaceDefinition) -> void: bought.append(s.id))
	assert_eq(sim.use_surface(_surface(&"floor_wood")), ServiceResult.OK)
	assert_eq(sim.style.floor_id, &"floor_wood")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 200 - 90)
	assert_eq(sim.use_surface(_surface(&"floor_beige")), ServiceResult.OK)
	assert_eq(sim.use_surface(_surface(&"floor_wood")), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 110, "trocar entre os já comprados é grátis")
	assert_eq(bought, [&"floor_wood"])
	assert_eq(sim.style.wall_id, &"wall_cream", "piso não mexe na parede")


func test_locked_or_unaffordable_surface_is_refused_without_charging() -> void:
	_setup(100)
	assert_eq(sim.use_surface(_surface(&"floor_marble")), ServiceResult.SURFACE_LOCKED, "mármore é nível 5")
	assert_eq(sim.use_surface(_surface(&"wall_mint_stripes")), ServiceResult.SURFACE_LOCKED)
	sim.progression.add_xp(30)
	assert_eq(sim.use_surface(_surface(&"floor_blue_tiles")), ServiceResult.NOT_ENOUGH_GOLD, "custa 160")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100)
	assert_eq(sim.style.floor_id, &"floor_beige")


func test_owned_surface_is_usable_even_without_gold() -> void:
	_setup(90)
	sim.use_surface(_surface(&"floor_wood"))
	sim.use_surface(_surface(&"floor_beige"))
	assert_eq(sim.wallet.balance(Wallet.SOFT), 0)
	assert_eq(sim.can_use_surface(_surface(&"floor_wood")), ServiceResult.OK)


# --- Beleza --------------------------------------------------------------------

func test_beauty_adds_placed_furniture_and_surfaces() -> void:
	_setup()
	assert_eq(sim.beauty(), 0, "cafeteria vazia com revestimentos iniciais")
	sim.acquire_and_place(sim.furniture.get_definition(&"plant_pot"), Vector2i(0, 7), 0)
	assert_eq(sim.beauty(), 15)
	sim.use_surface(_surface(&"wall_brick"))
	assert_eq(sim.beauty(), 25)
	sim.store_furniture(sim.last_placed_id)
	assert_eq(sim.beauty(), 10, "guardado não enfeita")


func test_beauty_factor_is_capped() -> void:
	_setup()
	sim.config = sim.config.duplicate()
	sim.config.beauty_for_max_bonus = 20.0
	sim.acquire_and_place(sim.furniture.get_definition(&"plant_pot"), Vector2i(0, 7), 0)
	assert_almost_eq(sim.beauty_factor(), 0.75)
	sim.acquire_and_place(sim.furniture.get_definition(&"plant_pot"), Vector2i(1, 7), 0)
	assert_almost_eq(sim.beauty_factor(), 1.0, 0.001, "nunca passa do bônus máximo")


## Uma cafeteria com mesa e cadeira, clientes chegando, e a beleza pedida.
func _patience_of_first_customer(extra_beauty_items: int) -> float:
	clock = ManualClock.new()
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	var furniture := FurnitureCatalog.load_from()
	layout.place(furniture.get_definition(&"table_round"), Vector2i(3, 3))
	layout.place(furniture.get_definition(&"chair_wood"), Vector2i(2, 3))
	for i in extra_beauty_items:
		layout.place(furniture.get_definition(&"bookshelf"), Vector2i(0, i * 2), 1)
	sim = CafeSimulation.with_game_data(clock, layout, furniture, 3)
	sim.customer_types.assign([load("res://data/customers/regular.tres")])
	for i in 200:
		clock.advance(0.1)
		sim.tick(0.1)
		if not sim.customers.is_empty():
			return sim.customers[0].patience_total
	return -1.0


func test_a_beautiful_cafe_makes_customers_more_patient() -> void:
	var plain := _patience_of_first_customer(0)
	var pretty := _patience_of_first_customer(4)
	assert_true(plain > 0.0 and pretty > 0.0, "clientes chegaram")
	assert_true(pretty > plain, "beleza aumenta a paciência: %.1f → %.1f" % [plain, pretty])
	var factor := sim.beauty_factor()
	assert_almost_eq(pretty, plain * (1.0 + factor * sim.config.beauty_patience_bonus) / (1.0 + 8.0 / sim.config.beauty_for_max_bonus * sim.config.beauty_patience_bonus), 0.01)


# --- Save ------------------------------------------------------------------------

func _round_trip() -> SaveCodec.DecodeResult:
	var text := JSON.stringify(SaveCodec.encode(sim), "", true, true)
	return SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 5)


func test_painting_charges_per_cell_only_for_cells_that_change() -> void:
	_setup(100)
	var wood := _surface(&"floor_wood")
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
	assert_eq(sim.paint_floor(wood, cells), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100 - wood.tile_price * 3)
	assert_eq(sim.style.floor_at(Vector2i(1, 0)), &"floor_wood")
	assert_eq(sim.style.floor_at(Vector2i(3, 0)), &"floor_beige", "o resto não muda")
	var again: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(99, 99)]
	assert_eq(sim.paint_floor(wood, again), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 100 - wood.tile_price * 4, "piso que já era de madeira e piso fora não custam")
	assert_false(sim.style.owns(&"floor_wood"), "pintar não compra o revestimento inteiro")


func test_painting_refused_without_gold_or_level_changes_nothing() -> void:
	_setup(10)
	var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	assert_eq(sim.paint_floor(_surface(&"floor_marble"), cells), ServiceResult.SURFACE_LOCKED)
	var all: Array[Vector2i] = []
	for x in 8:
		all.append(Vector2i(x, 0))
	assert_eq(sim.paint_floor(_surface(&"floor_wood"), all), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.style.floor_at(Vector2i(0, 0)), &"floor_beige")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 10)
	var walls: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_TOP, 0)]
	assert_eq(sim.paint_walls(_surface(&"floor_wood"), walls), ServiceResult.UNKNOWN_ITEM, "piso não vai na parede")


func test_painting_back_with_the_base_erases_the_paint() -> void:
	_setup()
	var cells: Array[Vector2i] = [Vector2i(4, 4)]
	sim.paint_floor(_surface(&"floor_wood"), cells)
	assert_eq(sim.style.painted_floor().size(), 1)
	assert_eq(sim.paint_floor(_surface(&"floor_beige"), cells), ServiceResult.OK)
	assert_eq(sim.style.painted_floor().size(), 0, "voltar para a base só apaga a pintura")


func test_beauty_counts_the_average_of_the_cells() -> void:
	_setup(100000)
	var base := sim.beauty()
	var club := _surface(&"floor_club")
	sim.progression.add_xp(99999)
	var half: Array[Vector2i] = []
	for y in 4:
		for x in 8:
			half.append(Vector2i(x, y))
	sim.paint_floor(club, half)
	var beige := _surface(&"floor_beige").beauty
	assert_eq(sim.beauty(), base + roundi((club.beauty - beige) / 2.0), "metade do piso, metade da beleza")
	var walls := sim.wall_segments()
	assert_eq(walls.size(), 16 + 15, "as duas paredes do fundo e a mureta da frente (sem a porta)")
	sim.paint_walls(_surface(&"wall_club"), walls)
	var expected := base + roundi((club.beauty - beige) / 2.0) + (_surface(&"wall_club").beauty - _surface(&"wall_cream").beauty)
	assert_eq(sim.beauty(), expected, "a parede inteira vale a beleza dela")


func test_save_keeps_painted_cells_and_old_saves_open_plain() -> void:
	_setup()
	var cells: Array[Vector2i] = [Vector2i(1, 2), Vector2i(5, 6)]
	sim.paint_floor(_surface(&"floor_wood"), cells)
	var walls: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_LEFT, 2)]
	sim.paint_walls(_surface(&"wall_brick"), walls)
	var loaded := _round_trip().simulation
	assert_eq(loaded.style.floor_at(Vector2i(5, 6)), &"floor_wood")
	assert_eq(loaded.style.floor_at(Vector2i(0, 0)), &"floor_beige")
	assert_eq(loaded.style.wall_at(CafeStyle.segment(CafeStyle.EDGE_LEFT, 2)), &"wall_brick")
	var data := SaveCodec.encode(sim)
	data["save_version"] = 5
	data["style"].erase("floor_cells")
	data["style"].erase("wall_cells")
	var old := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_eq(old.style.painted_floor().size(), 0, "save antigo: só a base")
	assert_eq(old.style.floor_id, &"floor_beige")


func test_save_drops_paint_of_unknown_surfaces() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["style"]["floor_cells"] = [[1, 1, "piso_que_sumiu"], [2, 2, "wall_brick"], [3, 3, "floor_wood"]]
	var result := SaveCodec.decode(JSON.parse_string(JSON.stringify(data)), clock)
	assert_eq(result.simulation.style.floor_at(Vector2i(1, 1)), &"floor_beige")
	assert_eq(result.simulation.style.floor_at(Vector2i(2, 2)), &"floor_beige", "parede não vai no piso")
	assert_eq(result.simulation.style.floor_at(Vector2i(3, 3)), &"floor_wood")
	assert_eq(result.warnings.size(), 2)


# --- Itens de parede ------------------------------------------------------------------

func _item(id: StringName) -> WallItemDefinition:
	return sim.wall_items.get_definition(id)


func test_wall_item_data_is_valid() -> void:
	_setup()
	assert_true(sim.wall_items.size() >= 13)
	var last_level := 0
	for item in sim.wall_items.all():
		assert_true(item.is_valid(), "%s inválido" % item.id)
		assert_true(sim.collections.get_definition(item.collection) != null, "%s sem coleção conhecida" % item.id)
		assert_true(item.min_level >= last_level, "fora de ordem: %s" % item.id)
		last_level = item.min_level
	assert_true(_item(&"janela").lets_light_in, "a janela deixa a luz entrar")
	assert_false(_item(&"tv").lets_light_in)


func test_new_game_starts_with_the_usual_wall_decorations() -> void:
	var game := CafeSimulation.create_new_game(ManualClock.new(), 3)
	assert_eq(game.style.wall_item_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 0)), &"relogio")
	assert_eq(game.style.wall_item_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 2)), &"janela")
	assert_eq(game.style.wall_item_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 1)), &"", "trecho livre")
	assert_eq(game.style.wall_item_at(CafeStyle.segment(CafeStyle.EDGE_LEFT, 1)), &"quadro_paisagem")


func test_hanging_charges_per_stretch_replaces_and_removing_is_free() -> void:
	_setup(1000)
	sim.progression.add_xp(99999)
	var start := sim.wallet.balance(Wallet.SOFT)  # subir de nível paga conquistas
	var tv := _item(&"tv")
	var two: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_TOP, 1), CafeStyle.segment(CafeStyle.EDGE_LEFT, 0)]
	assert_eq(sim.hang_items(tv, two), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), start - tv.price * 2)
	assert_eq(sim.style.wall_item_at(two[0]), &"tv")
	var again: Array[String] = [two[0], CafeStyle.segment(CafeStyle.EDGE_BOTTOM, 2), "nada:9"]
	assert_eq(sim.hang_items(tv, again), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), start - tv.price * 2, "onde já tem TV, na mureta da frente e fora não cobra")
	var clock_item: Array[String] = [two[0]]
	sim.hang_items(_item(&"relogio"), clock_item)
	assert_eq(sim.style.wall_item_at(two[0]), &"relogio", "o novo item substitui o que estava lá")
	assert_eq(sim.hang_items(null, two), ServiceResult.OK)
	assert_eq(sim.style.hung_items().size(), 0, "tirar enfeite é de graça")
	assert_eq(sim.wallet.balance(Wallet.SOFT), start - tv.price * 2 - _item(&"relogio").price)


func test_locked_or_unaffordable_item_is_refused_without_changes() -> void:
	_setup(10)
	var one: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_TOP, 0)]
	assert_eq(sim.hang_items(_item(&"tv"), one), ServiceResult.FURNITURE_LOCKED)
	assert_eq(sim.hang_items(_item(&"janela"), one), ServiceResult.NOT_ENOUGH_GOLD)
	assert_eq(sim.style.wall_item_at(one[0]), &"")
	assert_eq(sim.wallet.balance(Wallet.SOFT), 10)


func test_wall_items_add_beauty() -> void:
	_setup(1000)
	var before := sim.beauty()
	var spots: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_TOP, 3), CafeStyle.segment(CafeStyle.EDGE_TOP, 4)]
	sim.hang_items(_item(&"quadro_cupcake"), spots)
	assert_eq(sim.beauty(), before + _item(&"quadro_cupcake").beauty * 2)


func test_front_wall_stretches_can_be_painted_but_not_the_door() -> void:
	_setup(1000)
	var brick := _surface(&"wall_brick")
	var door := CafeStyle.segment(CafeStyle.EDGE_RIGHT, sim.layout.entrance.y)
	var spots: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_BOTTOM, 2), door]
	assert_eq(sim.paint_walls(brick, spots), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 1000 - brick.tile_price, "só a mureta; a porta não é parede")
	assert_eq(sim.style.wall_at(spots[0]), &"wall_brick")


func test_save_keeps_wall_items_and_old_saves_get_the_usual_ones_once() -> void:
	_setup(1000)
	var spot: Array[String] = [CafeStyle.segment(CafeStyle.EDGE_LEFT, 6)]
	sim.hang_items(_item(&"janela"), spot)
	assert_eq(_round_trip().simulation.style.wall_item_at(spot[0]), &"janela")
	var data := SaveCodec.encode(sim)
	data["save_version"] = 6
	data["style"].erase("wall_items")
	var old := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_eq(old.style.wall_item_at(CafeStyle.segment(CafeStyle.EDGE_TOP, 0)), &"relogio", "save antigo: os enfeites de sempre")
	assert_false(SaveCodec.encode(old).has(SaveCodec.LEGACY_WALL_ITEMS_KEY), "a marca não volta para o save")
	data = SaveCodec.encode(sim)
	data["style"]["wall_items"] = [["top:1", "item_que_sumiu"]]
	var result := SaveCodec.decode(JSON.parse_string(JSON.stringify(data)), clock)
	assert_eq(result.simulation.style.wall_item_at("top:1"), &"", "item que deixou de existir sai da parede")
	assert_eq(result.warnings.size(), 1)


func test_save_keeps_owned_and_applied_surfaces() -> void:
	_setup()
	sim.use_surface(_surface(&"floor_wood"))
	sim.use_surface(_surface(&"wall_brick"))
	sim.use_surface(_surface(&"floor_beige"))
	var loaded := _round_trip().simulation
	assert_eq(loaded.style.floor_id, &"floor_beige")
	assert_eq(loaded.style.wall_id, &"wall_brick")
	assert_true(loaded.style.owns(&"floor_wood"), "o piso comprado continua do jogador")


func test_version_2_save_opens_with_default_surfaces() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["save_version"] = 2
	data.erase("style")
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_true(loaded != null)
	assert_eq(loaded.style.floor_id, &"floor_beige")
	assert_eq(loaded.style.wall_id, &"wall_cream")


func test_unknown_applied_surface_falls_back_to_default() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["style"] = {"floor": "floor_que_sumiu", "wall": "wall_brick", "owned": ["floor_que_sumiu"]}
	var result := SaveCodec.decode(JSON.parse_string(JSON.stringify(data)), clock)
	assert_eq(result.simulation.style.floor_id, &"floor_beige")
	assert_eq(result.simulation.style.wall_id, &"wall_cream", "parede não comprada volta para a inicial")
	assert_true(result.simulation.style.owns(&"floor_beige"), "os iniciais continuam do jogador")
	assert_eq(result.warnings.size(), 2)
