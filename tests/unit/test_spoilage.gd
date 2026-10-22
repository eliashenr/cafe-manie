extends TestCase
## Comida que estraga (DT-055): o prato pronto esquecido no fogão estraga depois do dobro do tempo de preparo
## (nunca antes do mínimo). Estragado não vai para o balcão e só sai jogado fora. Tudo pelo relógio: estraga
## também com o jogo fechado, e a pausa segura.

var clock: ManualClock
var config: ServiceConfig
var kitchen: Kitchen
var stove: StringName


func _setup() -> void:
	clock = ManualClock.new()
	config = load("res://data/config/service.tres")
	var layout := CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	var furniture := FurnitureCatalog.load_from()
	stove = layout.place(furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	kitchen = Kitchen.new(clock, layout, config.counter_capacity)
	kitchen.spoil_factor = config.spoil_factor
	kitchen.min_spoil_time = config.min_spoil_time


func _recipe(cook_time: float) -> RecipeDefinition:
	var recipe := RecipeDefinition.new()
	recipe.id = &"teste"
	recipe.cook_time = cook_time
	recipe.servings = 4
	return recipe


## Começa a receita e espera ficar pronta.
func _ready_dish(cook_time: float) -> RecipeDefinition:
	var recipe := _recipe(cook_time)
	assert_eq(kitchen.start_cooking(stove, recipe), ServiceResult.OK)
	clock.advance(cook_time)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY)
	return recipe


func test_config_is_valid_and_slow_dishes_hold_longer() -> void:
	_setup()
	assert_true(config.is_valid())
	assert_true(config.spoil_factor > 1.0, "o prato aguenta mais que o próprio preparo")
	assert_true(config.min_spoil_time > 0.0)
	var quick := _recipe(15.0)
	var slow := _recipe(3600.0)
	assert_eq(kitchen.spoil_time(quick), config.min_spoil_time, "prato rápido aguenta o mínimo")
	assert_eq(kitchen.spoil_time(slow), 3600.0 * config.spoil_factor, "prato longo aguenta mais")
	var broken: ServiceConfig = config.duplicate()
	broken.spoil_factor = -1.0
	assert_false(broken.is_valid())


func test_a_forgotten_dish_spoils() -> void:
	_setup()
	var recipe := _ready_dish(3600.0)
	var hold := kitchen.spoil_time(recipe)
	assert_almost_eq(kitchen.time_to_spoil(stove), hold, 0.001)
	clock.advance(hold - 1.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "ainda dá tempo")
	assert_almost_eq(kitchen.time_to_spoil(stove), 1.0, 0.001)
	clock.advance(1.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.SPOILED, "estragou")
	assert_eq(kitchen.time_to_spoil(stove), 0.0)
	assert_eq(kitchen.spoiled_stoves(), [stove] as Array[StringName])


func test_a_quick_dish_holds_at_least_the_minimum() -> void:
	_setup()
	_ready_dish(15.0)
	clock.advance(config.min_spoil_time - 1.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY)
	clock.advance(1.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.SPOILED)


func test_a_spoiled_dish_cannot_be_served_and_keeps_the_stove_busy() -> void:
	_setup()
	var recipe := _ready_dish(60.0)
	clock.advance(kitchen.spoil_time(recipe))
	assert_eq(kitchen.collect(stove), ServiceResult.SPOILED, "estragado não vai para o balcão")
	assert_eq(kitchen.available_recipes().size(), 0)
	assert_true(kitchen.ready_stoves().is_empty(), "o garçom não busca prato estragado")
	assert_false(kitchen.is_preparing(recipe), "nem conta como prato a caminho")
	assert_true(kitchen.is_in_use(stove), "o fogão continua ocupado")
	assert_eq(kitchen.start_cooking(stove, _recipe(60.0)), ServiceResult.STOVE_BUSY)


