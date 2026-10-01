extends TestCase
## Formato do save: tudo o que importa volta igual, inclusive depois de passar
## por JSON, e o tempo de preparo continua correndo com o jogo fechado.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName
var counter: StringName


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	for placement in sim.layout.placements():
		if placement.origin == Vector2i(0, 0):
			stove = placement.id
		if placement.origin == Vector2i(3, 0):
			counter = placement.id


## Ida e volta completa, como no disco: dicionário → texto JSON → dicionário → jogo.
func _round_trip(load_clock: GameClock = clock) -> SaveCodec.DecodeResult:
	var text := JSON.stringify(SaveCodec.encode(sim), "", true, true)
	var parsed: Dictionary = JSON.parse_string(text)
	return SaveCodec.decode(SaveCodec.migrate(parsed), load_clock, 11)


func test_encoded_save_has_version_and_timestamp() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	assert_eq(data["save_version"], SaveCodec.CURRENT_VERSION, "nunca salvar sem versão (seção 64)")
	assert_eq(data["saved_at"], clock.now())


func test_round_trip_keeps_layout_with_original_ids() -> void:
	_setup()
	var plant := sim.layout.place(sim.furniture.get_definition(&"plant_pot"), Vector2i(6, 7), 2)
	var loaded := _round_trip().simulation
	assert_eq(loaded.layout.count(), sim.layout.count())
	for placement in sim.layout.placements():
		var copy := loaded.layout.get_placement(placement.id)
		assert_true(copy != null, "sumiu: %s" % placement.id)
		if copy != null:
			assert_eq(copy.definition.id, placement.definition.id)
			assert_eq(copy.origin, placement.origin)
			assert_eq(copy.rotation, placement.rotation)
	assert_eq(loaded.layout.get_placement(plant).rotation, 2)
	assert_eq(loaded.layout.grid.size, sim.layout.grid.size)
	assert_eq(loaded.layout.entrance, sim.layout.entrance)


func test_new_furniture_after_loading_never_reuses_an_id() -> void:
	_setup()
	var loaded := _round_trip().simulation
	var existing := {}
	for placement in loaded.layout.placements():
		existing[placement.id] = true
	# Mesmo tipo de um móvel que já existe: é aqui que um id repetido sobrescreveria o antigo.
	var fresh := loaded.layout.place(loaded.furniture.get_definition(&"stove_basic"), Vector2i(6, 7))
	assert_true(fresh != &"" and not existing.has(fresh), "id novo repetiu um antigo: %s" % fresh)
	assert_eq(loaded.layout.count(), existing.size() + 1, "nenhum móvel foi sobrescrito")


func test_round_trip_keeps_gold_xp_level_and_popularity() -> void:
	_setup()
	sim.wallet.earn(Wallet.SOFT, 123, "teste")
	sim.progression.add_xp(95)
	sim.restore_popularity(73.5)
	var loaded := _round_trip().simulation
	assert_eq(loaded.wallet.balance(Wallet.SOFT), sim.wallet.balance(Wallet.SOFT))
	assert_eq(loaded.progression.xp, 95)
	assert_eq(loaded.progression.level, sim.progression.level)
	assert_almost_eq(loaded.popularity, 73.5)


func test_food_keeps_cooking_while_the_game_is_closed() -> void:
	_setup()
	sim.start_cooking(stove, &"cheese_bread")  # 40 s
	clock.advance(10.0)
	var data := JSON.stringify(SaveCodec.encode(sim), "", true, true)

	var later := ManualClock.new()
	later.time = clock.time + 3600.0  # jogo reaberto 1 hora depois
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(data)), later).simulation
	assert_eq(loaded.kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "ficou pronto enquanto estava fechado")
	assert_eq(loaded.kitchen.stove_recipe(stove).id, &"cheese_bread")


func test_cooking_time_survives_json_precisely() -> void:
	_setup()
	clock.time = 1_759_150_123.25  # horário real típico, número grande
	sim.start_cooking(stove, &"coffee")
	clock.advance(5.0)
	var loaded := _round_trip().simulation
	assert_almost_eq(loaded.kitchen.time_left(stove), 10.0, 0.01, "o tempo restante não pode mudar ao salvar")


func test_counter_servings_and_reserved_orders_come_back() -> void:
	_setup()
	sim.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	sim.collect(stove)
	var coffee := sim.recipes.get_definition(&"coffee")
	sim.kitchen.take_serving(coffee)  # porção entregue de verdade: não volta
	# Um cliente pede (reserva uma porção), mas o jogo fecha antes de ele ser servido.
	var steps := 0
	while sim.pending_orders() == 0 and steps < 600:
		clock.advance(0.1)
		sim.tick(0.1)
		steps += 1
	assert_eq(sim.pending_orders(), 1, "precisava de um pedido em andamento")
	var loaded := _round_trip().simulation
	assert_eq(loaded.kitchen.servings_of(loaded.recipes.get_definition(&"coffee")), coffee.servings - 1,
		"a porção reservada volta ao balcão; a entregue não")
	assert_eq(loaded.customers.size(), 0, "a cafeteria reabre sem clientes")


