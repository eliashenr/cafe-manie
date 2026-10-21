extends CafeTestCase
## Efeitos visuais (só tela): raio-X atrás de móvel alto, halo de brilho, vapor, móvel que surge,
## pilha que quica, mureta que esmaece, confete do pagamento, esticar e achatar, áreas de toque,
## filtro de textura e a ordem de desenho do salão (y-sort).


func _place(cafe: Cafe, id: StringName, cell: Vector2i, rotation := 0) -> StringName:
	return cafe.layout.place(cafe.catalog.get_definition(id), cell, rotation)


## Cliente em pé no ponto [param at] do grid, já desenhado ali (indo embora: quem está chegando
## começa desenhado na calçada). O teste não deixa a simulação andar, então ele fica parado.
func _standing_customer(cafe: Cafe, at: Vector2, serial := 70) -> AgentView:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	customer.state = Customer.State.LEAVING
	customer.position = at
	cafe.simulation.customers.append(customer)
	cafe.world_layer.refresh(cafe.simulation)
	return cafe.world_layer.get_node("Agent_%d" % serial)


## Espera tempo de verdade (as animações por Tween andam pelo relógio, não pela contagem de frames).
func _wait(seconds: float) -> void:
	await tree.create_timer(seconds).timeout


## A mureta recebeu um ponto de foco perto de [param world]?
func _focus_near(material: ShaderMaterial, world: Vector2) -> bool:
	var focus: PackedVector2Array = material.get_shader_parameter("focus")
	for i in int(material.get_shader_parameter("focus_count")):
		if focus[i].distance_to(world) < 40.0:
			return true
	return false


func test_customer_behind_a_tall_stove_shows_through_it() -> void:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(2, 2))
	var view := _standing_customer(cafe, Vector2(1.6, 1.6))
	var stove_view := cafe.world_layer.view_for(stove)
	assert_true(view.position.y < stove_view.position.y, "o cliente está atrás (desenhado antes)")
	assert_true(view.shows_xray(), "a silhueta aparece por cima do fogão")
	assert_eq(view.occluders(), [stove_view], "no formato do fogão que tampa")
	var xray: Node2D = view.get_node("XRay")
	assert_eq(xray.clip_children, CanvasItem.CLIP_CHILDREN_ONLY, "o recorte é o desenho do fogão")
	assert_true(xray.z_index > 0 and xray.z_index < AgentView.OVERLAY_Z, "acima dos móveis, abaixo dos balões")
	var body: Node2D = xray.get_node("XRayBody")
	assert_true(body.material is ShaderMaterial, "silhueta por shader")
	assert_eq((body.material as ShaderMaterial).shader, FxMaterials.SILHOUETTE)


func test_no_xray_in_front_of_furniture_or_behind_tables() -> void:
	var cafe := await spawn_cafe()
	_place(cafe, &"stove_basic", Vector2i(2, 2))
	_place(cafe, &"table_round", Vector2i(5, 2))
	var in_front := _standing_customer(cafe, Vector2(3.4, 3.4), 71)
	var behind_table := _standing_customer(cafe, Vector2(4.6, 1.6), 72)
	assert_false(in_front.shows_xray(), "na frente do fogão, ele já aparece inteiro")
	assert_false(behind_table.shows_xray(), "mesa baixa não esconde ninguém")


func test_seated_customer_never_gets_the_xray() -> void:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(2, 2))
	var chair := _place(cafe, &"chair_wood", Vector2i(1, 1), 3)
	var customer := Customer.new()
	customer.serial = 78
	customer.type = load("res://data/customers/regular.tres")
	customer.seat_id = chair
	customer.seat_cell = Vector2i(1, 1)
	customer.position = Vector2(1, 1)
	customer.state = Customer.State.EATING
	customer.eat_left = 999.0
	customer.order = load("res://data/recipes/coffee.tres")
	cafe.simulation.customers.append(customer)
	cafe.world_layer.refresh(cafe.simulation)
	var view: AgentView = cafe.world_layer.get_node("Agent_78")
	var stove_view := cafe.world_layer.view_for(stove)
	var stove_rect := Rect2(stove_view.position + stove_view.sprite.draw_rect().position, stove_view.sprite.draw_rect().size)
	assert_true(view.seated_on_screen() and stove_rect.intersects(view.body_rect()), "sentado atrás do fogão")
	assert_false(view.shows_xray(), "sentado, a silhueta não aparece (a mesa na frente é o normal)")


