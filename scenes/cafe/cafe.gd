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

enum Mode { VIEW, BUILD, PAINT }

const FEEDBACK_GOLD := Color("ffd35c")
const FEEDBACK_GOOD := Color("9be08f")
const FEEDBACK_XP := Color("8fd3ff")
const FEEDBACK_SPEND := Color("ff9b8a")

const CLOSED_MESSAGE := "Café fechado: ninguém novo entra. Quem já está lá dentro é atendido e vai embora."
const OPEN_MESSAGE := "Café aberto! Os clientes voltam a chegar."
const TERRACE_BUILT_MESSAGE := "Terraço pronto! De dia, quem senta na fileira da frente paga %d%% a mais."
const DIRT_HINT_MESSAGE := "Um cliente sujou o chão! Toque na mancha para limpar: dá ouro, e o chão limpo segura a popularidade."
const SHOW_STARTED_MESSAGE := "Começou o show no palco! Os clientes chegam mais rápido enquanto ele dura."
const SHOW_ENDED_MESSAGE := "O show acabou. O próximo começa daqui a pouco."
const NIGHT_MESSAGE := "Anoiteceu! As luzes acenderam e o cardápio noturno está aberto no Fogão Lua Cheia."
const DAY_MESSAGE := "Amanheceu! O cardápio noturno fecha até a noite."
const EVENT_STARTED_MESSAGE := "Começou o %s! Toque na abóbora, à esquerda, para ver a história e as missões."
const EVENT_STOVE_WON_MESSAGE := "Você ganhou o %s! Ele cozinha %d%% mais rápido e está guardado na Loja, aba Cozinha."
const EVENT_STOVE_LEVEL_MESSAGE := "O %s subiu para o nível %d: agora cozinha %d%% mais rápido!"
const EVENT_FINISHED_MESSAGE := "Você completou o %s! Prêmio: %s, guardado na Loja."
const CRITIC_ARRIVED_MESSAGE := "O crítico gastronômico chegou! Esta semana ele avalia: %s. Sirva rápido para ganhar a estrela."
const CRITIC_STAR_MESSAGE := "O crítico adorou! Toque na estrela que ele deixou na mesa para receber o prêmio."
const CRITIC_UNHAPPY_MESSAGE := "O crítico foi embora sem ser servido a tempo. Ele volta outro dia."
## Onde o prêmio do crítico começa a subir, em relação ao centro do piso da mesa.
const CRITIC_FEEDBACK_OFFSET := Vector2(0, -80)
const SET_COMPLETE_MESSAGE := "%s completo! Cada peça rende o dobro de porções. Prêmio: %s, guardado na Loja."
const TROPHY_WORN_MESSAGE := "O %s se gastou e parou de acelerar os fogões. Toque nele para renovar."
## Onde o brilho do tempero estoura, em relação ao centro do piso do fogão (em cima da panela).
const SPICE_BURST_OFFSET := Vector2(0, -90)
const SPOILED_MESSAGE := "O prato de %s estragou de tanto esperar no fogão. Toque no fogão para jogar fora."

## Folga, em pixels de mundo, que a câmera pode passar da borda do grid.
## Folga da câmera em volta do café (pixels de mundo): dá para ver a rua e os prédios em volta.
@export var camera_margin := 360.0
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
## Reforma em andamento (Mode.PAINT): o revestimento escolhido e os pisos (Vector2i) ou trechos de
## parede ("borda:índice") marcados.
var painting: SurfaceDefinition
var paint_targets: Array = []
## Pendurando itens de parede (no mesmo modo): o item escolhido, ou null para tirar enfeites.
var hanging_items := false
var hanging: WallItemDefinition
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
		if value == ServiceResult.NOT_ENOUGH_GOLD:
			_offer_gold.call_deferred()

## Faltou ouro: a vitrine de Café Ouro aparece sozinha, no máximo uma vez a cada tantos segundos.
@export var gold_offer_cooldown := 60.0
var _since_gold_offer := INF

var _save_dirty := false
var _since_last_save := 0.0
var _saving_enabled := true
## O aviso de como limpar o chão já apareceu nesta sessão (DT-068).
var _dirt_hint_shown := false

var grid: CafeGrid:
	get:
		return layout.grid

@onready var exterior_view: ExteriorView = $ExteriorView
@onready var floor_view: FloorView = $FloorView
@onready var wall_view: WallView = $WallView
@onready var front_view: FrontView = $FrontView
@onready var street_view: StreetView = $StreetView
@onready var world_layer: WorldLayer = $WorldLayer
@onready var effects: Node2D = $Effects
## Partículas soltas (confete do pagamento), logo abaixo dos números que sobem.
@onready var particles: Node2D = $Particles
@onready var camera: CafeCamera = $CafeCamera
@onready var hud: GameHud = $GameHud
@onready var build_bar: BuildBar = $BuildBar
@onready var sound_board: SoundBoard = $SoundBoard
## Escurece o mundo à noite (DT-064).
var night_tint := NightTint.new()


