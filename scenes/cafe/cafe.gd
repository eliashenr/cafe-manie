class_name Cafe
extends Node2D
## Cena principal do protótipo: a cafeteria.
##
## Dona da CafeSimulation (regras e estado do jogo). Avança a simulação a
## cada frame, traduz a entrada do jogador em ações e mantém a
## visualização em dia. Tem dois modos:
## - VIEW: tocar num piso seleciona o piso e o móvel sobre ele; tocar num
##   fogão com prato pronto leva o prato para o balcão;
## - BUILD: posicionando um móvel novo ou movendo um existente.

## Emitido sempre que algo que a interface mostra muda (modo, seleção, prévia).
signal state_changed

enum Mode { VIEW, BUILD }

const FEEDBACK_GOLD := Color("ffd35c")
const FEEDBACK_GOOD := Color("9be08f")
const FEEDBACK_XP := Color("8fd3ff")
const FEEDBACK_SPEND := Color("ff9b8a")

## Folga, em pixels de mundo, que a câmera pode passar da borda do grid.
@export var camera_margin := 96.0
## Altura, em pixels de tela, ocupada pelo painel de cima (a câmera enquadra abaixo dele).
@export var ui_top_inset := 140.0
## Altura, em pixels de tela, ocupada pela barra de baixo.
@export var ui_bottom_inset := 200.0
## Espaço acima do grid reservado para a altura dos móveis da fileira de trás
## (as paredes podem pedir mais; vale o maior).
@export var furniture_headroom := 60.0
## Intervalo mínimo, em segundos, entre salvamentos automáticos quando algo mudou.
## Minimizar ou fechar o jogo salva na hora, sem esperar.
@export var autosave_min_interval := 5.0

## Estado do jogo. Pode ser injetado antes de a cena entrar na árvore (testes);
## se ficar vazio, é carregado do save ou vira um jogo novo.
var simulation: CafeSimulation
## Onde o jogo é salvo. Com uma simulação injetada e sem save_service, nada é salvo.
var save_service: SaveService
## Relógio do jogo. Injetável para testes; o padrão é o relógio do aparelho.
var game_clock: GameClock
var layout: CafeLayout
var catalog: FurnitureCatalog
var mode := Mode.VIEW
## Sessão de construção em andamento (só no modo BUILD).
var session: PlacementSession
var selected_cell := CafeGrid.NO_CELL
## Móvel selecionado no modo VIEW, ou &"".
var selected_id: StringName = &""
## Resultado da última checagem de posição, para a interface explicar recusas.
var last_check := CafeLayout.Check.OK
## Resultado da última ação (ServiceResult), para a interface explicar recusas.
## Toda recusa toca o som de erro.
var last_service_result := ServiceResult.OK:
	set(value):
		last_service_result = value
		if value != ServiceResult.OK and sound_board != null:
			sound_board.play(&"error")

var _save_dirty := false
var _since_last_save := 0.0
var _saving_enabled := true

var grid: CafeGrid:
	get:
		return layout.grid

@onready var floor_view: FloorView = $FloorView
@onready var wall_view: WallView = $WallView
@onready var world_layer: WorldLayer = $WorldLayer
@onready var effects: Node2D = $Effects
@onready var camera: CafeCamera = $CafeCamera
@onready var hud: GameHud = $GameHud
@onready var build_bar: BuildBar = $BuildBar
@onready var sound_board: SoundBoard = $SoundBoard