func test_xray_goes_away_when_the_customer_walks_out_from_behind() -> void:
	var cafe := await spawn_cafe()
	_place(cafe, &"stove_basic", Vector2i(2, 2))
	var view := _standing_customer(cafe, Vector2(1.6, 1.6))
	assert_true(view.shows_xray())
	view.agent.position = Vector2(5.5, 5.5)
	for i in 240:
		view.advance(1.0 / 60.0)
	cafe.world_layer.refresh(cafe.simulation)
	assert_false(view.shows_xray(), "saiu de trás: sem silhueta")
	assert_eq(view.occluders(), [])


func test_selected_furniture_glows_and_ghost_does_not() -> void:
	var cafe := await spawn_cafe()
	var table := _place(cafe, &"table_round", Vector2i(4, 4))
	var view := cafe.world_layer.view_for(table)
	assert_false(view.glowing(), "sem seleção, sem brilho")
	tap_cell(cafe, Vector2i(4, 4))
	await settle()
	assert_eq(cafe.selected_id, table)
	assert_true(view.glowing(), "o móvel escolhido ganha o halo")
	var halo: Node2D = view.get_node("Halo")
	var floor_mark: Node2D = view.get_node("FloorMark")
	for slice in view.slices():
		assert_true(halo.position.y < slice.position.y, "o halo fica atrás do desenho (antes de cada faixa no y-sort)")
		assert_true(floor_mark.position.y < slice.position.y, "o contorno no chão também")
	assert_eq((halo.material as ShaderMaterial).get_shader_parameter("glow_color"), FurnitureView.HALO_SELECTED)
	assert_true(cafe.start_placing(&"stove_basic"))
	tap_cell(cafe, Vector2i(1, 1))
	assert_true(cafe.world_layer.is_ghost_visible())
	assert_false((cafe.world_layer.get_node("Ghost") as FurnitureView).glowing(), "o fantasma da compra não brilha")


func test_ready_stove_glows_gold_and_steams_while_cooking() -> void:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(0, 0))
	await settle()
	var view := cafe.world_layer.view_for(stove)
	assert_false(view.steaming(), "fogão desligado não solta vapor")
	cafe.simulation.start_cooking(stove, &"coffee")
	await settle()
	assert_true(view.steaming(), "cozinhando: vapor saindo da panela")
	assert_false(view.glowing(), "ainda não está pronto")
	var steam: CPUParticles2D = view.get_node("Fx/Steam")
	assert_true(steam.position.y < 0.0, "o vapor sai lá de cima, da panela")
	clock.advance(15.0)
	await settle()
	assert_true(view.glowing(), "prato pronto: o fogão brilha")
	assert_eq((view.get_node("Halo").material as ShaderMaterial).get_shader_parameter("glow_color"), FurnitureView.HALO_READY)
	assert_true(view.steaming(), "o prato pronto ainda solta vapor")


func test_hot_dishes_on_the_counter_steam_and_land_with_a_bounce() -> void:
	var cafe := await spawn_cafe()
	var stove := _place(cafe, &"stove_basic", Vector2i(0, 0))
	var counter := _place(cafe, &"counter_basic", Vector2i(2, 0))
	await settle()
	var view := cafe.world_layer.view_for(counter)
	assert_false(view.steaming(), "balcão vazio, sem vapor")
	cafe.simulation.start_cooking(stove, &"coffee")
	clock.advance(15.0)
	cafe.simulation.collect(stove)
	cafe.world_layer.refresh(cafe.simulation)
	assert_true(view.steaming(), "pratos quentes no balcão soltam vapor")
	assert_true(view.stack_pop < 0.0, "a pilha chega de cima")
	await _wait(Juice.POP_TIME + 0.15)
	assert_almost_eq(view.stack_pop, 0.0, 0.01, "e assenta no tampo")
	assert_false(cafe.world_layer.view_for(stove).steaming(), "o fogão vazio parou de soltar vapor")


func test_new_furniture_pops_in_but_the_cafe_does_not_on_load() -> void:
	var simulation := quiet_simulation()
	var first := simulation.layout.place(simulation.furniture.get_definition(&"table_round"), Vector2i(1, 1))
	var cafe := await spawn_cafe(simulation)
	assert_eq(cafe.world_layer.view_for(first).scale, Vector2.ONE, "ao abrir, os móveis já estão no lugar")
	var table := _place(cafe, &"table_round", Vector2i(4, 4))
	var view := cafe.world_layer.view_for(table)
	assert_eq(view.scale, Vector2.ONE * Juice.POP_FROM, "o móvel novo começa pequeno")
	await _wait(Juice.POP_TIME + 0.15)
	assert_vec_almost_eq(view.scale, Vector2.ONE, 0.001, "e cresce até o tamanho certo")


