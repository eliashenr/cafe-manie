extends CafeTestCase
## Os 12 clientes autorados: 288 poses, quatro direções e encaixe das poses sentadas na cadeira.
## Não compara beleza por pixels; garante o contrato que mantém a arte ligada ao jogo.

const LegacyCharacterArt = preload("res://tests/support/legacy_character_art.gd")
const MOODS: Array[String] = ["feliz", "esperando", "bravo", "comendo"]
const DIRECTIONS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const VIEWS: Array[String] = ["frente", "frente", "costas", "costas"]
const MIRRORED: Array[bool] = [false, true, true, false]

var _legacy_art := LegacyCharacterArt.new()


func cleanup() -> void:
	_legacy_art.restore()
	super()


func _customer(serial: int) -> Customer:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	customer.position = Vector2(3, 4)
	customer.seat_cell = Vector2i(3, 4)
	customer.patience_total = 100.0
	customer.patience_left = 100.0
	customer.order = load("res://data/recipes/coffee.tres")
	return customer


func _view(customer: Customer, rotation := -1) -> AgentView:
	var view := AgentView.new()
	view.refresh(customer, rotation, &"chair_wood" if rotation >= 0 else &"")
	add_to_tree(view)
	return view


func test_all_twelve_customers_have_24_authored_poses() -> void:
	var looks: Array = ArtSprites.characters().get("customers", [])
	assert_eq(looks.size(), 12, "as doze identidades foram preservadas")
	var checked := 0
	for index in looks.size():
		var look: String = looks[index]
		assert_eq(look, "cliente_%02d" % (index + 1), "a ordem dos visuais por serial não mudou")
		var poses: Array[String] = []
		for direction in ["frente", "costas"]:
			poses.append(direction + "_em_pe")
			for frame in AgentView.WALK_FRAMES:
				poses.append("%s_passo_%d" % [direction, frame])
		for mood in MOODS:
			poses.append("sentado_" + mood)
		poses.append_array(["sentado_costas_r1", "sentado_costas_r2"])
		assert_eq(poses.size(), 24)
		for pose in poses:
			var name := look + "_" + pose
			var sprite := ArtSprites.get_sprite(name)
			assert_true(sprite != null, name + " existe")
			if sprite == null:
				continue
			assert_true(sprite.authored_motion, name + " preserva o movimento desenhado")
			assert_eq(sprite.external_shadow, not pose.begins_with("sentado_"), name + " declara a sombra correta")
			assert_true(sprite.density > 0.0 and sprite.anchor.is_finite(), name + " tem âncora e escala válidas")
			assert_true(sprite.tray.is_empty(), name + " não é pose de garçom")
			checked += 1
	assert_eq(checked, 288, "nenhuma pose ficou faltando")


func test_customer_walk_cycles_preserve_scale_and_four_directions() -> void:
	var looks := ArtSprites.characters()["customers"] as Array
	for serial in looks.size():
		var customer := _customer(serial)
		var view := _view(customer)
		for direction in DIRECTIONS.size():
			customer.facing = DIRECTIONS[direction]
			for frame in range(-1, AgentView.WALK_FRAMES):
				view.velocity = Vector2.ZERO if frame < 0 else DIRECTIONS[direction]
				view._traveled = 0.0 if frame < 0 else (frame + 0.5) * 2.0 / (AgentView.WALK_FRAMES * AgentView.STEPS_PER_CELL)
				var suffix := "em_pe" if frame < 0 else "passo_%d" % frame
				assert_eq(view.pose(), ["%s_%s_%s" % [looks[serial], VIEWS[direction], suffix], MIRRORED[direction]])
				var transform := view.body_transform()
				assert_eq(transform.x, Vector2(-1.0 if MIRRORED[direction] else 1.0, 0.0), "espelho sem achatamento")
				assert_eq(transform.y, Vector2.DOWN, "sem esticar o desenho nem adicionar respiração")
				assert_eq(transform.origin, Vector2(0.0, -AgentView.SORT_NUDGE), "sem duplicar o quique autorado")
				assert_eq(view.step_motion(), 0.0)
				assert_true(view.ground_shadow_rect().has_area(), "em pé e andando há sombra separada")
				assert_vec_almost_eq(view.ground_shadow_rect().get_center(), IsoProjection.grid_point_to_world(view.shown))


