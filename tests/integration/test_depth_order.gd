extends CafeTestCase
## Ordem de desenho do salão: o desenho de cada móvel é cortado em faixas, cada uma no y-sort pela
## borda da frente da pegada naquele trecho. Quem passa na frente de qualquer parte do móvel
## (inclusive da metade de trás de um móvel de 2 pisos, como a estante) aparece na frente dele, e quem
## está atrás fica atrás.


func _place(cafe: Cafe, id: StringName, cell: Vector2i, rotation := 0) -> StringName:
	return cafe.layout.place(cafe.catalog.get_definition(id), cell, rotation)


## Personagem em pé, parado no ponto [param at] do grid (indo embora: já nasce desenhado ali).
func _standing(cafe: Cafe, at: Vector2, serial := 90) -> AgentView:
	var customer := Customer.new()
	customer.serial = serial
	customer.type = load("res://data/customers/regular.tres")
	customer.state = Customer.State.LEAVING
	customer.position = at
	cafe.simulation.customers.append(customer)
	cafe.world_layer.refresh(cafe.simulation)
	return cafe.world_layer.get_node("Agent_%d" % serial)


## Faixas do móvel que cruzam, na horizontal, o retângulo [param rect] (no mundo).
func _slices_over(view: FurnitureView, rect: Rect2) -> Array:
	var found := []
	for slice in view.slices():
		var left := view.position.x + slice.span.position.x
		var right := left + slice.span.size.x
		if right > rect.position.x and left < rect.end.x:
			found.append(slice)
	return found


## Onde o corpo aparece de fato: o desenho do personagem tem sobra transparente à direita (a bandeja).
const BODY_HALF_WIDTH := 26.0


func _body(agent: AgentView) -> Rect2:
	var rect := agent.body_rect()
	return Rect2(agent.position.x - BODY_HALF_WIDTH, rect.position.y, BODY_HALF_WIDTH * 2.0, rect.size.y)


## Altura da faixa no y-sort do salão, com o móvel já no tamanho final (o móvel novo surge crescendo).
func _sort_y(view: FurnitureView, slice: FurnitureView.Slice) -> float:
	return view.position.y + slice.position.y


func _drawn_after_all(agent: AgentView, view: FurnitureView) -> bool:
	var over := _slices_over(view, _body(agent))
	assert_true(not over.is_empty(), "o personagem cruza o desenho do móvel")
	for slice: FurnitureView.Slice in over:
		if agent.position.y <= _sort_y(view, slice):
			return false
	return true


func _drawn_before_all(agent: AgentView, view: FurnitureView) -> bool:
	var over := _slices_over(view, _body(agent))
	assert_true(not over.is_empty(), "o personagem cruza o desenho do móvel")
	for slice: FurnitureView.Slice in over:
		if agent.position.y >= _sort_y(view, slice):
			return false
	return true


func test_waiter_in_front_of_the_back_half_of_a_counter_is_drawn_in_front() -> void:
	var cafe := await spawn_cafe()
	var counter := cafe.world_layer.view_for(_place(cafe, &"table_long", Vector2i(2, 0)))
	var waiter := _standing(cafe, Vector2(2.0, 1.0))
	assert_true(counter.y_sort_enabled, "as faixas entram no y-sort do salão")
	assert_true(waiter.position.y < counter.position.y, "pela ponta da frente, ele ficaria atrás (o defeito)")
	assert_true(_drawn_after_all(waiter, counter), "na frente de cada faixa que ele cruza")
	assert_false(waiter.shows_xray(), "e sem silhueta: ele não está atrás de nada")


func test_passing_close_to_the_counter_edge_still_counts_as_in_front() -> void:
	var cafe := await spawn_cafe()
	var counter := cafe.world_layer.view_for(_place(cafe, &"table_long", Vector2i(2, 0)))
	for x in [1.8, 2.2, 2.6, 3.0, 3.4]:
		var walker := _standing(cafe, Vector2(x, 0.8), 91 + int(x * 10))
		assert_true(_drawn_after_all(walker, counter), "passando a 0,3 piso da borda em x = %s" % x)


func test_customer_behind_a_counter_is_drawn_behind_every_slice() -> void:
	var cafe := await spawn_cafe()
	var counter := cafe.world_layer.view_for(_place(cafe, &"bookshelf", Vector2i(2, 3)))
	var behind := _standing(cafe, Vector2(2.5, 2.0))
	assert_true(_drawn_before_all(behind, counter))
	assert_true(behind.shows_xray(), "o balcão alto tampa: aparece a silhueta")


func test_rotated_counter_sorts_the_same_way() -> void:
	var cafe := await spawn_cafe()
	var counter := cafe.world_layer.view_for(_place(cafe, &"bookshelf", Vector2i(0, 2), 1))
	var in_front := _standing(cafe, Vector2(1.0, 2.0))
	assert_true(_drawn_after_all(in_front, counter), "na frente da metade de trás do balcão girado")


func test_plant_in_front_of_a_counter_is_drawn_in_front_of_it() -> void:
	var cafe := await spawn_cafe()
	var counter := cafe.world_layer.view_for(_place(cafe, &"bookshelf", Vector2i(2, 0)))
	var plant := cafe.world_layer.view_for(_place(cafe, &"plant_pot", Vector2i(2, 1)))
	var plant_rect := Rect2(plant.position + plant.sprite.draw_rect().position, plant.sprite.draw_rect().size)
	var over := _slices_over(counter, plant_rect)
	assert_true(not over.is_empty())
	for slice: FurnitureView.Slice in over:
		for plant_slice in plant.slices():
			assert_true(_sort_y(plant, plant_slice) > _sort_y(counter, slice), "o vaso da frente cobre o balcão")


func test_slices_cover_the_whole_drawing_side_by_side() -> void:
	var cafe := await spawn_cafe()
	var spots := {&"counter_basic": Vector2i(0, 0), &"stove_basic": Vector2i(4, 0), &"table_round": Vector2i(2, 4),
		&"plant_pot": Vector2i(5, 5)}
	for id: StringName in spots:
		var view := cafe.world_layer.view_for(_place(cafe, id, spots[id]))
		var rect := view.sprite.draw_rect()
		var slices := view.slices()
		assert_true(slices.size() >= 2, "%s cortado em faixas" % id)
		assert_almost_eq(slices[0].span.position.x, rect.position.x, 0.01)
		assert_almost_eq(slices[-1].span.end.x, rect.end.x, 0.01)
		for i in range(1, slices.size()):
			assert_almost_eq(slices[i].span.position.x, slices[i - 1].span.end.x, 0.01, "faixas encostadas, sem buraco")
		for i in range(1, slices.size() - 1):
			assert_true(slices[i].span.size.x <= FurnitureView.SLICE_WIDTH + 0.01, "faixas do meio com a largura certa")
		for slice in slices:
			assert_true(slice.position.y < 0.0, "toda faixa vem antes do vértice da frente (onde ficam panela e pilha)")


func test_moving_furniture_keeps_its_slices_in_place() -> void:
	var cafe := await spawn_cafe()
	var id := _place(cafe, &"counter_basic", Vector2i(2, 0))
	var view := cafe.world_layer.view_for(id)
	var before := view.slices().map(func(s: FurnitureView.Slice) -> Vector2: return s.position)
	assert_true(cafe.layout.move(id, Vector2i(3, 4), 0) == CafeLayout.Check.OK)
	await settle()
	var after := view.slices().map(func(s: FurnitureView.Slice) -> Vector2: return s.position)
	assert_eq(after, before, "as faixas são relativas ao móvel: mudar de lugar não recorta")
