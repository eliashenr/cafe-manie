extends CafeTestCase
## Cena da cafeteria de ponta a ponta: entrada simulada de mouse e toque
## chegando até a seleção de piso e o movimento da câmera.


func test_scene_starts_with_empty_8x8_grid_and_no_selection() -> void:
	var cafe := await spawn_cafe()
	assert_eq(cafe.grid.size, Vector2i(8, 8))
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL)
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_eq(cafe.floor_view.grid_size, Vector2i(8, 8), "o piso desenhado acompanha o grid")
	assert_eq(cafe.floor_view.entrance, Vector2i(7, 4), "entrada marcada no piso")


func test_camera_frames_the_whole_cafe_between_the_ui_bars() -> void:
	var cafe := await spawn_cafe()
	var viewport_size := cafe.camera.get_viewport_rect().size
	var bounds := IsoProjection.grid_bounds(Vector2i(8, 8))
	var free_area := Rect2(0.0, cafe.ui_top_inset, viewport_size.x,
		viewport_size.y - cafe.ui_top_inset - cafe.ui_bottom_inset).grow(1.0)
	for corner in [bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)]:
		var on_screen: Vector2 = (corner - cafe.camera.global_position) * cafe.camera.zoom + viewport_size / 2.0
		assert_true(free_area.has_point(on_screen), "canto %s aparece em %s, fora da área livre %s" % [corner, on_screen, free_area])
	assert_true(cafe.camera.zoom.x <= 1.0, "o enquadramento inicial não aproxima além de 1x")


func test_frame_shrinks_zoom_when_the_screen_is_short() -> void:
	var cafe := await spawn_cafe()
	var bounds := IsoProjection.grid_bounds(Vector2i(8, 8))
	var viewport_height := cafe.camera.get_viewport_rect().size.y
	# Simula uma tela baixa deixando só 256 px livres: o grid (512 px de altura) precisa de zoom 0,5.
	cafe.camera.frame(bounds, 0.0, viewport_height - 256.0)
	assert_almost_eq(cafe.camera.zoom.x, 0.5, 0.001)


func test_click_on_a_tile_selects_it() -> void:
	var cafe := await spawn_cafe()
	click_cell(cafe, Vector2i(2, 5))
	assert_eq(cafe.selected_cell, Vector2i(2, 5))
	assert_eq(cafe.floor_view.selected_cell, Vector2i(2, 5), "o destaque acompanha a seleção")


func test_click_outside_the_grid_clears_the_selection() -> void:
	var cafe := await spawn_cafe()
	click_cell(cafe, Vector2i(1, 1))
	click_cell(cafe, Vector2i(-2, 3))
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL)


func test_mouse_drag_pans_the_camera_and_is_not_a_tap() -> void:
	var cafe := await spawn_cafe()
	var start := cafe.camera.global_position
	var from := Vector2(640, 400)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	send(press)

	var move := InputEventMouseMotion.new()
	move.position = from + Vector2(100, 0)
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	send(move)

	var release := press.duplicate()
	release.pressed = false
	release.position = move.position
	send(release)

	assert_vec_almost_eq(cafe.camera.global_position, start - Vector2(100, 0) / cafe.camera.zoom, 0.01, "arrastar 100px à direita move a visão")
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL, "arrasto não seleciona")


func test_tiny_movement_still_counts_as_a_tap() -> void:
	var cafe := await spawn_cafe()
	var start := cafe.camera.global_position
	var target := screen_of_cell(cafe, Vector2i(4, 4))

	touch(0, target, true)
	touch_drag(0, target + Vector2(5, 3))
	touch(0, target + Vector2(5, 3), false)

	assert_vec_almost_eq(cafe.camera.global_position, start, 0.01, "tremida do dedo não move a câmera")
	assert_eq(cafe.selected_cell, Vector2i(4, 4))


func test_mouse_wheel_zoom_is_clamped() -> void:
	var cafe := await spawn_cafe()
	for i in 60:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		wheel.position = Vector2(640, 360)
		send(wheel)
	assert_almost_eq(cafe.camera.zoom.x, cafe.camera.max_zoom, 0.001, "zoom máximo")

	for i in 120:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
		wheel.pressed = true
		wheel.position = Vector2(640, 360)
		send(wheel)
	assert_almost_eq(cafe.camera.zoom.x, cafe.camera.min_zoom, 0.001, "zoom mínimo")


func test_zoom_keeps_the_point_under_the_cursor_fixed() -> void:
	var cafe := await spawn_cafe()
	var cursor := Vector2(800, 450)
	var before := cafe.camera.screen_to_world(cursor)
	cafe.camera.zoom_at(cursor, 1.5)
	assert_vec_almost_eq(cafe.camera.screen_to_world(cursor), before, 0.01)


func test_pinch_apart_zooms_in_and_does_not_select() -> void:
	var cafe := await spawn_cafe()
	var zoom_before := cafe.camera.zoom.x

	touch(0, Vector2(600, 360), true)
	touch(1, Vector2(680, 360), true)
	touch_drag(0, Vector2(560, 360))
	touch_drag(1, Vector2(720, 360))
	touch(1, Vector2(720, 360), false)
	touch(0, Vector2(560, 360), false)

	assert_almost_eq(cafe.camera.zoom.x, zoom_before * 2.0, 0.01, "dedos 2x mais afastados = 2x de zoom")
	assert_eq(cafe.selected_cell, CafeGrid.NO_CELL, "pinça não seleciona piso")


func test_camera_cannot_be_dragged_away_from_the_cafe() -> void:
	var cafe := await spawn_cafe()
	cafe.camera.pan_by_screen(Vector2(100000, 100000))
	var limits := IsoProjection.grid_bounds(Vector2i(8, 8)).grow(cafe.camera_margin)
	assert_vec_almost_eq(cafe.camera.global_position, limits.position, 0.01, "preso no canto do limite")
