extends "res://tools/art_sample.gd"
## Revisão dos clientes dentro do café, sem carregar nem gravar o save pessoal.
## foto.ps1: -Script res://tools/revisao/clientes_codex.gd -Variant mostruario -Mode fixa
## -Extra lote:1 / lote:2: uma visão geral com HUD, clientes 01–06 ou 07–12.
## -Extra cliente:01: nove detalhes e a saída principal; frente/costas em pé, os quatro humores sentados,
## frente sentada espelhada e as duas poses de costas. Aceita cliente:01 até cliente:12.
## -Extra todos: 108 detalhes + duas visões gerais + a saída principal.
## Os detalhes usam a mesa e as cadeiras reais; sombra, prato e encosto são desenhados pelo runtime.
## Modo revisao: simulação normal, sem corredor artificial. N troca dia/noite; 1/2 filtram os lotes; 0 mostra todos.

const OVERVIEW_ZOOM := 1.1
const DETAIL_ZOOM := 1.8
const CUSTOMER_COUNT := 12
const BATCH_SIZE := 6
const FIRST_REVIEW_SERIAL := 1200  # múltiplo de 12: o primeiro cliente usa o slot visual zero
const WARMUP_FRAMES := 12
const MOODS: Array[String] = ["feliz", "esperando", "bravo", "comendo"]
const SEAT_CELL := Vector2i(3, 4)
const STANDING_CELL := Vector2(3.0, 3.0)

var _request := "lote:1"
var _stage_ready := false
var _capture_started := false
var _original_looks: Array = []
var _target_customer
var _target_view
var _written := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 4:
		_request = args[4]
	super()


func _populate(simulation) -> void:
	super(simulation)
	_original_looks = ArtSprites.characters().get("customers", []).duplicate()
	# Seriais únicos, definidos antes de criar AgentViews. O visual vem de serial % 12.
	for index in simulation.customers.size():
		var customer = simulation.customers[index]
		customer.serial = FIRST_REVIEW_SERIAL + index * (CUSTOMER_COUNT + 1)
		if _review:
			customer.eat_left = 8.0 + index * 1.5  # deixa as mesas vagarem no fluxo normal
	simulation._next_serial = FIRST_REVIEW_SERIAL + simulation.customers.size() * (CUSTOMER_COUNT + 1) + 1
	if not simulation.customers.is_empty():
		_target_customer = simulation.customers[0]


func _process(delta: float) -> bool:
	if not _stage_ready:
		if not _prepare_stage():
			quit(1)
			return true
		_stage_ready = true
	if _review:
		return super(delta)  # relógio, clientes e garçons seguem as regras reais
	if not _capture_started:
		_capture_started = true
		_capture_suite.call_deferred()
	return false


func _prepare_stage() -> bool:
	if DisplayServer.get_name() == "headless":
		printerr("ERROR: a revisão dos clientes precisa de renderizador com janela; use foto.ps1 para capturas ocultas.")
		return false
	if _cafe == null or not _cafe.is_inside_tree() or _target_customer == null or _original_looks.size() != CUSTOMER_COUNT:
		printerr("ERROR: a amostra não montou os 12 visuais dos clientes.")
		return false
	var seat = _cafe.layout.placement_at(SEAT_CELL)
	if seat == null or seat.definition.category != FurnitureDefinition.Category.SEATING or seat.rotation != 3:
		printerr("ERROR: falta a cadeira inicial de revisão em ", SEAT_CELL)
		return false
	_target_view = _cafe.world_layer.get_node_or_null("Agent_%d" % _target_customer.serial)
	if _target_view == null:
		printerr("ERROR: o cliente de prova não tem uma vista na cena.")
		return false
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	_set_overview_camera()
	if _review:
		_select_batch(0)
		_set_review_title(0)
	else:
		_cafe.set_paused(true)
		_cafe.hud.show_pause_state(false)
		_cafe.process_mode = Node.PROCESS_MODE_DISABLED
	return true


## Só a tabela visual em memória muda. Seriais, tarefas, caminhos e manifesto em disco continuam intactos.
func _select_batch(batch: int) -> void:
	var looks := _original_looks.duplicate()
	if batch > 0:
		for index in looks.size():
			looks[index] = _original_looks[(batch - 1) * BATCH_SIZE + index % BATCH_SIZE]
	ArtSprites.characters()["customers"] = looks


func _set_overview_camera() -> void:
	var camera = _cafe.camera
	camera.zoom = Vector2.ONE * OVERVIEW_ZOOM
	camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0.0, 32.0)
	camera.force_update_scroll()


func _show_overview(batch: int) -> void:
	_select_batch(batch)
	_set_target(3, "comendo")
	for node in _cafe.world_layer.get_children():
		if "agent" in node and node.agent is Customer:
			node.visible = true
	for layer in ["GameHud", "BuildBar"]:
		_cafe.get_node(layer).visible = true
	_set_overview_camera()
	_sync_capture()


func _show_detail(look_number: int, rotation: int, mood := "feliz", standing_back := false) -> void:
	_select_batch(0)
	ArtSprites.characters()["customers"][0] = _original_looks[look_number - 1]
	_set_target(rotation, mood, standing_back)
	_sync_capture()
	for node in _cafe.world_layer.get_children():
		if "agent" in node and node.agent is Customer:
			node.visible = node == _target_view
	for layer in ["GameHud", "BuildBar"]:
		_cafe.get_node(layer).visible = false
	var camera = _cafe.camera
	camera.zoom = Vector2.ONE * DETAIL_ZOOM
	camera.global_position = _target_view.position - Vector2(0.0, 65.0)
	camera.force_update_scroll()


