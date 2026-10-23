extends TestCase
## Eventos com prazo (DT-063): o Halloween vale de 20/10 a 3/11 todo ano; tem historinha, 5 missões que recomeçam a
## cada edição e o Caldeirão da Bruxa, que chega na 1ª missão e sobe de nível na 3ª e na 5ª (cada nível mais rápido);
## completar tudo dá a Abóbora Gigante. O save guarda o progresso.

var clock: ManualClock
var sim: CafeSimulation


func _setup(date := "2026-10-25T12:00:00") -> void:
	clock = ManualClock.new()
	clock.time = Time.get_unix_time_from_datetime_string(date)
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.refresh_event()


func _halloween() -> EventDefinition:
	return load("res://data/events/halloween.tres")


## Conclui a missão do quadro do evento (a de índice [param index]).
func _complete(index: int) -> void:
	var entry := sim.event_board.entries()[index]
	sim.event_board.record(entry.mission.kind, entry.target, sim.recipes.get_definition(&"lasagna"), -1)


func test_the_halloween_data_is_valid() -> void:
	var event := _halloween()
	assert_true(event.is_valid())
	assert_eq(event.story.size(), 4, "historinha em 4 quadros")
	assert_eq(CafeSimulation.load_missions(event.missions_dir).size(), 5)
	var stove: FurnitureDefinition = FurnitureCatalog.load_from().get_definition(event.prize_stove)
	assert_eq(stove.category, FurnitureDefinition.Category.COOKING)
	assert_false(stove.sold_for_gold, "o caldeirão só se ganha")
	assert_eq(stove.stove_level_cuts.size(), event.stove_levels_at.size(), "um corte por nível")
	for i in range(1, stove.stove_level_cuts.size()):
		assert_true(stove.stove_level_cuts[i] > stove.stove_level_cuts[i - 1], "cada nível mais rápido")
	assert_false(FurnitureCatalog.load_from().get_definition(event.final_prize).sold_for_gold)
	var broken: EventDefinition = event.duplicate()
	broken.stove_levels_at = PackedInt32Array([3, 1])
	assert_false(broken.is_valid(), "níveis em ordem")


func test_the_event_window_and_editions() -> void:
	var event := _halloween()
	assert_true(event.is_active_on({"month": 10, "day": 20}))
	assert_true(event.is_active_on({"month": 11, "day": 3}))
	assert_false(event.is_active_on({"month": 10, "day": 19}))
	assert_false(event.is_active_on({"month": 11, "day": 4}))
	var winter: EventDefinition = event.duplicate()
	winter.start_month = 12
	winter.start_day = 20
	winter.end_month = 1
	winter.end_day = 6
	assert_true(winter.is_active_on({"month": 1, "day": 2}), "evento que vira o ano")
	assert_false(winter.is_active_on({"month": 2, "day": 2}))
	assert_eq(winter.edition_for({"year": 2027, "month": 1, "day": 2}), 2026, "a edição é a do ano em que começou")


func test_the_board_runs_only_during_the_event() -> void:
	_setup()
	assert_true(sim.current_event() != null)
	assert_eq(sim.event_board.size(), 5)
	assert_eq(sim.event_days_left(), 9, "de 25/10 a 3/11")
	clock.time = Time.get_unix_time_from_datetime_string("2026-11-04T12:00:00")
	sim.refresh_event()
	assert_true(sim.event_board == null, "acabou o prazo: as missões do evento somem")
	_setup("2026-12-01T12:00:00")
	assert_true(sim.current_event() == null)
	assert_true(sim.event_board == null, "fora do evento, sem missões dele")
	assert_eq(sim.event_days_left(), -1)


func test_missions_unlock_and_level_the_cauldron_and_the_final_prize() -> void:
	_setup()
	var event := sim.current_event()
	var upgrades: Array = []
	var finished: Array = []
	sim.event_stove_upgraded.connect(func(_e: EventDefinition, level: int) -> void: upgrades.append(level))
	sim.event_finished.connect(func(e: EventDefinition) -> void: finished.append(e.id))
	var gold := sim.wallet.balance(Wallet.SOFT)
	_complete(0)
	assert_eq(upgrades, [1], "a 1ª missão entrega o caldeirão")
	assert_eq(sim.inventory.count(event.prize_stove), 1, "guardado no inventário")
	assert_true(sim.wallet.balance(Wallet.SOFT) > gold, "e paga o ouro da missão")
	_complete(1)
	assert_eq(upgrades, [1])
	_complete(2)
	assert_eq(upgrades, [1, 2], "na 3ª, nível 2")
	_complete(3)
	_complete(4)
	assert_eq(upgrades, [1, 2, 3], "na 5ª, nível 3")
	assert_eq(finished, [&"halloween"])
	assert_eq(sim.inventory.count(event.final_prize), 1, "a Abóbora Gigante")
	assert_eq(sim.inventory.count(event.prize_stove), 1, "o caldeirão não vem repetido")


func test_the_cauldron_gets_faster_each_level() -> void:
	_setup()
	var cauldron := sim.layout.place(sim.furniture.get_definition(&"witch_cauldron"), Vector2i(5, 1))
	var coffee := sim.recipes.get_definition(&"coffee")
	var cuts := sim.furniture.get_definition(&"witch_cauldron").stove_level_cuts
	assert_eq(sim.cook_time_on(cauldron, coffee), coffee.cook_time, "sem nível, tempo normal")
	sim.event_stove_levels[&"witch_cauldron"] = 1
	assert_almost_eq(sim.cook_time_on(cauldron, coffee), coffee.cook_time * (1.0 - cuts[0]), 0.001)
	sim.event_stove_levels[&"witch_cauldron"] = 3
	assert_almost_eq(sim.cook_time_on(cauldron, coffee), coffee.cook_time * (1.0 - cuts[2]), 0.001)


func test_the_story_shows_once_per_edition() -> void:
	_setup()
	assert_true(sim.event_story_pending())
	sim.mark_event_story_seen()
	assert_false(sim.event_story_pending())
	clock.time = Time.get_unix_time_from_datetime_string("2027-10-25T12:00:00")
	sim.refresh_event()
	assert_true(sim.event_story_pending(), "no ano seguinte, de novo")


func test_a_new_edition_restarts_the_missions_but_keeps_the_cauldron() -> void:
	_setup()
	_complete(0)
	clock.time = Time.get_unix_time_from_datetime_string("2027-10-25T12:00:00")
	sim.refresh_event()
	assert_eq(sim.event_board.completed_count(), 0, "missões do zero")
	assert_eq(int(sim.event_stove_levels.get(&"witch_cauldron", 0)), 1, "o caldeirão continua com o nível")


func test_the_save_keeps_the_event_progress() -> void:
	_setup()
	_complete(0)
	_complete(1)
	sim.mark_event_story_seen()
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_eq(loaded.event_board.completed_count(), 2)
	assert_eq(int(loaded.event_stove_levels.get(&"witch_cauldron", 0)), 1)
	assert_false(loaded.event_story_pending())
	var old := SaveCodec.encode(sim)
	old["save_version"] = 15
	old.erase("events")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["events"], {}, "a migração acrescenta os eventos")


func test_playing_counts_for_the_event_missions() -> void:
	_setup()
	sim._record(MissionDefinition.Kind.SERVE_CUSTOMERS, 3)
	var serve: MissionBoard.Entry = null
	for entry in sim.event_board.entries():
		if entry.mission.kind == MissionDefinition.Kind.SERVE_CUSTOMERS:
			serve = entry
	assert_eq(serve.progress, 3, "servir clientes conta para a missão do evento")
