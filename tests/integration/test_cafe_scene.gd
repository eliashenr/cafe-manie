extends TestCase
## Cena da cafeteria de ponta a ponta: entrada simulada de mouse e toque
## chegando até a seleção de piso e o movimento da câmera.

const CafeScene := preload("res://scenes/cafe/cafe.tscn")


func _spawn_cafe() -> Node2D:
	var cafe: Node2D = add_to_tree(CafeScene.instantiate())
	await tree.process_frame
	return cafe


## Posição na tela onde está o centro de uma célula, com a câmera atual.
func _screen_of_cell(cafe: Node2D, cell: Vector2i) -> Vector2:
	var camera: CafeCamera = cafe.camera
	var viewport_size := camera.get_viewport_rect().size
	return (IsoProjection.cell_center(cell) - camera.global_position) * camera.zoom + viewport_size / 2.0


func _click(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		tree.root.push_input(event, true)


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	tree.root.push_input(event, true)


func _touch_drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	tree.root.push_input(event, true)


func test_scene_starts_with_empty_8x8_grid_and_no_selection() -> void:
	var cafe := await _spawn_cafe()
	assert_eq(cafe.grid.size, Vector2i(8, 8))
	assert_eq(cafe.grid.object_count(), 0)
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL)
	assert_eq(cafe.floor_view.grid_size, Vector2i(8, 8), "o piso desenhado acompanha o grid")


func test_camera_starts_centered_on_the_grid() -> void:
	var cafe := await _spawn_cafe()
	var center := IsoProjection.grid_bounds(Vector2i(8, 8)).get_center()
	assert_vec_almost_eq(cafe.camera.global_position, center)


func test_click_on_a_tile_selects_it_and_notifies_the_event_bus() -> void:
	var cafe := await _spawn_cafe()
	var received: Array[Vector2i] = []
	var listener := func(cell: Vector2i) -> void: received.append(cell)
	EventBus.cell_selected.connect(listener)

	_click(_screen_of_cell(cafe, Vector2i(2, 5)))

	EventBus.cell_selected.disconnect(listener)
	assert_eq(cafe.selected_cell, Vector2i(2, 5))
	assert_eq(cafe.floor_view.selected_cell, Vector2i(2, 5), "o destaque acompanha a seleção")
	assert_eq(received, [Vector2i(2, 5)] as Array[Vector2i], "EventBus avisado uma vez")


func test_click_outside_the_grid_clears_the_selection() -> void:
	var cafe := await _spawn_cafe()
	_click(_screen_of_cell(cafe, Vector2i(1, 1)))
	_click(_screen_of_cell(cafe, Vector2i(-2, 3)))
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL)


func test_mouse_drag_pans_the_camera_and_is_not_a_tap() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	var start := camera.global_position
	var from := Vector2(640, 400)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	tree.root.push_input(press, true)

	var move := InputEventMouseMotion.new()
	move.position = from + Vector2(100, 0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	tree.root.push_input(move, true)

	var release := press.duplicate()
	release.pressed = false
	release.position = move.position
	tree.root.push_input(release, true)

	assert_vec_almost_eq(camera.global_position, start - Vector2(100, 0), 0.01, "arrastar 100px à direita move a visão")
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL, "arrasto não seleciona")


func test_tiny_movement_still_counts_as_a_tap() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	var start := camera.global_position
	var target := _screen_of_cell(cafe, Vector2i(4, 4))

	_touch(0, target, true)
	_touch_drag(0, target + Vector2(5, 3))
	_touch(0, target + Vector2(5, 3), false)

	assert_vec_almost_eq(camera.global_position, start, 0.01, "tremida do dedo não move a câmera")
	assert_eq(cafe.selected_cell, Vector2i(4, 4))


func test_mouse_wheel_zoom_is_clamped() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	for i in 60:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		wheel.position = Vector2(640, 360)
		tree.root.push_input(wheel, true)
	assert_almost_eq(camera.zoom.x, camera.max_zoom, 0.001, "zoom máximo")

	for i in 120:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = Vector2(640, 360)
		tree.root.push_input(wheel, true)
	assert_almost_eq(camera.zoom.x, camera.min_zoom, 0.001, "zoom mínimo")


func test_zoom_keeps_the_point_under_the_cursor_fixed() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	var cursor := Vector2(800, 450)
	var before := camera.screen_to_world(cursor)
	camera.zoom_at(cursor, 1.5)
	assert_vec_almost_eq(camera.screen_to_world(cursor), before, 0.01)


func test_pinch_apart_zooms_in_and_does_not_select() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	var zoom_before := camera.zoom.x

	_touch(0, Vector2(600, 360), true)
	_touch(1, Vector2(680, 360), true)
	_touch_drag(0, Vector2(560, 360))
	_touch_drag(1, Vector2(720, 360))
	_touch(1, Vector2(720, 360), false)
	_touch(0, Vector2(560, 360), false)

	assert_almost_eq(camera.zoom.x, zoom_before * 2.0, 0.01, "dedos 2x mais afastados = 2x de zoom")
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL, "pinça não seleciona piso")


func test_camera_cannot_be_dragged_away_from_the_cafe() -> void:
	var cafe := await _spawn_cafe()
	var camera: CafeCamera = cafe.camera
	camera.pan_by_screen(Vector2(100000, 100000))
	var limits := IsoProjection.grid_bounds(Vector2i(8, 8)).grow(cafe.camera_margin)
	assert_vec_almost_eq(camera.global_position, limits.position, 0.01, "preso no canto do limite")
