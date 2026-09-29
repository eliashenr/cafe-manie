extends TestCase
## Cozinha: preparo por relógio (inclusive com o jogo fechado) e porções no balcão.

var clock: ManualClock
var layout: CafeLayout
var kitchen: Kitchen
var stove: StringName
var counter_a: StringName
var counter_b: StringName


func _setup(capacity := 40) -> void:
	clock = ManualClock.new()
	layout = CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))
	var furniture := FurnitureCatalog.load_from()
	stove = layout.place(furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	counter_a = layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	counter_b = layout.place(furniture.get_definition(&"counter_basic"), Vector2i(2, 2))
	kitchen = Kitchen.new(clock, layout, capacity)


func _recipe(id: StringName, cook_time := 60.0, servings := 4) -> RecipeDefinition:
	var recipe := RecipeDefinition.new()
	recipe.id = id
	recipe.cook_time = cook_time
	recipe.servings = servings
	return recipe


func test_cooking_goes_idle_then_cooking_then_ready_by_the_clock() -> void:
	_setup()
	var cake := _recipe(&"cake", 60.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE)
	assert_eq(kitchen.start_cooking(stove, cake), ServiceResult.OK)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING)
	clock.advance(15.0)
	assert_almost_eq(kitchen.progress(stove), 0.25)
	assert_almost_eq(kitchen.time_left(stove), 45.0)
	clock.advance(45.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY)
	assert_eq(kitchen.time_left(stove), 0.0)


func test_food_gets_ready_while_the_game_is_closed() -> void:
	# O relógio pula 2 horas sem nenhum "tick": como no jogo fechado.
	_setup()
	kitchen.start_cooking(stove, _recipe(&"lasagna", 900.0))
	clock.advance(7200.0)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY)


func test_busy_stove_and_non_stove_are_refused() -> void:
	_setup()
	kitchen.start_cooking(stove, _recipe(&"a"))
	assert_eq(kitchen.start_cooking(stove, _recipe(&"b")), ServiceResult.STOVE_BUSY)
	assert_eq(kitchen.start_cooking(counter_a, _recipe(&"b")), ServiceResult.NOT_A_STOVE)
	assert_eq(kitchen.stove_recipe(stove).id, &"a", "o preparo original continua")


func test_collect_only_when_ready() -> void:
	_setup()
	assert_eq(kitchen.collect(stove), ServiceResult.NOT_READY, "fogão vazio")
	kitchen.start_cooking(stove, _recipe(&"a", 10.0))
	assert_eq(kitchen.collect(stove), ServiceResult.NOT_READY, "ainda cozinhando")
	clock.advance(10.0)
	assert_eq(kitchen.collect(stove), ServiceResult.OK)
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE, "fogão fica livre")


func test_collect_stacks_same_recipe_then_uses_empty_counter() -> void:
	_setup()
	var coffee := _recipe(&"coffee", 1.0, 6)
	var bread := _recipe(&"bread", 1.0, 8)
	for recipe in [coffee, coffee, bread]:
		kitchen.start_cooking(stove, recipe)
		clock.advance(1.0)
		assert_eq(kitchen.collect(stove), ServiceResult.OK)
	assert_eq(kitchen.counter_stack(counter_a).recipe, coffee)
	assert_eq(kitchen.counter_stack(counter_a).servings, 12, "café empilhado no mesmo balcão")
	assert_eq(kitchen.counter_stack(counter_b).recipe, bread, "outra receita vai para o balcão vazio")


func test_collect_refuses_when_no_counter_has_room() -> void:
	_setup(10)
	var coffee := _recipe(&"coffee", 1.0, 6)
	var bread := _recipe(&"bread", 1.0, 6)
	for recipe in [coffee, bread]:
		kitchen.start_cooking(stove, recipe)
		clock.advance(1.0)
		kitchen.collect(stove)
	kitchen.start_cooking(stove, coffee)
	clock.advance(1.0)
	assert_eq(kitchen.collect(stove), ServiceResult.NO_COUNTER_SPACE, "6 + 6 passaria da capacidade 10")
	assert_eq(kitchen.stove_status(stove), Kitchen.StoveStatus.READY, "o prato espera no fogão")


func test_take_serving_empties_the_counter_at_zero() -> void:
	_setup()
	var coffee := _recipe(&"coffee", 1.0, 2)
	kitchen.start_cooking(stove, coffee)
	clock.advance(1.0)
	kitchen.collect(stove)
	assert_eq(kitchen.available_recipes(), [coffee] as Array[RecipeDefinition])
	assert_eq(kitchen.take_serving(coffee), counter_a)
	assert_eq(kitchen.take_serving(coffee), counter_a)
	assert_eq(kitchen.counter_stack(counter_a), null, "balcão vazio de novo")
	assert_eq(kitchen.take_serving(coffee), &"", "acabou")
	assert_eq(kitchen.available_recipes().size(), 0)


func test_return_serving_goes_back_to_its_counter() -> void:
	_setup()
	var coffee := _recipe(&"coffee", 1.0, 1)
	kitchen.start_cooking(stove, coffee)
	clock.advance(1.0)
	kitchen.collect(stove)
	var from := kitchen.take_serving(coffee)
	assert_true(kitchen.return_serving(from, coffee))
	assert_eq(kitchen.servings_of(coffee), 1)


func test_in_use_means_cooking_ready_or_holding_food() -> void:
	_setup()
	assert_false(kitchen.is_in_use(stove))
	kitchen.start_cooking(stove, _recipe(&"a", 1.0))
	assert_true(kitchen.is_in_use(stove), "cozinhando")
	clock.advance(1.0)
	assert_true(kitchen.is_in_use(stove), "pronto no fogão")
	kitchen.collect(stove)
	assert_false(kitchen.is_in_use(stove))
	assert_true(kitchen.is_in_use(counter_a), "balcão com comida")


func test_changed_is_emitted_on_every_state_change() -> void:
	_setup()
	var changes := [0]
	kitchen.changed.connect(func() -> void: changes[0] += 1)
	var coffee := _recipe(&"coffee", 1.0, 1)
	kitchen.start_cooking(stove, coffee)
	clock.advance(1.0)
	kitchen.collect(stove)
	kitchen.take_serving(coffee)
	assert_eq(changes[0], 3)
