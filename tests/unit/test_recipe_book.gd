extends TestCase
## Livro de receitas (DT-053 e DT-054): as abas, as 31 receitas (uma nova a cada nível até o 30) e o equilíbrio entre pratos
## rápidos (mais lucro por minuto, para quem joga ativo) e demorados (mais lucro e XP por fornada, para quem volta depois).


func test_books_are_valid_ordered_and_every_recipe_has_its_book() -> void:
	var catalog := RecipeCatalog.load_from()
	var books := catalog.books()
	assert_eq(books.size(), 4, "Básico, Brasil, Doces e Mundo")
	for i in books.size():
		assert_true(books[i].is_valid(), String(books[i].id))
		if i > 0:
			assert_true(books[i].order > books[i - 1].order, "na ordem")
	for recipe in catalog.all():
		assert_true(catalog.get_book(recipe.book) != null, "a receita %s tem aba" % recipe.id)
	for book in books:
		assert_true(catalog.in_book(book.id).size() >= 3, "a aba %s tem receitas" % book.id)


func test_a_new_recipe_at_every_level() -> void:
	var catalog := RecipeCatalog.load_from()
	var table: LevelTable = load("res://data/progression/levels.tres")
	assert_eq(catalog.size(), 31)
	for level in range(1, table.max_level() + 1):
		var found := catalog.all().filter(func(r: RecipeDefinition) -> bool: return r.unlock_level == level)
		assert_true(not found.is_empty(), "o nível %d libera receita" % level)


func test_book_recipes_come_by_level() -> void:
	var catalog := RecipeCatalog.load_from()
	for book in catalog.books():
		var last := 0
		for recipe in catalog.in_book(book.id):
			assert_eq(recipe.book, book.id)
			assert_true(recipe.unlock_level >= last, "%s fora de ordem" % recipe.id)
			last = recipe.unlock_level


func test_slow_dishes_pay_more_per_batch_and_fast_dishes_pay_more_per_minute() -> void:
	var recipes := RecipeCatalog.load_from().all()
	for fast in recipes:
		for slow in recipes:
			if slow.cook_time < fast.cook_time * 4.0:
				continue
			var pair := "%s x %s" % [fast.id, slow.id]
			assert_true(slow.batch_profit() > fast.batch_profit(), "fornada demorada rende mais: " + pair)
			assert_true(slow.xp_reward > fast.xp_reward, "e dá mais XP: " + pair)
			assert_true(slow.batch_profit() / slow.cook_time < fast.batch_profit() / fast.cook_time,
				"mas o rápido rende mais por minuto: " + pair)


func test_every_recipe_has_dish_and_cookware_art() -> void:
	for recipe in RecipeCatalog.load_from().all():
		assert_true(ArtSprites.food(recipe.id) != null, "prato de %s" % recipe.id)
		assert_true(ArtSprites.cookware(recipe.id) != null, "panela de %s" % recipe.id)


func test_every_dish_fits_on_a_counter() -> void:
	var config: ServiceConfig = load("res://data/config/service.tres")
	for recipe in RecipeCatalog.load_from().all():
		assert_true(recipe.servings <= config.counter_capacity, "%s cabe num balcão" % recipe.id)


func test_a_recipe_needs_a_book() -> void:
	var recipe: RecipeDefinition = load("res://data/recipes/coffee.tres").duplicate()
	assert_true(recipe.is_valid())
	recipe.book = &""
	assert_false(recipe.is_valid(), "receita sem aba não entra no livro")
