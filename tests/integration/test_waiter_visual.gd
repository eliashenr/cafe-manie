extends CafeTestCase
## Contrato da arte autorada do garçom: quadros RGBA sem sombra, movimento dentro da imagem,
## sombra apoiada no chão e prato preso à bandeja em todas as direções, inclusive parado.

const FRAMES: Array[String] = ["em_pe", "passo_0", "passo_1", "passo_2", "passo_3", "passo_4", "passo_5", "passo_6", "passo_7"]
const LegacyCharacterArt = preload("res://tests/support/legacy_character_art.gd")

var _legacy_art := LegacyCharacterArt.new()


func cleanup() -> void:
	_legacy_art.restore()
	super()


func _view(agent: Agent) -> AgentView:
	var view := AgentView.new()
	view.refresh(agent)
	add_to_tree(view)
	return view


func test_waiter_frames_declare_their_visual_contract() -> void:
	var look: String = ArtSprites.characters()["waiter"]
	for direction in ["frente", "costas"]:
		for frame in FRAMES:
			for carrying in [false, true]:
				var sprite_name := "%s_%s_%s%s" % [look, direction, frame, "_bandeja" if carrying else ""]
				var sprite := ArtSprites.get_sprite(sprite_name)
				assert_true(sprite != null, sprite_name + " existe")
				if sprite == null:
					continue
				assert_true(sprite.external_shadow, sprite_name + " recebe sombra separada")
				assert_true(sprite.authored_motion, sprite_name + " não recebe deformação adicional")
				if carrying:
					assert_eq(sprite.tray.size(), 3, sprite_name + " define a posição e a largura do prato")
					if sprite.tray.size() == 3:
						assert_true(float(sprite.tray[2]) > 0.0, sprite_name + " tem largura válida de prato")


func test_authored_waiter_walks_and_stops_without_extra_deformation() -> void:
	var waiter := Waiter.new()
	waiter.position = Vector2(2, 3)
	waiter.speed = 2.2
	var view := _view(waiter)
	var frames := {}
	for i in 120:
		waiter.position.x += waiter.speed / 60.0
		view.advance(1.0 / 60.0)
		frames[view.pose()[0]] = true
		_assert_native_body(view)
	assert_true(frames.size() >= AgentView.WALK_FRAMES, "o garçom percorre o ciclo de quadros")
	for i in 120:
		view.advance(1.0 / 60.0)
		_assert_native_body(view)
	assert_false(view.walking(), "parou de andar")
	assert_true(String(view.pose()[0]).ends_with("_em_pe"), "voltou para a pose parada")
	assert_almost_eq(view.modulate.a, 1.0, 0.001, "a aparição suave continua funcionando")


func _assert_native_body(view: AgentView) -> void:
	var transform := view.body_transform()
	assert_almost_eq(transform.x.length(), 1.0, 0.001, "sem achatar o quadro autorado")
	assert_almost_eq(transform.y.length(), 1.0, 0.001, "sem esticar nem respirar sobre o quadro autorado")
	assert_eq(transform.origin, Vector2(0.0, -AgentView.SORT_NUDGE), "sem quique extra")
	assert_eq(view.step_motion(), 0.0)
	assert_eq(view.stretch(), 0.0)


func test_shadow_stays_on_the_floor_while_the_waiter_walks() -> void:
	var waiter := Waiter.new()
	waiter.position = Vector2(2, 3)
	waiter.speed = 2.2
	var view := _view(waiter)
	for i in 90:
		waiter.position.x += waiter.speed / 60.0
		view.advance(1.0 / 60.0)
		var shadow := view.ground_shadow_rect()
		assert_eq(shadow.size, AgentView.GROUND_SHADOW_SIZE, "a sombra não muda com as passadas")
		assert_almost_eq(shadow.get_center().distance_to(IsoProjection.grid_point_to_world(view.shown)), 0.0, 0.001,
			"a sombra fica nos pés, sem receber o quique do corpo nem o desempate do y-sort")
	view.set_frozen(true)
	assert_true(view.ground_shadow_rect().has_area(), "a sombra continua visível ao pausar")
	assert_almost_eq(view.modulate.a, 1.0, 0.001, "pausar não deixa o personagem transparente")


func test_plate_follows_authored_trays_when_idle_walking_and_mirrored() -> void:
	var waiter := Waiter.new()
	waiter.position = Vector2(2, 3)
	waiter.carrying = load("res://data/recipes/coffee.tres")
	var view := _view(waiter)
	var directions := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for direction: Vector2 in directions:
		waiter.facing = direction
		for frame in range(-1, AgentView.WALK_FRAMES):
			view.velocity = Vector2.ZERO if frame < 0 else direction
			view._traveled = 0.0 if frame < 0 else (frame + 0.5) / AgentView.WALK_FRAMES * 2.0 / AgentView.STEPS_PER_CELL
			var body_pose := view.pose()
			var sprite := ArtSprites.get_sprite(body_pose[0])
			assert_true(sprite != null, String(body_pose[0]))
			if sprite == null or sprite.tray.size() != 3:
				assert_true(false, "falta a âncora por quadro em " + String(body_pose[0]))
				continue
			assert_eq(view.tray_food(), sprite.tray, "a âncora do quadro tem prioridade, inclusive parado")
			var transform := view.body_transform()
			var plate := transform * Vector2(sprite.tray[0], sprite.tray[1])
			var mirrored: bool = direction == Vector2.DOWN or direction == Vector2.LEFT
			assert_eq(body_pose[1], mirrored, "espelho da direção " + str(direction))
			assert_almost_eq(plate.x, float(sprite.tray[0]) * (-1.0 if mirrored else 1.0), 0.001,
				"o prato espelha junto com a bandeja")
			assert_almost_eq(plate.y, float(sprite.tray[1]) - AgentView.SORT_NUDGE, 0.001,
				"o prato não recebe um segundo quique")
			var rect := view.body_rect()
			var local_rect := sprite.draw_rect()
			var left := -local_rect.end.x if mirrored else local_rect.position.x
			assert_almost_eq(rect.position.x, view.position.x + left, 0.001,
				"a área do corpo segue o espelho, sem incorporar a sombra")


func test_legacy_customer_keeps_procedural_motion_and_embedded_shadow() -> void:
	var customer := Customer.new()
	_legacy_art.use_customer(customer.serial)
	customer.type = load("res://data/customers/regular.tres")
	customer.position = Vector2(2, 3)
	customer.speed = 2.2
	var view := _view(customer)
	var sprite := ArtSprites.get_sprite(view.pose()[0])
	assert_false(sprite.external_shadow, "arte legada não ganha uma segunda sombra")
	assert_false(sprite.authored_motion, "o opt-in preserva o contrato legado")
	assert_false(view.ground_shadow_rect().has_area())
	var bounced := false
	for i in 60:
		customer.position.x += customer.speed / 60.0
		view.advance(1.0 / 60.0)
		bounced = bounced or view.step_motion() > 1.0
	assert_true(bounced, "o quique legado dos clientes foi preservado")
