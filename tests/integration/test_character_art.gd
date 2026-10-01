extends CafeTestCase
## Arte v3 dos personagens: todo visual tem as poses que o AgentView pede, a
## direção e o espelhamento seguem o movimento, quem senta segue a cadeira, a
## expressão segue a paciência e o prato de quem come vai para a mesa certa.

const FRAMES: Array[String] = ["em_pe", "andar", "andar2"]


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
	# Quem senta de costas leva o encosto da cadeira desenhado por cima: cadeira nova precisa de arte nova.
	var chair: String = ArtSprites.characters().get("seated_back_chair", "")
	for definition in FurnitureCatalog.load_from().all():
		if definition.category == FurnitureDefinition.Category.SEATING:
			assert_eq(String(definition.id), chair, "%s não tem a arte de quem senta de costas" % definition.id)


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


func test_walk_cycle_alternates_feet_and_stops_standing() -> void:
	var customer := _customer()
	customer.facing = Vector2(1, 0)
	customer.path = [Vector2i(5, 3)]
	var seen := {}
	for i in 8:
		customer.position = Vector2(3.0 + i * 0.25, 3.0)
		var pose: String = _view(customer).pose()[0]
		seen[pose.get_slice("_frente_", 1)] = true
	for frame in FRAMES:
		assert_true(seen.has(frame), "o ciclo passa por " + frame)
	customer.path.clear()
	assert_true(String(_view(customer).pose()[0]).ends_with("_frente_em_pe"), "parado fica em pé")


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
	customer.state = Customer.State.LEAVING
	cafe.world_layer.refresh(cafe.simulation)
	assert_eq(cafe.world_layer.view_for(table).dishes.size(), 0, "quem levantou leva o prato")


func test_balloons_are_drawn_above_the_whole_room() -> void:
	var view := _view(_customer())
	var overlay: Node2D = view.get_node("Overlay")
	assert_true(overlay.z_index > 0 and overlay.z_as_relative, "balão por cima de móveis e personagens")
