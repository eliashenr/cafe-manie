extends "res://tools/art_sample.gd"
## Revisão determinística do garçom no café, sem ler nem gravar save.
## Use foto.ps1 com -Variant mostruario -Mode fixa e um destes -Extra:
##   todos                 4 ciclos de 8 PNGs, 4 poses paradas e a foto principal;
##   loop_frente           8 PNGs do ciclo escolhido e a foto principal;
##   andando_frente        uma foto do primeiro quadro andando;
##   parado_frente_bandeja  uma foto parado (padrão).
## Troque "frente" por "costas" e acrescente "_bandeja" para os outros estados.
## Os ciclos ficam no mesmo ponto do piso para formar GIFs sem salto na emenda.
## Cada nome termina em <estado>_00.png a _07.png, ou <estado>_parado.png.
## O modo "revisao" fica aberto: vai e volta por caminhos livres calculados
## pela navegação do jogo, na velocidade normal do garçom, com e sem bandeja.
## A troca acontece ao chegar ao destino, nunca no meio do caminho. N: dia/noite.
## Precisa do renderizador com janela (oculta pelo foto.ps1), nunca --headless.

const REVIEW_ZOOM := 1.7
const TARGET_FEET := Vector2(318.0, 300.0)
const STATES: Array[String] = ["frente", "costas", "frente_bandeja", "costas_bandeja"]
const WARMUP_FRAMES := 12
## Só seleciona a pose andando nas capturas fixas; não controla a revisão interativa.
const CAPTURE_WALK_SPEED := 0.4


## Movimento da amostra: usa as mesmas rotas e o mesmo avanço do Agent do jogo.
## Separado da captura fixa para poder conferir desvio de móveis sem renderizador.
class ReviewWalk:
	extends RefCounted

	const PREFERRED_START := Vector2i(2, 3)
	const PREFERRED_END := Vector2i(6, 5)

	var simulation
	var waiter
	var endpoints: Array[Vector2i] = []
	var stage := 0  # ida/volta sem bandeja, depois ida/volta com bandeja
	var ready := false
	var _pause_left := 0.0


	func _init(sample) -> void:
		simulation = sample
		waiter = simulation.waiters[0]
		waiter.speed = simulation.config.waiter_walk_speed
		var start: Vector2i = PREFERRED_START if simulation.navigation.is_walkable(PREFERRED_START) else simulation.layout.entrance
		# Preferir o outro lado do salão; se a variante ocupar esse piso, usar
		# o piso alcançável mais próximo. Nunca atravessar um móvel para chegar.
		var candidates: Array[Vector2i] = []
		for y in simulation.layout.grid.size.y:
			for x in simulation.layout.grid.size.x:
				var cell := Vector2i(x, y)
				if cell != start and simulation.navigation.is_walkable(cell):
					candidates.append(cell)
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return a.distance_squared_to(PREFERRED_END) < b.distance_squared_to(PREFERRED_END))
		for goal in candidates:
			var goals: Array[Vector2i] = [goal]
			var path: Array[Vector2i] = simulation.navigation.path_to_any(start, goals)
			if path.size() < 2:
				continue
			endpoints.assign([start, goal])
			waiter.position = Vector2(start)
			ready = _start_leg()
			return


	func advance(delta: float) -> void:
		if not ready or delta <= 0.0:
			return
		if waiter.is_moving():
			if waiter.advance(delta):
				_pause_left = simulation.config.handling_time
			return
		_pause_left -= delta
		if _pause_left <= 0.0:
			stage = (stage + 1) % 4
			ready = _start_leg()


	func _start_leg() -> bool:
		var goal := endpoints[1 if stage % 2 == 0 else 0]
		var goals: Array[Vector2i] = [goal]
		var path: Array[Vector2i] = simulation.navigation.path_to_any(waiter.cell(), goals)
		if path.size() < 2:
			return false
		waiter.speed = simulation.config.waiter_walk_speed
		waiter.carrying = simulation.recipes.get_definition(&"carrot_cake") if stage >= 2 else null
		waiter.follow(path, goals)
		return true

