extends "res://tools/art_sample.gd"
## DT-111: revisão integrada do café, Loja, HUD, Chef e Cidade reais.
## A simulação é injetada por art_sample: tudo em memória, nenhum save lido/escrito.
## CLI: <saida.png> mostruario dia [revisao|foto] [cafe|suite]

var _frontend_frames := 0
var _capturing := false
var _view := "cafe"
var _photos := 0
var _layout_report := {}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_view = args[4] if args.size() > 4 else "cafe"
	super()
	root.title = "Café Manie — Loja, HUD e Cidade · revisão completa · sem salvar"


func _dress(simulation, variant: String) -> void:
	super(simulation, variant)
	# A revisão deixa todos os itens testáveis, inclusive na captura determinística.
	if not _review:
		simulation.wallet.earn(&"soft_currency", REVIEW_GOLD, "revisão da interface")
		simulation.progression.restore_xp(REVIEW_XP)
	# Só esta instância: nenhuma oferta automática ao restaurar a janela.
	simulation.daily.calendar = null


func _on_review_input(event: InputEvent) -> void:
	# A tecla N do mostruário não deve trocar o horário enquanto se digita na busca.
	if root.gui_get_focus_owner() is LineEdit:
		return
	super(event)


func _process(delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("ERROR: a revisão não montou o café.")
		quit(1)
		return true
	_frontend_frames += 1
	if _frontend_frames <= REVIEW_HIDE_FRAMES:
		for window: Window in _cafe.find_children("*", "Window", true, false):
			window.hide()
	if _frontend_frames == REVIEW_HIDE_FRAMES + 1:
		_cafe.camera.zoom = Vector2.ONE * 0.9
		_cafe.camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0, 52)
		_cafe.camera.force_update_scroll()
		if not _review:
			_cafe.set_paused(true)
			_cafe.hud.show_pause_state(false)
	if _review:
		_clock.time += delta
	elif _frontend_frames >= 45 and not _capturing:
		_capturing = true
		_capture_suite.call_deferred()
	return false


func _capture_suite() -> void:
	if not await _photo(""):
		return
	if _view == "suite":
		for tab in range(6):
			_cafe.build_bar.open_shop(tab)
			if not await _photo("loja_" + ["salao", "cozinha", "decoracao", "pisos", "paredes", "cupons"][tab]):
				return
		for group in [[0, ["tables", "seats"]], [1, ["stoves", "counters", "drinks"]],
				[4, ["surfaces", "windows", "doors", "ornaments"]]]:
			_cafe.build_bar.open_shop(group[0])
			for filter_id in group[1]:
				_cafe.build_bar.show_shop_filter(StringName(filter_id))
				if not await _photo("loja_tipo_" + filter_id):
					return
		_cafe.build_bar.open_shop(0)
		for collection in [&"brasileiro", &"japones"]:
			_cafe.build_bar.show_shop_collection(collection)
			if not await _photo("loja_colecao_" + String(collection)):
				return
		_cafe.build_bar.clear_shop_filters()
		_cafe.build_bar.show_shop_search("mesa")
		if not await _photo("loja_busca"):
			return
		_cafe.build_bar.show_shop_search("xxxxxxxxxx")
		if not await _photo("loja_busca_vazia"):
			return
		_cafe.build_bar.clear_shop_filters()
		_cafe.build_bar.close_shop()
		_cafe.hud.find_child("MissionToggle", true, false).pressed.emit()
		if not await _photo("hud_objetivo_recolhido"):
			return
		_cafe.hud.show_settings()
		if not await _photo("configuracoes"):
			return
		_cafe.hud.ask_restart()
		if not await _photo("recomecar_confirmacao"):
			return
		_cafe.hud.restart_dialog().hide()
		_cafe.hud.show_avatar()
		if not await _photo("chef"):
			return
		_cafe.hud.avatar_dialog().hide()
		_cafe.hud.show_city()
		var city = _cafe.hud.city_dialog()
		city.show_tab(&"branch")
		if not await _photo("cidade_filial"):
			return
		city.ask_action()
		if not await _photo("cidade_confirmar"):
			return
		city.cancel()
		# Estados de renda, somente na simulação de fotografia em memória.
		_cafe.simulation.branch.open(_clock.now())
		_clock.time += 3600.0
		city.show_tab(&"branch")
		if not await _photo("cidade_filial_aberta"):
			return
		city.show_tab(&"neighbors")
		if not await _photo("cidade_vizinhos"):
			return
		city.visit(&"rafa")
		if not await _photo("cidade_visitado"):
			return
		city.find_child("NeighborsScroll", true, false).scroll_vertical = 10000
		if not await _photo("cidade_vizinhos_final"):
			return
		city.hide()
	var report := FileAccess.open(_output.get_basename() + "_layout.json", FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify(_layout_report, "\t"))
	print("FRONTEND OK: ", _photos, " capturas | ", _output)
	quit(0)


func _photo(suffix: String) -> bool:
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _output if suffix.is_empty() else _output.get_basename() + "_" + suffix + ".png"
	var result := root.get_texture().get_image().save_png(path)
	if result != OK:
		printerr("ERROR: não foi possível gravar ", path, " (", result, ")")
		quit(1)
		return false
	var controls := {}
	for node: Control in _cafe.find_children("*", "Control", true, false):
		if node.is_visible_in_tree() and node.get_window().visible and (node is Button or node is LineEdit):
			controls[str(node.get_path())] = {"rect": str(node.get_global_rect()), "text": node.text,
				"window": node.get_window().name}
	_layout_report["cafe" if suffix.is_empty() else suffix] = controls
	_photos += 1
	return true