func _ready() -> void:
	if SmokeCheck.requested():
		_saving_enabled = false
		add_child(SmokeCheck.new())
	var welcome := ""
	if simulation == null:
		welcome = _load_or_start_game()
	add_child(night_tint)
	night_tint.set_amount(simulation.darkness())
	layout = simulation.layout
	catalog = simulation.furniture
	world_layer.bind(layout)
	simulation.payment_received.connect(_on_payment_received)
	simulation.leveled_up.connect(_on_leveled_up)
	simulation.cafe_expanded.connect(_on_cafe_expanded)
	simulation.waiter_hired.connect(_on_waiter_hired)
	hud.coin_pack_chosen.connect(_on_coin_pack_chosen)
	hud.pause_toggled.connect(toggle_pause)
	hud.closed_toggled.connect(toggle_closed)
	hud.event_requested.connect(_on_event_requested)
	simulation.mission_completed.connect(_on_mission_completed)
	simulation.board_mission_completed.connect(_on_board_mission_completed)
	simulation.achievement_unlocked.connect(_on_achievement_unlocked)
	simulation.recipe_mastered.connect(_on_recipe_mastered)
	simulation.dish_spoiled.connect(_on_dish_spoiled)
	simulation.spice_used.connect(_on_spice_used)
	simulation.trophy_worn_out.connect(_on_trophy_worn_out)
	simulation.stove_set_completed.connect(_on_stove_set_completed)
	simulation.critic_arrived.connect(_on_critic_arrived)
	simulation.event_started.connect(_on_event_started)
	simulation.night_changed.connect(_on_night_changed)
	simulation.show_started.connect(func() -> void: EventBus.message_posted.emit(SHOW_STARTED_MESSAGE))
	simulation.show_ended.connect(func() -> void: EventBus.message_posted.emit(SHOW_ENDED_MESSAGE))
	simulation.event_mission_completed.connect(_on_event_mission_completed)
	simulation.event_stove_upgraded.connect(_on_event_stove_upgraded)
	simulation.event_finished.connect(_on_event_finished)
	simulation.critic_left.connect(_on_critic_left)
	_connect_sounds()
	simulation.style.changed.connect(_apply_style)
	_apply_style()
	simulation.dirt.changed.connect(_on_dirt_changed)
	_on_dirt_changed()

	_fit_floor_and_camera()
	camera.tapped.connect(_on_tapped)
	camera.hovered.connect(_on_hovered)

	hud.bind(simulation)
	hud.restart_requested.connect(restart_game)
	hud.daily_claim_requested.connect(claim_daily_reward)
	hud.name_chosen.connect(_on_name_chosen)
	hud.name_skipped.connect(_on_name_skipped)
	hud.daily_requested.connect(_on_daily_requested)
	hud.zoom_requested.connect(func(factor: float) -> void:
		camera.zoom_at(get_viewport().get_visible_rect().size / 2.0, camera.zoom.x * factor))
	build_bar.bind(self)
	_show_closed_state()
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
	night_tint.set_amount(simulation.darkness())
	world_layer.refresh(simulation)
	front_view.set_focus(world_layer.front_focus_points(selected_cell))
	_since_last_save += delta
	_since_gold_offer += delta
	if _save_dirty and _since_last_save >= autosave_min_interval:
		save_now()


# --- Pausa -----------------------------------------------------------------

## Pausa (ou continua) o jogo inteiro: clientes, garçons, fogões, trânsito e vapor param, e o jogador
## compra, move, cozinha e reforma à vontade (DT-049).
func set_paused(value: bool) -> void:
	if simulation.paused == value:
		return
	simulation.set_paused(value)
	world_layer.set_frozen(value)
	street_view.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	hud.show_pause_state(value)
	state_changed.emit()


func toggle_pause() -> void:
	set_paused(not simulation.paused)


func is_paused() -> bool:
	return simulation.paused


# --- Abrir e fechar --------------------------------------------------------

## Vira a placa da porta (DT-051). Fechado, ninguém novo chega e a fila da calçada vai embora; quem já está
## lá dentro é atendido e sai sem tirar popularidade. O jogo continua rodando (é diferente da pausa).
func set_closed(value: bool) -> void:
	if simulation.closed == value:
		return
	simulation.set_closed(value)
	_show_closed_state()
	_mark_dirty()
	EventBus.message_posted.emit(CLOSED_MESSAGE if value else OPEN_MESSAGE)
	state_changed.emit()


func toggle_closed() -> void:
	set_closed(not simulation.closed)


func is_closed() -> bool:
	return simulation.closed


## A placa da porta e o botão mostram o estado atual (também ao abrir um save com o café fechado).
func _show_closed_state() -> void:
	front_view.closed = simulation.closed
	hud.show_closed_state(simulation.closed)


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
	var spoiled := simulation.forget_spoiled_while_away()
	var text := "Bem-vindo de volta!"
	match ready_while_away:
		0:
			pass
		1:
			text += " 1 prato ficou pronto enquanto você estava fora."
		_:
			text += " %d pratos ficaram prontos enquanto você estava fora." % ready_while_away
	match spoiled:
		0:
			return text
		1:
			return text + " 1 prato estragou no fogão: toque nele para jogar fora."
	return text + " %d pratos estragaram no fogão: toque neles para jogar fora." % spoiled


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
	simulation.avatar.changed.connect(_mark_dirty)
	simulation.missions.progress_changed.connect(_mark_dirty)
	simulation.stats.changed.connect(_mark_dirty.unbind(2))
	simulation.daily.changed.connect(_mark_dirty)
	simulation.energy.changed.connect(_mark_dirty)
	simulation.mastery.changed.connect(_mark_dirty)