func _ready() -> void:
	if SmokeCheck.requested():
		_saving_enabled = false
		add_child(SmokeCheck.new())
	var welcome := ""
	if simulation == null:
		welcome = _load_or_start_game()
	layout = simulation.layout
	catalog = simulation.furniture
	world_layer.bind(layout)
	simulation.payment_received.connect(_on_payment_received)
	simulation.leveled_up.connect(_on_leveled_up)
	simulation.cafe_expanded.connect(_on_cafe_expanded)
	simulation.mission_completed.connect(_on_mission_completed)
	simulation.achievement_unlocked.connect(_on_achievement_unlocked)
	_connect_sounds()
	simulation.style.changed.connect(_apply_style)
	_apply_style()

	_fit_floor_and_camera()
	camera.tapped.connect(_on_tapped)
	camera.hovered.connect(_on_hovered)

	hud.bind(simulation)
	hud.restart_requested.connect(restart_game)
	hud.daily_claim_requested.connect(claim_daily_reward)
	hud.name_chosen.connect(_on_name_chosen)
	hud.name_skipped.connect(_on_name_skipped)
	build_bar.bind(self)
	world_layer.refresh(simulation)
	_watch_for_changes()
	if not welcome.is_empty():
		EventBus.message_posted.emit(welcome)
	if simulation.cafe_name.is_empty():
		hud.ask_cafe_name(true)  # a recompensa diária vem depois do nome
	else:
		offer_daily_reward()


func _process(delta: float) -> void:
	simulation.tick(delta)
	world_layer.refresh(simulation)
	_since_last_save += delta
	if _save_dirty and _since_last_save >= autosave_min_interval:
		save_now()


# --- Save ------------------------------------------------------------------

## Carrega o save (ou começa um jogo novo). Retorna a mensagem de boas-vindas.
func _load_or_start_game() -> String:
	if game_clock == null:
		game_clock = GameClock.new()
	if save_service == null:
		save_service = SaveService.new()
	var loaded := save_service.load_game(game_clock)
	for warning in loaded.warnings:
		push_warning("Save: " + warning)
	match loaded.status:
		SaveService.Status.OK:
			simulation = loaded.simulation
			return _welcome_back(loaded.saved_at)
		SaveService.Status.RECOVERED_FROM_BACKUP:
			simulation = loaded.simulation
			return "O save estava danificado; recuperamos a cópia anterior."
		SaveService.Status.CORRUPT:
			simulation = CafeSimulation.create_new_game(game_clock)
			return "Não deu para ler o save. Começamos um jogo novo (o arquivo antigo foi guardado)."
		SaveService.Status.NEWER_VERSION:
			simulation = CafeSimulation.create_new_game(game_clock)
			return "O save é de uma versão mais nova do jogo. Começamos um jogo novo (o save foi guardado)."
	simulation = CafeSimulation.create_new_game(game_clock)
	return ""


## "Bem-vindo de volta!" contando os pratos que ficaram prontos enquanto o jogo estava fechado.
func _welcome_back(saved_at: float) -> String:
	var kitchen := simulation.kitchen
	var ready_while_away := 0
	for placement in simulation.layout.placements():
		var ready_at := kitchen.stove_ready_at(placement.id)
		if ready_at > saved_at and kitchen.stove_status(placement.id) == Kitchen.StoveStatus.READY:
			ready_while_away += 1
	match ready_while_away:
		0:
			return "Bem-vindo de volta!"
		1:
			return "Bem-vindo de volta! 1 prato ficou pronto enquanto você estava fora."
	return "Bem-vindo de volta! %d pratos ficaram prontos enquanto você estava fora." % ready_while_away


## Salva agora. Sem save_service (testes), não faz nada.
func save_now() -> Error:
	if save_service == null or not _saving_enabled:
		return ERR_UNAVAILABLE
	var error := save_service.save(simulation)
	_save_dirty = false
	_since_last_save = 0.0
	if error != OK:
		EventBus.message_posted.emit("Não foi possível salvar o jogo (erro %d)." % error)
	return error


## Apaga o save e reabre a cafeteria do zero. Pedido pelo jogador, com confirmação no HUD.
func restart_game() -> void:
	_saving_enabled = false
	if save_service != null:
		save_service.delete_save()
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _watch_for_changes() -> void:
	simulation.layout.changed.connect(_mark_dirty)
	simulation.kitchen.changed.connect(_mark_dirty)
	simulation.wallet.balance_changed.connect(_mark_dirty.unbind(2))
	simulation.progression.xp_changed.connect(_mark_dirty.unbind(1))
	simulation.popularity_changed.connect(_mark_dirty.unbind(1))
	simulation.inventory.changed.connect(_mark_dirty)
	simulation.style.changed.connect(_mark_dirty)
	simulation.missions.progress_changed.connect(_mark_dirty)
	simulation.stats.changed.connect(_mark_dirty.unbind(2))
	simulation.daily.changed.connect(_mark_dirty)


