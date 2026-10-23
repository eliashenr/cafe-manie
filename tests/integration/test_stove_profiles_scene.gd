extends CafeTestCase
## Fogões com perfil na cena (DT-058): a loja diz a função de cada fogão e avisa o limite por café; o fogão livre diz
## o perfil; o número que sobe ao tirar o prato mostra as porções e o XP de verdade.


func _profile_cafe(stove_id: StringName) -> Array:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(99999)  # nível 30
	simulation.wallet.earn(Wallet.SOFT, 50000, "teste")
	var stove := simulation.layout.place(simulation.furniture.get_definition(stove_id), Vector2i(0, 0))
	simulation.layout.place(simulation.furniture.get_definition(&"counter_basic"), Vector2i(3, 0))
	var cafe := await spawn_cafe(simulation)
	return [cafe, stove]


## Procura o cartão em todas as páginas da aba aberta da loja.
func _find_in_shop(cafe: Cafe, button_name: String) -> Button:
	for page in cafe.build_bar.shop_page_count():
		cafe.build_bar.shop_page = page
		await settle()
		var card := cafe.build_bar.find_button(button_name)
		if card != null:
			return card
	return null


func test_the_shop_tells_what_each_stove_does_and_the_limit() -> void:
	var setup := await _profile_cafe(&"stove_copper")
	var cafe: Cafe = setup[0]
	cafe.build_bar.open_shop(BuildBar.ShopTab.KITCHEN)
	await settle()
	var steel := await _find_in_shop(cafe, "Build_stove_steel")
	assert_true(steel != null and steel.tooltip_text.contains("25% mais rápido"), steel.tooltip_text if steel else "sem cartão")
	var copper := await _find_in_shop(cafe, "Build_stove_copper")
	assert_true(copper.tooltip_text.contains("qualquer prato pronto em até 1h"), copper.tooltip_text)
	assert_true(copper.text.contains("Só 1 por café") and copper.disabled, "já tem um: o cartão avisa e fica apagado")


func test_an_idle_stove_tells_its_profile() -> void:
	var setup := await _profile_cafe(&"stove_yellow")
	var cafe: Cafe = setup[0]
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	await settle()
	assert_true(cafe.build_bar.message_text().contains("+25% de XP"), cafe.build_bar.message_text())


func test_collecting_shows_the_real_servings_and_xp() -> void:
	var setup := await _profile_cafe(&"stove_cream")
	var cafe: Cafe = setup[0]
	var stove: StringName = setup[1]
	var coffee := cafe.simulation.recipes.get_definition(&"coffee")
	cafe.simulation.start_cooking(stove, &"coffee")
	var servings := cafe.simulation.kitchen.stove_servings(stove)
	assert_true(servings > coffee.servings)
	clock.advance(coffee.cook_time)
	cafe.collect_stove(stove)
	await settle()
	var texts: Array[String] = []
	for child in cafe.effects.get_children():
		if child is FloatingText:
			texts.append((child as FloatingText).text)
	assert_true(texts.has("+%d Café" % servings), str(texts))
