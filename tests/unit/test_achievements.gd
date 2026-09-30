extends TestCase
## Contadores do jogador e conquistas progressivas (seção 49).

var clock: ManualClock
var sim: CafeSimulation


func _setup(gold := 1000) -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 4)
	sim.customer_types.clear()
	sim.wallet.earn(Wallet.SOFT, gold, "teste")


func _achievement(id: StringName) -> AchievementDefinition:
	for achievement in sim.achievements.achievements:
		if achievement.id == id:
			return achievement
	return null


func test_achievement_data_is_valid_and_progressive() -> void:
	var list := CafeSimulation.default_achievements()
	assert_true(list.size() >= 6)
	var stats := [PlayerStats.CUSTOMERS_SERVED, PlayerStats.DISHES_COOKED, PlayerStats.GOLD_EARNED,
		PlayerStats.FURNITURE_BOUGHT, PlayerStats.EXPANSIONS, PlayerStats.LEVEL, PlayerStats.BEAUTY]
	for achievement in list:
		assert_true(achievement.is_valid(), "%s inválida" % achievement.id)
		assert_true(achievement.tier_count() >= 2, "%s precisa ser progressiva" % achievement.id)
		assert_true(achievement.stat in stats, "%s acompanha um contador que não existe" % achievement.id)


func test_definition_rejects_bad_tiers() -> void:
	var achievement := AchievementDefinition.new()
	achievement.id = &"x"
	achievement.stat = PlayerStats.LEVEL
	achievement.tier_titles.assign(["a", "b"])
	achievement.tier_rewards.assign([1, 1])
	achievement.tier_targets.assign([5, 3])
	assert_false(achievement.is_valid(), "metas precisam crescer")
	achievement.tier_targets.assign([3, 5])
	assert_true(achievement.is_valid())
	achievement.tier_rewards.assign([1])
	assert_false(achievement.is_valid(), "um prêmio por degrau")


func test_first_purchase_unlocks_and_pays_once() -> void:
	_setup(200)
	var unlocked := []
	sim.achievement_unlocked.connect(func(a: AchievementDefinition, tier: int) -> void: unlocked.append([a.id, tier]))
	sim.acquire_and_place(sim.furniture.get_definition(&"chair_wood"), Vector2i(2, 2), 0)
	assert_eq(unlocked, [[&"a07_furniture", 0]])
	assert_eq(sim.wallet.balance(Wallet.SOFT), 200 - 30 + 10, "Primeira Compra paga 10")
	sim.acquire_and_place(sim.furniture.get_definition(&"chair_wood"), Vector2i(4, 4), 0)
	assert_eq(unlocked.size(), 1, "o mesmo degrau não paga duas vezes")
	assert_eq(sim.achievements.unlocked_tiers(&"a07_furniture"), 1)


func test_jumping_several_tiers_unlocks_each_in_order() -> void:
	_setup()
	var unlocked := []
	sim.achievement_unlocked.connect(func(a: AchievementDefinition, tier: int) -> void:
		if a.id == &"a06_level":
			unlocked.append(tier))
	var gold := sim.wallet.balance(Wallet.SOFT)
	sim.progression.add_xp(1830)  # nível 10 de uma vez
	assert_eq(unlocked, [0, 1, 2])
	var level := _achievement(&"a06_level")
	var expected := 0
	for reward in level.tier_rewards:
		expected += reward
	assert_true(sim.wallet.balance(Wallet.SOFT) >= gold + expected, "todos os degraus pagos")


func test_counters_follow_the_game() -> void:
	_setup()
	var stove := sim.layout.place(sim.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	sim.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	sim.collect(stove)
	assert_eq(sim.stats.value(PlayerStats.DISHES_COOKED), 1)
	sim.acquire_and_place(sim.furniture.get_definition(&"plant_pot"), Vector2i(0, 7), 0)
	assert_eq(sim.stats.value(PlayerStats.FURNITURE_BOUGHT), 1)
	assert_eq(sim.stats.value(PlayerStats.BEAUTY), sim.beauty(), "beleza máxima já vista")
	sim.store_furniture(sim.last_placed_id)
	assert_eq(sim.stats.value(PlayerStats.BEAUTY), 17, "o recorde de beleza não cai")


func test_beauty_achievement_counts_surfaces() -> void:
	_setup(5000)
	sim.progression.add_xp(450)
	for id in [&"floor_marble", &"wall_navy"]:
		sim.use_surface(sim.surfaces.get_definition(id))
	assert_eq(sim.achievements.unlocked_tiers(&"a05_beauty"), 1, "50 de beleza: Caprichoso")


func test_save_keeps_counters_and_does_not_pay_again() -> void:
	_setup(200)
	sim.acquire_and_place(sim.furniture.get_definition(&"chair_wood"), Vector2i(2, 2), 0)
	var text := JSON.stringify(SaveCodec.encode(sim), "", true, true)
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 4).simulation
	assert_eq(loaded.stats.value(PlayerStats.FURNITURE_BOUGHT), 1)
	assert_eq(loaded.achievements.unlocked_tiers(&"a07_furniture"), 1)
	assert_eq(loaded.wallet.balance(Wallet.SOFT), sim.wallet.balance(Wallet.SOFT), "carregar não paga de novo")


func test_old_save_catches_up_on_level_achievements() -> void:
	_setup(0)
	sim.progression.add_xp(280)  # nível 5
	var data := SaveCodec.encode(sim)
	data["save_version"] = 2
	for key in ["style", "stats", "achievements"]:
		data.erase(key)
	var gold := sim.wallet.balance(Wallet.SOFT)
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock).simulation
	assert_eq(loaded.achievements.unlocked_tiers(&"a06_level"), 2, "Aprendiz e Gerente")
	assert_eq(loaded.stats.value(PlayerStats.LEVEL), 5)
	var level := _achievement(&"a06_level")
	assert_eq(loaded.wallet.balance(Wallet.SOFT), gold + level.tier_rewards[0] + level.tier_rewards[1],
		"quem já estava no nível 5 recebe o que merecia")


func test_serving_a_customer_counts_customers_and_gold() -> void:
	clock = ManualClock.new()
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	var furniture := FurnitureCatalog.load_from()
	var stove := layout.place(furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	layout.place(furniture.get_definition(&"table_round"), Vector2i(3, 3))
	layout.place(furniture.get_definition(&"chair_wood"), Vector2i(2, 3))
	sim = CafeSimulation.with_game_data(clock, layout, furniture, 8)
	sim.customer_types.assign([load("res://data/customers/regular.tres")])
	sim.wallet.earn(Wallet.SOFT, 100, "teste")
	sim.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	sim.collect(stove)
	var paid := [0]
	sim.payment_received.connect(func(_c: Customer, amount: int) -> void: paid[0] += amount)
	for i in 900:
		clock.advance(0.1)
		sim.tick(0.1)
		if paid[0] > 0:
			break
	assert_true(paid[0] > 0, "um cliente pagou")
	assert_eq(sim.stats.value(PlayerStats.CUSTOMERS_SERVED), 1)
	assert_eq(sim.stats.value(PlayerStats.GOLD_EARNED), paid[0])
	assert_eq(sim.achievements.unlocked_tiers(&"a01_customers"), 1, "Primeiro Cliente")
