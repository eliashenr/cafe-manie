extends CafeTestCase
## Livro de receitas na cena (DT-053): o fogão livre abre o livro em abas, na aba de um prato esperado; cada fogão
## lembra a aba escolhida; as estrelas de domínio aparecem nos cartões; a estrela nova avisa; abas grandes têm páginas.


func _stove_cafe(xp := 0) -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(xp)
	var stove := simulation.layout.place(simulation.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	var cafe := await spawn_cafe(simulation)
	return [cafe, stove]


func _open_stove(cafe: Cafe) -> void:
	tap_cell(cafe, Vector2i(0, 0))
	await settle()


func _book_ids(cafe: Cafe) -> Array[StringName]:
	var ids: Array[StringName] = []
	for recipe in cafe.simulation.recipes.all():
		if cafe.build_bar.find_button("Cook_" + String(recipe.id)) != null:
			ids.append(recipe.id)
	return ids


func test_idle_stove_opens_the_book_on_the_first_tab() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	await _open_stove(cafe)
	for book in cafe.simulation.recipes.books():
		assert_true(cafe.build_bar.find_button("Book_" + String(book.id)) != null, "aba %s" % book.id)
	assert_true(cafe.build_bar.find_button("Book_basico").button_pressed, "abre no Básico")
	var basics: Array[StringName] = []
	for recipe in cafe.simulation.recipes.in_book(&"basico"):
		basics.append(recipe.id)
	assert_eq(_book_ids(cafe), basics.slice(0, BuildBar.RECIPES_PER_PAGE), "só as receitas da aba, na primeira página")
	cafe.build_bar.find_button("Book_mundo").pressed.emit()
	await settle()
	assert_true(_book_ids(cafe).has(&"lasagna") and _book_ids(cafe).has(&"pizza"), "a aba Mundo")
	assert_false(_book_ids(cafe).has(&"coffee"))


func test_the_book_opens_where_a_customer_is_waiting() -> void:
	var setup := await _stove_cafe(680)  # nível 8: a pizza já sai
	var cafe: Cafe = setup[0]
	var simulation := cafe.simulation
	simulation.layout.place(simulation.furniture.get_definition(&"table_round"), Vector2i(4, 4))
	var chair := simulation.layout.place(simulation.furniture.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	var customer := Customer.new()
	customer.serial = 70
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	customer.state = Customer.State.WAITING_TO_ORDER
	customer.patience_total = 999.0
	customer.patience_left = 999.0
	simulation.customers.append(customer)
	simulation.config.menu_order_chance = 1.0
	while customer.order == null or customer.order.book != &"mundo":  # pede um prato da aba Mundo
		simulation._cancel_order_of(customer)
		customer.order = null
		customer.state = Customer.State.WAITING_TO_ORDER
		simulation._place_order(customer)
	await _open_stove(cafe)
	assert_true(cafe.build_bar.find_button("Book_mundo").button_pressed, "o livro abre na aba do prato esperado")
	var dot := cafe.build_bar.find_button("Book_mundo").get_node("BookDemand") as Label
	assert_true(dot.visible and dot.text == "1", "a aba mostra quantos esperam")
	assert_false((cafe.build_bar.find_button("Book_basico").get_node("BookDemand") as Label).visible)


func test_each_stove_remembers_the_chosen_tab() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	await _open_stove(cafe)
	cafe.build_bar.find_button("Book_doces").pressed.emit()
	await settle()
	cafe.clear_selection()
	await settle()
	await _open_stove(cafe)
	assert_true(cafe.build_bar.find_button("Book_doces").button_pressed, "volta na aba que você escolheu")


func test_cards_show_the_mastery_stars() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var mastery := cafe.simulation.mastery
	for i in mastery.config.thresholds[0]:
		mastery.record(&"coffee")
	await _open_stove(cafe)
	var card := cafe.build_bar.find_button("Cook_coffee")
	var stars := card.get_node("Stars")
	assert_eq(stars.get_child_count(), mastery.config.max_stars())
	assert_eq((stars.get_child(0) as TextureRect).texture, ArtSprites.get_sprite("icone_estrela").texture, "a primeira acesa")
	assert_eq((stars.get_child(1) as TextureRect).texture, ArtSprites.get_sprite("icone_estrela_vazia").texture, "a segunda apagada")
	assert_true(card.tooltip_text.contains("%d de %d" % [mastery.config.thresholds[0], mastery.config.thresholds[1]]), card.tooltip_text)


func test_mastery_progress_marks_the_save_dirty() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	cafe._save_dirty = false
	cafe.simulation.mastery.record(&"coffee")
	assert_true(cafe._save_dirty, "o domínio é gravado no próximo salvamento")


func test_a_new_star_is_announced() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	cafe.simulation.wallet.earn(Wallet.SOFT, 1000, "teste")
	for i in cafe.simulation.mastery.config.thresholds[0]:
		cafe.simulation.start_cooking(stove, &"coffee")
		clock.advance(coffee.cook_time)
		cafe.collect_stove(stove)
	assert_true(all_messages(cafe).contains("Domínio de Café: estrela 1 de 3!"), all_messages(cafe))


func test_a_big_tab_turns_pages() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var recipes := cafe.simulation.recipes
	var extra: Array[StringName] = []
	while recipes.in_book(&"doces").size() <= BuildBar.RECIPES_PER_PAGE:
		var sweet := RecipeDefinition.new()
		sweet.id = StringName("doce_teste_%d" % extra.size())
		sweet.display_name = "Doce %d" % extra.size()
		sweet.book = &"doces"
		sweet.unlock_level = 20
		recipes.add(sweet)
		extra.append(sweet.id)
	await _open_stove(cafe)
	cafe.build_bar.find_button("Book_doces").pressed.emit()
	await settle()
	assert_eq(_book_ids(cafe).size(), BuildBar.RECIPES_PER_PAGE, "uma página cheia")
	var next := cafe.build_bar.find_button("RecipeNextButton")
	assert_true(next != null and not next.disabled)
	assert_true(cafe.build_bar.find_button("RecipePrevButton").disabled, "na primeira página, voltar fica apagado")
	next.pressed.emit()
	await settle()
	assert_eq(_book_ids(cafe).size(), recipes.in_book(&"doces").size() - BuildBar.RECIPES_PER_PAGE, "o resto na outra página")
	assert_true(cafe.build_bar.find_button("RecipeNextButton").disabled)


func test_the_late_recipes_fill_a_second_page() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var brasil := cafe.simulation.recipes.in_book(&"brasil")
	assert_true(brasil.size() > BuildBar.RECIPES_PER_PAGE, "a aba Brasil já passa de uma página (DT-054)")
	await _open_stove(cafe)
	cafe.build_bar.find_button("Book_brasil").pressed.emit()
	await settle()
	assert_false(_book_ids(cafe).has(&"barbecue"), "o churrasco fica na segunda página")
	cafe.build_bar.find_button("RecipeNextButton").pressed.emit()
	await settle()
	assert_true(_book_ids(cafe).has(&"barbecue"), "e aparece ao virar a página")
	assert_true(cafe.build_bar.find_button("Cook_barbecue").disabled, "travado até o nível 29")
