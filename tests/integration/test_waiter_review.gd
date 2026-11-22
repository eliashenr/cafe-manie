extends CafeTestCase
## A revisão interativa deve mostrar a velocidade e os caminhos do jogo, sem
## usar a interpolação da antiga prova que atravessava o mobiliário.

const ReviewScript := preload("res://tools/revisao/garcom_codex.gd")


func _blocked_sample() -> CafeSimulation:
	var simulation := quiet_simulation()
	var table := simulation.furniture.get_definition(&"table_round")
	# Uma fileira de mesas separa os pontos preferidos da demonstração.
	for y in [3, 4, 5]:
		assert_true(simulation.layout.place(table, Vector2i(4, y)) != &"")
	return simulation


func test_review_route_goes_around_tables() -> void:
	var simulation := _blocked_sample()
	var review = ReviewScript.ReviewWalk.new(simulation)
	assert_true(review.ready, "há um caminho em volta das mesas")
	var from: Vector2i = review.waiter.cell()
	var path: Array[Vector2i] = review.waiter.path
	assert_true(path.size() > 6, "o caminho faz o desvio, não cruza a fileira")
	for cell in path:
		assert_true(simulation.navigation.is_walkable(cell), "piso livre: " + str(cell))
		assert_eq(absi(cell.x - from.x) + absi(cell.y - from.y), 1, "anda entre vizinhos, sem cortar a mesa")
		from = cell
	assert_eq(from, review.endpoints[1])


func test_review_uses_game_speed_and_visits_all_four_states() -> void:
	var simulation := _blocked_sample()
	var review = ReviewScript.ReviewWalk.new(simulation)
	var seen := {}
	var directions := {}
	var view := AgentView.new()
	view.refresh(review.waiter)
	add_to_tree(view)
	view.set_frozen(true)  # o teste avança a apresentação à mão, como a revisão
	const STEP := 1.0 / 60.0
	var initial: Vector2 = review.waiter.position
	review.advance(STEP)
	view.advance(STEP)
	assert_almost_eq(initial.distance_to(review.waiter.position), simulation.config.waiter_walk_speed * STEP,
		0.0001, "a primeira passada usa a velocidade normal, não 0,4 pisos/s")
	for _frame in 1800:
		var before: Vector2 = review.waiter.position
		review.advance(STEP)
		view.advance(STEP)
		assert_true(review.ready)
		assert_true(simulation.navigation.is_walkable(review.waiter.cell()), "nunca pisa numa mesa")
		assert_true(simulation.navigation.is_walkable(Vector2i(roundi(view.shown.x), roundi(view.shown.y))),
			"os pés desenhados também ficam nos pisos livres")
		assert_true(before.distance_to(review.waiter.position) <= simulation.config.waiter_walk_speed * STEP + 0.0001,
			"chegar ou trocar de estado não teletransporta o garçom")
		assert_eq(review.waiter.speed, simulation.config.waiter_walk_speed)
		seen[review.stage] = true
		var carrying: bool = review.waiter.carrying != null
		assert_eq(carrying, review.stage >= 2)
		if review.waiter.is_moving():
			var back: bool = review.waiter.facing.x < 0.0 or review.waiter.facing.y < 0.0
			directions[[back, carrying]] = true
	assert_eq(seen.size(), 4, "ida e volta, com e sem bandeja")
	assert_eq(directions.size(), 4, "frente e costas aparecem nos dois estados da bandeja")
