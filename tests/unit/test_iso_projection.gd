extends TestCase
## Conversão grid <-> mundo isométrico. Se isto falhar, cliques caem no piso errado.


func test_origin_cell_top_vertex_is_world_origin() -> void:
	assert_vec_almost_eq(IsoProjection.cell_top_vertex(Vector2i.ZERO), Vector2.ZERO)


func test_axes_follow_isometric_directions() -> void:
	var half := IsoProjection.HALF_TILE
	assert_vec_almost_eq(IsoProjection.cell_top_vertex(Vector2i(1, 0)), Vector2(half.x, half.y), 0.01, "x desce para a direita")
	assert_vec_almost_eq(IsoProjection.cell_top_vertex(Vector2i(0, 1)), Vector2(-half.x, half.y), 0.01, "y desce para a esquerda")


func test_round_trip_through_cell_center() -> void:
	for y in range(-2, 12):
		for x in range(-2, 12):
			var cell := Vector2i(x, y)
			assert_eq(IsoProjection.world_to_cell(IsoProjection.cell_center(cell)), cell, "ida e volta de %s" % cell)


func test_points_near_each_vertex_stay_in_their_cell() -> void:
	var cell := Vector2i(3, 5)
	var polygon := IsoProjection.cell_polygon(cell)
	var center := IsoProjection.cell_center(cell)
	for vertex in polygon:
		# 90% do caminho do centro até o vértice ainda está dentro do losango.
		var point := center.lerp(vertex, 0.9)
		assert_eq(IsoProjection.world_to_cell(point), cell, "ponto perto do vértice %s" % vertex)


func test_points_just_outside_an_edge_go_to_the_neighbor() -> void:
	var cell := Vector2i(3, 3)
	var right_vertex := IsoProjection.cell_polygon(cell)[1]
	var bottom_vertex := IsoProjection.cell_polygon(cell)[2]
	var edge_middle := (right_vertex + bottom_vertex) / 2.0
	var outward := Vector2(1.0, 2.0).normalized() * 2.0
	assert_eq(IsoProjection.world_to_cell(edge_middle - outward), cell, "lado de dentro")
	assert_eq(IsoProjection.world_to_cell(edge_middle + outward), Vector2i(4, 3), "lado de fora")


func test_grid_bounds_contains_every_cell_polygon() -> void:
	var grid_size := Vector2i(8, 6)
	var bounds := IsoProjection.grid_bounds(grid_size).grow(0.01)
	for y in grid_size.y:
		for x in grid_size.x:
			for vertex in IsoProjection.cell_polygon(Vector2i(x, y)):
				assert_true(bounds.has_point(vertex), "vértice %s fora dos limites" % vertex)


func test_fractional_grid_points_match_cell_centers_and_interpolate() -> void:
	assert_vec_almost_eq(IsoProjection.grid_point_to_world(Vector2(3, 5)), IsoProjection.cell_center(Vector2i(3, 5)))
	var halfway := IsoProjection.grid_point_to_world(Vector2(3.5, 5))
	var expected := (IsoProjection.cell_center(Vector2i(3, 5)) + IsoProjection.cell_center(Vector2i(4, 5))) / 2.0
	assert_vec_almost_eq(halfway, expected, 0.01, "meio do caminho entre dois pisos")
