extends TestCase
## Recompensa diária (seção 51): sequência de 7 dias, reinício ao perder um dia,
## relógio voltando para trás, e entrega de cada tipo de prêmio.

const DAY := 86400.0

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	clock.time = 20.0 * DAY + 12.0 * 3600.0  # meio-dia de um dia qualquer
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 2)
	sim.customer_types.clear()
	var no_achievements: Array[AchievementDefinition] = []
	sim.set_achievements(no_achievements)


func _calendar() -> DailyRewardCalendar:
	var calendar := DailyRewardCalendar.new()
	calendar.days.assign([{"gold": 10}, {"gold": 20}, {"gold": 30}])
	return calendar


func test_calendar_data_is_valid_and_references_real_items() -> void:
	var calendar: DailyRewardCalendar = load(CafeSimulation.DAILY_REWARDS_PATH)
	assert_true(calendar.is_valid())
	assert_eq(calendar.days.size(), 7, "sequência de 7 dias")
	var furniture := FurnitureCatalog.load_from()
	var surfaces := SurfaceCatalog.load_from()
	for day in calendar.days:
		var furniture_id := StringName(day.get("furniture", &""))
		assert_true(furniture_id == &"" or furniture.get_definition(furniture_id) != null, "móvel %s existe" % furniture_id)
		var surface_id := StringName(day.get("surface", &""))
		assert_true(surface_id == &"" or surfaces.get_definition(surface_id) != null, "revestimento %s existe" % surface_id)


func test_sequence_advances_one_day_at_a_time_and_loops() -> void:
	var daily := DailyRewards.new(_calendar())
	var got := []
	for today in [100, 101, 102, 103]:
		got.append(daily.claim(today).get("gold"))
	assert_eq(got, [10, 20, 30, 10], "depois do último dia recomeça")


func test_only_once_per_day() -> void:
	var daily := DailyRewards.new(_calendar())
	daily.claim(100)
	assert_false(daily.can_claim(100))
	assert_eq(daily.claim(100), {})


func test_missing_a_day_restarts_the_sequence() -> void:
	var daily := DailyRewards.new(_calendar())
	daily.claim(100)
	daily.claim(101)
	assert_eq(daily.index_for(103), 0, "pulou o dia 102")
	daily.calendar.reset_when_missed = false
	assert_eq(daily.index_for(103), 2, "sem reinício, continua de onde parou")


func test_clock_going_backwards_gives_nothing() -> void:
	var daily := DailyRewards.new(_calendar())
	daily.claim(100)
	assert_false(daily.can_claim(99))
	assert_false(daily.can_claim(50))


func test_disabled_without_calendar() -> void:
	var daily := DailyRewards.new()
	assert_false(daily.can_claim(100))
	assert_eq(daily.claim(100), {})


func test_local_midnight_decides_the_day() -> void:
	clock = ManualClock.new()
	clock.offset = -3 * 3600  # Brasília
	clock.time = 10.0 * DAY + 2.0 * 3600.0  # 02:00 UTC = 23:00 do dia anterior em Brasília
	assert_eq(clock.local_day(), 9)
	clock.advance(3600.0)  # meia-noite em Brasília
	assert_eq(clock.local_day(), 10)


func test_claiming_delivers_gold_xp_items_and_surfaces() -> void:
	_setup()
	sim.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	var claimed := []
	sim.daily_reward_claimed.connect(func(day: int, reward: Dictionary) -> void: claimed.append(day))
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_true(sim.can_claim_daily())
	assert_eq(sim.claim_daily()["gold"], 50)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + 50)
	assert_false(sim.can_claim_daily(), "uma vez por dia")
	clock.advance(DAY)
	sim.claim_daily()
	assert_eq(sim.progression.xp, 20)
	clock.advance(DAY)
	sim.claim_daily()
	assert_eq(sim.inventory.count(&"flower_vase"), 1, "móvel vai para o inventário")
	clock.advance(DAY)
	sim.claim_daily()
	clock.advance(DAY)
	var day5 := sim.claim_daily()
	assert_true(sim.style.owns(&"wall_brick"), "revestimento fica do jogador")
	assert_eq(day5.get("surface"), &"wall_brick")
	assert_eq(claimed, [1, 2, 3, 4, 5])


func test_surface_already_owned_turns_into_gold() -> void:
	_setup()
	var calendar := DailyRewardCalendar.new()
	calendar.days.assign([{"surface": &"wall_brick"}])
	sim.daily = DailyRewards.new(calendar)
	sim.style.own(&"wall_brick")
	var gold := sim.wallet.balance(Wallet.SOFT)
	var delivered := sim.claim_daily()
	assert_eq(delivered["gold"], sim.surfaces.get_definition(&"wall_brick").price)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + delivered["gold"])


func test_save_keeps_the_streak() -> void:
	_setup()
	sim.daily = DailyRewards.new(load(CafeSimulation.DAILY_REWARDS_PATH))
	sim.claim_daily()
	clock.advance(DAY)
	sim.claim_daily()
	var text := JSON.stringify(SaveCodec.encode(sim), "", true, true)
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 2).simulation
	assert_false(loaded.can_claim_daily(), "já recebeu hoje")
	clock.advance(DAY)
	assert_eq(loaded.daily_day_number(), 3)


func test_time_until_the_next_daily_reward_counts_to_local_midnight() -> void:
	var clock := ManualClock.new()
	clock.offset = -10800  # Brasília
	clock.time = 86400.0 * 100 + 10800.0 + 3600.0  # 01:00 no horário local
	assert_almost_eq(clock.seconds_to_next_local_day(), 23 * 3600.0, 0.01, "faltam 23 horas para a meia-noite local")
	var simulation := CafeSimulation.create_new_game(clock, 3)
	assert_eq(simulation.seconds_until_daily(), 0.0, "o presente de hoje ainda não foi recebido")
	simulation.claim_daily()
	assert_almost_eq(simulation.seconds_until_daily(), 23 * 3600.0, 0.01, "recebido: volta à meia-noite")