func _set_target(rotation: int, mood: String, standing_back := false) -> void:
	_target_customer.path.clear()
	_target_customer.goals.clear()
	_target_customer.order = _cafe.simulation.recipes.get_definition(&"coxinha")
	_target_customer.patience_total = 100.0
	_target_customer.patience_left = {"feliz": 80.0, "esperando": 40.0, "bravo": 10.0, "comendo": 80.0}[mood]
	_target_customer.eat_left = 1000.0
	# Só a foto congelada gira a cadeira existente. Não acrescenta obstáculos nem muda o layout interativo.
	# A visão geral restaura a rotação 3 antes de mostrar todos os clientes.
	var seat = _cafe.layout.placement_at(SEAT_CELL)
	seat.rotation = rotation if rotation >= 0 else 3
	_cafe.world_layer.sync()
	if rotation >= 0:
		_target_customer.seat_id = seat.id
		_target_customer.seat_cell = seat.origin
		_target_customer.position = Vector2(seat.origin)
		_target_customer.state = Customer.State.EATING if mood == "comendo" else Customer.State.WAITING_FOR_FOOD
	else:
		_target_customer.seat_id = &""
		_target_customer.position = STANDING_CELL
		_target_customer.state = Customer.State.WALKING_IN
		_target_customer.facing = Vector2.UP if standing_back else Vector2.RIGHT
	_target_view.shown = _target_customer.position
	_target_view.velocity = Vector2.ZERO
	_target_view._traveled = 0.0
	_target_view._time = 0.0
	_target_view._stretch = 0.0


func _sync_capture() -> void:
	_cafe.world_layer.refresh(_cafe.simulation)
	for node in _cafe.world_layer.get_children():
		if "agent" in node:
			node.set_frozen(true)
	_cafe.front_view.set_focus(_cafe.world_layer.front_focus_points(_cafe.selected_cell))
	_cafe._apply_night()
	_cafe.hud.refresh()


func _capture_suite() -> void:
	for _frame in WARMUP_FRAMES:
		await process_frame
		await RenderingServer.frame_post_draw
	if _request in ["lote:1", "lote:2"]:
		_show_overview(int(_request.get_slice(":", 1)))
		if not await _write_capture(_output):
			quit(1)
			return
	else:
		var first := 1
		var last := CUSTOMER_COUNT
		if _request.begins_with("cliente:"):
			first = int(_request.get_slice(":", 1))
			last = first
		if (_request != "todos" and not _request.begins_with("cliente:")) or first < 1 or last > CUSTOMER_COUNT:
			printerr("ERROR: use todos, lote:1, lote:2 ou cliente:01 até cliente:12.")
			quit(1)
			return
		var base := _output.get_basename()
		if _request == "todos":
			for batch in [1, 2]:
				_show_overview(batch)
				if not await _write_capture("%s_lote_%d.png" % [base, batch]):
					quit(1)
					return
		for look_number in range(first, last + 1):
			for mood in MOODS:
				_show_detail(look_number, 3, mood)
				if not await _write_capture("%s_cliente_%02d_sentado_%s.png" % [base, look_number, mood]):
					quit(1)
					return
			for rotation in [0, 1, 2]:
				_show_detail(look_number, rotation)
				var suffix := "feliz_r0" if rotation == 0 else "costas_r%d" % rotation
				if not await _write_capture("%s_cliente_%02d_sentado_%s.png" % [base, look_number, suffix]):
					quit(1)
					return
			for back in [false, true]:
				_show_detail(look_number, -1, "feliz", back)
				if not await _write_capture("%s_cliente_%02d_%s_em_pe.png" % [base, look_number, "costas" if back else "frente"]):
					quit(1)
					return
		if _request == "todos":
			_show_overview(1)
		else:
			_show_detail(first, 3)
		if not await _write_capture(_output):
			quit(1)
			return
	print("CLIENTES CODEX OK: %d PNGs; saída principal em %s" % [_written, _output])
	quit(0)


func _write_capture(path: String) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := path.get_base_dir()
	if not directory.is_empty():
		var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if error != OK and error != ERR_ALREADY_EXISTS:
			printerr("ERROR: não foi possível criar ", directory)
			return false
	var screenshot: Image = root.get_texture().get_image()
	if screenshot == null or screenshot.is_empty() or screenshot.save_png(path) != OK:
		printerr("ERROR: falha ao gravar a captura ", path)
		return false
	_written += 1
	print("CLIENTE QUADRO ", path.get_file(), " | ", _target_view.pose()[0])
	return true


func _set_review_title(batch: int) -> void:
	var group := "todos os 12" if batch == 0 else ("01–06" if batch == 1 else "07–12")
	root.title = "Clientes %s — N: dia/noite · 1/2: lotes · 0: todos — sem salvar" % group


func _on_review_input(event: InputEvent) -> void:
	super(event)
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _stage_ready:
		return
	var batch := -1
	if key.keycode == KEY_0:
		batch = 0
	elif key.keycode == KEY_1:
		batch = 1
	elif key.keycode == KEY_2:
		batch = 2
	if batch >= 0:
		_select_batch(batch)
		_set_review_title(batch)