func test_front_wall_fades_near_people_at_the_front() -> void:
	var cafe := await spawn_cafe()
	var material := cafe.front_view.material as ShaderMaterial
	assert_true(material != null and material.shader == FxMaterials.FADE, "a mureta tem o shader de esmaecer")
	# Clientes sentados comendo (o relógio manual parado os mantém no lugar): um no meio, um junto da frente.
	var spots := {Vector2i(2, 2): 76, Vector2i(3, 7): 77}
	for cell: Vector2i in spots:
		var chair := _place(cafe, &"chair_wood", cell, 3)
		var customer := Customer.new()
		customer.serial = spots[cell]
		customer.type = load("res://data/customers/regular.tres")
		customer.seat_id = chair
		customer.seat_cell = cell
		customer.position = Vector2(cell)
		customer.state = Customer.State.EATING
		customer.eat_left = 999.0
		customer.order = load("res://data/recipes/coffee.tres")
		cafe.simulation.customers.append(customer)
	await settle()
	await settle()
	var focus: PackedVector2Array = material.get_shader_parameter("focus")
	assert_eq(focus.size(), FxMaterials.MAX_FOCUS, "o shader sempre recebe os 8 pontos")
	var mark := Vector2(0.0, WorldLayer.FRONT_FOCUS_LIFT)
	assert_true(_focus_near(material, IsoProjection.grid_point_to_world(Vector2(3, 7)) - mark),
		"cliente junto da frente: a mureta abre ali")
	assert_false(_focus_near(material, IsoProjection.grid_point_to_world(Vector2(2, 2)) - mark),
		"no meio do salão a mureta não atrapalha: fica normal")
	tap_cell(cafe, Vector2i(6, 7))
	await settle()
	assert_true(_focus_near(material, IsoProjection.cell_center(Vector2i(6, 7))), "o piso escolhido também abre")


func test_front_wall_also_opens_for_who_is_leaving() -> void:
	var cafe := await spawn_cafe()
	var view := _standing_customer(cafe, Vector2(5.0, 7.3), 79)
	var at := IsoProjection.grid_point_to_world(view.shown) - Vector2(0.0, WorldLayer.FRONT_FOCUS_LIFT)
	view.agent.state = Customer.State.GONE
	cafe.simulation.tick(0.0)
	cafe.world_layer.refresh(cafe.simulation)
	assert_eq(cafe.world_layer.exiting_count(), 1, "saiu nas regras e anda até a calçada")
	assert_true(cafe.world_layer.front_focus_points(CafeGrid.NO_CELL).has(at), "a mureta continua aberta enquanto ele passa")


func test_payment_bursts_gold_confetti_that_cleans_itself_up() -> void:
	var cafe := await spawn_cafe()
	var customer := Customer.new()
	customer.seat_cell = Vector2i(3, 4)
	cafe.simulation.payment_received.emit(customer, 7)
	assert_eq(cafe.particles.get_child_count(), 1, "um estouro de confete")
	var burst: Node2D = cafe.particles.get_child(0)
	var confetti: CPUParticles2D = burst.get_node("Confetti")
	assert_true(confetti.one_shot and confetti.emitting, "estoura uma vez")
	assert_true(burst.get_node("Sparks") is CPUParticles2D, "com faíscas")
	assert_true(burst.position.distance_to(IsoProjection.grid_point_to_world(Vector2(3, 4))) < 80.0, "em cima da mesa")
	confetti.finished.emit()
	await settle()
	assert_eq(cafe.particles.get_child_count(), 0, "e some sozinho quando acaba")


func test_walking_stretches_and_braking_squashes() -> void:
	var cafe := await spawn_cafe()
	var view := _standing_customer(cafe, Vector2(2.0, 2.0))
	assert_eq(view.stretch(), 0.0, "parado: forma normal")
	view.agent.position = Vector2(6.0, 2.0)
	view.advance(1.0 / 60.0)
	view.advance(1.0 / 60.0)
	assert_true(view.stretch() > 0.0, "arrancando: estica")
	assert_true(view.stretch() <= AgentView.STRETCH_MAX, "sutil")
	var peak := 0.0
	for i in 600:
		view.advance(1.0 / 60.0)
		peak = minf(peak, view.stretch())
	assert_true(peak < 0.0, "chegando: achata ao frear")
	assert_true(peak >= -AgentView.STRETCH_MAX)
	assert_almost_eq(view.stretch(), 0.0, 0.002, "parou: volta ao normal")


