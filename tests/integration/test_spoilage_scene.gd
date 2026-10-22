extends CafeTestCase
## Comida que estraga na cena (DT-055): o fogão mostra o prato estragado (panela esverdeada, selo "Estragou" e
## fumaça verde); tocar nele abre o "Jogar fora" em vez de levar ao balcão; o aviso sai quando estraga e as
## boas-vindas contam o que estragou com o jogo fechado.


func _stove_cafe() -> Array:
	var simulation := quiet_simulation()
	var stove := simulation.layout.place(simulation.furniture.get_definition(&"stove_basic"), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(2, 0))
	var cafe := await spawn_cafe(simulation)
	return [cafe, stove]


## Cozinha um café e deixa estragar no fogão.
func _spoil_coffee(cafe: Cafe, stove: StringName) -> void:
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	assert_eq(cafe.simulation.start_cooking(stove, &"coffee"), ServiceResult.OK)
	clock.advance(coffee.cook_time + cafe.simulation.kitchen.spoil_time(coffee))
	await settle()


func test_a_spoiled_stove_looks_spoiled() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	await _spoil_coffee(cafe, stove)
	var view := cafe.world_layer.view_for(stove)
	assert_true(view.status_spoiled, "o fogão sabe que estragou")
	assert_eq(view.kitchen_detail, WorldLayer.SPOILED_TEXT, "o selo diz Estragou")
	assert_true(view.stinking(), "fumaça verde")
	assert_false(view.steaming(), "sem vapor de comida boa")
	assert_false(view.glowing(), "e sem o brilho de prato pronto")


func test_tapping_a_spoiled_stove_offers_to_throw_it_away() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	await _spoil_coffee(cafe, stove)
	tap_cell(cafe, Vector2i(0, 0))
	await settle()
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.SPOILED, "não vai para o balcão")
	assert_eq(cafe.selected_id, stove, "o toque escolhe o fogão")
	assert_true(cafe.build_bar.message_text().contains("estragou"), cafe.build_bar.message_text())
	var discard := cafe.build_bar.find_button("DiscardButton")
	assert_true(discard != null, "botão Jogar fora")
	assert_eq(discard.icon, ArtSprites.get_sprite("botao_trash").texture, "com a lixeira")
	discard.pressed.emit()
	await settle()
	assert_eq(cafe.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.IDLE, "o fogão fica livre")
	assert_true(cafe.build_bar.find_button("Book_basico") != null, "e o livro de receitas abre de novo")
	assert_false(cafe.world_layer.view_for(stove).stinking(), "a fumaça verde some")


func test_a_dish_spoiling_during_play_is_announced() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	await _spoil_coffee(cafe, setup[1])
	cafe.simulation.tick(0.1)
	await settle()
	assert_true(all_messages(cafe).contains(Cafe.SPOILED_MESSAGE % "Café"), all_messages(cafe))


func test_a_ready_stove_says_when_it_spoils() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	cafe.simulation.start_cooking(stove, &"coffee")
	clock.advance(coffee.cook_time)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()
	var hold := WorldLayer.format_time(cafe.simulation.kitchen.spoil_time(coffee))
	assert_true(cafe.build_bar.message_text().contains("estraga em " + hold), cafe.build_bar.message_text())


func test_welcome_back_counts_what_spoiled_while_away() -> void:
	var setup := await _stove_cafe()
	var cafe: Cafe = setup[0]
	var saved_at := clock.now()
	await _spoil_coffee(cafe, setup[1])
	var text := cafe._welcome_back(saved_at)
	assert_true(text.contains("1 prato estragou"), text)
	var warned: Array = []
	cafe.simulation.dish_spoiled.connect(func(_id: StringName, recipe: RecipeDefinition) -> void: warned.append(recipe))
	cafe.simulation.tick(0.1)
	assert_true(warned.is_empty(), "não avisa de novo o que as boas-vindas contaram")
