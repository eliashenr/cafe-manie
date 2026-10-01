extends TestCase
## Regras de posicionamento do layout. Grid 8x8, entrada em (7, 4).

const SIZE := Vector2i(8, 8)
const ENTRANCE := Vector2i(7, 4)

var _changes := 0


func _layout() -> CafeLayout:
	var layout := CafeLayout.new(SIZE, ENTRANCE)
	layout.changed.connect(func() -> void: _changes += 1)
	return layout


func _def(id: StringName, footprint := Vector2i.ONE, needs_access := true) -> FurnitureDefinition:
	var definition := FurnitureDefinition.new()
	definition.id = id
	definition.display_name = String(id)
	definition.footprint = footprint
	definition.needs_access = needs_access
	return definition


func _table() -> FurnitureDefinition:
	return _def(&"table")


func _plant() -> FurnitureDefinition:
	return _def(&"plant", Vector2i.ONE, false)


func _counter() -> FurnitureDefinition:
	return _def(&"counter", Vector2i(2, 1))


func test_default_entrance_is_middle_of_front_edge() -> void:
	assert_eq(CafeLayout.default_entrance(Vector2i(8, 8)), Vector2i(7, 4))
	assert_eq(CafeLayout.default_entrance(Vector2i(12, 10)), Vector2i(11, 5))


func test_front_direction_turns_clockwise_from_southwest() -> void:
	assert_eq(CafeLayout.front_direction(0), Vector2i(0, 1))
	assert_eq(CafeLayout.front_direction(1), Vector2i(-1, 0))
	assert_eq(CafeLayout.front_direction(2), Vector2i(0, -1))
	assert_eq(CafeLayout.front_direction(3), Vector2i(1, 0))
	assert_eq(CafeLayout.front_direction(4), Vector2i(0, 1), "volta ao começo depois de uma volta inteira")


func test_rotated_footprint_swaps_on_odd_quarter_turns() -> void:
	assert_eq(CafeLayout.rotated_footprint(Vector2i(2, 1), 0), Vector2i(2, 1))
	assert_eq(CafeLayout.rotated_footprint(Vector2i(2, 1), 1), Vector2i(1, 2))
	assert_eq(CafeLayout.rotated_footprint(Vector2i(2, 1), 2), Vector2i(2, 1))
	assert_eq(CafeLayout.rotated_footprint(Vector2i(2, 1), 3), Vector2i(1, 2))


func test_place_returns_unique_ids_and_occupies_grid() -> void:
	var layout := _layout()
	var first := layout.place(_counter(), Vector2i(1, 1))
	var second := layout.place(_counter(), Vector2i(1, 3))
	assert_ne_empty(first)
	assert_ne_empty(second)
	assert_true(first != second, "ids diferentes para móveis iguais")
	assert_eq(layout.grid.occupant_at(Vector2i(2, 1)), first)
	assert_eq(layout.placement_at(Vector2i(2, 3)).id, second)
	assert_eq(layout.count(), 2)
	assert_eq(_changes, 2, "um aviso de mudança por móvel")


func test_basic_rejections() -> void:
	var layout := _layout()
	layout.place(_table(), Vector2i(2, 2))
	assert_eq(layout.check_placement(_counter(), Vector2i(7, 0), 0), CafeLayout.Check.OUT_OF_BOUNDS)
	assert_eq(layout.check_placement(_table(), Vector2i(2, 2), 0), CafeLayout.Check.OCCUPIED)
	assert_eq(layout.check_placement(_plant(), ENTRANCE, 0), CafeLayout.Check.BLOCKS_ENTRANCE)
	assert_eq(layout.check_placement(_counter(), Vector2i(6, 4), 0), CafeLayout.Check.BLOCKS_ENTRANCE, "parte do balcão na entrada")


func test_new_ids_never_repeat_even_if_the_counter_is_behind() -> void:
	var layout := _layout()
	assert_true(layout.restore_placement(&"table#1", _table(), Vector2i(0, 0), 0))
	assert_true(layout.restore_placement(&"table#2", _table(), Vector2i(2, 0), 0))
	var fresh := layout.place(_table(), Vector2i(4, 0))
	assert_true(fresh != &"table#1" and fresh != &"table#2", "repetiu um id: %s" % fresh)
	assert_eq(layout.count(), 3, "nenhum móvel foi sobrescrito")


