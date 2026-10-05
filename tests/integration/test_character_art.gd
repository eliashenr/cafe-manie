extends CafeTestCase
## Arte v3 dos personagens: todo visual tem as poses que o AgentView pede, a
## direção e o espelhamento seguem o movimento, quem senta segue a cadeira, a
## expressão segue a paciência e o prato de quem come vai para a mesa certa.

const FRAMES: Array[String] = ["em_pe", "passo", "passo2"]


func _customer(serial := 0) -> Customer:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	return customer


func _view(agent: Agent, seat_rotation := -1) -> AgentView:
	var view := AgentView.new()
	view.refresh(agent, seat_rotation)
	add_to_tree(view)
	return view


func test_every_look_has_all_poses() -> void:
	var info := ArtSprites.characters()
	var looks: Array = info.get("customers", [])
	assert_true(looks.size() >= 8, "clientes variados")
	for look: String in looks:
		var names: Array[String] = []
		for view in ["frente", "costas"]:
			for frame in FRAMES:
				names.append("%s_%s_%s" % [look, view, frame])
		for mood in ["feliz", "esperando", "bravo", "comendo"]:
			names.append("%s_sentado_%s" % [look, mood])
		names.append("%s_sentado_costas_r1" % look)
		names.append("%s_sentado_costas_r2" % look)
		for sprite_name in names:
			assert_true(ArtSprites.get_sprite(sprite_name) != null, "falta " + sprite_name)
	var waiter: String = info.get("waiter", "")
	for view in ["frente", "costas"]:
		for frame in FRAMES:
			for tray in ["", "_bandeja"]:
				var sprite_name := "%s_%s_%s%s" % [waiter, view, frame, tray]
				assert_true(ArtSprites.get_sprite(sprite_name) != null, "falta " + sprite_name)


func test_every_recipe_has_a_dish_and_moods_exist() -> void:
	for recipe in RecipeCatalog.load_from().all():
		assert_true(ArtSprites.food(recipe.id) != null, "%s sem prato" % recipe.id)
	for mood in ["feliz", "esperando", "bravo"]:
		assert_true(ArtSprites.get_sprite("humor_" + mood) != null, "falta a carinha " + mood)
	var tray: Array = ArtSprites.characters().get("tray_food", [])
	assert_eq(tray.size(), 3, "a bandeja diz onde fica o prato")


func test_seated_back_art_matches_the_seats_in_the_catalog() -> void:
	# Quem senta de costas leva o encosto da cadeira desenhado por cima: toda cadeira precisa dizer o seu
	# (banqueta sem encosto diz "nenhum").
	for definition in FurnitureCatalog.load_from().all():
		if definition.category == FurnitureDefinition.Category.SEATING:
			assert_true(ArtSprites.has_backrest_entry(definition.id), "%s sem o encosto de quem senta de costas" % definition.id)
	assert_true(ArtSprites.chair_backrest(&"chair_wood", 1) != null and ArtSprites.chair_backrest(&"chair_wood", 2) != null,
		"a cadeira de madeira tem encosto nas duas rotações de costas")
	assert_eq(ArtSprites.chair_backrest(&"chair_wood", 3), null, "de frente, o encosto já está no desenho da cadeira")


func test_walking_direction_picks_front_or_back_and_mirror() -> void:
	var customer := _customer()
	customer.position = Vector2(3, 3)
	var expected := {
		Vector2(1, 0): ["frente", false],   # sudeste
		Vector2(0, 1): ["frente", true],    # sudoeste
		Vector2(-1, 0): ["costas", true],   # noroeste
		Vector2(0, -1): ["costas", false],  # nordeste
	}
	for facing: Vector2 in expected:
		customer.facing = facing
		var pose := _view(customer).pose()
		assert_true(String(pose[0]).contains("_%s_" % expected[facing][0]), "%s: %s" % [facing, pose[0]])
		assert_eq(pose[1], expected[facing][1], "espelhado para %s" % facing)


