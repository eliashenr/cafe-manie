extends CafeTestCase
## Botões da interface respondem a toque de verdade (sem emulação de mouse, DT-006).


func _tap_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	touch(0, center, true)
	touch(0, center, false)


func test_tapping_a_shop_button_with_a_finger_works() -> void:
	var cafe := await spawn_cafe()
	await settle()
	await settle()
	var button := cafe.build_bar.find_button("Build_table_round")
	_tap_control(button)
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "o toque no botão da loja começou a construção")
	assert_eq(cafe.session.target, CafeGrid.NO_CELL, "o toque não vazou para o piso atrás do botão")


func test_tapping_empty_floor_does_not_press_any_button() -> void:
	var cafe := await spawn_cafe()
	await settle()
	tap_cell(cafe, Vector2i(4, 4))
	assert_eq(cafe.mode, Cafe.Mode.VIEW)
	assert_eq(cafe.selected_cell, Vector2i(4, 4))


func test_dialog_buttons_respond_to_touch() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(30)
	var cafe := await spawn_cafe(simulation)
	cafe.build_bar.ask_expand()
	await settle()
	var dialog := cafe.build_bar.confirm_dialog()
	var ok := dialog.get_ok_button()
	var center := Vector2(dialog.position) + ok.get_global_rect().get_center()
	touch(0, center, true)
	touch(0, center, false)
	await settle()
	assert_eq(cafe.layout.grid.size, Vector2i(10, 8), "tocar em Expandir na janela confirma")