func _mark_dirty() -> void:
	_save_dirty = true


func _exit_tree() -> void:
	if _save_dirty:
		save_now()


## No celular o sistema pode encerrar o jogo a qualquer momento depois de
## minimizado, então salva assim que ele sai de foco, pausa ou vai fechar.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if simulation != null:
				save_now()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			# O jogo pode ter ficado aberto (ou minimizado) de um dia para o outro.
			if simulation != null and is_node_ready():
				offer_daily_reward()


# --- Sons ------------------------------------------------------------------------

## Cada acontecimento do jogo com o seu som (seção 123: toda ação tem resposta).
func _connect_sounds() -> void:
	var play := sound_board.play
	simulation.payment_received.connect(play.bind(&"coin").unbind(2))
	simulation.furniture_sold.connect(play.bind(&"coin").unbind(2))
	simulation.dish_collected.connect(play.bind(&"dish_ready").unbind(2))
	simulation.leveled_up.connect(play.bind(&"level_up").unbind(1))
	simulation.mission_completed.connect(play.bind(&"achievement").unbind(1))
	simulation.achievement_unlocked.connect(play.bind(&"achievement").unbind(2))
	simulation.daily_reward_claimed.connect(play.bind(&"achievement").unbind(2))
	simulation.furniture_bought.connect(play.bind(&"purchase").unbind(1))
	simulation.surface_bought.connect(play.bind(&"purchase").unbind(1))
	simulation.cafe_expanded.connect(play.bind(&"purchase").unbind(1))
	hud.mute_toggled.connect(sound_board.set_muted)
	sound_board.muted_changed.connect(hud.show_sound_state)
	hud.show_sound_state(sound_board.muted)


# --- Recompensa diária ------------------------------------------------------

## Mostra a recompensa diária se ainda não foi recebida hoje.
func offer_daily_reward() -> bool:
	if not simulation.can_claim_daily() or is_dialog_open():
		return false
	hud.show_daily_reward()
	return true


## Alguma janela de pergunta aberta? Só cabe uma por vez na tela.
func is_dialog_open() -> bool:
	for dialog: Window in [hud.daily_dialog(), hud.restart_dialog(), hud.achievements_dialog(),
			hud.name_dialog(), build_bar.confirm_dialog()]:
		if dialog.visible:
			return true
	return false


func _on_name_chosen(text: String) -> void:
	var first_time := simulation.cafe_name.is_empty()
	if not simulation.set_cafe_name(text):
		EventBus.message_posted.emit("Nome inválido: use de %d a %d letras." % [CafeSimulation.CAFE_NAME_MIN, CafeSimulation.CAFE_NAME_MAX])
		if first_time:
			_on_name_skipped()
		return
	_mark_dirty()
	if first_time:
		EventBus.message_posted.emit("Bem-vindo ao %s!" % simulation.cafe_name)
		offer_daily_reward()


## Fechou sem escolher na primeira vez: fica com o nome padrão (dá para trocar depois).
func _on_name_skipped() -> void:
	if simulation.cafe_name.is_empty():
		simulation.set_cafe_name(CafeSimulation.DEFAULT_CAFE_NAME)
		_mark_dirty()
		# No fim do frame: a janela do nome ainda está fechando neste momento.
		offer_daily_reward.call_deferred()


func claim_daily_reward() -> Dictionary:
	var day := simulation.daily_day_number()
	var delivered := simulation.claim_daily()
	if not delivered.is_empty():
		EventBus.message_posted.emit("Recompensa do dia %d: %s" % [day, hud.reward_text(delivered).replace("\n", ", ")])
		state_changed.emit()
	return delivered


# --- Cozinha ---------------------------------------------------------------