func test_rejected_place_changes_nothing() -> void:
	var layout := _layout()
	layout.place(_table(), Vector2i(2, 2))
	_changes = 0
	assert_eq(layout.place(_table(), Vector2i(2, 2)), &"")
	assert_eq(layout.count(), 1)
	assert_eq(_changes, 0, "recusa não avisa mudança")


func test_decor_can_be_placed_where_nobody_reaches() -> void:
	var layout := _layout()
	assert_ne_empty(layout.place(_plant(), Vector2i(1, 0)))
	assert_ne_empty(layout.place(_plant(), Vector2i(0, 1)))
	assert_ne_empty(layout.place(_plant(), Vector2i(0, 0)), "canto fechado, mas planta não precisa de acesso")


func test_functional_furniture_without_access_is_refused() -> void:
	var layout := _layout()
	layout.place(_plant(), Vector2i(1, 0))
	layout.place(_plant(), Vector2i(0, 1))
	assert_eq(layout.check_placement(_table(), Vector2i(0, 0), 0), CafeLayout.Check.NO_ACCESS)


func test_cannot_wall_off_an_existing_table() -> void:
	var layout := _layout()
	var table := layout.place(_table(), Vector2i(0, 0))
	assert_ne_empty(layout.place(_plant(), Vector2i(1, 0)), "ainda sobra o acesso por (0,1)")
	assert_eq(layout.check_placement(_plant(), Vector2i(0, 1), 0), CafeLayout.Check.BLOCKS_ACCESS)
	assert_eq(layout.place(_plant(), Vector2i(0, 1)), &"")
	assert_true(layout.get_placement(table) != null)


func test_cannot_isolate_the_entrance() -> void:
	var layout := _layout()
	layout.place(_table(), Vector2i(0, 0))
	layout.place(_plant(), Vector2i(6, 4))
	layout.place(_plant(), Vector2i(7, 3))
	assert_eq(layout.check_placement(_plant(), Vector2i(7, 5), 0), CafeLayout.Check.BLOCKS_ACCESS,
		"fechar o último vizinho da entrada isola a mesa")


func test_isolating_the_entrance_is_fine_while_nothing_needs_access() -> void:
	var layout := _layout()
	layout.place(_plant(), Vector2i(6, 4))
	layout.place(_plant(), Vector2i(7, 3))
	assert_eq(layout.check_placement(_plant(), Vector2i(7, 5), 0), CafeLayout.Check.OK)


func test_move_to_free_spot_and_onto_own_cells() -> void:
	var layout := _layout()
	var counter := layout.place(_counter(), Vector2i(2, 2))
	_changes = 0
	assert_eq(layout.move(counter, Vector2i(3, 2), 0), CafeLayout.Check.OK, "sobrepor só a si mesmo é permitido")
	assert_eq(layout.grid.occupant_at(Vector2i(2, 2)), &"", "célula antiga liberada")
	assert_eq(layout.grid.occupant_at(Vector2i(4, 2)), counter)
	assert_eq(layout.move(counter, Vector2i(0, 6), 0), CafeLayout.Check.OK)
	assert_eq(layout.get_placement(counter).origin, Vector2i(0, 6))
	assert_eq(_changes, 2)


func test_invalid_move_changes_nothing() -> void:
	var layout := _layout()
	var counter := layout.place(_counter(), Vector2i(2, 2))
	layout.place(_table(), Vector2i(5, 5))
	_changes = 0
	assert_eq(layout.move(counter, Vector2i(4, 5), 0), CafeLayout.Check.OCCUPIED)
	assert_eq(layout.get_placement(counter).origin, Vector2i(2, 2))
	assert_eq(layout.grid.occupant_at(Vector2i(3, 2)), counter)
	assert_eq(_changes, 0)