var _request := "parado_frente_bandeja"
var _stage_ready := false
var _capture_started := false
var _review_state := -1
var _review_walk: ReviewWalk
var _capture_position := Vector2.ZERO
var _waiter
var _waiter_view
var _written := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 4:
		_request = args[4]
	super()


func _populate(simulation) -> void:
	super(simulation)
	# Também em "revisao": só o garçom de prova anda; os clientes do mostruário
	# continuam nas mesas e não surgem novas tarefas que mudem a bandeja.
	simulation.customer_types.clear()


func _process(delta: float) -> bool:
	# Não chamar super(delta): o pai tira uma foto após 20 frames e encerra.
	if not _stage_ready:
		if not _prepare_stage():
			quit(1)
			return true
		_stage_ready = true
	if _review:
		_update_review(delta)
	elif not _capture_started:
		_capture_started = true
		_capture_suite.call_deferred()
	return false


func _prepare_stage() -> bool:
	if DisplayServer.get_name() == "headless":
		printerr("ERROR: a revisão do garçom precisa de janela oculta, sem --headless.")
		return false
	if _cafe == null or not _cafe.is_inside_tree() or _cafe.simulation.waiters.is_empty():
		printerr("ERROR: a amostra não montou o garçom.")
		return false
	_waiter = _cafe.simulation.waiters[0]
	for node in _cafe.world_layer.get_children():
		if "agent" in node and node.agent == _waiter:
			_waiter_view = node
			break
	if _waiter_view == null:
		printerr("ERROR: o garçom não tem uma vista na cena.")
		return false
	# A simulação foi injetada pelo art_sample; sem SaveService, não há save.
	# Congelar a árvore mantém os clientes, o cenário e a câmera comparáveis.
	_cafe.set_paused(true)
	_cafe.process_mode = Node.PROCESS_MODE_DISABLED
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	for layer in ["GameHud", "BuildBar"]:
		_cafe.get_node(layer).visible = false
	var camera := _cafe.get_viewport().get_camera_2d()
	camera.zoom = Vector2.ONE * REVIEW_ZOOM
	camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() + Vector2(0.0, 10.0)
	camera.force_update_scroll()
	# Mesmo enquadramento de cena_alvo.gd; inversão contínua da projeção para
	# deixar a âncora dos pés exatamente em TARGET_FEET, sem arredondar a célula.
	var world := camera.global_position + (TARGET_FEET - Vector2(root.size) / 2.0) / REVIEW_ZOOM
	var u := world.x / IsoProjection.HALF_TILE.x
	var v := world.y / IsoProjection.HALF_TILE.y - 1.0
	_capture_position = Vector2((u + v) / 2.0, (v - u) / 2.0)
	if _review:
		_review_walk = ReviewWalk.new(_cafe.simulation)
		if not _review_walk.ready:
			printerr("ERROR: a revisão não encontrou um caminho livre no salão.")
			return false
		_waiter_view.shown = _waiter.position
		_waiter_view.velocity = Vector2.ZERO
		_waiter_view.set_frozen(true)
		_cafe.world_layer.refresh(_cafe.simulation)
	else:
		_set_pose("frente_bandeja", false, 0.0, _capture_position)
	return true


func _set_pose(state: String, walking: bool, distance: float, at: Vector2, time := 0.0) -> void:
	# Frente e costas percorrem o mesmo eixo em sentidos opostos. De frente,
	# o espelho corresponde à imagem-alvo; de costas, usa a imagem sem espelho.
	var facing := Vector2(0.0, -1.0 if state.begins_with("costas") else 1.0)
	_waiter.position = at
	_waiter.path.clear()
	_waiter.goals.clear()
	_waiter.facing = facing
	_waiter.speed = CAPTURE_WALK_SPEED if walking else 0.0
	_waiter.carrying = _cafe.simulation.recipes.get_definition(&"carrot_cake") if state.ends_with("_bandeja") else null
	_waiter_view.shown = at
	_waiter_view.velocity = facing * _waiter.speed
	_waiter_view._traveled = distance
	_waiter_view._time = time
	_waiter_view._stretch = 0.0
	_waiter_view._previous_velocity = _waiter_view.velocity
	_waiter_view.set_frozen(true)
	# Usa a renderização real: sombra no piso, transformação do corpo, prato
	# por quadro e oclusão pelos móveis continuam sob responsabilidade do jogo.
	_cafe.world_layer.refresh(_cafe.simulation)
	_cafe.front_view.set_focus(_cafe.world_layer.front_focus_points(_cafe.selected_cell))