func _mark_dirty() -> void:
	_save_dirty = true


func _exit_tree() -> void:
	if _save_dirty:
		save_now()


## No celular o sistema pode encerrar o jogo a qualquer momento depois de
## minimizado, então salva assim que ele sai de foco, pausa ou vai fechar.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_APPLICATION_PAUSED, \
				NOTIFICATION_APPLICATION_FOCUS_OUT:
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
	simulation.drink_served.connect(play.bind(&"dish_ready").unbind(2))
	simulation.leveled_up.connect(play.bind(&"level_up").unbind(1))
	simulation.mission_completed.connect(play.bind(&"achievement").unbind(1))
	simulation.achievement_unlocked.connect(play.bind(&"achievement").unbind(2))
	simulation.recipe_mastered.connect(play.bind(&"achievement").unbind(3))
	simulation.dish_spoiled.connect(play.bind(&"error").unbind(2))
	simulation.spice_used.connect(play.bind(&"achievement").unbind(2))
	simulation.stove_set_completed.connect(play.bind(&"achievement").unbind(1))
	simulation.critic_arrived.connect(play.bind(&"level_up").unbind(1))
	simulation.event_mission_completed.connect(play.bind(&"achievement").unbind(2))
	simulation.event_stove_upgraded.connect(play.bind(&"level_up").unbind(2))
	simulation.critic_star_collected.connect(play.bind(&"achievement").unbind(1))
	simulation.fruit_harvested.connect(play.bind(&"coin").unbind(3))
	simulation.attraction_collected.connect(play.bind(&"coin").unbind(2))
	simulation.floor_cleaned.connect(play.bind(&"coin").unbind(3))
	simulation.terrace_built.connect(play.bind(&"achievement"))
	simulation.delivery_sent.connect(play.bind(&"coin").unbind(1))
	simulation.branch_collected.connect(play.bind(&"coin").unbind(1))
	simulation.neighbor_visited.connect(play.bind(&"coin").unbind(2))
	simulation.neighbor_visits.changed.connect(_mark_dirty)
	simulation.branch.changed.connect(_mark_dirty)
	simulation.show_started.connect(play.bind(&"level_up"))
	simulation.daily_reward_claimed.connect(play.bind(&"achievement").unbind(2))
	simulation.furniture_bought.connect(play.bind(&"purchase").unbind(1))
	simulation.surface_bought.connect(play.bind(&"purchase").unbind(1))
	simulation.cafe_expanded.connect(play.bind(&"purchase").unbind(1))
	simulation.waiter_hired.connect(play.bind(&"purchase").unbind(1))
	hud.mute_toggled.connect(sound_board.set_muted)
	sound_board.muted_changed.connect(hud.show_sound_state)
	hud.show_sound_state(sound_board.muted)
	hud.music_toggled.connect(sound_board.set_music_muted)
	sound_board.music_muted_changed.connect(hud.show_music_state)
	hud.show_music_state(sound_board.music_muted)


# --- Recompensa diária ------------------------------------------------------

## Mostra a recompensa diária se ainda não foi recebida hoje.
func offer_daily_reward() -> bool:
	if not simulation.can_claim_daily() or is_dialog_open():
		return false
	hud.show_daily_reward()
	return true


## O jogador tocou no presente: abre a recompensa, ou diz quanto falta para a próxima.
func _on_daily_requested() -> void:
	if offer_daily_reward():
		return
	if not simulation.can_claim_daily():
		var left := ceili(simulation.seconds_until_daily())
		EventBus.message_posted.emit("Próximo presente em %dh%02d" % [left / 3600, (left % 3600) / 60])


## Alguma janela de pergunta aberta? Só cabe uma por vez na tela.
func is_dialog_open() -> bool:
	for dialog: Window in [hud.daily_dialog(), hud.restart_dialog(), hud.achievements_dialog(), hud.missions_dialog(),
			hud.name_dialog(), build_bar.confirm_dialog(), hud.coin_dialog(), hud.coin_info_dialog(), hud.event_dialog()]:
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
	var servings := simulation.kitchen.stove_servings(stove_id)
	var xp := simulation.xp_on(stove_id, recipe) if recipe != null else 0
	var result := simulation.collect(stove_id)
	if result == ServiceResult.OK:
		_float_over(stove_id, "+%d %s" % [servings, recipe.display_name], FEEDBACK_GOOD)
		_float_over(stove_id, "+%d XP" % xp, FEEDBACK_XP, Vector2(0, 22))
	else:
		_set_selected_cell(layout.get_placement(stove_id).origin)
		_set_selected_id(stove_id)
		last_service_result = result
	state_changed.emit()
	return result


## Joga fora o prato estragado do fogão (DT-055). Recusa deixa a barra explicar o motivo.
func discard_stove(stove_id: StringName) -> int:
	var recipe := simulation.kitchen.stove_recipe(stove_id)
	var result := simulation.discard_spoiled(stove_id)
	last_service_result = result
	if result == ServiceResult.OK:
		_float_over(stove_id, "%s foi para o lixo" % recipe.display_name, FEEDBACK_SPEND)
	state_changed.emit()
	return result


