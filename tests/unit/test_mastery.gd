extends TestCase
## Domínio das receitas (DT-053): cada prato pronto conta; nas metas, a receita ganha uma estrela com prêmio em ouro
## e XP, pago na hora. O save guarda a contagem.

var clock: ManualClock
var sim: CafeSimulation
var stove: StringName


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	for placement in sim.layout.placements():
		if placement.origin == Vector2i(0, 0):
			stove = placement.id
	sim.wallet.earn(Wallet.SOFT, 50000, "teste")


func _cook_and_collect(recipe_id: StringName) -> void:
	var recipe := sim.recipes.get_definition(recipe_id)
	assert_eq(sim.start_cooking(stove, recipe_id), ServiceResult.OK)
	clock.advance(recipe.cook_time)
	assert_eq(sim.collect(stove), ServiceResult.OK)


func test_config_is_valid() -> void:
	var config: MasteryConfig = load("res://data/config/mastery.tres")
	assert_true(config.is_valid())
	assert_eq(config.max_stars(), 3)
	var broken := config.duplicate()
	broken.thresholds = PackedInt32Array([5, 5, 10])
	assert_false(broken.is_valid(), "metas precisam crescer")


func test_stars_come_at_each_goal() -> void:
	var mastery := RecipeMastery.new(load("res://data/config/mastery.tres"))
	var goals := mastery.config.thresholds
	assert_eq(mastery.next_goal(&"coffee"), goals[0])
	var earned := 0
	for i in goals[0] - 1:
		earned += mastery.record(&"coffee")
	assert_eq(earned, 0, "antes da meta, nenhuma estrela")
	assert_eq(mastery.record(&"coffee"), 1, "na meta, uma estrela")
	assert_eq(mastery.stars(&"coffee"), 1)
	assert_eq(mastery.count(&"coffee"), goals[0])
	assert_eq(mastery.next_goal(&"coffee"), goals[1])
	for i in goals[goals.size() - 1] - goals[0]:
		mastery.record(&"coffee")
	assert_eq(mastery.stars(&"coffee"), mastery.config.max_stars(), "todas as estrelas")
	assert_eq(mastery.next_goal(&"coffee"), -1, "domínio completo")
	assert_eq(mastery.stars(&"lasagna"), 0, "cada receita conta separado")


func test_reward_scales_with_the_recipe_and_the_star() -> void:
	var mastery := RecipeMastery.new(load("res://data/config/mastery.tres"))
	var lasagna: RecipeDefinition = load("res://data/recipes/lasagna.tres")
	var first := mastery.reward(lasagna, 1)
	var third := mastery.reward(lasagna, 3)
	assert_eq(first["gold"], roundi(lasagna.ingredient_cost * mastery.config.gold_multipliers[0]))
	assert_eq(first["xp"], roundi(lasagna.xp_reward * mastery.config.xp_multipliers[0]))
	assert_true(third["gold"] > first["gold"] and third["xp"] > first["xp"], "a última estrela vale mais")


func test_collecting_dishes_earns_the_star_and_pays_the_prize() -> void:
	_setup()
	var coffee := sim.recipes.get_definition(&"coffee")
	var goal := sim.mastery.config.thresholds[0]
	var stars: Array[int] = []
	var which: Array[StringName] = []
	sim.recipe_mastered.connect(func(recipe: RecipeDefinition, earned: int, _reward: Dictionary) -> void:
		which.append(recipe.id)
		stars.append(earned))
	for i in goal - 1:
		_cook_and_collect(&"coffee")
	assert_eq(stars.size(), 0)
	var gold := sim.wallet.balance(Wallet.SOFT)
	var xp := sim.progression.xp
	_cook_and_collect(&"coffee")
	assert_eq(stars, [1] as Array[int], "a primeira estrela, uma vez só")
	assert_eq(which, [&"coffee"] as Array[StringName])
	var prize := sim.mastery.reward(coffee, 1)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - coffee.ingredient_cost + prize["gold"], "pagou o prêmio em ouro")
	assert_eq(sim.progression.xp, xp + coffee.xp_reward + prize["xp"], "e em XP")


func test_the_save_keeps_the_mastery() -> void:
	_setup()
	for i in 3:
		sim.mastery.record(&"pizza")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_eq(loaded.mastery.count(&"pizza"), 3)
	assert_eq(loaded.mastery.count(&"coffee"), 0)


func test_an_old_save_starts_without_stars() -> void:
	_setup()
	var data := SaveCodec.encode(sim)
	data["save_version"] = 10
	data.erase("mastery")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(data)))
	assert_eq(migrated["save_version"], SaveCodec.CURRENT_VERSION)
	assert_eq(migrated["mastery"], {}, "a migração acrescenta o domínio")
	assert_eq(SaveCodec.decode(migrated, clock, 11).simulation.mastery.count(&"coffee"), 0)