func test_seated_customers_use_the_chair_vertex_and_its_backrest() -> void:
	var looks := ArtSprites.characters()["customers"] as Array
	for serial in looks.size():
		var customer := _customer(serial)
		customer.state = Customer.State.WAITING_FOR_FOOD
		for rotation in 4:
			var view := _view(customer, rotation)
			assert_true(view.seated_on_screen())
			var origin := IsoProjection.cell_top_vertex(customer.cell() + Vector2i.ONE)
			assert_eq(view.position, origin + Vector2(0.0, AgentView.SORT_NUDGE), "sentado ancora no vértice frontal da cadeira")
			assert_false(view.ground_shadow_rect().has_area(), "não aparece sombra flutuando sob o corpo sentado")
			var expected := "%s_sentado_feliz" % looks[serial]
			if rotation in [1, 2]:
				expected = "%s_sentado_costas_r%d" % [looks[serial], rotation]
				assert_eq(view.backrest(), ArtSprites.chair_backrest(&"chair_wood", rotation), "o encosto da cadeira cobre o cliente")
				assert_true(view.backrest() != null)
			else:
				assert_eq(view.backrest(), null, "de frente não duplica o encosto")
			assert_eq(view.pose(), [expected, rotation == 0], "só a frente na rotação zero espelha")
			var transform := view.body_transform()
			assert_eq(transform.origin, Vector2(0.0, -AgentView.SORT_NUDGE))
			assert_almost_eq(transform.x.length(), 1.0)
			assert_eq(transform.y, Vector2.DOWN)


func test_every_customer_changes_seated_expression_with_patience_and_eating() -> void:
	var looks := ArtSprites.characters()["customers"] as Array
	for serial in looks.size():
		var customer := _customer(serial)
		customer.state = Customer.State.WAITING_FOR_FOOD
		var view := _view(customer, 3)
		for mood in MOODS.size():
			customer.state = Customer.State.EATING if mood == 3 else Customer.State.WAITING_FOR_FOOD
			customer.patience_left = [80.0, 40.0, 10.0, 80.0][mood]
			assert_eq(view.pose(), ["%s_sentado_%s" % [looks[serial], MOODS[mood]], false])


func test_drink_touch_reaches_the_customer_drawn_on_each_seat_rotation() -> void:
	var simulation := quiet_simulation()
	simulation.progression.add_xp(30)  # nível 2: o expresso está disponível
	var cells: Array[Vector2i] = [Vector2i(2, 2), Vector2i(5, 2), Vector2i(2, 5), Vector2i(5, 5)]
	var chairs: Array[StringName] = []
	var customers: Array[Customer] = []
	assert_true(simulation.layout.place(simulation.furniture.get_definition(&"machine_coffee"), Vector2i.ZERO) != &"")
	# Monta o salão completo antes dos clientes: layout.changed reavalia quem ficou sem mesa ou máquina.
	for rotation in 4:
		var table_cell := cells[rotation] + CafeLayout.front_direction(rotation)
		assert_true(simulation.layout.place(simulation.furniture.get_definition(&"table_round"), table_cell) != &"",
			"a mesa da cadeira de prova cabe")
		var chair := simulation.layout.place(simulation.furniture.get_definition(&"chair_wood"), cells[rotation], rotation)
		assert_true(chair != &"", "a cadeira de prova cabe")
		chairs.append(chair)
	for rotation in 4:
		var customer := _customer(100 + rotation)
		customer.state = Customer.State.WAITING_FOR_DRINK
		customer.drink = simulation.drinks.get_definition(&"espresso")
		customer.seat_id = chairs[rotation]
		customer.seat_cell = cells[rotation]
		customer.position = Vector2(cells[rotation])
		simulation.customers.append(customer)
		customers.append(customer)
	var cafe := await spawn_cafe(simulation)
	cafe.world_layer.refresh(simulation)
	for customer in customers:
		assert_eq(customer.state, Customer.State.WAITING_FOR_DRINK, "a montagem manteve o cliente esperando a bebida")
		var view := cafe.world_layer.get_node("Agent_%d" % customer.serial) as AgentView
		assert_true(view.seated_on_screen(), "o toque é verificado na pose sentada")
		var body := view.body_rect()
		assert_true(body.has_area(), "o corpo continua com área de toque")
		assert_eq(cafe.world_layer.drink_customer_at(body.get_center()), customer, "o toque alcança quem aparece naquela cadeira")
		var balloon := Vector2(body.get_center().x, body.position.y - AgentView.TAP_REACH_ABOVE * 0.5)
		assert_eq(cafe.world_layer.drink_customer_at(balloon), customer, "o balão também permanece alcançável")

func test_legacy_fixture_restores_the_authored_sprite_objects() -> void:
	var looks := ArtSprites.characters()["customers"] as Array
	var name: String = looks[0] + "_frente_em_pe"
	var original := ArtSprites.get_sprite(name)
	assert_true(original.authored_motion and original.external_shadow)
	_legacy_art.use_customer(0)
	var legacy := ArtSprites.get_sprite(name)
	assert_true(legacy != original, "a fixture não modifica o objeto de produção")
	assert_false(legacy.authored_motion)
	assert_false(legacy.external_shadow)
	_legacy_art.restore()
	assert_eq(ArtSprites.get_sprite(name), original, "devolve o mesmo objeto ao cache")
	assert_true(original.authored_motion and original.external_shadow, "metadados de produção permanecem intactos")
