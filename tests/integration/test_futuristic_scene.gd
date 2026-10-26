extends CafeTestCase
## O toque futurista (DT-082): a Máquina de Café Inteligente e o Painel Digital. O Robô Garçom saiu a pedido do PO
## (DT-088): todos os garçons são humanos.


func _rich_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 999999, "teste")
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_every_waiter_is_a_person() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	while sim.waiters.size() < sim.economy.max_waiters():
		assert_eq(sim.hire_waiter(), ServiceResult.OK)
	await settle()
	var waiter_look: String = ArtSprites.characters()["waiter"]
	var views := 0
	for child in cafe.world_layer.get_children():
		if child is AgentView and child.agent is Waiter:
			assert_true(String(child.pose()[0]).begins_with(waiter_look + "_"), child.pose()[0])
			views += 1
	assert_eq(views, sim.economy.max_waiters(), "todos os garçons na tela, todos com o desenho do garçom")
	assert_false(ArtSprites.characters().has("robot_waiter"), "o desenho do robô saiu do jogo")
	assert_true(cafe.build_bar.find_button("HireButton").text.begins_with("Garçons"), "a equipe completa")


func test_smart_coffee_machine_serves_coffee() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	var smart: FurnitureDefinition = sim.furniture.get_definition(&"machine_coffee_smart")
	assert_true(smart != null and smart.is_valid())
	assert_eq(smart.machine, (sim.furniture.get_definition(&"machine_coffee") as FurnitureDefinition).machine,
		"faz os mesmos cafés da máquina clássica")
	assert_true(smart.beauty > (sim.furniture.get_definition(&"machine_coffee") as FurnitureDefinition).beauty, "e é mais bonita")
	var coffee: DrinkDefinition = null
	for drink: DrinkDefinition in sim.drinks.all():
		if drink.machine == smart.machine:
			coffee = drink
	assert_true(coffee != null)
	assert_false(sim.has_machine_for(coffee))
	assert_true(sim.layout.place(smart, Vector2i(6, 0)) != &"", "cabe no café")
	assert_true(sim.has_machine_for(coffee), "com ela no café, os clientes pedem café")
	assert_true(ArtSprites.furniture(&"machine_coffee_smart", 0) != null)
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.KITCHEN)
	cafe.build_bar.show_shop_collection(&"anos2010")
	await settle()
	assert_true(cafe.build_bar.shop_item_ids().has(&"machine_coffee_smart"), "à venda na Cozinha")


func test_digital_panel_glows_at_night() -> void:
	var cafe := await _rich_cafe()
	var panel: WallItemDefinition = cafe.simulation.wall_items.get_definition(&"painel_digital")
	assert_true(panel != null and panel.is_valid())
	assert_true(panel.glows_at_night and panel.glow_color.b > panel.glow_color.r, "acende em ciano")
	assert_true(ArtSprites.get_sprite("enfeite_painel_digital_R") != null)
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	cafe.build_bar.show_shop_collection(&"anos2010")
	await settle()
	assert_true(cafe.build_bar.shop_item_ids().has(&"painel_digital"))
