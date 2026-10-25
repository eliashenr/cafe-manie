extends CafeTestCase
## Revisão visual do redesign (DT-083): o que ainda estava no estilo claro antigo ficou no padrão escuro (abas do livro
## de receitas, receitas bloqueadas, botões de texto da barra), o botão da loja diz o que falta e o progresso é ciano.


func _stove_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.layout.place(simulation.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	var cafe := await spawn_cafe(simulation)
	tap_cell(cafe, Vector2i(0, 0))
	await settle()
	return cafe


func _bg(button: Button, state: String) -> Color:
	return (button.get_theme_stylebox(state) as StyleBoxFlat).bg_color


func test_recipe_book_tabs_are_dark_pills_like_the_collections() -> void:
	var cafe := await _stove_cafe()
	var active := cafe.build_bar.find_button("Book_basico")
	var other := cafe.build_bar.find_button("Book_brasil")
	assert_true(active.button_pressed)
	assert_true(_bg(other, "normal").a < 0.5, "a aba fechada é escura e transparente, não mais branca")
	assert_true(_bg(active, "normal").a > 0.9, "a aberta fica cheia na cor dela")
	var book: RecipeBookDefinition = null
	for candidate: RecipeBookDefinition in cafe.simulation.recipes.books():
		if candidate.id == &"brasil":
			book = candidate
	assert_true(book != null)
	assert_true(other.get_theme_color("font_color").is_equal_approx(book.color.lightened(0.5)), "o texto na cor clara da aba")


func test_locked_recipes_are_dark_cards() -> void:
	var cafe := await _stove_cafe()
	var locked: Button = null
	for recipe in cafe.simulation.recipes.all():
		var card := cafe.build_bar.find_button("Cook_" + String(recipe.id))
		if card != null and card.disabled:
			locked = card
			break
	assert_true(locked != null, "no nível 1 há receitas bloqueadas no livro")
	assert_eq(_bg(locked, "disabled"), UiTheme.NAVY_DEEP, "bloqueada: cartão escuro (antes era claro)")
	assert_eq(locked.get_theme_color("font_disabled_color"), UiTheme.METAL, "com o texto cinza metálico, legível")


func test_bar_text_buttons_use_theme_roles_and_keep_their_height() -> void:
	var cafe := await spawn_cafe()
	cafe.start_painting(&"floor_wood")
	await settle()
	var all := cafe.build_bar.find_button("PaintAllButton")
	assert_eq(all.theme_type_variation, UiTheme.GHOST_BUTTON, "Tudo e Limpar são botões fantasma")
	assert_eq(cafe.build_bar.find_button("PaintClearButton").theme_type_variation, UiTheme.GHOST_BUTTON)
	assert_eq(all.size_flags_vertical, Control.SIZE_SHRINK_CENTER, "sem esticar até a altura dos ícones")


func test_the_shop_button_says_what_is_missing() -> void:
	var simulation := quiet_simulation()
	var cafe := await spawn_cafe(simulation)
	cafe.build_bar.open_shop(BuildBar.ShopTab.COUPONS)
	await settle()
	var item := cafe.simulation.coupon_shop_items()[0]
	cafe.build_bar.find_button("Build_" + String(item.id)).pressed.emit()
	await settle()
	var buy := cafe.build_bar.find_button("BuyButton")
	assert_true(buy.disabled)
	assert_eq(buy.text, "Faltam cupons", "sem cupons, o botão diz o que falta (antes: Indisponível)")


func test_progress_bars_are_cyan() -> void:
	var cafe := await spawn_cafe()
	var bar := cafe.hud.find_child("MissionCard", true, false).find_children("*", "ProgressBar", true, false)[0] as ProgressBar
	assert_eq((bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color, UiTheme.CYAN, "a missão em andamento em ciano")
	assert_eq((UiTheme.theme().get_stylebox("fill", "ProgressBar") as StyleBoxFlat).bg_color, UiTheme.CYAN)