## Começa a preparar uma receita no fogão selecionado.
func cook_on_selected(recipe_id: StringName) -> int:
	last_service_result = simulation.start_cooking(selected_id, recipe_id)
	if last_service_result == ServiceResult.OK:
		sound_board.play(&"tap")
		var recipe := simulation.recipes.get_definition(recipe_id)
		if recipe.ingredient_cost > 0:
			_float_over(selected_id, "-%d" % recipe.ingredient_cost, FEEDBACK_SPEND)
	state_changed.emit()
	return last_service_result


## Leva o prato pronto do fogão para o balcão. Se não der, seleciona o fogão
## para a barra explicar o motivo.
func collect_stove(stove_id: StringName) -> int:
	var recipe := simulation.kitchen.stove_recipe(stove_id)
	var result := simulation.collect(stove_id)
	if result == ServiceResult.OK:
		_float_over(stove_id, "+%d %s" % [recipe.servings, recipe.display_name], FEEDBACK_GOOD)
		_float_over(stove_id, "+%d XP" % recipe.xp_reward, FEEDBACK_XP, Vector2(0, 22))
	else:
		_set_selected_cell(layout.get_placement(stove_id).origin)
		_set_selected_id(stove_id)
		last_service_result = result
	state_changed.emit()
	return result


func _on_payment_received(customer: Customer, amount: int) -> void:
	var at := IsoProjection.grid_point_to_world(Vector2(customer.seat_cell)) + Vector2(0, -70)
	FloatingText.spawn(effects, at, "+%d" % amount, FEEDBACK_GOLD)


func _on_leveled_up(level: int) -> void:
	var unlocked: Array[String] = []
	for recipe in simulation.recipes.all():
		if recipe.unlock_level == level:
			unlocked.append(recipe.display_name)
	var text := "Nível %d!" % level
	if not unlocked.is_empty():
		text += "  Nova receita: %s" % ", ".join(unlocked)
	EventBus.message_posted.emit(text)
	state_changed.emit()


## Recompensa da missão: aviso no centro da tela (a próxima missão aparece no HUD).
func _on_mission_completed(mission: MissionDefinition) -> void:
	var rewards: Array[String] = []
	if mission.reward_gold > 0:
		rewards.append("+%d ouro" % mission.reward_gold)
	if mission.reward_xp > 0:
		rewards.append("+%d XP" % mission.reward_xp)
	var text := "Missão concluída: %s" % mission.title
	if not rewards.is_empty():
		text += "  %s" % "  ".join(rewards)
	if simulation.missions.all_done():
		text += "\nVocê completou todas as missões iniciais!"
	EventBus.message_posted.emit(text)
	state_changed.emit()


func _on_achievement_unlocked(achievement: AchievementDefinition, tier: int) -> void:
	var text := "Conquista: %s!" % achievement.tier_titles[tier]
	var reward: int = achievement.tier_rewards[tier]
	if reward > 0:
		text += "  +%d ouro" % reward
	EventBus.message_posted.emit(text)


## Expande a cafeteria (a confirmação fica na barra de baixo).
func expand_cafe() -> int:
	last_service_result = simulation.expand()
	state_changed.emit()
	return last_service_result


func _on_cafe_expanded(new_size: Vector2i) -> void:
	_fit_floor_and_camera()
	EventBus.message_posted.emit("Cafeteria ampliada para %d×%d!" % [new_size.x, new_size.y])


## Ajusta o piso e a câmera ao tamanho atual do grid.
func _fit_floor_and_camera() -> void:
	floor_view.grid_size = layout.grid.size
	floor_view.entrance = layout.entrance
	wall_view.grid_size = layout.grid.size
	var headroom := maxf(furniture_headroom, wall_view.wall_height)
	var bounds := IsoProjection.grid_bounds(layout.grid.size).grow_individual(0.0, headroom, 0.0, 0.0)
	camera.set_bounds(bounds.grow(camera_margin))
	camera.frame(bounds, ui_top_inset, ui_bottom_inset)


## Piso e parede com os revestimentos aplicados.
func _apply_style() -> void:
	var surfaces := simulation.surfaces
	floor_view.floor_style = surfaces.get_definition(simulation.style.floor_id)
	wall_view.wall_style = surfaces.get_definition(simulation.style.wall_id)


