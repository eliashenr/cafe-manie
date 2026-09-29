extends CafeTestCase
## Modo de construção de ponta a ponta: posicionar, recusar, mover, girar e
## remover móveis pela entrada simulada e pelos botões da barra.


func test_unknown_furniture_does_not_enter_build_mode() -> void:
	var cafe := await spawn_cafe()
	assert_false(cafe.start_placing(&"nao_existe"))
	assert_eq(cafe.mode, Cafe.Mode.VIEW)


func test_entering_build_mode_clears_the_selection_panel() -> void:
	# Regressão: o painel de cima continuava mostrando o piso selecionado antes de construir.
	var cafe := await spawn_cafe()
	var hud := cafe.get_node("DebugHud")
	tap_cell(cafe, Vector2i(4, 3))
	assert_true(hud.cell_text().contains("(4, 3)"))
	cafe.start_placing(&"table_round")
	assert_eq(hud.cell_text(), "Nenhum piso selecionado")


func test_touch_places_with_two_taps_on_the_same_tile() -> void:
	var cafe := await spawn_cafe()
	assert_true(cafe.start_placing(&"stove_basic"))
	assert_eq(cafe.mode, Cafe.Mode.BUILD)
	assert_eq(cafe.last_check, CafeLayout.Check.NO_TARGET)

	tap_cell(cafe, Vector2i(1, 1))
	assert_eq(cafe.layout.count(), 0, "o primeiro toque só mostra a prévia")
	assert_true(cafe.furniture_layer.is_ghost_visible())
	assert_eq(cafe.furniture_layer.ghost_look(), FurnitureView.Look.GHOST_VALID)
	assert_eq(cafe.floor_view.preview_cells(), [Vector2i(1, 1)] as Array[Vector2i])

	tap_cell(cafe, Vector2i(1, 1))
	assert_eq(cafe.layout.count(), 1, "o segundo toque no mesmo piso confirma")
	assert_eq(cafe.layout.placement_at(Vector2i(1, 1)).definition.id, &"stove_basic")
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_false(cafe.furniture_layer.is_ghost_visible(), "prévia some ao confirmar")
	assert_eq(cafe.floor_view.preview_cells().size(), 0)
	await settle()
	assert_eq(cafe.furniture_layer.view_count(), 1)


func test_tapping_another_tile_moves_the_preview_instead_of_confirming() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"table_round")
	tap_cell(cafe, Vector2i(1, 1))
	tap_cell(cafe, Vector2i(3, 2))
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.session.target, Vector2i(3, 2))


func test_mouse_hover_then_single_click_places() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"table_round")
	hover(screen_of_cell(cafe, Vector2i(2, 6)))
	assert_eq(cafe.session.target, Vector2i(2, 6), "a prévia segue o mouse")
	click_cell(cafe, Vector2i(2, 6))
	assert_eq(cafe.layout.count(), 1)
	assert_true(cafe.layout.placement_at(Vector2i(2, 6)) != null)


func test_invalid_spot_is_refused_with_a_reason_and_cancel_leaves_nothing() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"plant_pot")
	tap_cell(cafe, cafe.layout.entrance)
	assert_eq(cafe.last_check, CafeLayout.Check.BLOCKS_ENTRANCE)
	assert_eq(cafe.furniture_layer.ghost_look(), FurnitureView.Look.GHOST_INVALID)
	tap_cell(cafe, cafe.layout.entrance)
	assert_eq(cafe.layout.count(), 0, "tocar de novo num lugar inválido não confirma")
	assert_false(cafe.confirm_placement(), "confirmar direto também é recusado")

	await settle()
	assert_true(cafe.build_bar.message_text().contains("entrada"), "a barra explica o motivo")
	assert_true(cafe.build_bar.find_button("ConfirmButton").disabled, "Confirmar desabilitado")

	press_key(KEY_ESCAPE)
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_false(cafe.furniture_layer.is_ghost_visible())
	assert_eq(cafe.layout.count(), 0)


func test_counter_rotates_during_placement() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"counter_basic")
	tap_cell(cafe, Vector2i(1, 1))
	assert_eq(cafe.floor_view.preview_cells().size(), 2)
	press_key(KEY_R)
	assert_eq(cafe.session.rotation, 1)
	assert_true(cafe.floor_view.preview_cells().has(Vector2i(1, 2)), "girou para a vertical")
	press_key(KEY_ENTER)
	assert_eq(cafe.layout.placement_at(Vector2i(1, 2)).rotation, 1)


