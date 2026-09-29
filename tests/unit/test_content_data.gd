extends TestCase
## Integridade dos dados de conteúdo: receitas, clientes e configurações.
## Um erro de digitação num .tres deve falhar aqui, não no meio do jogo.


func test_recipes_load_valid_and_sorted_by_unlock_level() -> void:
	var catalog := RecipeCatalog.load_from()
	assert_eq(catalog.size(), 6, "o MVP pede de 5 a 10 receitas (seção 120)")
	var last_level := 0
	for recipe in catalog.all():
		assert_true(recipe.is_valid(), "%s inválida" % recipe.id)
		assert_false(recipe.display_name.is_empty(), "%s sem nome" % recipe.id)
		assert_true(recipe.unlock_level >= last_level, "fora de ordem: %s" % recipe.id)
		last_level = recipe.unlock_level


func test_every_recipe_is_profitable_when_fully_sold() -> void:
	# Seção 86: evitar economia quebrada. Preparar e vender tudo tem que dar lucro.
	for recipe in RecipeCatalog.load_from().all():
		assert_true(recipe.batch_profit() > 0, "%s dá prejuízo" % recipe.id)


func test_first_level_has_at_least_two_recipes() -> void:
	assert_true(RecipeCatalog.load_from().unlocked_at(1).size() >= 2, "o jogador precisa ter escolha desde o início")


func test_every_recipe_unlocks_within_the_level_table() -> void:
	var table: LevelTable = load("res://data/progression/levels.tres")
	for recipe in RecipeCatalog.load_from().all():
		assert_true(recipe.unlock_level <= table.max_level(), "%s nunca desbloqueia" % recipe.id)


func test_recipe_catalog_rejects_bad_definitions() -> void:
	var catalog := RecipeCatalog.new()
	var good := RecipeDefinition.new()
	good.id = &"a"
	assert_true(catalog.add(good))
	assert_false(catalog.add(good), "id repetido")
	var bad := RecipeDefinition.new()
	bad.id = &"b"
	bad.cook_time = 0.0
	assert_false(catalog.add(bad), "tempo de preparo zero")


func test_customer_types_load_valid() -> void:
	var store := DefinitionStore.new(func(a: CustomerType, b: CustomerType) -> bool: return String(a.id) < String(b.id))
	store.load_dir("res://data/customers", CustomerType)
	assert_eq(store.size(), 2, "o MVP pede de 2 a 3 tipos de cliente (seção 120)")
	for customer_type: CustomerType in store.all():
		assert_true(customer_type.is_valid(), "%s inválido" % customer_type.id)


func test_service_config_is_valid_and_popularity_speeds_up_arrivals() -> void:
	var config: ServiceConfig = load("res://data/config/service.tres")
	assert_true(config.is_valid())
	assert_true(config.spawn_interval_for(100.0) < config.spawn_interval_for(50.0), "mais popular = clientes mais frequentes")
	assert_true(config.spawn_interval_for(50.0) < config.spawn_interval_for(0.0))


func test_new_game_starter_layout_is_legal() -> void:
	var config: NewGameConfig = load("res://data/config/new_game.tres")
	assert_true(config.is_valid())
	var furniture := FurnitureCatalog.load_from()
	var layout := CafeLayout.new(config.grid_size, CafeLayout.default_entrance(config.grid_size))
	for item in config.starter_items:
		var definition := furniture.get_definition(item["id"])
		assert_true(definition != null, "móvel inicial inexistente: %s" % item["id"])
		if definition != null:
			var check := layout.check_placement(definition, item["origin"], item["rotation"])
			assert_eq(check, CafeLayout.Check.OK, "móvel inicial %s em %s não cabe" % [item["id"], item["origin"]])
			layout.place(definition, item["origin"], item["rotation"])
	assert_eq(layout.count(), config.starter_items.size())


func test_new_game_has_a_counter_for_each_stove() -> void:
	# Regressão: com 1 balcão e 2 fogões, o segundo prato ficava preso no fogão
	# (um balcão guarda um tipo de prato por vez).
	var config: NewGameConfig = load("res://data/config/new_game.tres")
	var furniture := FurnitureCatalog.load_from()
	var stoves := 0
	var counters := 0
	for item in config.starter_items:
		match furniture.get_definition(item["id"]).category:
			FurnitureDefinition.Category.COOKING:
				stoves += 1
			FurnitureDefinition.Category.COUNTER:
				counters += 1
	assert_true(counters >= stoves, "%d fogões e só %d balcões" % [stoves, counters])


func test_new_game_can_afford_the_cheapest_recipe() -> void:
	var config: NewGameConfig = load("res://data/config/new_game.tres")
	var cheapest := RecipeCatalog.load_from().all()[0]
	assert_true(config.starting_gold >= cheapest.ingredient_cost, "o jogador precisa conseguir cozinhar no primeiro minuto")