## Renova o troféu (DT-057; a confirmação já foi pedida pela barra).
func renew_trophy(trophy_id: StringName) -> int:
	var price := layout.get_placement(trophy_id).definition.renew_price
	last_service_result = simulation.renew_trophy(trophy_id)
	if last_service_result == ServiceResult.OK:
		_float_over(trophy_id, "Renovado!", FEEDBACK_GOOD)
		_float_over(trophy_id, "-%s" % UiTheme.thousands(price), FEEDBACK_SPEND, Vector2(0, 22))
	state_changed.emit()
	return last_service_result


## Coleta o ouro que os clientes deixaram na atração (DT-066).
## Limpa a mancha do piso (DT-068), com o ouro subindo e o brilho da limpeza.
func clean_floor(cell: Vector2i) -> int:
	last_service_result = simulation.clean_floor(cell)
	if last_service_result == ServiceResult.OK:
		var at := IsoProjection.cell_center(cell)
		FxParticles.gold_burst(effects, at)
		FloatingText.spawn(effects, at + Vector2(0, -30), "+%d ouro" % simulation.dirt_config.clean_gold, FEEDBACK_GOLD)
	state_changed.emit()
	return last_service_result


## Mostra as manchas no piso; a primeira do jogo vem com um aviso de como limpar.
func _on_dirt_changed() -> void:
	floor_view.dirt = simulation.dirt.spots()
	if simulation.dirt.count() > 0 and not _dirt_hint_shown:
		_dirt_hint_shown = true
		EventBus.message_posted.emit(DIRT_HINT_MESSAGE)


func collect_attraction(attraction_id: StringName) -> int:
	var amount := simulation.attractions.gold(attraction_id)
	last_service_result = simulation.collect_attraction(attraction_id)
	if last_service_result == ServiceResult.OK:
		_float_over(attraction_id, "+%s ouro" % UiTheme.thousands(amount), FEEDBACK_GOLD)
	state_changed.emit()
	return last_service_result


## Colhe o pé de fruta maduro (DT-065): as frutas sobem do vaso.
func harvest_tree(tree_id: StringName) -> int:
	var fruit_id := layout.get_placement(tree_id).definition.fruit
	last_service_result = simulation.harvest(tree_id)
	if last_service_result == ServiceResult.OK:
		var fruit: FruitDefinition = simulation.fruits.get_definition(fruit_id)
		_float_over(tree_id, "+%d %s" % [simulation.layout.get_placement(tree_id).definition.fruit_yield, fruit.display_name], FEEDBACK_GOOD)
	state_changed.emit()
	return last_service_result


## Toque na estrela do crítico (DT-061): o prêmio sobe da mesa, com confete.
func collect_critic_star() -> Dictionary:
	var cell: Vector2i = simulation.critic_star.get("cell", Vector2i.ZERO)
	var reward := simulation.collect_critic_star()
	if not reward.is_empty():
		var at := IsoProjection.cell_center(cell) + CRITIC_FEEDBACK_OFFSET
		FloatingText.spawn(effects, at, "+%s ouro" % UiTheme.thousands(reward["gold"]), FEEDBACK_GOLD)
		FloatingText.spawn(effects, at + Vector2(0, 22), "+%d XP" % reward["xp"], FEEDBACK_XP)
		FloatingText.spawn(effects, at + Vector2(0, 44), "+%d cupons" % reward["coupons"], FEEDBACK_GOOD)
		FxParticles.gold_burst(particles, at)
	state_changed.emit()
	return reward


## Toque no medalhão do evento: abre a janela dele (uma janela por vez).
func _on_event_requested() -> void:
	if not is_dialog_open():
		hud.show_event()


func _on_night_changed(night: bool) -> void:
	EventBus.message_posted.emit(NIGHT_MESSAGE if night else DAY_MESSAGE)


func _on_event_started(event: EventDefinition) -> void:
	EventBus.message_posted.emit(EVENT_STARTED_MESSAGE % event.title)


func _on_event_mission_completed(event: EventDefinition, entry: MissionBoard.Entry) -> void:
	EventBus.message_posted.emit("%s: missão concluída! %s  +%s ouro" % [event.title, entry.title(), UiTheme.thousands(entry.reward_gold)])


func _on_event_stove_upgraded(event: EventDefinition, level: int) -> void:
	var stove := catalog.get_definition(event.prize_stove)
	var cut := roundi(stove.stove_level_cuts[level - 1] * 100.0) if level <= stove.stove_level_cuts.size() else 0
	if level == 1:
		EventBus.message_posted.emit(EVENT_STOVE_WON_MESSAGE % [stove.display_name, cut])
	else:
		EventBus.message_posted.emit(EVENT_STOVE_LEVEL_MESSAGE % [stove.display_name, level, cut])


func _on_event_finished(event: EventDefinition) -> void:
	var prize := catalog.get_definition(event.final_prize)
	EventBus.message_posted.emit(EVENT_FINISHED_MESSAGE % [event.title, prize.display_name if prize != null else "um enfeite"])


func _on_critic_arrived(_customer: Customer) -> void:
	var book := simulation.recipes.get_book(simulation.critic_theme())
	EventBus.message_posted.emit(CRITIC_ARRIVED_MESSAGE % (book.display_name if book != null else "o cardápio"))


