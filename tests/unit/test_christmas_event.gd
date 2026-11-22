extends TestCase
## Evento de Natal (DT-100): vale de 1/12 a 26/12 todo ano, não se cruza com outro evento, tem historinha do Papai Noel,
## 5 missões, o Forno do Papai Noel que sobe de nível e a Árvore de Natal no fim. Cada evento tem o seu ícone.


func _natal() -> EventDefinition:
	return load("res://data/events/natal.tres")


## Todos os eventos de res://data/events.
func _all_events() -> Array[EventDefinition]:
	var events: Array[EventDefinition] = []
	for file_name in ResourceLoader.list_directory(CafeSimulation.EVENTS_DIR):
		if file_name.ends_with(".tres"):
			events.append(load(CafeSimulation.EVENTS_DIR.path_join(file_name)))
	return events


func test_the_christmas_data_is_valid() -> void:
	var event := _natal()
	assert_true(event.is_valid())
	assert_eq(event.speaker, "Papai Noel")
	assert_eq(event.story.size(), 4, "historinha em 4 quadros")
	assert_eq(CafeSimulation.load_missions(event.missions_dir).size(), 5)
	var catalog := FurnitureCatalog.load_from()
	var oven: FurnitureDefinition = catalog.get_definition(event.prize_stove)
	assert_eq(oven.category, FurnitureDefinition.Category.COOKING)
	assert_false(oven.sold_for_gold, "o forno só se ganha")
	assert_eq(oven.stove_level_cuts.size(), event.stove_levels_at.size(), "um corte por nível")
	var tree: FurnitureDefinition = catalog.get_definition(event.final_prize)
	assert_eq(tree.category, FurnitureDefinition.Category.DECOR)
	assert_false(tree.sold_for_gold)


func test_christmas_runs_from_the_first_to_the_twenty_sixth_of_december() -> void:
	var event := _natal()
	assert_false(event.is_active_on({"month": 11, "day": 30}))
	assert_true(event.is_active_on({"month": 12, "day": 1}))
	assert_true(event.is_active_on({"month": 12, "day": 25}))
	assert_true(event.is_active_on({"month": 12, "day": 26}))
	assert_false(event.is_active_on({"month": 12, "day": 27}))


func test_no_two_events_share_a_day() -> void:
	var events := _all_events()
	assert_true(events.size() >= 2, "Halloween e Natal")
	for month in range(1, 13):
		for day in range(1, 32):
			var active := events.filter(func(e: EventDefinition) -> bool: return e.is_active_on({"month": month, "day": day}))
			assert_true(active.size() <= 1, "dois eventos em %d/%d" % [day, month])


func test_each_event_has_its_own_icon_and_art() -> void:
	for event in _all_events():
		assert_true(ArtSprites.get_sprite(event.icon) != null, "ícone de %s" % event.id)
		assert_true(ArtSprites.get_sprite(event.portrait) != null, "retrato de %s" % event.id)
		for prize in [event.prize_stove, event.final_prize]:
			assert_true(ArtSprites.furniture(prize, 0) != null, "arte de %s" % prize)
	assert_eq(_natal().icon, "medalhao_natal")
	assert_eq((load("res://data/events/halloween.tres") as EventDefinition).icon, "medalhao_evento", "o Halloween continua com a abóbora")


func test_christmas_starts_on_the_first_of_december_and_gives_the_oven() -> void:
	var clock := ManualClock.new()
	clock.time = Time.get_unix_time_from_datetime_string("2026-12-10T12:00:00")
	var sim := CafeSimulation.create_new_game(clock, 11)
	sim.refresh_event()
	assert_eq(sim.current_event().id, &"natal")
	assert_eq(sim.event_board.entries().size(), 5)
	var first := sim.event_board.entries()[0]
	sim.event_board.record(first.mission.kind, first.target, sim.recipes.get_definition(&"lasagna"), -1)
	assert_eq(int(sim.event_stove_levels.get(&"santa_oven", 0)), 1, "a 1ª missão entrega o forno")
	assert_eq(sim.inventory.count(&"santa_oven"), 1, "o forno vai para o inventário")