## Compra (se preciso) e aplica um revestimento. A confirmação da compra fica na barra.
func use_surface(surface_id: StringName) -> int:
	var definition := simulation.surfaces.get_definition(surface_id)
	if definition == null:
		return ServiceResult.UNKNOWN_ITEM
	var buying := not simulation.style.owns(surface_id) and definition.price > 0
	last_service_result = simulation.use_surface(definition)
	if last_service_result == ServiceResult.OK and buying:
		EventBus.message_posted.emit("%s aplicado! -%d ouro" % [definition.display_name, definition.price])
	state_changed.emit()
	return last_service_result


func _float_over(placement_id: StringName, text: String, color: Color, offset := Vector2.ZERO) -> void:
	var placement := layout.get_placement(placement_id)
	if placement == null:
		return
	var at := IsoProjection.cell_center(placement.origin) + Vector2(0, -60) + offset
	FloatingText.spawn(effects, at, text, color)


# --- Modo VIEW -------------------------------------------------------------

## Seleciona a célula sob o ponto do mundo (e o móvel sobre ela). Fora do grid, limpa tudo.
func select_at_world(world_position: Vector2) -> void:
	var cell := IsoProjection.world_to_cell(world_position)
	_set_selected_cell(cell if layout.grid.is_inside(cell) else CafeGrid.NO_CELL)
	var placement := layout.placement_at(selected_cell)
	_set_selected_id(placement.id if placement != null else &"")
	state_changed.emit()


func clear_selection() -> void:
	_set_selected_cell(CafeGrid.NO_CELL)
	_set_selected_id(&"")
	state_changed.emit()


## Toque no modo VIEW: fogão com prato pronto serve direto; o resto seleciona.
func tap_at_world(world_position: Vector2) -> void:
	var placement := layout.placement_at(IsoProjection.world_to_cell(world_position))
	if placement != null and simulation.kitchen.is_stove(placement.id) \
			and simulation.kitchen.stove_status(placement.id) == Kitchen.StoveStatus.READY:
		collect_stove(placement.id)
	else:
		select_at_world(world_position)


## Gira o móvel selecionado no lugar. Retorna o resultado (pode ser recusado).
func rotate_selected() -> CafeLayout.Check:
	var placement := layout.get_placement(selected_id)
	if placement == null:
		return CafeLayout.Check.UNKNOWN_PLACEMENT
	last_check = layout.move(selected_id, placement.origin, placement.rotation + 1)
	state_changed.emit()
	return last_check


## Guarda o móvel selecionado no inventário (pode ser recolocado de graça).
func remove_selected() -> bool:
	var check := simulation.store_furniture(selected_id)
	if check != CafeLayout.Check.OK:
		last_check = check
		sound_board.play(&"error")
		state_changed.emit()
		return false
	clear_selection()
	return true


## Vende o móvel selecionado (a confirmação fica na barra). Recusa explica o motivo.
func sell_selected() -> int:
	var placement := layout.get_placement(selected_id)
	if placement == null:
		return ServiceResult.UNKNOWN_ITEM
	var definition := placement.definition
	var origin := placement.origin
	last_service_result = simulation.sell_furniture(selected_id)
	if last_service_result == ServiceResult.OK:
		var amount := simulation.sell_price(definition)
		FloatingText.spawn(effects, IsoProjection.cell_center(origin) + Vector2(0, -60), "+%d" % amount, FEEDBACK_GOLD)
		clear_selection()
	else:
		state_changed.emit()
	return last_service_result


# --- Modo BUILD ------------------------------------------------------------

## Começa a posicionar um móvel novo do catálogo.
func start_placing(definition_id: StringName) -> bool:
	var definition := catalog.get_definition(definition_id)
	if definition == null:
		return false
	var availability := simulation.can_acquire(definition)
	if availability != ServiceResult.OK:
		last_service_result = availability
		state_changed.emit()
		return false
	clear_selection()
	_begin_session(PlacementSession.for_new(layout, definition))
	return true