func test_discarding_frees_the_stove() -> void:
	_setup()
	assert_eq(kitchen.discard(stove), ServiceResult.NOT_SPOILED, "fogão livre")
	var recipe := _recipe(60.0)
	kitchen.start_cooking(stove, recipe)
	assert_eq(kitchen.discard(stove), ServiceResult.NOT_SPOILED, "cozinhando")
	clock.advance(60.0)
	assert_eq(kitchen.discard(stove), ServiceResult.NOT_SPOILED, "pronto ainda se aproveita")
	clock.advance(kitchen.spoil_time(recipe))
	assert_eq(kitchen.discard(stove), ServiceResult.OK)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE)
	assert_eq(kitchen.start_cooking(stove, recipe), ServiceResult.OK, "dá para cozinhar de novo")


func test_pause_holds_the_spoil_clock() -> void:
	_setup()
	var recipe := _ready_dish(60.0)
	clock.advance(100.0)
	kitchen.set_paused(true)
	clock.advance(kitchen.spoil_time(recipe) * 10.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "pausado, nada estraga")
	kitchen.set_paused(false)
	assert_almost_eq(kitchen.time_to_spoil(stove), kitchen.spoil_time(recipe) - 100.0, 0.001)


func test_zero_factor_never_spoils() -> void:
	_setup()
	kitchen.spoil_factor = 0.0
	_ready_dish(60.0)
	clock.advance(1.0e7)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY)
	assert_true(is_inf(kitchen.time_to_spoil(stove)))


# --- Na simulação ---------------------------------------------------------------------------

func _sim_with_dish(recipe_id: StringName) -> Array:
	clock = ManualClock.new()
	var sim := CafeSimulation.create_new_game(clock, 11)
	var sim_stove: StringName
	for placement in sim.layout.placements():
		if sim.kitchen.is_stove(placement.id):
			sim_stove = placement.id
			break
	assert_eq(sim.start_cooking(sim_stove, recipe_id), ServiceResult.OK)
	return [sim, sim_stove]


func test_the_simulation_warns_once_per_spoiled_dish() -> void:
	var setup := _sim_with_dish(&"coffee")
	var sim: CafeSimulation = setup[0]
	var sim_stove: StringName = setup[1]
	var coffee := sim.recipes.get_definition(&"coffee")
	var warned: Array = []
	sim.dish_spoiled.connect(func(id: StringName, recipe: RecipeDefinition) -> void: warned.append([id, recipe]))
	clock.advance(coffee.cook_time + sim.kitchen.spoil_time(coffee))
	sim.tick(0.1)
	assert_eq(warned, [[sim_stove, coffee]], "avisa o prato que estragou")
	sim.tick(0.1)
	assert_eq(warned.size(), 1, "uma vez só")
	assert_eq(sim.collect(sim_stove), ServiceResult.SPOILED)
	assert_eq(sim.discard_spoiled(sim_stove), ServiceResult.OK)
	assert_eq(sim.start_cooking(sim_stove, &"coffee"), ServiceResult.OK)
	clock.advance(coffee.cook_time + sim.kitchen.spoil_time(coffee))
	sim.tick(0.1)
	assert_eq(warned.size(), 2, "o próximo prato esquecido avisa de novo")


func test_dishes_spoiled_while_away_are_counted_not_warned_one_by_one() -> void:
	var setup := _sim_with_dish(&"coffee")
	var sim: CafeSimulation = setup[0]
	var text := JSON.stringify(SaveCodec.encode(sim))
	clock.advance(24 * 3600.0)  # jogo fechado
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 11).simulation
	assert_eq(loaded.kitchen.stove_status(setup[1]), Kitchen.StoveStatus.SPOILED, "estragou com o jogo fechado")
	var warned: Array = []
	loaded.dish_spoiled.connect(func(_id: StringName, recipe: RecipeDefinition) -> void: warned.append(recipe))
	assert_eq(loaded.forget_spoiled_while_away(), 1)
	loaded.tick(0.1)
	assert_true(warned.is_empty(), "as boas-vindas já contaram")


func test_dishes_of_four_hours_or_more_survive_a_night_of_sleep() -> void:
	_setup()
	var night := 8 * 3600.0
	for recipe in RecipeCatalog.load_from().all():
		if recipe.cook_time >= night / 2.0:
			assert_true(kitchen.spoil_time(recipe) >= night, "%s aguenta uma noite pronto no fogão" % recipe.id)