func _capture_suite() -> void:
	for _frame in WARMUP_FRAMES:
		await process_frame
		await RenderingServer.frame_post_draw
	var states: Array[String] = []
	if _request == "todos":
		states.assign(STATES)
	else:
		states.append(_state_from_request())
	if states[0] not in STATES:
		printerr("ERROR: estado desconhecido: ", _request)
		quit(1)
		return
	var make_loop := _request == "todos" or _request.begins_with("loop_")
	var basename := _output.get_basename()
	for state in states:
		if make_loop:
			for frame in _waiter_view.WALK_FRAMES:
				# Meio de cada intervalo evita erro de arredondamento na troca
				# de passo. Os PNGs representam exatamente os passos 0 a 7.
				var distance: float = (float(frame) + 0.5) * 2.0 / (_waiter_view.WALK_FRAMES * _waiter_view.STEPS_PER_CELL)
				_set_pose(state, true, distance, _capture_position)
				if not await _write_capture("%s_%s_%02d.png" % [basename, state, frame]):
					quit(1)
					return
		if _request == "todos":
			_set_pose(state, false, 0.0, _capture_position)
			if not await _write_capture("%s_%s_parado.png" % [basename, state]):
				quit(1)
				return
	# A saída pedida sempre existe, inclusive quando também há uma sequência.
	var final_state := "frente_bandeja" if _request == "todos" else states[0]
	var final_walking := _request.begins_with("andando_") or _request.begins_with("loop_")
	var first_frame_distance: float = 1.0 / (_waiter_view.WALK_FRAMES * _waiter_view.STEPS_PER_CELL)
	_set_pose(final_state, final_walking, first_frame_distance if final_walking else 0.0, _capture_position)
	if not await _write_capture(_output):
		quit(1)
		return
	print("GARCOM CODEX OK: %d PNGs; foto principal em %s" % [_written, _output])
	quit(0)


func _state_from_request() -> String:
	return _request.trim_prefix("loop_").trim_prefix("andando_").trim_prefix("parado_")


func _write_capture(path: String) -> bool:
	# Ler a textura antes de frame_post_draw salvaria a pose anterior.
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := path.get_base_dir()
	if not directory.is_empty():
		var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
			printerr("ERROR: não foi possível criar a pasta de captura: ", directory)
			return false
	var screenshot: Image = root.get_texture().get_image()
	if screenshot == null or screenshot.is_empty():
		printerr("ERROR: o renderizador não devolveu uma imagem para ", path)
		return false
	var write_error := screenshot.save_png(path)
	if write_error != OK:
		printerr("ERROR: falha ao gravar ", path, " (", write_error, ")")
		return false
	_written += 1
	print("QUADRO ", path.get_file(), " | ", _waiter_view.pose()[0])
	return true


func _update_review(delta: float) -> void:
	_review_walk.advance(delta)
	_waiter_view.advance(delta)
	_cafe.world_layer.refresh(_cafe.simulation)
	_cafe.front_view.set_focus(_cafe.world_layer.front_focus_points(_cafe.selected_cell))
	var index := _review_walk.stage
	if index != _review_state:
		_review_state = index
		var trip := "ida" if index % 2 == 0 else "volta"
		var hands := "mãos livres" if index < 2 else "com bandeja"
		root.title = "Garçom: %s, %s — velocidade do jogo — N: dia/noite — sem salvar" % [trip, hands]


func _on_review_input(event: InputEvent) -> void:
	super(event)
	if _stage_ready:
		_cafe._apply_night()