func test_tapping_furniture_selects_it_and_bar_shows_actions() -> void:
	var cafe := await spawn_cafe()
	var id := cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(3, 3))
	tap_cell(cafe, Vector2i(3, 3))
	assert_eq(cafe.selected_id, id)
	await settle()
	assert_eq(cafe.furniture_layer.view_for(id).look, FurnitureView.Look.SELECTED)
	for button_name in ["MoveButton", "RotateButton", "RemoveButton", "CloseButton"]:
		assert_true(cafe.build_bar.find_button(button_name) != null, "falta o botão " + button_name)

	tap_cell(cafe, Vector2i(5, 5))
	assert_eq(cafe.selected_id, &"", "tocar em piso vazio tira a seleção do móvel")


func test_move_selected_furniture_through_the_bar() -> void:
	var cafe := await spawn_cafe()
	var id := cafe.layout.place(cafe.catalog.get_definition(&"table_round"), Vector2i(3, 3))
	tap_cell(cafe, Vector2i(3, 3))
	await settle()
	cafe.build_bar.find_button("MoveButton").pressed.emit()

	assert_eq(cafe.mode, Cafe.Mode.BUILD)
	assert_false(cafe.furniture_layer.view_for(id).visible, "o original some enquanto é movido")
	tap_cell(cafe, Vector2i(0, 6))
	tap_cell(cafe, Vector2i(0, 6))

	assert_eq(cafe.layout.count(), 1, "mover não duplica")
	assert_eq(cafe.layout.get_placement(id).origin, Vector2i(0, 6))
	assert_true(cafe.furniture_layer.view_for(id).visible)
	assert_eq(cafe.selected_id, id, "continua selecionado depois de mover")


func test_cancelling_a_move_keeps_the_furniture_where_it_was() -> void:
	var cafe := await spawn_cafe()
	var id := cafe.layout.place(cafe.catalog.get_definition(&"counter_basic"), Vector2i(2, 2))
	tap_cell(cafe, Vector2i(2, 2))
	cafe.start_moving_selected()
	tap_cell(cafe, Vector2i(0, 6))
	cafe.cancel_placement()
	assert_eq(cafe.layout.get_placement(id).origin, Vector2i(2, 2))
	assert_true(cafe.furniture_layer.view_for(id).visible)


func test_rotate_selected_in_place_and_refusal_is_explained() -> void:
	var cafe := await spawn_cafe()
	var catalog := cafe.catalog
	var id := cafe.layout.place(catalog.get_definition(&"counter_basic"), Vector2i(0, 7))
	tap_cell(cafe, Vector2i(0, 7))
	assert_eq(cafe.rotate_selected(), CafeLayout.Check.OUT_OF_BOUNDS, "encostado na borda não há espaço para girar")
	await settle()
	assert_true(cafe.build_bar.message_text().contains("Não cabe"), "a barra explica a recusa")
	assert_eq(cafe.layout.get_placement(id).rotation, 0)

	var other := cafe.layout.place(catalog.get_definition(&"counter_basic"), Vector2i(3, 3))
	tap_cell(cafe, Vector2i(3, 3))
	assert_eq(cafe.rotate_selected(), CafeLayout.Check.OK)
	assert_eq(cafe.layout.get_placement(other).rotation, 1)


func test_remove_selected_with_delete_key() -> void:
	var cafe := await spawn_cafe()
	cafe.layout.place(cafe.catalog.get_definition(&"plant_pot"), Vector2i(0, 0))
	tap_cell(cafe, Vector2i(0, 0))
	press_key(KEY_DELETE)
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.selected_id, &"")
	await settle()
	assert_eq(cafe.furniture_layer.view_count(), 0)


func test_catalog_buttons_start_placement() -> void:
	var cafe := await spawn_cafe()
	await settle()
	for definition in cafe.catalog.all():
		assert_true(cafe.build_bar.find_button("Build_" + String(definition.id)) != null,
			"sem botão para " + definition.display_name)
	cafe.build_bar.find_button("Build_chair_wood").pressed.emit()
	assert_eq(cafe.mode, Cafe.Mode.BUILD)
	assert_eq(cafe.session.definition.id, &"chair_wood")
	await settle()
	assert_true(cafe.build_bar.find_button("CancelButton") != null)
	cafe.build_bar.find_button("CancelButton").pressed.emit()
	assert_eq(cafe.mode, Cafe.Mode.VIEW)


func test_camera_drag_in_build_mode_does_not_place() -> void:
	var cafe := await spawn_cafe()
	cafe.start_placing(&"table_round")
	var start := screen_of_cell(cafe, Vector2i(2, 2))
	touch(0, start, true)
	touch_drag(0, start + Vector2(80, 0))
	touch(0, start + Vector2(80, 0), false)
	assert_eq(cafe.layout.count(), 0)
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "continua construindo")