func test_walk_cycle_alternates_feet_bounces_and_stops_standing() -> void:
	var customer := _customer()
	customer.speed = 2.2
	customer.position = Vector2(2, 3)
	var view := _view(customer)
	var seen := {}
	var bounced := false
	var swayed := false
	for i in 90:
		customer.position.x += customer.speed / 60.0
		view.advance(1.0 / 60.0)
		seen[String(view.pose()[0]).get_slice("_frente_", 1)] = true
		bounced = bounced or view.step_motion()[0] > 1.0
		swayed = swayed or absf(view.step_motion()[1]) > 0.02
	for frame in FRAMES:
		assert_true(seen.has(frame), "o ciclo passa por " + frame)
	assert_true(bounced and swayed, "cada passada quica e balança o corpo")
	for i in 120:
		view.advance(1.0 / 60.0)
	assert_false(view.walking(), "parou de andar")
	assert_true(String(view.pose()[0]).ends_with("_frente_em_pe"), "parado fica em pé")
	assert_eq(view.step_motion(), [0.0, 0.0], "parado não quica")


func test_jumps_in_the_rules_become_short_walks_on_screen() -> void:
	var customer := _customer()
	customer.speed = 2.2
	customer.position = Vector2(3, 3)
	var view := _view(customer)
	customer.position = Vector2(4, 3)  # nas regras, o cliente pula para o piso ao lado (ex.: levantou da cadeira)
	view.advance(1.0 / 60.0)
	var moved := view.shown.distance_to(Vector2(3, 3))
	assert_true(moved > 0.0 and moved <= customer.speed * AgentView.CATCH_UP / 60.0 + 0.001, "anda, não pula: %f" % moved)
	for i in 60:
		view.advance(1.0 / 60.0)
	assert_true(view.shown.distance_to(customer.position) < 0.02, "chega em menos de um segundo")


func test_customer_sits_only_when_the_drawing_reaches_the_chair() -> void:
	var customer := _customer()
	customer.speed = 2.2
	customer.state = Customer.State.WAITING_TO_ORDER
	customer.patience_total = 10.0
	customer.patience_left = 10.0
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	var view := _view(customer, 3)
	view.arrive_from(Vector2(4, 4))  # o desenho ainda está no piso de acesso
	assert_false(view.seated_on_screen())
	view.advance(1.0 / 60.0)
	assert_false(String(view.pose()[0]).contains("_sentado_"), "ainda andando até a cadeira")
	for i in 60:
		view.advance(1.0 / 60.0)
	assert_true(String(view.pose()[0]).ends_with("_sentado_feliz"), "chegou e sentou")