func _on_critic_left(_customer: Customer, star: bool) -> void:
	EventBus.message_posted.emit(CRITIC_STAR_MESSAGE if star else CRITIC_UNHAPPY_MESSAGE)


## Multifogão completo pela primeira vez (DT-060): o prêmio já está no inventário.
func _on_stove_set_completed(stove_set: StoveSetDefinition) -> void:
	var reward := catalog.get_definition(stove_set.reward)
	EventBus.message_posted.emit(SET_COMPLETE_MESSAGE % [stove_set.display_name,
		reward.display_name if reward != null else "um enfeite"])


## O troféu gastou a última carga.
func _on_trophy_worn_out(trophy_id: StringName) -> void:
	var placement := layout.get_placement(trophy_id)
	if placement != null:
		EventBus.message_posted.emit(TROPHY_WORN_MESSAGE % placement.definition.display_name)


## Usa no fogão um tempero da prateleira (DT-056). Recusa deixa a barra explicar o motivo.
func use_spice(stove_id: StringName, spice_id: StringName) -> int:
	last_service_result = simulation.use_spice(stove_id, spice_id)
	state_changed.emit()
	return last_service_result


## Compra o tempero e usa na hora (a confirmação já foi pedida pela barra).
func buy_and_use_spice(stove_id: StringName, spice_id: StringName) -> int:
	var spice := simulation.spices.get_definition(spice_id)
	last_service_result = simulation.buy_and_use_spice(stove_id, spice_id)
	if last_service_result == ServiceResult.OK:
		_float_over(stove_id, "-%s" % UiTheme.thousands(spice.price), FEEDBACK_SPEND, Vector2(0, 22))
	state_changed.emit()
	return last_service_result


## Tempero usado: o efeito sobe do fogão com um brilho.
func _on_spice_used(stove_id: StringName, spice: SpiceDefinition) -> void:
	var kitchen := simulation.kitchen
	var text := "%s!" % spice.display_name
	match spice.effect:
		SpiceDefinition.Effect.EXTRA_SERVINGS:
			text = "+%d porções" % (kitchen.stove_servings(stove_id) - kitchen.stove_recipe(stove_id).servings)
		SpiceDefinition.Effect.CUT_TIME:
			text = "Pronto!" if kitchen.stove_status(stove_id) == Kitchen.StoveStatus.READY \
				else "-%s" % WorldLayer.format_time(spice.amount)
		SpiceDefinition.Effect.INSTANT:
			text = "Pronto na hora!"
		SpiceDefinition.Effect.RECOVER:
			text = "Prato salvo!"
	_float_over(stove_id, text, FEEDBACK_GOOD)
	var placement := layout.get_placement(stove_id)
	if placement != null:
		FxParticles.gold_burst(particles, IsoProjection.cell_center(placement.origin) + SPICE_BURST_OFFSET)


## Serve a bebida ao cliente que tocou (DT-052): sai na hora, gastando energia. Recusa explica o motivo.
func serve_drink(customer: Customer) -> int:
	var drink := customer.drink
	var result := simulation.serve_drink(customer)
	if result == ServiceResult.OK:
		var at := IsoProjection.grid_point_to_world(Vector2(customer.seat_cell)) + Vector2(0, -70)
		FloatingText.spawn(effects, at, "-%d energia" % drink.energy_cost, FEEDBACK_XP)
		FloatingText.spawn(effects, at + Vector2(0, 22), "+%d XP" % drink.xp_reward, FEEDBACK_XP)
	else:
		last_service_result = result
	state_changed.emit()
	return result


func _on_payment_received(customer: Customer, amount: int) -> void:
	var at := IsoProjection.grid_point_to_world(Vector2(customer.seat_cell)) + Vector2(0, -70)
	FloatingText.spawn(effects, at, "+%d" % amount, FEEDBACK_GOLD)
	FxParticles.gold_burst(particles, at + Vector2(0, 20))


func _on_leveled_up(level: int) -> void:
	var unlocked: Array[String] = []
	for recipe in simulation.recipes.all():
		if recipe.unlock_level == level:
			unlocked.append(recipe.display_name)
	var text := "Nível %d!" % level
	var gold := simulation.progression.table.gold_for(level)
	if gold > 0:
		text += "  +%s de Café Ouro" % UiTheme.thousands(gold)
	if not unlocked.is_empty():
		text += "  Nova receita: %s" % ", ".join(unlocked)
	var machines: Array[String] = []
	for definition in simulation.furniture.all():
		if definition.category == FurnitureDefinition.Category.MACHINE and definition.min_level == level:
			machines.append(definition.display_name)
	if not machines.is_empty():
		text += "  Nova máquina na Loja: %s" % ", ".join(machines)
	EventBus.message_posted.emit(text)
	state_changed.emit()


## Estrela de domínio de uma receita (DT-053): aviso com o prêmio (já entregue).
func _on_recipe_mastered(recipe: RecipeDefinition, stars: int, reward: Dictionary) -> void:
	EventBus.message_posted.emit("Domínio de %s: estrela %d de %d!  +%s de Café Ouro e +%d XP" % [recipe.display_name, stars,
		simulation.mastery.config.max_stars(), UiTheme.thousands(reward["gold"]), reward["xp"]])