func test_rotation_changes_the_occupied_cells() -> void:
	var layout := _layout()
	var counter := layout.place(_counter(), Vector2i(5, 0))
	assert_eq(layout.move(counter, Vector2i(5, 0), 1), CafeLayout.Check.OK)
	assert_eq(layout.grid.occupant_at(Vector2i(5, 1)), counter, "virou na vertical")
	assert_eq(layout.grid.occupant_at(Vector2i(6, 0)), &"", "saiu da horizontal")
	assert_eq(layout.get_placement(counter).rotation, 1)


func test_rotation_that_would_leave_the_grid_is_refused() -> void:
	var layout := _layout()
	var counter := layout.place(_counter(), Vector2i(7, 0), 1)
	assert_ne_empty(counter)
	assert_eq(layout.move(counter, Vector2i(7, 0), 2), CafeLayout.Check.OUT_OF_BOUNDS)
	assert_eq(layout.get_placement(counter).rotation, 1)


func test_remove_frees_cells_and_unknown_ids_are_handled() -> void:
	var layout := _layout()
	var table := layout.place(_table(), Vector2i(3, 3))
	assert_true(layout.remove(table))
	assert_eq(layout.placement_at(Vector2i(3, 3)), null)
	assert_false(layout.remove(table))
	assert_eq(layout.move(&"fantasma", Vector2i.ZERO, 0), CafeLayout.Check.UNKNOWN_PLACEMENT)


func assert_ne_empty(id: StringName, message := "") -> void:
	assert_true(id != &"", "esperado um id, veio vazio. " + message)


func _with_category(definition: FurnitureDefinition, category: FurnitureDefinition.Category) -> FurnitureDefinition:
	definition.category = category
	return definition


func test_seat_turns_toward_the_table_beside_it() -> void:
	var layout := _layout()
	var table := _with_category(_def(&"dining_table"), FurnitureDefinition.Category.TABLE)
	layout.place(table, Vector2i(3, 3))
	assert_eq(layout.rotation_toward_table(Vector2i(2, 3)), 3, "mesa em +x: olha para sudeste")
	assert_eq(layout.rotation_toward_table(Vector2i(4, 3)), 1, "mesa em -x: olha para noroeste")
	assert_eq(layout.rotation_toward_table(Vector2i(3, 2)), 0, "mesa em +y: olha para sudoeste")
	assert_eq(layout.rotation_toward_table(Vector2i(3, 4)), 2, "mesa em -y: olha para nordeste")
	assert_eq(layout.rotation_toward_table(Vector2i(6, 6)), -1, "sem mesa ao lado")
	layout.place(_plant(), Vector2i(5, 5))
	assert_eq(layout.rotation_toward_table(Vector2i(5, 4)), -1, "planta não é mesa")


func test_seat_between_two_tables_keeps_the_side_it_already_faces() -> void:
	var layout := _layout()
	var table := _with_category(_def(&"dining_table"), FurnitureDefinition.Category.TABLE)
	layout.place(table, Vector2i(1, 3))
	layout.place(table, Vector2i(3, 3))
	assert_eq(layout.rotation_toward_table(Vector2i(2, 3), 1), 1, "já olhava para a mesa de -x")
	assert_eq(layout.rotation_toward_table(Vector2i(2, 3), 3), 3, "já olhava para a mesa de +x")


func test_turn_seats_fixes_only_seats_that_face_no_table() -> void:
	var layout := _layout()
	var table := _with_category(_def(&"dining_table"), FurnitureDefinition.Category.TABLE)
	var seat := _with_category(_def(&"seat"), FurnitureDefinition.Category.SEATING)
	layout.place(table, Vector2i(3, 3))
	var away := layout.place(seat, Vector2i(2, 3), 1)      # de costas para a mesa
	var facing := layout.place(seat, Vector2i(4, 3), 1)    # já olha para a mesa
	var alone := layout.place(seat, Vector2i(6, 6), 2)     # sem mesa ao lado
	_changes = 0
	assert_eq(layout.turn_seats_toward_tables(), 1)
	assert_eq(layout.get_placement(away).rotation, 3, "virou para a mesa")
	assert_eq(layout.get_placement(facing).rotation, 1, "quem já olhava fica")
	assert_eq(layout.get_placement(alone).rotation, 2, "sem mesa, fica como estava")
	assert_eq(_changes, 1, "avisa a tela da mudança")
