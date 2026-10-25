extends CafeTestCase
## O toque futurista (DT-082): o Robô Garçom (do terceiro garçom em diante, só o visual muda), a Máquina de Café
## Inteligente e o Painel Digital.


func _rich_cafe() -> Cafe:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 999999, "teste")
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_from_the_third_hire_on_the_waiter_is_a_robot() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	var from := sim.economy.robot_waiter_from
	assert_eq(from, 2, "o terceiro garçom (data/config/economy.tres)")
	while sim.waiters.size() < sim.economy.max_waiters():
		var robot_expected := sim.waiters.size() >= from
		assert_eq(sim.next_waiter_is_robot(), robot_expected)
		assert_eq(sim.hire_waiter(), ServiceResult.OK)
		assert_eq(sim.waiters[-1].robot, robot_expected, "garçom %d" % sim.waiters.size())
	for i in sim.waiters.size():
		assert_eq(sim.waiters[i].robot, i >= from)


func test_robots_work_like_waiters_and_come_back_after_loading() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	while sim.waiters.size() < 3:
		sim.hire_waiter()
	assert_eq(sim.waiters[2].speed, sim.waiters[0].speed, "o robô anda na mesma velocidade")
	var data := SaveCodec.encode(sim)
	var loaded := SaveCodec.decode(data, clock)
	assert_eq(loaded.simulation.waiters.size(), 3)
	assert_true(loaded.simulation.waiters[2].robot and not loaded.simulation.waiters[1].robot, "o save traz o robô de volta")


func test_the_robot_is_drawn_with_its_own_art() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	while sim.waiters.size() < 3:
		sim.hire_waiter()
	await settle()
	var robot_view: AgentView = null
	var human_view: AgentView = null
	for child in cafe.world_layer.get_children():
		if child is AgentView and child.agent is Waiter:
			if (child.agent as Waiter).robot:
				robot_view = child
			else:
				human_view = child
	assert_true(robot_view != null and human_view != null)
	assert_true(String(robot_view.pose()[0]).begins_with("robo_"), robot_view.pose()[0])
	assert_true(String(human_view.pose()[0]).begins_with("garcom_"), human_view.pose()[0])
	assert_true(ArtSprites.get_sprite(robot_view.pose()[0]) != null, "o desenho do quadro existe")
	for view in ["frente", "costas"]:
		for pose in ["em_pe", "passo_0", "passo_7"]:
			for tray in ["", "_bandeja"]:
				assert_true(ArtSprites.get_sprite("robo_%s_%s%s" % [view, pose, tray]) != null, "robo_%s_%s%s" % [view, pose, tray])


func test_hire_button_and_question_announce_the_robot() -> void:
	var cafe := await _rich_cafe()
	var sim := cafe.simulation
	while not sim.next_waiter_is_robot():
		sim.hire_waiter()
	await settle()
	assert_true(cafe.build_bar.find_button("HireButton").text.begins_with(BuildBar.ROBOT_WAITER_SHORT), "o botão diz Robô")
	cafe.build_bar.ask_hire_waiter()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.title.contains("Robô"), dialog.title)
	assert_true(dialog.dialog_text.contains("igual a um garçom"), "avisa que ele trabalha igual")
	dialog.get_ok_button().pressed.emit()
	assert_true(sim.waiters[-1].robot)


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