## Prato esquecido no fogão estragou (DT-055).
func _on_dish_spoiled(_stove_id: StringName, recipe: RecipeDefinition) -> void:
	EventBus.message_posted.emit(SPOILED_MESSAGE % recipe.display_name)


## Missão diária ou semanal concluída: aviso com a recompensa (já entregue).
func _on_board_mission_completed(board: MissionBoard, entry: MissionBoard.Entry) -> void:
	var rewards: Array[String] = []
	if entry.reward_gold > 0:
		rewards.append("+%s ouro" % UiTheme.thousands(entry.reward_gold))
	if entry.reward_xp > 0:
		rewards.append("+%d XP" % entry.reward_xp)
	var spice := MissionsPanel.spice_reward_text(simulation.spices, entry.mission)
	if not spice.is_empty():
		rewards.append(spice)
	var period := "diária" if board == simulation.daily_missions else "semanal"
	EventBus.message_posted.emit("Missão %s concluída: %s  %s" % [period, entry.title(), "  ".join(rewards)])
	state_changed.emit()


## Recompensa da missão: aviso no centro da tela (a próxima missão aparece no HUD).
func _on_mission_completed(mission: MissionDefinition) -> void:
	var rewards: Array[String] = []
	if mission.reward_gold > 0:
		rewards.append("+%d ouro" % mission.reward_gold)
	if mission.reward_xp > 0:
		rewards.append("+%d XP" % mission.reward_xp)
	var spice := MissionsPanel.spice_reward_text(simulation.spices, mission)
	if not spice.is_empty():
		rewards.append(spice)
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
## Constrói o terraço (DT-069); a barra já pediu confirmação.
## Manda o pedido de entrega (DT-071) com as porções dos balcões; o ouro sobe do Balcão de Entregas.
func send_delivery(index: int) -> int:
	var orders := simulation.delivery.orders
	var order: DeliveryBoard.Order = orders[index] if index >= 0 and index < orders.size() else null
	last_service_result = simulation.send_delivery(index)
	if last_service_result == ServiceResult.OK:
		_float_over(selected_id, "+%s ouro" % UiTheme.thousands(order.gold), FEEDBACK_GOLD)
		EventBus.message_posted.emit("Entrega enviada: %s ×%d! +%s ouro" % [order.recipe.display_name, order.servings,
			UiTheme.thousands(order.gold)])
	state_changed.emit()
	return last_service_result


func build_terrace() -> int:
	last_service_result = simulation.build_terrace()
	if last_service_result == ServiceResult.OK:
		EventBus.message_posted.emit(TERRACE_BUILT_MESSAGE % roundi(simulation.terrace_config.day_pay_bonus * 100))
	state_changed.emit()
	return last_service_result


func expand_cafe() -> int:
	last_service_result = simulation.expand()
	state_changed.emit()
	return last_service_result


func hire_waiter() -> int:
	last_service_result = simulation.hire_waiter()
	state_changed.emit()
	return last_service_result


## Oferece os pacotes de Café Ouro quando uma compra falha por falta de ouro (sem empilhar janelas).
func _offer_gold() -> void:
	if not is_inside_tree() or is_dialog_open() or _since_gold_offer < gold_offer_cooldown:
		return
	_since_gold_offer = 0.0
	hud.show_coin_shop(true)


func _on_coin_pack_chosen(pack_id: StringName) -> void:
	var pack := simulation.coin_shop.get_pack(pack_id)
	match simulation.coin_shop.buy(pack_id):
		CoinShop.Result.OK:
			hud.coin_dialog().hide()
			sound_board.play(&"coin")
			EventBus.message_posted.emit("Compra concluída: +%s Café Ouro" % UiTheme.thousands(pack.gold))
			_mark_dirty()
		CoinShop.Result.UNAVAILABLE:
			hud.show_coin_unavailable()
		_:
			pass  # cancelada ou recusada na loja: nada muda


func _on_waiter_hired(count: int) -> void:
	_mark_dirty()
	EventBus.message_posted.emit("Garçom contratado! Agora são %d na equipe." % count)


func _on_cafe_expanded(new_size: Vector2i) -> void:
	_fit_floor_and_camera()
	EventBus.message_posted.emit("Cafeteria ampliada para %d×%d!" % [new_size.x, new_size.y])


## Ajusta o piso e a câmera ao tamanho atual do grid.
func _fit_floor_and_camera() -> void:
	floor_view.grid_size = layout.grid.size
	floor_view.entrance = layout.entrance
	wall_view.grid_size = layout.grid.size
	exterior_view.grid_size = layout.grid.size
	exterior_view.entrance = layout.entrance
	front_view.grid_size = layout.grid.size
	front_view.entrance = layout.entrance
	floor_view.terrace = simulation.terrace_cells()  # o terraço acompanha a fileira da frente
	street_view.configure(layout.grid.size, layout.entrance, street_keep_clear())
	var headroom := maxf(furniture_headroom, wall_view.wall_height)
	var bounds := IsoProjection.grid_bounds(layout.grid.size).grow_individual(0.0, headroom, 0.0, 0.0)
	camera.set_bounds(bounds.grow(camera_margin))
	camera.frame(bounds, ui_top_inset, ui_bottom_inset)


