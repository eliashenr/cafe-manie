extends TestCase
## Sessão de posicionamento (modo de construção): móvel novo e móvel movido.


func _layout() -> CafeLayout:
	return CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4))


func _counter() -> FurnitureDefinition:
	var definition := FurnitureDefinition.new()
	definition.id = &"counter"
	definition.footprint = Vector2i(2, 1)
	return definition


func test_new_session_needs_a_target_before_confirming() -> void:
	var session := PlacementSession.for_new(_layout(), _counter())
	assert_eq(session.check(), CafeLayout.Check.NO_TARGET)
	assert_false(session.can_confirm())
	assert_eq(session.confirm(), &"")


func test_new_session_places_on_confirm_and_not_before() -> void:
	var layout := _layout()
	var session := PlacementSession.for_new(layout, _counter())
	session.set_target(Vector2i(1, 1))
	assert_eq(layout.count(), 0, "escolher alvo não posiciona")
	var id := session.confirm()
	assert_true(id != &"")
	assert_eq(layout.placement_at(Vector2i(2, 1)).id, id)


func test_rotation_cycles_and_changes_footprint() -> void:
	var session := PlacementSession.for_new(_layout(), _counter())
	var seen: Array[Vector2i] = []
	for i in 4:
		seen.append(session.footprint())
		session.rotate_clockwise()
	assert_eq(seen, [Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 1), Vector2i(1, 2)] as Array[Vector2i])
	assert_eq(session.rotation, 0, "volta ao início após 4 giros")


func test_invalid_target_cannot_be_confirmed() -> void:
	var layout := _layout()
	var session := PlacementSession.for_new(layout, _counter())
	session.set_target(Vector2i(7, 0))
	assert_eq(session.check(), CafeLayout.Check.OUT_OF_BOUNDS)
	assert_eq(session.confirm(), &"")
	assert_eq(layout.count(), 0)


func test_move_session_starts_at_current_position() -> void:
	var layout := _layout()
	var id := layout.place(_counter(), Vector2i(2, 2), 1)
	var session := PlacementSession.for_move(layout, id)
	assert_true(session.is_moving())
	assert_eq(session.target, Vector2i(2, 2))
	assert_eq(session.rotation, 1)
	assert_true(session.can_confirm(), "a posição atual é válida para ele mesmo")


func test_move_session_moves_on_confirm_and_discarding_is_a_cancel() -> void:
	var layout := _layout()
	var id := layout.place(_counter(), Vector2i(2, 2))

	var abandoned := PlacementSession.for_move(layout, id)
	abandoned.set_target(Vector2i(0, 6))
	abandoned = null
	assert_eq(layout.get_placement(id).origin, Vector2i(2, 2), "descartar a sessão não move nada")

	var session := PlacementSession.for_move(layout, id)
	session.set_target(Vector2i(3, 2))
	assert_eq(session.confirm(), id)
	assert_eq(layout.get_placement(id).origin, Vector2i(3, 2))
	assert_eq(layout.count(), 1, "mover não duplica")


func test_move_session_for_unknown_id_is_null() -> void:
	assert_eq(PlacementSession.for_move(_layout(), &"fantasma"), null)


func _category(id: StringName, category: FurnitureDefinition.Category) -> FurnitureDefinition:
	var definition := FurnitureDefinition.new()
	definition.id = id
	definition.category = category
	return definition


func test_chair_brought_next_to_a_table_turns_toward_it() -> void:
	var layout := _layout()
	layout.place(_category(&"table", FurnitureDefinition.Category.TABLE), Vector2i(3, 3))
	var session := PlacementSession.for_new(layout, _category(&"chair", FurnitureDefinition.Category.SEATING))
	session.set_target(Vector2i(3, 2))
	assert_eq(session.rotation, 0, "mesa em +y")
	session.set_target(Vector2i(2, 3))
	assert_eq(session.rotation, 3, "mudou de lado, virou de novo")
	session.rotate_clockwise()
	session.set_target(Vector2i(2, 3))
	assert_eq(session.rotation, 0, "girar no mesmo piso continua valendo")
	session.set_target(Vector2i(6, 6))
	assert_eq(session.rotation, 0, "longe da mesa, fica como estava")
	assert_eq(layout.get_placement(session.confirm()).rotation, 0)


func test_other_furniture_does_not_turn_by_itself() -> void:
	var layout := _layout()
	layout.place(_category(&"table", FurnitureDefinition.Category.TABLE), Vector2i(3, 3))
	var session := PlacementSession.for_new(layout, _category(&"stove", FurnitureDefinition.Category.COOKING))
	session.set_target(Vector2i(2, 3))
	assert_eq(session.rotation, 0)