func test_unknown_content_is_skipped_with_warnings() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["layout"]["placements"].append({"id": "sofa_magico#99", "furniture": "sofa_magico", "origin": [6, 7], "rotation": 0})
	data["kitchen"]["stoves"].append({"id": String(stove), "recipe": "receita_extinta", "started_at": 0.0})
	var result := SaveCodec.decode(data, clock)
	assert_true(result.simulation != null, "o resto do save continua valendo")
	assert_eq(result.simulation.layout.count(), sim.layout.count())
	assert_eq(result.warnings.size(), 2)


func test_unusable_data_gives_no_simulation() -> void:
	_setup()
	assert_eq(SaveCodec.decode({}, clock).simulation, null, "sem versão")
	var data := SaveCodec.encode(sim)
	data["layout"]["size"] = "grande"
	assert_eq(SaveCodec.decode(data, clock).simulation, null, "layout sem tamanho válido")


func test_version_1_save_still_opens() -> void:
	# Um save da versão 1 (zip anterior ao inventário e às missões) precisa abrir.
	_setup()
	sim.wallet.earn(Wallet.SOFT, 40, "teste")
	var data := SaveCodec.encode(sim)
	data["save_version"] = 1
	data.erase("inventory")
	data.erase("missions")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(data)))
	assert_eq(migrated["save_version"], SaveCodec.CURRENT_VERSION)
	var loaded := SaveCodec.decode(migrated, clock).simulation
	assert_true(loaded != null)
	assert_eq(loaded.wallet.balance(Wallet.SOFT), sim.wallet.balance(Wallet.SOFT))
	assert_eq(loaded.inventory.total(), 0)
	assert_eq(loaded.missions.completed_count(), 0)


func test_round_trip_keeps_inventory_and_mission_progress() -> void:
	_setup()
	sim.inventory.add(&"plant_pot", 2)
	sim.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	sim.collect(stove)  # conta para a missão "Prepare 3 pratos"
	var loaded := _round_trip().simulation
	assert_eq(loaded.inventory.count(&"plant_pot"), 2)
	assert_eq(loaded.missions.current().id, sim.missions.current().id)
	assert_eq(loaded.missions.progress(), 1)


func test_migration_runs_each_step_in_order() -> void:
	var steps: Array[Callable] = [
		func(d: Dictionary) -> Dictionary:
			d["gold"] = d.get("gold", 0) + 1
			return d,
		func(d: Dictionary) -> Dictionary:
			d["renamed"] = d["gold"] * 10
			return d,
	]
	var migrated := SaveCodec.migrate({"save_version": 1, "gold": 5}, 3, steps)
	assert_eq(migrated["save_version"], 3)
	assert_eq(migrated["renamed"], 60)


func test_migration_refuses_newer_missing_or_incomplete_versions() -> void:
	var no_steps: Array[Callable] = []
	assert_eq(SaveCodec.migrate({"save_version": 5}, 3, no_steps), {}, "versão mais nova que o jogo")
	assert_eq(SaveCodec.migrate({"gold": 1}, 3, no_steps), {}, "sem versão")
	assert_eq(SaveCodec.migrate({"save_version": 1}, 3, no_steps), {}, "falta o passo de migração")
	assert_eq(SaveCodec.migrate({"save_version": 3, "x": 1}, 3, no_steps), {"save_version": 3, "x": 1}, "já atual")


func test_round_trip_keeps_the_cafe_name_and_old_saves_get_a_default() -> void:
	_setup()
	sim.set_cafe_name("Doce Grão")
	assert_eq(_round_trip().simulation.cafe_name, "Doce Grão")
	var data := SaveCodec.encode(sim)
	data["save_version"] = 2
	data.erase("cafe_name")
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_eq(loaded.cafe_name, CafeSimulation.DEFAULT_CAFE_NAME, "quem já jogava não é interrompido")


func _chair_away_from_table() -> StringName:
	# Canto livre do jogo novo: nenhuma outra mesa encosta na cadeira.
	var table := sim.layout.place(sim.furniture.get_definition(&"table_round"), Vector2i(6, 6))
	assert_true(table != &"", "mesa posta")
	var chair := sim.layout.place(sim.furniture.get_definition(&"chair_wood"), Vector2i(5, 6), 1)
	assert_true(chair != &"", "cadeira posta de costas para a mesa")
	return chair


func test_old_saves_turn_their_chairs_toward_the_table_once() -> void:
	_setup()
	var chair := _chair_away_from_table()
	var data := SaveCodec.encode(sim)
	data["save_version"] = 3
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_eq(loaded.layout.get_placement(chair).rotation, 3, "a cadeira do save antigo olha para a mesa")
	var again := SaveCodec.encode(loaded)
	assert_false(again.has(SaveCodec.TURN_SEATS_KEY), "a marca não volta para o save")


func test_current_saves_keep_the_chair_where_the_player_turned_it() -> void:
	_setup()
	var chair := _chair_away_from_table()
	assert_eq(_round_trip().simulation.layout.get_placement(chair).rotation, 1, "escolha do jogador")