## Pontos da calçada (vértices do grid) onde a rua não põe enfeite: o caminho da porta até a calçada,
## os lugares da fila e o caminho de quem desiste dela, a cada meio piso.
func street_keep_clear() -> Array[Vector2]:
	var center := Vector2(0.5, 0.5)  # o personagem usa o centro da célula; a cidade, os vértices
	var points: Array[Vector2] = []
	var door := Vector2(layout.entrance)
	_sample_path(points, door + center, door + WorldLayer.SIDEWALK_OFFSET + center)
	for i in simulation.config.queue_capacity:
		var spot := simulation.queue_spot(i) + center
		_sample_path(points, spot, spot + WorldLayer.QUEUE_WALK)
	return points


func _sample_path(points: Array[Vector2], from: Vector2, to: Vector2) -> void:
	var steps := maxi(ceili(from.distance_to(to) / 0.5), 1)
	for i in steps + 1:
		points.append(from.lerp(to, float(i) / steps))


## Piso e parede com os revestimentos aplicados (a base e o que foi pintado por cima).
func _apply_style() -> void:
	var surfaces := simulation.surfaces
	var style := simulation.style
	floor_view.floor_style = surfaces.get_definition(style.floor_id)
	wall_view.wall_style = surfaces.get_definition(style.wall_id)
	var floor_cells := {}
	var painted_floor := style.painted_floor()
	for cell: Vector2i in painted_floor:
		var surface := surfaces.get_definition(painted_floor[cell])
		if surface != null:
			floor_cells[cell] = surface
	floor_view.painted = floor_cells
	var wall_segments := {}
	var painted_walls := style.painted_walls()
	for wall_segment: String in painted_walls:
		var surface := surfaces.get_definition(painted_walls[wall_segment])
		if surface != null:
			wall_segments[wall_segment] = surface
	wall_view.painted = wall_segments
	front_view.wall_style = wall_view.wall_style
	front_view.painted = wall_segments
	var door := simulation.current_door()
	if door != null:
		front_view.door_base = door.sprite_base
	floor_view.terrace = simulation.terrace_cells()
	front_view.terrace = simulation.has_terrace()
	var hung := {}
	var items := style.hung_items()
	for wall_segment: String in items:
		var item := simulation.wall_items.get_definition(items[wall_segment])
		if item != null:
			hung[wall_segment] = item
	wall_view.items = hung


# --- Reforma (Mode.PAINT) ---------------------------------------------------------

## Começa a pendurar um item de parede (&"" = tirar enfeites): o jogador marca os trechos e confirma.
func start_hanging(item_id: StringName) -> bool:
	var item: WallItemDefinition = null
	if item_id != &"":
		item = simulation.wall_items.get_definition(item_id)
		if item == null:
			return false
		if item.min_level > simulation.progression.level:
			last_service_result = ServiceResult.FURNITURE_LOCKED
			state_changed.emit()
			return false
	if session != null:
		_end_session()
	clear_selection()
	painting = null
	hanging_items = true
	hanging = item
	paint_targets = []
	mode = Mode.PAINT
	last_service_result = ServiceResult.OK
	_show_paint_preview()
	state_changed.emit()
	return true

## Começa a reforma com um revestimento: o jogador marca pisos ou trechos de parede e confirma.
func start_painting(surface_id: StringName) -> bool:
	var definition := simulation.surfaces.get_definition(surface_id)
	if definition == null:
		return false
	if not simulation.style.owns(surface_id) and definition.min_level > simulation.progression.level:
		last_service_result = ServiceResult.SURFACE_LOCKED
		state_changed.emit()
		return false
	if session != null:
		_end_session()
	clear_selection()
	painting = definition
	hanging_items = false
	hanging = null
	paint_targets = []
	mode = Mode.PAINT
	last_service_result = ServiceResult.OK
	_show_paint_preview()
	state_changed.emit()
	return true


func is_painting_floor() -> bool:
	return painting != null and painting.kind == SurfaceDefinition.Kind.FLOOR


## Marca ou desmarca o piso (ou trecho de parede) tocado.
func toggle_paint_at(world_position: Vector2) -> void:
	var target: Variant
	if is_painting_floor():
		var cell := IsoProjection.world_to_cell(world_position)
		if not layout.grid.is_inside(cell):
			return
		target = cell
	else:
		var wall_segment := wall_view.segment_at(world_position)
		if wall_segment.is_empty() and not hanging_items:
			wall_segment = front_view.segment_at(world_position)
		if wall_segment.is_empty():
			return
		target = wall_segment
	if paint_targets.has(target):
		paint_targets.erase(target)
	else:
		paint_targets.append(target)
	_show_paint_preview()
	state_changed.emit()


## Marca tudo o que mudaria de revestimento.
func paint_all() -> void:
	paint_targets = []
	if is_painting_floor():
		for y in layout.grid.size.y:
			for x in layout.grid.size.x:
				paint_targets.append(Vector2i(x, y))
	elif hanging_items:
		paint_targets.append_array(simulation.item_segments())
	else:
		paint_targets.append_array(simulation.wall_segments())
	paint_targets = _changing_targets()
	_show_paint_preview()
	state_changed.emit()


func clear_paint() -> void:
	paint_targets = []
	_show_paint_preview()
	state_changed.emit()


## Quantos dos marcados realmente mudam (os que já têm o revestimento não contam nem custam).
func paint_target_count() -> int:
	return _changing_targets().size() if painting != null or hanging_items else 0