func test_customers_arrive_from_the_sidewalk_and_leave_to_it() -> void:
	var simulation := quiet_simulation()
	simulation.customer_types.append(load("res://data/customers/regular.tres"))
	simulation.config.spawn_jitter = 0.0
	var cafe := await spawn_cafe(simulation)
	cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(4, 4))
	cafe.layout.place(cafe.catalog.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	while simulation.customers.is_empty():
		simulation.tick(0.1)
	cafe.world_layer.refresh(simulation)
	var customer: Customer = simulation.customers[0]
	var view: AgentView = cafe.world_layer.get_node("Agent_%d" % customer.serial)
	var sidewalk := Vector2(cafe.layout.entrance) + WorldLayer.SIDEWALK_OFFSET
	assert_true(view.shown.distance_to(sidewalk) < 0.01, "o desenho começa na calçada")
	assert_true(view.modulate.a < 0.01, "e aparece aos poucos")
	customer.state = Customer.State.GONE
	simulation.tick(0.0)
	cafe.world_layer.refresh(simulation)
	assert_eq(cafe.world_layer.agent_view_count(), 1, "nas regras, só o garçom ficou")
	assert_eq(cafe.world_layer.exiting_count(), 1, "o cliente termina a caminhada até a calçada")
	assert_true(view.exiting)
	for i in 400:
		if not is_instance_valid(view):
			break
		view.advance(1.0 / 30.0)
	await settle()
	assert_eq(cafe.world_layer.exiting_count(), 0, "chegou na calçada, sumiu e saiu da tela")


func test_customers_get_different_looks() -> void:
	var looks := {}
	for serial in 6:
		looks[String(_view(_customer(serial)).pose()[0]).get_slice("_frente_", 0)] = true
	assert_eq(looks.size(), 6, "seis clientes seguidos, seis visuais")


func test_seated_customer_follows_the_chair_rotation() -> void:
	var customer := _customer()
	customer.state = Customer.State.WAITING_TO_ORDER
	customer.patience_total = 10.0
	customer.patience_left = 10.0
	var front: Array = _view(customer, 3).pose()
	assert_true(String(front[0]).ends_with("_sentado_feliz"), front[0])
	assert_false(front[1], "rotação 3 olha para a direita")
	assert_true(_view(customer, 0).pose()[1], "rotação 0 sai espelhada")
	assert_true(String(_view(customer, 1).pose()[0]).ends_with("_sentado_costas_r1"))
	assert_true(String(_view(customer, 2).pose()[0]).ends_with("_sentado_costas_r2"))


func test_back_seated_customer_is_covered_by_the_backrest_of_their_own_chair() -> void:
	var customer := _customer()
	customer.state = Customer.State.WAITING_TO_ORDER
	customer.patience_total = 10.0
	customer.patience_left = 10.0
	var on := func(rotation: int, chair: StringName) -> AgentView:
		var view := AgentView.new()
		view.refresh(customer, rotation, chair)
		add_to_tree(view)
		return view
	for rotation in [1, 2]:
		var backrest: ArtSprites.Sprite = on.call(rotation, &"chair_70s").backrest()
		assert_true(backrest != null, "de costas na rotação %d, o encosto vai por cima" % rotation)
		assert_eq(backrest, ArtSprites.chair_backrest(&"chair_70s", rotation), "o encosto da cadeira em que sentou")
		assert_true(backrest != ArtSprites.chair_backrest(&"chair_wood", rotation), "não o da cadeira clássica")
	assert_eq(on.call(3, &"chair_70s").backrest(), null, "de frente, o encosto já está no desenho da cadeira")
	assert_eq(on.call(1, &"stool_diner").backrest(), null, "banqueta não tem encosto")
	customer.state = Customer.State.WALKING_IN
	assert_eq(on.call(1, &"chair_70s").backrest(), null, "em pé, nada por cima")


func test_expression_follows_patience_and_eating() -> void:
	var customer := _customer()
	customer.state = Customer.State.WAITING_FOR_FOOD
	customer.patience_total = 10.0
	customer.patience_left = 8.0
	assert_eq(_view(customer, 3).expression(), "feliz")
	customer.patience_left = 4.0
	assert_eq(_view(customer, 3).expression(), "esperando")
	customer.patience_left = 1.0
	assert_eq(_view(customer, 3).expression(), "bravo")
	customer.state = Customer.State.EATING
	assert_eq(_view(customer, 3).expression(), "comendo")


func test_waiter_carrying_food_uses_the_tray_pose() -> void:
	var waiter := Waiter.new()
	waiter.facing = Vector2(0, -1)
	assert_false(String(_view(waiter).pose()[0]).ends_with("_bandeja"), "de mãos vazias")
	waiter.carrying = load("res://data/recipes/coffee.tres")
	var pose: String = _view(waiter).pose()[0]
	assert_true(pose.ends_with("_costas_em_pe_bandeja"), pose)


func test_scene_seats_customer_with_chair_rotation_and_serves_dish_on_table() -> void:
	var cafe := await spawn_cafe()
	var table := cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(4, 4))
	var chair := cafe.layout.place(cafe.catalog.get_definition(&"chair_wood"), Vector2i(3, 4), 3)
	var customer := _customer(50)
	customer.seat_id = chair
	customer.seat_cell = Vector2i(3, 4)
	customer.position = Vector2(3, 4)
	customer.state = Customer.State.EATING
	customer.order = load("res://data/recipes/coxinha.tres")
	cafe.simulation.customers.append(customer)
	cafe.world_layer.refresh(cafe.simulation)
	var dishes := cafe.world_layer.view_for(table).dishes
	assert_eq(dishes.size(), 1, "o prato está na mesa")
	assert_eq(dishes[0][1], customer.order)
	assert_true((dishes[0][0] as Vector2).x < 4.0, "do lado da cadeira")
	var seated: AgentView = cafe.world_layer.get_node("Agent_50")
	assert_eq(seated.seat_rotation, 3, "senta virado como a cadeira")
	assert_eq(seated.seat_furniture, &"chair_wood", "sabe em que cadeira sentou (para o encosto)")
	customer.state = Customer.State.LEAVING
	cafe.world_layer.refresh(cafe.simulation)
	assert_eq(cafe.world_layer.view_for(table).dishes.size(), 0, "quem levantou leva o prato")


func test_balloons_are_drawn_above_the_whole_room() -> void:
	var view := _view(_customer())
	var overlay: Node2D = view.get_node("Overlay")
	assert_true(overlay.z_index > 0 and overlay.z_as_relative, "balão por cima de móveis e personagens")