## Começa a mover o móvel selecionado (se não estiver em uso).
func start_moving_selected() -> bool:
	if layout.is_in_use(selected_id):
		last_check = CafeLayout.Check.IN_USE
		sound_board.play(&"error")
		state_changed.emit()
		return false
	var moving := PlacementSession.for_move(layout, selected_id)
	if moving == null:
		return false
	_set_selected_cell(CafeGrid.NO_CELL)
	_begin_session(moving)
	return true


func rotate_placement() -> void:
	if session == null:
		return
	session.rotate_clockwise()
	_refresh_preview()


## Confirma a posição atual. Retorna false (e mantém o modo) se for inválida.
func confirm_placement() -> bool:
	if session == null:
		return false
	var was_moving := session.is_moving()
	var placed_id: StringName = &""
	if was_moving:
		placed_id = session.confirm()
	elif session.can_confirm():
		# Móvel novo: sai do inventário (grátis) ou é comprado agora.
		var definition := session.definition
		var from_inventory := simulation.inventory.count(definition.id) > 0
		last_service_result = simulation.acquire_and_place(definition, session.target, session.rotation)
		if last_service_result == ServiceResult.OK:
			placed_id = simulation.last_placed_id
			if not from_inventory and definition.price > 0:
				_float_over(placed_id, "-%d" % definition.price, FEEDBACK_SPEND)
	if placed_id == &"":
		_refresh_preview()
		if last_service_result == ServiceResult.OK:
			sound_board.play(&"error")  # posição inválida (sem ouro já tocou pelo resultado)
		return false
	_end_session()
	if was_moving:
		_set_selected_id(placed_id)
		state_changed.emit()
	return true


func cancel_placement() -> void:
	if session != null:
		_end_session()


func _begin_session(new_session: PlacementSession) -> void:
	session = new_session
	mode = Mode.BUILD
	world_layer.hidden_id = session.moving_id
	_refresh_preview()


func _end_session() -> void:
	session = null
	mode = Mode.VIEW
	last_check = CafeLayout.Check.OK
	last_service_result = ServiceResult.OK
	world_layer.hidden_id = &""
	world_layer.hide_ghost()
	floor_view.clear_preview()
	state_changed.emit()


func _refresh_preview() -> void:
	last_check = session.check()
	if session.target == CafeGrid.NO_CELL:
		world_layer.hide_ghost()
		floor_view.clear_preview()
	else:
		var valid := last_check == CafeLayout.Check.OK
		world_layer.show_ghost(session.definition, session.target, session.rotation, valid)
		floor_view.set_preview(CafeGrid.footprint_cells(session.target, session.footprint()), valid)
	state_changed.emit()


# --- Entrada ---------------------------------------------------------------

func _on_tapped(world_position: Vector2) -> void:
	if mode == Mode.VIEW:
		tap_at_world(world_position)
		return
	var cell := IsoProjection.world_to_cell(world_position)
	if not layout.grid.is_inside(cell):
		return
	# Tocar de novo no mesmo lugar confirma; no mouse, o hover já levou a prévia até lá,
	# então um clique só basta.
	if cell == session.target and session.can_confirm():
		confirm_placement()
	else:
		session.set_target(cell)
		_refresh_preview()


func _on_hovered(world_position: Vector2) -> void:
	if mode != Mode.BUILD:
		return
	var cell := IsoProjection.world_to_cell(world_position)
	if layout.grid.is_inside(cell) and cell != session.target:
		session.set_target(cell)
		_refresh_preview()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_R:
			if mode == Mode.BUILD:
				rotate_placement()
			elif selected_id != &"":
				rotate_selected()
		KEY_ENTER, KEY_KP_ENTER:
			confirm_placement()
		KEY_ESCAPE:
			if mode == Mode.BUILD:
				cancel_placement()
			else:
				clear_selection()
		KEY_DELETE, KEY_BACKSPACE:
			if mode == Mode.VIEW:
				remove_selected()
		_:
			return
	get_viewport().set_input_as_handled()


func _set_selected_cell(cell: Vector2i) -> void:
	selected_cell = cell
	floor_view.selected_cell = cell


func _set_selected_id(id: StringName) -> void:
	selected_id = id
	last_check = CafeLayout.Check.OK
	last_service_result = ServiceResult.OK
	world_layer.selected_id = id