func paint_cost() -> int:
	if hanging_items:
		return (hanging.price if hanging != null else 0) * paint_target_count()
	return simulation.paint_price(painting) * paint_target_count() if painting != null else 0


## Nome do que está sendo aplicado (revestimento, item ou "tirar enfeites"), para a barra e os avisos.
func paint_subject() -> String:
	if hanging_items:
		return hanging.display_name if hanging != null else "Tirar enfeites"
	return painting.display_name if painting != null else ""


## Paga e pinta. Recusa (nível, ouro) mantém o modo e explica na barra.
func confirm_paint() -> int:
	if painting == null and not hanging_items:
		return ServiceResult.UNKNOWN_ITEM
	var cost := paint_cost()
	var count := paint_target_count()
	if hanging_items:
		var targets: Array[String] = []
		targets.assign(paint_targets)
		last_service_result = simulation.hang_items(hanging, targets)
		if last_service_result != ServiceResult.OK:
			sound_board.play(&"error")
			state_changed.emit()
			return last_service_result
		if count > 0:
			EventBus.message_posted.emit(("Pendurado: %s ×%d%s" % [hanging.display_name, count, " (-%d ouro)" % cost if cost > 0 else ""])
				if hanging != null else "Enfeites tirados: %d" % count)
		_end_paint()
		return last_service_result
	if is_painting_floor():
		var cells: Array[Vector2i] = []
		cells.assign(paint_targets)
		last_service_result = simulation.paint_floor(painting, cells)
	else:
		var segments: Array[String] = []
		segments.assign(paint_targets)
		last_service_result = simulation.paint_walls(painting, segments)
	if last_service_result != ServiceResult.OK:
		sound_board.play(&"error")
		state_changed.emit()
		return last_service_result
	if count > 0:
		EventBus.message_posted.emit("Reforma feita: %d %s com %s%s" % [count, "pisos" if is_painting_floor() else "trechos de parede",
			painting.display_name, " (-%d ouro)" % cost if cost > 0 else ""])
	_end_paint()
	return last_service_result


func cancel_paint() -> void:
	if mode == Mode.PAINT:
		_end_paint()


func _end_paint() -> void:
	painting = null
	hanging_items = false
	hanging = null
	paint_targets = []
	mode = Mode.VIEW
	floor_view.clear_paint_preview()
	wall_view.clear_paint_preview()
	wall_view.clear_item_preview()
	front_view.clear_paint_preview()
	state_changed.emit()


func _changing_targets() -> Array:
	if hanging_items:
		var wall_segments: Array[String] = []
		wall_segments.assign(paint_targets)
		return simulation.item_segments_to_change(hanging, wall_segments)
	if is_painting_floor():
		var cells: Array[Vector2i] = []
		cells.assign(paint_targets)
		return simulation.floor_cells_to_paint(painting, cells)
	var segments: Array[String] = []
	segments.assign(paint_targets)
	return simulation.wall_segments_to_paint(painting, segments)


func _show_paint_preview() -> void:
	var segments: Array[String] = []
	if hanging_items:
		segments.assign(paint_targets)
		wall_view.set_item_preview(hanging, segments)
		return
	if is_painting_floor():
		var cells: Array[Vector2i] = []
		cells.assign(paint_targets)
		floor_view.set_paint_preview(painting, cells)
		wall_view.clear_paint_preview()
		front_view.clear_paint_preview()
	else:
		segments.assign(paint_targets)
		wall_view.set_paint_preview(painting, segments)
		front_view.set_paint_preview(painting, segments)
		floor_view.clear_paint_preview()


## Compra (se preciso) e aplica um revestimento. A confirmação da compra fica na barra.
## Põe a porta escolhida na entrada (DT-067); comprar já pediu confirmação pela barra.
func use_door(door_id: StringName) -> int:
	var door: DoorDefinition = simulation.doors.get_definition(door_id)
	var buying := door != null and not simulation.style.owns(door_id) and door.price > 0
	last_service_result = simulation.use_door(door_id)
	if last_service_result == ServiceResult.OK and buying:
		EventBus.message_posted.emit("%s na entrada! -%d ouro" % [door.display_name, door.price])
	state_changed.emit()
	return last_service_result


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
	if world_layer.critic_star_hit(world_position):
		collect_critic_star()
		return
	var thirsty := world_layer.drink_customer_at(world_position)
	if thirsty != null:
		serve_drink(thirsty)
		return
	var tapped := layout.placement_at(IsoProjection.world_to_cell(world_position))
	if tapped != null and simulation.orchard.is_ripe(tapped.id):
		harvest_tree(tapped.id)
		return
	if tapped != null and simulation.attractions.gold(tapped.id) > 0:
		collect_attraction(tapped.id)
		return
	var cell := IsoProjection.world_to_cell(world_position)
	if tapped == null and simulation.dirt.has_spot(cell):
		clean_floor(cell)
		return
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
	if mode == Mode.PAINT:
		toggle_paint_at(world_position)
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
		KEY_P:
			toggle_pause()
			get_viewport().set_input_as_handled()
		KEY_F:
			toggle_closed()
			get_viewport().set_input_as_handled()
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
			elif mode == Mode.PAINT:
				cancel_paint()
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
