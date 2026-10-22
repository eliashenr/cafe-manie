extends TestCase
## Fogão temático (DT-059): o Fogão Japonês libera 4 receitas próprias, que só saem nele. Os clientes só pedem esses
## pratos quando o café tem o fogão; as receitas comuns também saem nele.

const JAPANESE: Array[StringName] = [&"mochi", &"misso_soup", &"yakisoba", &"tempura"]

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	var no_customers: Array[CustomerType] = []
	sim = CafeSimulation.new(clock, CafeLayout.new(Vector2i(10, 10), Vector2i(9, 5)), load("res://data/config/service.tres"),
		FurnitureCatalog.load_from(), RecipeCatalog.load_from(), load("res://data/progression/levels.tres"), no_customers, 7)
	sim.wallet.earn(Wallet.SOFT, 100000, "teste")
	sim.progression.add_xp(46000)  # nível 30
	sim.layout.place(sim.furniture.get_definition(&"counter_basic"), Vector2i(6, 6))


func test_the_japanese_stove_has_four_recipes_of_its_own() -> void:
	var catalog := RecipeCatalog.load_from()
	var stove := FurnitureCatalog.load_from().get_definition(&"stove_blue")
	assert_eq(stove.category, FurnitureDefinition.Category.COOKING)
	assert_eq(stove.display_name, "Fogão Japonês")
	assert_eq(catalog.in_book(&"japao").size(), JAPANESE.size(), "a aba Japão tem as receitas do fogão")
	for id in JAPANESE:
		var recipe := catalog.get_definition(id)
		assert_true(recipe != null and recipe.is_valid(), String(id))
		assert_eq(recipe.stove, &"stove_blue", "%s só sai no Fogão Japonês" % id)
		assert_eq(recipe.book, &"japao")
		assert_true(recipe.unlock_level >= stove.min_level, "%s não libera antes do fogão" % id)


func test_a_japanese_dish_only_cooks_on_its_stove() -> void:
	_setup()
	var basic := sim.layout.place(sim.furniture.get_definition(&"stove_basic"), Vector2i(2, 2))
	var japanese := sim.layout.place(sim.furniture.get_definition(&"stove_blue"), Vector2i(4, 2))
	assert_eq(sim.start_cooking(basic, &"yakisoba"), ServiceResult.WRONG_STOVE, "no fogão comum, não")
	assert_eq(sim.kitchen.stove_status(basic), Kitchen.StoveStatus.IDLE, "e nada é cobrado nem começa")
	assert_eq(sim.start_cooking(japanese, &"yakisoba"), ServiceResult.OK)
	var second := sim.layout.place(sim.furniture.get_definition(&"stove_blue"), Vector2i(2, 4))
	assert_eq(sim.start_cooking(second, &"coffee"), ServiceResult.OK, "as receitas comuns também saem nele")


func test_customers_only_order_japanese_food_with_the_stove() -> void:
	_setup()
	sim.layout.place(sim.furniture.get_definition(&"stove_basic"), Vector2i(2, 2))
	for recipe in sim.order_menu():
		assert_false(JAPANESE.has(recipe.id), "%s não aparece sem o fogão" % recipe.id)
	sim.layout.place(sim.furniture.get_definition(&"stove_blue"), Vector2i(4, 2))
	var ids: Array[StringName] = []
	for recipe in sim.order_menu():
		ids.append(recipe.id)
	for id in JAPANESE:
		assert_true(ids.has(id), "%s entra no cardápio com o fogão" % id)
