extends TestCase
## Regras do grid lógico: limites, ocupação, colisão e expansão.


func test_new_grid_is_empty_with_given_size() -> void:
	var grid := CafeGrid.new(Vector2i(8, 6))
	assert_eq(grid.size, Vector2i(8, 6))
	assert_eq(grid.object_count(), 0)


func test_is_inside_respects_all_four_edges() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	assert_true(grid.is_inside(Vector2i(0, 0)), "canto inicial")
	assert_true(grid.is_inside(Vector2i(7, 7)), "canto final")
	assert_false(grid.is_inside(Vector2i(-1, 0)), "x negativo")
	assert_false(grid.is_inside(Vector2i(0, -1)), "y negativo")
	assert_false(grid.is_inside(Vector2i(8, 0)), "x no limite")
	assert_false(grid.is_inside(Vector2i(0, 8)), "y no limite")


func test_footprint_cells_covers_whole_rectangle() -> void:
	var cells := CafeGrid.footprint_cells(Vector2i(2, 3), Vector2i(2, 2))
	assert_eq(cells.size(), 4)
	for expected in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(2, 4), Vector2i(3, 4)]:
		assert_true(cells.has(expected), "falta a célula %s" % expected)


func test_place_occupies_every_cell_of_the_footprint() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	assert_true(grid.place(&"mesa_1", Vector2i(1, 1), Vector2i(2, 1)))
	assert_eq(grid.occupant_at(Vector2i(1, 1)), &"mesa_1")
	assert_eq(grid.occupant_at(Vector2i(2, 1)), &"mesa_1")
	assert_eq(grid.occupant_at(Vector2i(3, 1)), &"")
	assert_false(grid.is_free(Vector2i(2, 1)))


func test_place_rejects_overlap_without_side_effects() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	grid.place(&"fogao_1", Vector2i(0, 0), Vector2i(2, 2))
	assert_false(grid.place(&"mesa_1", Vector2i(1, 1), Vector2i(2, 2)), "sobrepõe o fogão")
	assert_false(grid.has_object(&"mesa_1"))
	assert_true(grid.is_free(Vector2i(2, 2)), "a tentativa recusada não pode ocupar nada")


func test_place_rejects_objects_crossing_the_edge() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	assert_false(grid.place(&"balcao", Vector2i(7, 0), Vector2i(2, 1)))
	assert_true(grid.is_free(Vector2i(7, 0)))


func test_place_rejects_duplicate_id_empty_id_and_bad_footprint() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	assert_true(grid.place(&"mesa_1", Vector2i(0, 0), Vector2i.ONE))
	assert_false(grid.place(&"mesa_1", Vector2i(5, 5), Vector2i.ONE), "id repetido")
	assert_false(grid.place(&"", Vector2i(5, 5), Vector2i.ONE), "id vazio")
	assert_false(grid.place(&"mesa_2", Vector2i(5, 5), Vector2i.ZERO), "tamanho zero")
	assert_eq(grid.object_count(), 1)


func test_remove_frees_cells_and_allows_placing_again() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	grid.place(&"mesa_1", Vector2i(3, 3), Vector2i(2, 2))
	assert_true(grid.remove(&"mesa_1"))
	assert_true(grid.is_free(Vector2i(4, 4)))
	assert_false(grid.remove(&"mesa_1"), "remover duas vezes")
	assert_true(grid.place(&"mesa_2", Vector2i(3, 3), Vector2i(2, 2)))


func test_resize_expands_the_grid() -> void:
	var grid := CafeGrid.new(Vector2i(8, 8))
	assert_true(grid.resize(Vector2i(10, 8)))
	assert_eq(grid.size, Vector2i(10, 8))
	assert_true(grid.is_inside(Vector2i(9, 7)))


func test_resize_refuses_to_cut_placed_objects() -> void:
	var grid := CafeGrid.new(Vector2i(10, 10))
	grid.place(&"mesa_1", Vector2i(8, 8), Vector2i.ONE)
	assert_false(grid.resize(Vector2i(8, 8)))
	assert_eq(grid.size, Vector2i(10, 10), "tamanho não pode mudar após recusa")
	assert_false(grid.resize(Vector2i(0, 5)), "tamanho inválido")