func test_shop_fades_in_and_toast_pops() -> void:
	var cafe := await spawn_cafe()
	cafe.build_bar.open_shop()
	await settle()
	var shop: Control = cafe.build_bar._shop
	assert_true(shop.visible)
	assert_true(shop.modulate.a < 1.0, "a loja acende aos poucos")
	await _wait(Juice.FADE_IN_TIME + 0.15)
	assert_almost_eq(shop.modulate.a, 1.0, 0.001, "e fica inteira")
	cafe.hud.show_message("Olá!")
	await settle()
	assert_eq(cafe.hud.toast_text(), "Olá!")
	var toast: Control = cafe.hud._toast
	assert_true(toast.scale.x < 1.0, "o aviso surge crescendo")


func test_gold_label_bumps_when_gold_comes_in() -> void:
	var cafe := await spawn_cafe()
	await settle()
	var label: Label = cafe.hud._gold_label
	assert_eq(label.scale, Vector2.ONE)
	cafe.simulation.wallet.earn(Wallet.SOFT, 10, "teste")
	await settle()
	await settle()
	assert_true(label.scale.x > 1.0, "o número do ouro quica")
	assert_eq(label.pivot_offset, label.size / 2.0, "quica pelo meio")
	await _wait(Juice.BUMP_TIME + 0.15)
	assert_vec_almost_eq(label.scale, Vector2.ONE, 0.001)
	cafe.simulation.wallet.spend(Wallet.SOFT, 5, "teste")
	await settle()
	await settle()
	assert_eq(label.scale, Vector2.ONE, "gastar não quica")


func test_icon_buttons_have_finger_sized_touch_areas() -> void:
	var small := UiTheme.icon_button("Small", "loja", "", 30)
	assert_true(small.custom_minimum_size.x >= UiTheme.MIN_TOUCH and small.custom_minimum_size.y >= UiTheme.MIN_TOUCH,
		"ícone pequeno, área de toque de dedo")
	small.free()
	var cafe := await spawn_cafe()
	await settle()
	var buttons: Array[Node] = cafe.build_bar.find_children("*", "Button", true, false)
	buttons.append_array(cafe.hud.find_children("*", "Button", true, false))
	var checked := 0
	for node in buttons:
		var button := node as Button
		if button.is_visible_in_tree() and button.icon != null:
			checked += 1
			assert_true(button.size.x >= UiTheme.MIN_TOUCH - 0.5 and button.size.y >= UiTheme.MIN_TOUCH - 0.5,
				"%s tem %s" % [button.name, button.size])
	assert_true(checked >= 3, "conferiu os botões da tela (%d)" % checked)


func test_texture_filter_policy_is_smooth_for_zoom() -> void:
	# A lista do projeto é outra que a do CanvasItem: 0 Nearest, 1 Linear, 2 Linear Mipmap, 3 Nearest Mipmap.
	const PROJECT_LINEAR_MIPMAP := 2
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"),
		PROJECT_LINEAR_MIPMAP, "o padrão do projeto suaviza a arte ao afastar o zoom")
	assert_true(ProjectSettings.get_setting("importer_defaults/texture", {}).get("mipmaps/generate", false),
		"as imagens importam com mipmaps")
	var cafe := await spawn_cafe()
	for node: CanvasItem in [cafe.floor_view, cafe.wall_view, cafe.front_view]:
		assert_eq(node.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, node.name)


func test_y_sort_anchors_follow_the_front_of_the_footprint() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.world_layer.y_sort_enabled, "o salão ordena pela altura na tela")
	var counter := _place(cafe, &"counter_basic", Vector2i(2, 2), 1)
	var view := cafe.world_layer.view_for(counter)
	var footprint := CafeLayout.rotated_footprint(view.definition.footprint, 1)
	assert_vec_almost_eq(view.position, IsoProjection.cell_top_vertex(Vector2i(2, 2) + footprint), 0.01,
		"âncora no vértice da frente da pegada (girada)")
	var behind := _standing_customer(cafe, Vector2(2.5, 1.5), 74)
	var beside := _standing_customer(cafe, Vector2(2.5, 2.0 + footprint.y + 0.5), 75)
	assert_true(behind.position.y < view.position.y, "quem está atrás do balcão é desenhado antes")
	assert_true(beside.position.y > view.position.y, "quem está na frente é desenhado depois")
	assert_almost_eq(behind.position.y - IsoProjection.grid_point_to_world(behind.shown).y, AgentView.SORT_NUDGE,
		0.001, "personagem ordenado pelos pés")
