class_name GameHud
extends CanvasLayer
## Interface de cima e das laterais, no formato da v3 (o do jogo antigo, desenho nosso):
## - no alto à esquerda, o Café Ouro num contador escuro com a moeda;
## - no meio, a barra de XP listrada com a estrela do chef e o nível em número grande,
##   e a barra de beleza com a flor;
## - no alto à direita, o cronômetro do presente diário;
## - na lateral esquerda, os medalhões de Missões (com o cartão da missão atual),
##   Presente e Conquistas; na direita, botões quadrados de zoom e som;
## - embaixo à esquerda, a satisfação dos clientes (popularidade) e o nome da cafeteria;
## - um aviso no alto para mensagens curtas (subiu de nível, missão concluída...).
##
## Os nomes exibidos das moedas ficam aqui, na interface; o código do jogo
## usa ids neutros (ver docs/economy.md).

## O jogador confirmou que quer apagar o progresso e recomeçar.
signal restart_requested
## O jogador tocou em Receber na recompensa diária.
signal daily_claim_requested
## O jogador escolheu um nome (ainda não validado).
signal name_chosen(text: String)
## O jogador fechou a pergunta do nome sem escolher.
signal name_skipped
## O jogador tocou no botão de som. [param muted] é o novo estado.
signal mute_toggled(muted: bool)
## O jogador tocou no botão da música. [param muted] é o novo estado.
signal music_toggled(muted: bool)
## O jogador tocou no presente diário (medalhão ou cronômetro).
signal daily_requested
## O jogador tocou num botão de zoom: multiplica o zoom por [param factor].
signal zoom_requested(factor: float)
## O jogador tocou no botão de pausar (ou de continuar).
signal pause_toggled
## O jogador tocou no botão da porta: fechar (ou abrir) o café.
signal closed_toggled
## O jogador escolheu um pacote de Café Ouro na vitrine.
signal coin_pack_chosen(pack_id: StringName)
## O jogador tocou no medalhão do evento (DT-063).
signal event_requested

const SOFT_CURRENCY_NAME := "Café Ouro"
const COIN_UNAVAILABLE_TEXT := ("A compra de Café Ouro com dinheiro de verdade fica disponível quando o Café Manie estiver "
	+ "na Play Store. Nada foi cobrado.")
const TOAST_SECONDS := 2.8
## Tempo extra de aviso por caractere, para textos longos darem tempo de ler.
const TOAST_SECONDS_PER_CHAR := 0.05
const MISSION_CARD_WIDTH := 300.0
const ZOOM_STEP := 1.2
const STARS := 5
## Cartão do perfil e o círculo do retrato (DT-077).
const PROFILE_SIZE := Vector2(340, 86)
const AVATAR_SIZE := 70.0
const CITY_TEXT := "Nova York"
const RATING_CAPTION := "Popularidade do café"
## Menu lateral e botões quadrados da direita.
const SIDE_TILE_SIZE := Vector2(80, 80)
const SIDE_TILE_GAP := 10.0
const SIDE_TILES_TOP := 108.0
const SIDE_BUTTONS_TOP := 80.0
const SIDE_BUTTON_STEP := 54.0
const DAILY_TITLE := "PRESENTE DIÁRIO EM"
const DAILY_READY_TITLE := "PRESENTE DIÁRIO"
const DAILY_READY := "Receber!"
const PAUSE_TEXT := "JOGO PAUSADO: mexa à vontade. Toque em ▶ para continuar."
const CLOSED_TEXT := "CAFÉ FECHADO: ninguém novo entra. Toque na porta verde para abrir."
## Janelas (DT-079): o fundo escurecido atrás delas, numa camada acima do HUD e da barra (os avisos ficam por cima).
const OVERLAY_LAYER := 2
const DIM_COLOR := Color(0.016, 0.04, 0.09, 0.62)
## Onde fica o aviso: no alto; com uma janela aberta, embaixo (a janela cobriria o do alto).
const TOAST_TOP := 98.0
const TOAST_BOTTOM_WITH_DIALOG := -62.0
## Cartões do presente diário, dos pacotes de Café Ouro e o troféu das conquistas.
const DAY_CARD_SIZE := Vector2(104, 146)
const DAY_ICON_SIZE := 46.0
const COIN_PACK_SIZE := Vector2(132, 184)
const COIN_ART_MIN := 38.0
const COIN_ART_STEP := 7.0
const BEST_VALUE_TEXT := "Melhor valor"
const ACHIEVEMENT_ICON_SIZE := 48.0
const ENERGY_HELP := ("Energia: cada bebida gasta um pouco. Ela volta sozinha, 1 ponto por minuto, mesmo com o jogo "
	+ "fechado, e enche quando você sobe de nível. Toque no cliente com o balão verde para servir a bebida.")

var simulation: CafeSimulation

var _root: Control
var _name_button: Button
var _sound_button: Button
var _muted := false
var _music_button: Button
var _music_muted := false
var _pause_button: Button
var _pause_banner: PanelContainer
var _closed_button: Button
var _closed_banner: PanelContainer
var _name_dialog: ConfirmationDialog
var _name_edit: LineEdit
var _gold_label: Label
## Energia das máquinas de bebida (DT-052): aparece quando o café tem uma máquina.
var _energy_button: Button
## Retrato do chef no cartão do perfil (DT-077) e as peças que ele mostra agora.
var _profile_portrait: AvatarPortrait
var _portrait_layers: Array[String] = []
## Cronômetro do evento no alto à direita (DT-077).
var _event_timer: Button
var _event_timer_value: Label
var _coupon_pill: Control
var _event_button: Button
var _event_badge: Control
var _event_days: Label
var _event_dialog: EventDialog
var _avatar_dialog: AvatarDialog
var _city_dialog: CityDialog
var _coupon_label: Label
var _energy_label: Label
var _energy_next: Label
var _xp_bar: StripedBar
var _level_label: Label
var _beauty_bar: StripedBar
var _rating_label: Label
var _rating_card: Control
## Camada do menu lateral, dos botões da direita, da missão e da satisfação: some com a loja aberta (DT-077).
var _side_layer: Control
var _stars: Array[TextureRect] = []
var _daily_title: Label
var _daily_digits: Array[Label] = []
var _daily_boxes: Control
var _daily_ready: Label
var _daily_badge: Control
var _toast: Label
var _toast_time := 0.0
## Camada das janelas (DT-079): o fundo escurecido e, por cima, os avisos.
var _overlay: CanvasLayer
var _overlay_root: Control
var _dim: ColorRect
var _restart_dialog: ConfirmationDialog
var _achievements_dialog: AcceptDialog
var _missions_dialog: MissionsPanel
var _coin_dialog: AcceptDialog
var _shown_gold := -1
var _coin_info_dialog: AcceptDialog
var _coin_note: Label
var _coin_packs: HBoxContainer
var _daily_dialog: AcceptDialog
var _daily_days: HBoxContainer
var _achievements_list: VBoxContainer
## Avisos esperando a vez: um aviso nunca apaga o outro.
var _toast_queue: Array[String] = []
var _mission_card: PanelContainer
var _mission_header: Label
var _mission_title: Label
var _mission_bar: ProgressBar
var _mission_count: Label
var _mission_reward: Label
var _mission_hint: Label
## O jogador escondeu o cartão da missão (tocando nele)? Abrir as missões mostra de novo.
var _mission_collapsed := false


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.theme()
	add_child(_root)
	_build_profile()
	_build_currencies()
	_build_top_right()
	_side_layer = Control.new()
	_side_layer.name = "SideLayer"
	_side_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_side_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_side_layer)
	_build_side_buttons()
	_build_medallions()
	_build_rating()
	_build_overlay()
	_build_toast()
	_build_dialogs()
	EventBus.message_posted.connect(show_message)


# --- Montagem ------------------------------------------------------------------

## Um nó posicionado a partir de um canto (ou do meio de cima) da tela, em [param parent] (sem ele, na raiz).
func _anchored(node: Control, anchor: Vector2, offset: Vector2, size: Vector2, parent: Control = null) -> Control:
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.offset_right = offset.x + size.x
	node.offset_bottom = offset.y + size.y
	(parent if parent != null else _root).add_child(node)
	return node


func _place(parent: Control, child: Control, at: Vector2, size := Vector2.ZERO) -> Control:
	child.position = at
	if size != Vector2.ZERO:
		child.size = size
	parent.add_child(child)
	return child


func _group(group_name: String) -> Control:
	var group := Control.new()
	group.name = group_name
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return group


## Contadores no alto (DT-077): ouro com o "+" verde, energia (só com máquina), cupons (só com algum) e beleza,
## em pílulas de vidro escuro lado a lado. A fileira se arruma sozinha quando um contador aparece ou some.
func _build_currencies() -> void:
	var row := HBoxContainer.new()
	row.name = "Currencies"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	_anchored(row, Vector2.ZERO, Vector2(364, 16), Vector2(640, 42))
	row.add_child(_build_gold())
	row.add_child(_build_energy())
	row.add_child(_build_coupons())
	row.add_child(_build_beauty())


## Uma pílula do HUD com o ícone saindo pela esquerda.
func _pill(pill_name: String, icon: String, width: float) -> Control:
	var pill := Panel.new()
	pill.name = pill_name
	pill.custom_minimum_size = Vector2(width, 40)
	pill.add_theme_stylebox_override("panel", UiTheme.pill_box(20))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(pill, UiTheme.art(icon, Vector2(44, 44)), Vector2(-6, -2))
	return pill


func _build_gold() -> Control:
	var group := _pill("Gold", "icone_moeda", 188)
	_gold_label = UiTheme.outlined("0", 21, UiTheme.GOLD, UiTheme.NAVY, 3)
	_gold_label.name = "GoldValue"
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(group, _gold_label, Vector2(44, 0), Vector2(104, 40))
	# "+" verde no fim do contador: abre a vitrine de Café Ouro.
	var buy := Button.new()
	buy.name = "BuyGoldButton"
	buy.text = "+"
	buy.tooltip_text = "Comprar Café Ouro"
	buy.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var fill := UiTheme.GREEN.lightened(0.12) if state == "hover" else UiTheme.GREEN
		var box := UiTheme.button_box(fill, fill.lightened(0.3))
		box.set_corner_radius_all(14)
		box.content_margin_top = 0
		box.content_margin_bottom = 2
		buy.add_theme_stylebox_override(state, box)
	buy.add_theme_font_size_override("font_size", 22)
	buy.pressed.connect(func() -> void: show_coin_shop())
	_place(group, buy, Vector2(150, 5), Vector2(30, 30))
	return group


## Contador de energia: o raio, "7/10" e quanto falta para o próximo ponto. Tocar explica.
func _build_energy() -> Control:
	_energy_button = Button.new()
	_energy_button.name = "EnergyButton"
	_energy_button.focus_mode = Control.FOCUS_NONE
	_energy_button.tooltip_text = "Energia das máquinas de bebida"
	_energy_button.custom_minimum_size = Vector2(168, 40)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_energy_button.add_theme_stylebox_override(state, UiTheme.pill_box(20))
	_energy_button.pressed.connect(func() -> void: show_message(ENERGY_HELP))
	_place(_energy_button, UiTheme.art("icone_energia", Vector2(44, 44)), Vector2(-6, -2))
	_energy_label = UiTheme.outlined("0/0", 19, UiTheme.WHITE_SOFT, UiTheme.NAVY, 3)
	_energy_label.name = "EnergyValue"
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_energy_button, _energy_label, Vector2(44, 0), Vector2(64, 40))
	_energy_next = UiTheme.outlined("", 12, UiTheme.CYAN, UiTheme.NAVY, 0)
	_energy_next.name = "EnergyNext"
	_energy_next.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energy_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_energy_button, _energy_next, Vector2(100, 0), Vector2(58, 40))
	return _energy_button


## Contador de cupons (DT-061): aparece quando o jogador tem algum.
func _build_coupons() -> Control:
	_coupon_pill = _pill("CouponPill", "icone_cupom", 124)
	_coupon_pill.tooltip_text = "Cupons do crítico: troque na Loja, aba Cupons"
	_coupon_label = UiTheme.outlined("0", 19, UiTheme.WHITE_SOFT, UiTheme.NAVY, 3)
	_coupon_label.name = "CouponValue"
	_coupon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_coupon_pill, _coupon_label, Vector2(44, 0), Vector2(74, 40))
	_coupon_pill.visible = false
	return _coupon_pill


## Beleza do café: a flor e a barrinha rosa com o número.
func _build_beauty() -> Control:
	var group := _pill("Beauty", "icone_flor", 150)
	_beauty_bar = StripedBar.new()
	_beauty_bar.name = "BeautyBar"
	_beauty_bar.stripes = ""
	_beauty_bar.gradient = [Color("ff6fb5"), Color("ffa3d6")]
	_beauty_bar.font_size = 12
	_place(group, _beauty_bar, Vector2(42, 11), Vector2(98, 18))
	return group


func _refresh_coupons() -> void:
	var coupons := simulation.wallet.balance(Wallet.COUPONS)
	_coupon_pill.visible = coupons > 0
	_coupon_label.text = UiTheme.thousands(coupons)


## Medalhão do evento (DT-063): aparece enquanto um evento vale, com os dias que faltam.
func _refresh_event() -> void:
	var event := simulation.current_event()
	_event_button.visible = event != null
	_event_timer.visible = event != null
	if event != null:
		var days := simulation.event_days_left()
		_event_days.text = "%dd" % days if days > 0 else "hoje"
		var hours := floori(simulation.clock.seconds_to_next_local_day() / 3600.0)
		_event_timer_value.text = "%dd %02dh" % [days, hours] if days > 0 else "%dh restantes" % hours
		(_event_button.get_child(1) as Label).text = event.title.to_upper() if event.title.length() <= 11 else "EVENTO"


## Retrato do chef no perfil: só redesenha quando o jogador troca uma peça do avatar.
func _refresh_portrait() -> void:
	var shown := {}
	for slot: int in AvatarPartDefinition.Slot.values():
		var part := simulation.avatar_part(slot)
		if part == null:
			return
		shown[slot] = part
	var layers := AvatarPortrait.layer_names(shown)
	if layers != _portrait_layers:
		_portrait_layers = layers
		_profile_portrait.layers = layers


func is_event_visible() -> bool:
	return _event_button.visible


func event_dialog() -> EventDialog:
	return _event_dialog


func show_event() -> void:
	_event_dialog.simulation = simulation
	_event_dialog.show_event()


## Cupons que o contador mostra, ou -1 se ele está escondido (para os testes).
func shown_coupons() -> int:
	return int(_coupon_label.text.replace(".", "")) if _coupon_pill.visible else -1


## Cartão do perfil no alto à esquerda (DT-077): o retrato do chef (o avatar que o jogador montou) num círculo com
## aro ciano, o selo dourado do nível, o nome do café (toque para trocar), a cidade e a barra de XP.
func _build_profile() -> void:
	var card := Panel.new()
	card.name = "Profile"
	card.add_theme_stylebox_override("panel", UiTheme.glass_box(20, 0))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchored(card, Vector2.ZERO, Vector2(12, 10), PROFILE_SIZE)
	var ring := Panel.new()
	ring.name = "AvatarRing"
	var ring_style := UiTheme.bar_box(Color("13305a"), int(AVATAR_SIZE / 2.0))
	ring_style.border_color = UiTheme.CYAN
	ring_style.set_border_width_all(2)
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(card, ring, Vector2(8, 8), Vector2.ONE * AVATAR_SIZE)
	_profile_portrait = AvatarPortrait.new()
	_profile_portrait.name = "ChefPortrait"
	_profile_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(ring, _profile_portrait, Vector2(-9, -30), Vector2(AVATAR_SIZE + 18, AVATAR_SIZE * 1.52))
	var badge := Panel.new()
	badge.name = "LevelBadge"
	var badge_style := UiTheme.bar_box(UiTheme.NAVY_DEEP, 17)
	badge_style.border_color = UiTheme.GOLD
	badge_style.set_border_width_all(2)
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(card, badge, Vector2(2, 50), Vector2(34, 34))
	_level_label = UiTheme.outlined("1", 17, UiTheme.GOLD, UiTheme.NAVY, 3)
	_level_label.name = "LevelValue"
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(badge, _level_label, Vector2.ZERO, Vector2(34, 34))
	_name_button = Button.new()
	_name_button.name = "CafeNameButton"
	_name_button.flat = true
	_name_button.focus_mode = Control.FOCUS_NONE
	_name_button.tooltip_text = "Toque para trocar o nome"
	_name_button.clip_text = true
	_name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_left = 0
		_name_button.add_theme_stylebox_override(state, empty)
	_name_button.add_theme_font_size_override("font_size", 19)
	for color_name in ["font_color", "font_pressed_color", "font_focus_color"]:
		_name_button.add_theme_color_override(color_name, UiTheme.WHITE_SOFT)
	_name_button.add_theme_color_override("font_hover_color", UiTheme.CYAN)
	_name_button.add_theme_color_override("font_hover_pressed_color", UiTheme.CYAN)
	_name_button.pressed.connect(func() -> void: ask_cafe_name(false))
	_place(card, _name_button, Vector2(88, 6), Vector2(PROFILE_SIZE.x - 98, 28))
	var city := UiTheme.outlined(CITY_TEXT, 12, UiTheme.TEXT_SOFT, Color(0, 0, 0, 0), 0)
	city.name = "City"
	_place(card, city, Vector2(89, 33), Vector2(PROFILE_SIZE.x - 98, 16))
	_xp_bar = StripedBar.new()
	_xp_bar.name = "XpBar"
	_xp_bar.stripes = ""
	_xp_bar.gradient = [UiTheme.TECH_BLUE, UiTheme.CYAN]
	_xp_bar.font_size = 12
	_place(card, _xp_bar, Vector2(88, 56), Vector2(PROFILE_SIZE.x - 100, 20))


## No alto à direita: o presente diário com o cronômetro, o evento com os dias que faltam e a engrenagem.
func _build_top_right() -> void:
	var row := HBoxContainer.new()
	row.name = "TopRight"
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	_anchored(row, Vector2(1.0, 0.0), Vector2(-590, 10), Vector2(578, 56))
	row.add_child(_build_daily_timer())
	_event_timer = _top_panel("EventTimer", "medalhao_evento", "EVENTO ESPECIAL", func() -> void: event_requested.emit())
	_event_timer_value = UiTheme.outlined("", 20, UiTheme.WHITE_SOFT, UiTheme.NAVY, 3)
	_event_timer_value.name = "EventTimerValue"
	_place(_event_timer, _event_timer_value, Vector2(58, 22), Vector2(110, 26))
	_event_timer.custom_minimum_size = Vector2(176, 56)
	_event_timer.visible = false
	row.add_child(_event_timer)
	var settings := UiTheme.icon_button("RestartButton", "gear", "", 46)
	settings.tooltip_text = "Recomeçar o jogo"
	settings.pressed.connect(ask_restart)
	settings.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(settings)


## Painel do alto à direita: ícone, título pequeno e um valor embaixo.
func _top_panel(panel_name: String, icon: String, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = panel_name
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "focus"]:
		button.add_theme_stylebox_override(state, UiTheme.glass_box(16, 0))
	for state in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, UiTheme.glass_box(16, 0, UiTheme.CYAN, true))
	button.pressed.connect(action)
	_place(button, UiTheme.art(icon, Vector2(46, 46)), Vector2(6, 5))
	var caption := UiTheme.caption(title, UiTheme.TEXT_SOFT, 10)
	caption.name = "Caption"
	_place(button, caption, Vector2(58, 6), Vector2(130, 14))
	return button


func _build_daily_timer() -> Button:
	var button := _top_panel("DailyButton", "icone_presente", DAILY_TITLE, func() -> void: daily_requested.emit())
	button.custom_minimum_size = Vector2(204, 56)
	_daily_title = button.get_node("Caption") as Label
	_daily_boxes = _group("Digits")
	_place(button, _daily_boxes, Vector2(58, 22), Vector2(140, 28))
	for i in 3:
		var digits := UiTheme.outlined("00", 20, UiTheme.WHITE_SOFT, UiTheme.NAVY, 3)
		digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(_daily_boxes, digits, Vector2(i * 44, 0), Vector2(30, 26))
		_daily_digits.append(digits)
		if i < 2:
			_place(_daily_boxes, UiTheme.outlined(":", 18, UiTheme.CYAN, UiTheme.NAVY, 0), Vector2(i * 44 + 31, 0), Vector2(12, 24))
	_daily_ready = UiTheme.outlined(DAILY_READY, 21, UiTheme.GREEN, UiTheme.NAVY, 3)
	_place(button, _daily_ready, Vector2(58, 21), Vector2(140, 28))
	return button


## Botões quadrados da direita: pausa, porta, zoom, som e música (a engrenagem fica no alto, DT-077).
func _build_side_buttons() -> void:
	var y := SIDE_BUTTONS_TOP
	_pause_button = UiTheme.icon_button("PauseButton", "pause", "", 44)
	_pause_button.pressed.connect(func() -> void: pause_toggled.emit())
	_anchored(_pause_button, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	_build_pause_banner()
	y += SIDE_BUTTON_STEP
	_closed_button = UiTheme.icon_button("ClosedButton", "door_close", "", 44)
	_closed_button.pressed.connect(func() -> void: closed_toggled.emit())
	_anchored(_closed_button, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	_closed_banner = _banner("ClosedBanner", "ClosedText", CLOSED_TEXT, UiTheme.RED, -248)  # acima da faixa da pausa
	y += SIDE_BUTTON_STEP
	var zoom_in := UiTheme.icon_button("ZoomInButton", "zoom_in", "", 44)
	zoom_in.tooltip_text = "Aproximar"
	zoom_in.pressed.connect(func() -> void: zoom_requested.emit(ZOOM_STEP))
	_anchored(zoom_in, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	y += SIDE_BUTTON_STEP
	var zoom_out := UiTheme.icon_button("ZoomOutButton", "zoom_out", "", 44)
	zoom_out.tooltip_text = "Afastar"
	zoom_out.pressed.connect(func() -> void: zoom_requested.emit(1.0 / ZOOM_STEP))
	_anchored(zoom_out, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	y += SIDE_BUTTON_STEP
	_sound_button = UiTheme.icon_button("SoundButton", "sound", "", 44)
	_sound_button.pressed.connect(func() -> void: mute_toggled.emit(not _muted))
	_anchored(_sound_button, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	y += SIDE_BUTTON_STEP
	_music_button = UiTheme.icon_button("MusicButton", "music", "", 44)
	_music_button.pressed.connect(func() -> void: music_toggled.emit(not _music_muted))
	_anchored(_music_button, Vector2(1.0, 0.0), Vector2(-60, y), Vector2(50, 50), _side_layer)
	show_sound_state(false)
	show_music_state(false)
	show_pause_state(false)
	show_closed_state(false)


## Faixa no alto do salão enquanto o jogo está pausado.
func _build_pause_banner() -> void:
	_pause_banner = _banner("PauseBanner", "PauseText", PAUSE_TEXT, UiTheme.ORANGE, -196)  # acima da barra de baixo, longe dos avisos


## Faixa de aviso centrada, [param bottom_offset] pixels acima da borda de baixo da tela.
func _banner(banner_name: String, label_name: String, text: String, color: Color, bottom_offset: float) -> PanelContainer:
	var banner := PanelContainer.new()
	banner.name = banner_name
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiTheme.glass_box(14, 8, color)
	style.shadow_color = Color(color, 0.3)
	style.shadow_size = 10
	style.shadow_offset = Vector2.ZERO
	banner.add_theme_stylebox_override("panel", style)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_anchored(banner, Vector2(0.5, 1.0), Vector2(-260, bottom_offset), Vector2(520, 0))
	var label := UiTheme.outlined(text, 16, color.lightened(0.25), Color(0, 0, 0, 0), 0)
	label.name = label_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(label)
	return banner


## Botão de pausa vira "continuar" (e a faixa aparece) enquanto o jogo está pausado.
func show_pause_state(paused: bool) -> void:
	var sprite := ArtSprites.get_sprite("botao_play" if paused else "botao_pause")
	if sprite != null:
		_pause_button.icon = sprite.texture
	_pause_button.tooltip_text = "Continuar o jogo (P)" if paused else "Pausar o jogo (P)"
	_pause_banner.visible = paused


func is_pause_banner_visible() -> bool:
	return _pause_banner.visible


## Botão da porta: vermelho (fechar) com o café aberto, verde (abrir) com ele fechado; a faixa avisa (DT-051).
func show_closed_state(closed: bool) -> void:
	var sprite := ArtSprites.get_sprite("botao_door_open" if closed else "botao_door_close")
	if sprite != null:
		_closed_button.icon = sprite.texture
	_closed_button.tooltip_text = "Abrir o café (F)" if closed else "Fechar o café (F)"
	_closed_banner.visible = closed


func is_closed_banner_visible() -> bool:
	return _closed_banner.visible


## Bloco do menu lateral (DT-077): vidro escuro com o ícone em cima e o nome embaixo; brilho ciano ao passar.
func _side_tile(button_name: String, icon: String, label: String, top: float, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = label.capitalize()
	for state in ["normal", "focus"]:
		button.add_theme_stylebox_override(state, UiTheme.glass_box(16, 0))
	for state in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, UiTheme.glass_box(16, 0, UiTheme.CYAN, true))
	button.pressed.connect(action)
	_anchored(button, Vector2.ZERO, Vector2(12, top), SIDE_TILE_SIZE, _side_layer)
	_place(button, UiTheme.art(icon, Vector2(46, 46)), Vector2((SIDE_TILE_SIZE.x - 46) / 2.0, 6))
	var text := UiTheme.caption(label, UiTheme.WHITE_SOFT, 11)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(button, text, Vector2(0, SIDE_TILE_SIZE.y - 22), Vector2(SIDE_TILE_SIZE.x, 16))
	return button


func _build_medallions() -> void:
	var top := SIDE_TILES_TOP
	_side_tile("MissionsButton", "icone_prancheta", "Missões", top, show_missions)
	top += SIDE_TILE_SIZE.y + SIDE_TILE_GAP
	var gift := _side_tile("GiftButton", "icone_presente", "Presentes", top, func() -> void: daily_requested.emit())
	_daily_badge = _badge("1")
	_place(gift, _daily_badge, Vector2(SIDE_TILE_SIZE.x - 18, -6), Vector2(24, 24))
	top += SIDE_TILE_SIZE.y + SIDE_TILE_GAP
	_side_tile("AchievementsButton", "icone_trofeu", "Conquistas", top, show_achievements)
	top += SIDE_TILE_SIZE.y + SIDE_TILE_GAP
	_event_button = _side_tile("EventButton", "medalhao_evento", "Halloween", top, func() -> void: event_requested.emit())
	_event_badge = _badge("")
	_place(_event_button, _event_badge, Vector2(SIDE_TILE_SIZE.x - 30, -6), Vector2(36, 24))
	_event_days = _event_badge.get_child(0) as Label
	_event_days.name = "EventDays"
	_event_days.size = Vector2(36, 24)
	_event_button.visible = false
	_build_mission_card()


## Bolinha vermelha com um número (há algo esperando).
func _badge(text: String) -> Control:
	var badge := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiTheme.RED
	style.border_color = UiTheme.NAVY_DEEP
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(UiTheme.RED, 0.45)
	style.shadow_size = 4
	style.anti_aliasing = true
	badge.add_theme_stylebox_override("panel", style)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiTheme.outlined(text, 13, Color.WHITE, Color(0, 0, 0, 0), 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(badge, label, Vector2.ZERO, Vector2(24, 24))
	return badge


## Cartão da missão atual, ao lado do medalhão: as missões iniciais são o tutorial
## (seção 143), então a dica fica à vista. Tocar no cartão esconde; abrir as missões mostra de novo.
func _build_mission_card() -> void:
	_mission_card = PanelContainer.new()
	_mission_card.name = "MissionCard"
	_mission_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_mission_card.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_mission_collapsed = true
			_refresh_mission()
			_mission_card.accept_event())
	_mission_card.add_theme_stylebox_override("panel", UiTheme.glass_box(14, 12))
	_anchored(_mission_card, Vector2.ZERO, Vector2(12 + SIDE_TILE_SIZE.x + 10, SIDE_TILES_TOP), Vector2(MISSION_CARD_WIDTH, 0),
		_side_layer)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	_mission_card.add_child(column)
	_mission_header = UiTheme.caption("", UiTheme.CYAN, 11)
	_mission_header.name = "MissionHeader"
	column.add_child(_mission_header)
	_mission_title = UiTheme.outlined("", 16, UiTheme.TEXT, Color(0, 0, 0, 0), 0)
	_mission_title.name = "MissionTitle"
	_mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_title.custom_minimum_size = Vector2(MISSION_CARD_WIDTH - 24, 0)
	column.add_child(_mission_title)
	var progress := HBoxContainer.new()
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_theme_constant_override("separation", 6)
	column.add_child(progress)
	_mission_bar = ProgressBar.new()
	_mission_bar.show_percentage = false
	_mission_bar.custom_minimum_size = Vector2(150, 10)
	_mission_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mission_bar.max_value = 1.0
	_mission_bar.step = 0.001
	_mission_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mission_bar.add_theme_stylebox_override("background", _bar_style(Color(1, 1, 1, 0.1)))
	_mission_bar.add_theme_stylebox_override("fill", _bar_style(UiTheme.CYAN))  # progresso em ciano (DT-083)
	progress.add_child(_mission_bar)
	_mission_count = UiTheme.outlined("", 12, UiTheme.TEXT, Color(0, 0, 0, 0), 0)
	progress.add_child(_mission_count)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(spacer)
	progress.add_child(UiTheme.art("icone_moeda", Vector2(20, 20)))
	_mission_reward = UiTheme.outlined("", 12, UiTheme.GOLD, Color(0, 0, 0, 0), 0)
	progress.add_child(_mission_reward)
	_mission_hint = UiTheme.outlined("", 13, UiTheme.TEXT_SOFT, Color(0, 0, 0, 0), 0)
	_mission_hint.name = "MissionHint"
	_mission_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_hint.custom_minimum_size = Vector2(MISSION_CARD_WIDTH - 24, 0)
	column.add_child(_mission_hint)


## Satisfação dos clientes (DT-077): a carinha, o percentual, "Satisfeitos", as estrelas e o que ela mede.
func _build_rating() -> void:
	var card := Panel.new()
	card.name = "Rating"
	_rating_card = card
	card.add_theme_stylebox_override("panel", UiTheme.glass_box(18, 0))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchored(card, Vector2(0.0, 1.0), Vector2(12, -86), Vector2(196, 74), _side_layer)
	_place(card, UiTheme.art("icone_sorriso", Vector2(46, 46)), Vector2(7, 14))
	_rating_label = UiTheme.outlined("0%", 23, UiTheme.WHITE_SOFT, UiTheme.NAVY, 3)
	_rating_label.name = "RatingValue"
	_place(card, _rating_label, Vector2(58, 4), Vector2(62, 30))
	_place(card, UiTheme.outlined("Satisfeitos", 12, UiTheme.CYAN, Color(0, 0, 0, 0), 0), Vector2(116, 11), Vector2(78, 18))
	for i in STARS:
		var star := UiTheme.art("icone_estrela", Vector2(17, 17))
		_place(card, star, Vector2(58 + i * 18, 34))
		_stars.append(star)
	var caption := UiTheme.outlined(RATING_CAPTION, 11, UiTheme.TEXT_SOFT, Color(0, 0, 0, 0), 0)
	caption.name = "RatingCaption"
	_place(card, caption, Vector2(58, 53), Vector2(136, 16))


func _build_toast() -> void:
	_toast = Label.new()
	_toast.name = "Toast"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 19)
	_toast.add_theme_color_override("font_color", UiTheme.WHITE_SOFT)
	var style := UiTheme.glass_box(14, 10, UiTheme.CYAN, true)
	style.content_margin_left = 22
	style.content_margin_right = 22
	_toast.add_theme_stylebox_override("normal", style)
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_anchored(_toast, Vector2(0.5, 0.0), Vector2(0, TOAST_TOP), Vector2.ZERO, _overlay_root)


## Camada acima do HUD e da barra: o fundo escurecido das janelas e, por cima dele, os avisos (que continuam legíveis
## com uma janela aberta, como o "Novo visual!" do avatar).
func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.name = "Overlay"
	_overlay.layer = OVERLAY_LAYER
	add_child(_overlay)
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = DIM_COLOR
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	_overlay.add_child(_dim)
	_overlay_root = Control.new()
	_overlay_root.name = "OverlayRoot"
	_overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_root.theme = UiTheme.theme()
	_overlay.add_child(_overlay_root)


## Escurece o café atrás de uma janela aberta (DT-079), com um esmaecer suave ao entrar.
func set_dimmed(dimmed: bool) -> void:
	if dimmed == _dim.visible:
		return
	if dimmed:
		Juice.fade_in(_dim)
	_dim.visible = dimmed
	_toast.anchor_top = 1.0 if dimmed else 0.0
	_toast.anchor_bottom = _toast.anchor_top
	_toast.offset_top = TOAST_BOTTOM_WITH_DIALOG if dimmed else TOAST_TOP
	_toast.offset_bottom = _toast.offset_top


func is_dimmed() -> bool:
	return _dim.visible


func _build_dialogs() -> void:
	_build_achievements_dialog()
	_event_dialog = EventDialog.new()
	_add_dialog(_event_dialog, &"")  # o botão muda de papel a cada quadro (EventDialog)
	_avatar_dialog = AvatarDialog.new()
	_add_dialog(_avatar_dialog)
	_city_dialog = CityDialog.new()
	_add_dialog(_city_dialog)
	_missions_dialog = MissionsPanel.new()
	_add_dialog(_missions_dialog)
	_build_coin_dialogs()
	_build_daily_dialog()
	_build_name_dialog()
	_restart_dialog = ConfirmationDialog.new()
	_restart_dialog.name = "RestartDialog"
	_restart_dialog.title = "Recomeçar do zero?"
	_restart_dialog.dialog_text = "Isso apaga todo o seu progresso: móveis, Café Ouro, nível e o que está cozinhando."
	_restart_dialog.ok_button_text = "Apagar e recomeçar"
	_restart_dialog.cancel_button_text = "Cancelar"
	_restart_dialog.confirmed.connect(func() -> void: restart_requested.emit())
	_add_dialog(_restart_dialog, UiTheme.DANGER_BUTTON)


## Janela no padrão (DT-079): [param ok_role] é o papel do botão de OK (fantasma para Fechar, verde para receber e
## confirmar, vermelho para apagar, &"" para o azul principal).
func _add_dialog(dialog: AcceptDialog, ok_role := UiTheme.GHOST_BUTTON) -> void:
	dialog.theme = UiTheme.theme()
	UiTheme.style_dialog(dialog, ok_role)
	add_child(dialog)


func _build_achievements_dialog() -> void:
	_achievements_dialog = AcceptDialog.new()
	_achievements_dialog.name = "AchievementsDialog"
	_achievements_dialog.ok_button_text = "Fechar"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_achievements_dialog.add_child(scroll)
	_achievements_list = VBoxContainer.new()
	_achievements_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_achievements_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_achievements_list)
	_add_dialog(_achievements_dialog)


## Abre a lista de conquistas com o progresso de cada uma.
func show_achievements() -> void:
	for child in _achievements_list.get_children():
		_achievements_list.remove_child(child)
		child.queue_free()
	var tracker := simulation.achievements
	_achievements_dialog.title = "Conquistas (%d de %d)" % [tracker.unlocked_total(), tracker.tiers_total()]
	for achievement in tracker.achievements:
		_achievements_list.add_child(_achievement_card(achievement))
	_achievements_dialog.popup_centered()


## Cartão da conquista (DT-079): o troféu (apagado antes do primeiro degrau), o título já conquistado, uma estrela por
## degrau, o próximo degrau com a barra e o prêmio. A dica do cartão traz o texto completo (achievement_text).
func _achievement_card(achievement: AchievementDefinition) -> Control:
	var tiers := simulation.achievements.unlocked_tiers(achievement.id)
	var complete := tiers >= achievement.tier_count()
	var value := simulation.stats.value(achievement.stat)
	var card := PanelContainer.new()
	card.name = "Achievement_" + String(achievement.id)
	card.tooltip_text = achievement_text(achievement)
	card.add_theme_stylebox_override("panel", UiTheme.card_box(12, 10, UiTheme.GOLD if complete else UiTheme.CARD_EDGE))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var trophy := UiTheme.art("icone_trofeu", Vector2.ONE * ACHIEVEMENT_ICON_SIZE)
	trophy.modulate.a = 1.0 if tiers > 0 else 0.3
	row.add_child(trophy)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	row.add_child(column)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	column.add_child(head)
	var title := UiTheme.outlined("Ainda não conquistada" if tiers == 0 else achievement.tier_titles[tiers - 1], 17,
		UiTheme.GOLD if complete else (UiTheme.WHITE_SOFT if tiers > 0 else UiTheme.TEXT_SOFT), UiTheme.NAVY, 0)
	title.name = "Title"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	for i in achievement.tier_count():
		head.add_child(UiTheme.art("icone_estrela" if i < tiers else "icone_estrela_vazia", Vector2(18, 18)))
	var detail := Label.new()
	detail.name = "Detail"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_override("font", UiTheme.font(UiTheme.WEIGHT, true))
	detail.add_theme_font_size_override("font_size", 14)
	detail.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	column.add_child(detail)
	if complete:
		detail.text = "Completa! %d %s" % [value, achievement.description]
		return card
	var target: int = achievement.tier_targets[tiers]
	detail.text = "Próximo: %s — %d/%d %s" % [achievement.tier_titles[tiers], mini(value, target), target,
		achievement.description]
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation", 8)
	column.add_child(progress)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 8)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = target
	bar.value = mini(value, target)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(bar)
	progress.add_child(UiTheme.art("icone_moeda", Vector2(20, 20)))
	var reward := UiTheme.outlined("+%s" % UiTheme.thousands(achievement.tier_rewards[tiers]), 15, UiTheme.GOLD,
		UiTheme.NAVY, 0)
	reward.name = "Reward"
	progress.add_child(reward)
	return card


## Duas linhas: o título já conquistado (ou "Ainda não") e o próximo degrau.
func achievement_text(achievement: AchievementDefinition) -> String:
	var tiers := simulation.achievements.unlocked_tiers(achievement.id)
	var value := simulation.stats.value(achievement.stat)
	var done := "Ainda não conquistada" if tiers == 0 else achievement.tier_titles[tiers - 1]
	var first_line := "%s  (degrau %d de %d)" % [done, tiers, achievement.tier_count()]
	if tiers >= achievement.tier_count():
		return "%s\n    Completa! %d %s" % [first_line, value, achievement.description]
	var target: int = achievement.tier_targets[tiers]
	return "%s\n    Próximo: %s — %d/%d %s (+%d ouro)" % [first_line, achievement.tier_titles[tiers],
		mini(value, target), target, achievement.description, achievement.tier_rewards[tiers]]


func show_sound_state(muted: bool) -> void:
	_muted = muted
	var sprite := ArtSprites.get_sprite("botao_mute" if muted else "botao_sound")
	if sprite != null:
		_sound_button.icon = sprite.texture
	_sound_button.tooltip_text = sound_text()


## "Som: ligado" ou "Som: desligado" (o botão mostra só o símbolo; o texto vai na dica).
func sound_text() -> String:
	return "Som: desligado" if _muted else "Som: ligado"


func show_music_state(muted: bool) -> void:
	_music_muted = muted
	var sprite := ArtSprites.get_sprite("botao_music_off" if muted else "botao_music")
	if sprite != null:
		_music_button.icon = sprite.texture
	_music_button.tooltip_text = music_text()


## "Música: ligada" ou "Música: desligada".
func music_text() -> String:
	return "Música: desligada" if _music_muted else "Música: ligada"


func _build_name_dialog() -> void:
	_name_dialog = ConfirmationDialog.new()
	_name_dialog.name = "NameDialog"
	_name_dialog.title = "Sua cafeteria"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_name_dialog.add_child(column)
	var question := Label.new()
	question.text = "Como vai se chamar a sua cafeteria?"
	column.add_child(question)
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.max_length = CafeSimulation.CAFE_NAME_MAX
	_name_edit.placeholder_text = "Ex.: Café da Esquina"
	_name_edit.custom_minimum_size = Vector2(360, 44)
	_name_edit.text_changed.connect(func(text: String) -> void:
		_name_dialog.get_ok_button().disabled = CafeSimulation.clean_cafe_name(text).is_empty())
	_name_edit.text_submitted.connect(func(text: String) -> void:
		if not CafeSimulation.clean_cafe_name(text).is_empty():
			_name_dialog.hide()
			name_chosen.emit(text))
	column.add_child(_name_edit)
	var rules := Label.new()
	rules.text = "De %d a %d letras. Dá para trocar depois tocando no nome." % [CafeSimulation.CAFE_NAME_MIN, CafeSimulation.CAFE_NAME_MAX]
	rules.add_theme_font_size_override("font_size", 13)
	rules.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	column.add_child(rules)
	_name_dialog.confirmed.connect(func() -> void: name_chosen.emit(_name_edit.text))
	_name_dialog.canceled.connect(func() -> void: name_skipped.emit())
	_add_dialog(_name_dialog, UiTheme.SUCCESS_BUTTON)


## Pergunta o nome. Na primeira vez, o botão é "Abrir as portas".
func ask_cafe_name(first_time: bool) -> void:
	_name_edit.text = "" if first_time else simulation.cafe_name
	_name_dialog.ok_button_text = "Abrir as portas" if first_time else "Salvar"
	_name_dialog.cancel_button_text = "Depois" if first_time else "Cancelar"
	_name_dialog.get_ok_button().disabled = CafeSimulation.clean_cafe_name(_name_edit.text).is_empty()
	_name_dialog.popup_centered()
	_name_edit.grab_focus()


func name_dialog() -> ConfirmationDialog:
	return _name_dialog


func name_edit() -> LineEdit:
	return _name_edit


func _build_coin_dialogs() -> void:
	_coin_dialog = AcceptDialog.new()
	_coin_dialog.name = "CoinShopDialog"
	_coin_dialog.title = "Comprar Café Ouro"
	_coin_dialog.ok_button_text = "Fechar"
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_coin_note = Label.new()
	_coin_note.name = "CoinNote"
	_coin_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coin_note.custom_minimum_size = Vector2(COIN_PACK_SIZE.x * 5, 0)
	_coin_note.add_theme_font_size_override("font_size", 15)
	_coin_note.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	column.add_child(_coin_note)
	_coin_packs = HBoxContainer.new()
	_coin_packs.name = "CoinPacks"
	_coin_packs.add_theme_constant_override("separation", 10)
	column.add_child(_coin_packs)
	_coin_dialog.add_child(column)
	_add_dialog(_coin_dialog)
	_coin_info_dialog = AcceptDialog.new()
	_coin_info_dialog.name = "CoinInfoDialog"
	_coin_info_dialog.title = "Compra de Café Ouro"
	_coin_info_dialog.ok_button_text = "Entendi"
	_coin_info_dialog.dialog_autowrap = true
	_coin_info_dialog.dialog_text = COIN_UNAVAILABLE_TEXT
	_add_dialog(_coin_info_dialog, &"")


## Vitrine dos pacotes. [param short_of_gold]: aberta porque faltou ouro numa compra.
func show_coin_shop(short_of_gold := false) -> void:
	for child in _coin_packs.get_children():
		_coin_packs.remove_child(child)
		child.queue_free()
	var shop := simulation.coin_shop
	var note := "Faltou Café Ouro? Escolha um pacote:" if short_of_gold else "Escolha um pacote de Café Ouro:"
	if not shop.is_available():
		note += "\n(Por enquanto só dá para ver os pacotes: a compra é liberada quando o jogo estiver na Play Store.)"
	_coin_note.text = note
	var cheapest := shop.packs()[0].gold_per_real() if not shop.packs().is_empty() else 1.0
	var best := 0.0
	for pack in shop.packs():
		best = maxf(best, pack.gold_per_real())
	for i in shop.packs().size():
		var pack := shop.packs()[i]
		var bonus := roundi((pack.gold_per_real() / cheapest - 1.0) * 100.0)
		_coin_packs.add_child(_coin_pack_card(pack, i, bonus, bonus > 0 and is_equal_approx(pack.gold_per_real(), best)))
	_coin_dialog.popup_centered()


## Cartão de um pacote (DT-079): a pilha de moedas (maior nos pacotes maiores), o nome, o ouro em dourado, o preço e o
## selo do bônus; o de melhor valor ganha a borda dourada. O texto do botão (não desenhado) guarda tudo numa linha,
## para quem lê a tela sem a imagem e para os testes.
func _coin_pack_card(pack: CoinPack, index: int, bonus: int, best_value: bool) -> Button:
	var chosen := pack.id
	var button := Button.new()
	button.name = "Pack_" + String(pack.id)
	button.text = "%s\n%s ouro\n%s%s" % [pack.display_name, UiTheme.thousands(pack.gold), pack.price_text(),
		"\n+%d%%" % bonus if bonus > 0 else "\n"]
	button.clip_text = true
	button.custom_minimum_size = COIN_PACK_SIZE
	button.focus_mode = Control.FOCUS_NONE
	var edge := UiTheme.GOLD if best_value else UiTheme.CARD_EDGE
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var box := UiTheme.card_box(14, 0, UiTheme.CYAN if state.begins_with("hover") or state == "pressed" else edge)
		if best_value:
			box.set_border_width_all(2)
		button.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color",
			"font_disabled_color"]:
		button.add_theme_color_override(color_name, Color(0, 0, 0, 0))
	button.pressed.connect(func() -> void: coin_pack_chosen.emit(chosen))
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 8
	column.offset_bottom = -10
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(column)
	var ribbon := PanelContainer.new()
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ribbon.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ribbon_box := UiTheme.bar_box(UiTheme.GOLD if best_value else UiTheme.GREEN, 9)
	ribbon_box.content_margin_left = 10
	ribbon_box.content_margin_right = 10
	ribbon_box.content_margin_top = 1
	ribbon_box.content_margin_bottom = 1
	ribbon.add_theme_stylebox_override("panel", ribbon_box)
	ribbon.modulate.a = 1.0 if bonus > 0 else 0.0
	var ribbon_text := UiTheme.outlined((BEST_VALUE_TEXT + " · " if best_value else "") + "+%d%%" % bonus, 11,
		UiTheme.NAVY_DEEP, UiTheme.NAVY, 0)
	ribbon.add_child(ribbon_text)
	column.add_child(ribbon)
	var coin := UiTheme.art("icone_moeda", Vector2.ONE * (COIN_ART_MIN + COIN_ART_STEP * index))
	coin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(coin)
	for line: Array in [[pack.display_name, 13, UiTheme.WHITE_SOFT], [UiTheme.thousands(pack.gold), 24, UiTheme.GOLD],
			[pack.price_text(), 14, UiTheme.CYAN]]:
		var label := UiTheme.outlined(line[0], line[1], line[2], UiTheme.NAVY, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
	return button


## Explica que a compra com dinheiro de verdade ainda não existe neste build (nada foi cobrado).
func show_coin_unavailable() -> void:
	_coin_dialog.hide()
	_coin_info_dialog.popup_centered()


func coin_dialog() -> AcceptDialog:
	return _coin_dialog


func coin_info_dialog() -> AcceptDialog:
	return _coin_info_dialog


func _build_daily_dialog() -> void:
	_daily_dialog = AcceptDialog.new()
	_daily_dialog.name = "DailyDialog"
	_daily_dialog.title = "Recompensa diária"
	_daily_dialog.ok_button_text = "Receber"
	_daily_dialog.confirmed.connect(func() -> void: daily_claim_requested.emit())
	_daily_days = HBoxContainer.new()
	_daily_days.add_theme_constant_override("separation", 8)
	_daily_dialog.add_child(_daily_days)
	_add_dialog(_daily_dialog, UiTheme.SUCCESS_BUTTON)


## Mostra os dias da sequência, com o de hoje em destaque.
func show_daily_reward() -> void:
	for child in _daily_days.get_children():
		_daily_days.remove_child(child)
		child.queue_free()
	var days := simulation.daily.calendar.days
	var today := simulation.daily_day_number()
	for i in days.size():
		_daily_days.add_child(_day_card(i + 1, days[i], today))
	_daily_dialog.reset_size()
	_daily_dialog.popup_centered()
	_daily_dialog.get_ok_button().grab_focus()


## Cartão de um dia (DT-079): "Hoje" com a borda ciano e o brilho; os dias já recebidos apagados, com o visto.
func _day_card(day: int, reward: Dictionary, today: int) -> Control:
	var card := PanelContainer.new()
	card.name = "Day%d" % day
	card.custom_minimum_size = DAY_CARD_SIZE
	var style := UiTheme.card_box(12, 8, UiTheme.CYAN if day == today else UiTheme.CARD_EDGE)
	if day == today:
		style.set_border_width_all(2)
		style.bg_color = UiTheme.CARD_SOFT
		style.shadow_color = Color(UiTheme.CYAN, 0.4)
		style.shadow_size = 10
		style.shadow_offset = Vector2.ZERO
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var caption := UiTheme.caption("Hoje" if day == today else ("✓ Dia %d" % day if day < today else "Dia %d" % day),
		UiTheme.CYAN if day == today else (UiTheme.GREEN if day < today else UiTheme.TEXT_SOFT), 12)
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	var icon := TextureRect.new()
	icon.texture = _reward_art(reward)
	icon.custom_minimum_size = Vector2.ONE * DAY_ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	column.add_child(icon)
	var label := Label.new()
	label.name = "Reward"
	label.text = reward_text(reward)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Largura fixa: sem ela o texto quebraria letra a letra e a janela cresceria.
	label.custom_minimum_size = Vector2(DAY_CARD_SIZE.x - 16, 0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", UiTheme.GOLD if int(reward.get("gold", 0)) > 0 else UiTheme.WHITE_SOFT)
	column.add_child(label)
	if day < today:
		card.modulate.a = 0.5
	return card


## Desenho do prêmio do dia: o móvel ou o revestimento que vem de presente; senão a moeda, a estrela do XP ou o
## presente.
func _reward_art(reward: Dictionary) -> Texture2D:
	var furniture := simulation.furniture.get_definition(StringName(reward.get("furniture", &"")))
	var sprite: ArtSprites.Sprite = null
	if furniture != null:
		sprite = ArtSprites.furniture(furniture.id, 3)
	elif int(reward.get("gold", 0)) > 0:
		sprite = ArtSprites.get_sprite("icone_moeda")
	elif int(reward.get("xp", 0)) > 0:
		sprite = ArtSprites.get_sprite("icone_estrela")
	else:
		sprite = ArtSprites.get_sprite("icone_presente")
	return sprite.texture if sprite != null else null


## "50 ouro", "20 XP", "Vaso de flores"... (uma linha por parte da recompensa).
func reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if int(reward.get("gold", 0)) > 0:
		parts.append("%d ouro" % int(reward["gold"]))
	if int(reward.get("xp", 0)) > 0:
		parts.append("%d XP" % int(reward["xp"]))
	var furniture := simulation.furniture.get_definition(StringName(reward.get("furniture", &"")))
	if furniture != null:
		parts.append(furniture.display_name)
	var surface := simulation.surfaces.get_definition(StringName(reward.get("surface", &"")))
	if surface != null:
		parts.append(surface.display_name)
	var spice := simulation.spices.get_definition(StringName(reward.get("spice", &"")))
	if spice != null:
		parts.append("%d %s" % [int(reward.get("spice_amount", 1)), spice.display_name])
	return "\n".join(parts)


func daily_dialog() -> AcceptDialog:
	return _daily_dialog


func achievements_dialog() -> AcceptDialog:
	return _achievements_dialog


func missions_dialog() -> MissionsPanel:
	return _missions_dialog


## Abre a janela das missões (diárias, semanais e as do começo) e volta a mostrar o cartão do tutorial.
## Com outra janela aberta, não abre (uma pergunta por vez).
func avatar_dialog() -> AvatarDialog:
	return _avatar_dialog


## Abre o avatar do chef (DT-070), se nenhuma outra janela estiver aberta.
func show_avatar() -> void:
	for dialog: Window in find_children("*", "Window", true, false):
		if dialog.visible and dialog != _avatar_dialog:
			return
	_avatar_dialog.show_for(simulation)


func city_dialog() -> CityDialog:
	return _city_dialog


## Abre a janela da cidade (DT-072), se nenhuma outra janela estiver aberta.
func show_city() -> void:
	for dialog: Window in find_children("*", "Window", true, false):
		if dialog.visible and dialog != _city_dialog:
			return
	_city_dialog.show_for(simulation)


func show_missions() -> void:
	_mission_collapsed = false
	_refresh_mission()
	for dialog: Window in find_children("*", "Window", true, false):
		if dialog.visible and dialog != _missions_dialog:
			return
	_missions_dialog.show_for(simulation)


func ask_restart() -> void:
	_restart_dialog.popup_centered()
	# O botão já selecionado é o seguro: um Enter sem querer não apaga nada.
	_restart_dialog.get_cancel_button().grab_focus()


func restart_dialog() -> ConfirmationDialog:
	return _restart_dialog


## Loja aberta (DT-077): o painel dela ocupa a tela, então o menu lateral, os botões da direita, a missão e a
## satisfação saem e voltam quando ela fecha. O perfil e os contadores ficam.
func set_shop_open(open: bool) -> void:
	_side_layer.visible = not open


func is_rating_visible() -> bool:
	return _rating_card.is_visible_in_tree()


func bind(target: CafeSimulation) -> void:
	simulation = target
	refresh()


func _process(delta: float) -> void:
	refresh()
	if _toast.visible:
		_toast_time -= delta
		if _toast_time <= 0.0:
			_toast.visible = false
			if not _toast_queue.is_empty():
				_show_now(_toast_queue.pop_front())


func refresh() -> void:
	if simulation == null:
		return
	var progression := simulation.progression
	_name_button.text = simulation.cafe_name
	_name_button.visible = not simulation.cafe_name.is_empty()
	_level_label.text = str(progression.level)
	_xp_bar.value = progression.level_progress()
	_xp_bar.text = _xp_text()
	var gold := simulation.wallet.balance(Wallet.SOFT)
	if gold > _shown_gold and _shown_gold >= 0:
		Juice.bump(_gold_label)  # ouro entrando: o número quica
	_shown_gold = gold
	_gold_label.text = UiTheme.thousands(gold)
	var popularity := roundi(simulation.popularity)
	_rating_label.text = "%d%%" % popularity
	var lit := roundi(simulation.popularity / 100.0 * STARS)
	for i in _stars.size():
		var sprite := ArtSprites.get_sprite("icone_estrela" if i < lit else "icone_estrela_vazia")
		if sprite != null and _stars[i].texture != sprite.texture:
			_stars[i].texture = sprite.texture
	var beauty := simulation.beauty()
	_beauty_bar.text = "Beleza %d" % beauty
	_beauty_bar.value = beauty / 100.0
	_refresh_portrait()
	_refresh_energy()
	_refresh_coupons()
	_refresh_event()
	_refresh_daily()
	_refresh_mission()


func _xp_text() -> String:
	var progression := simulation.progression
	if progression.is_max_level():
		return "%s XP (nível máximo)" % UiTheme.thousands(progression.xp)
	return "%s / %s XP" % [UiTheme.thousands(progression.xp), UiTheme.thousands(progression.table.xp_for_next(progression.level))]


func _refresh_energy() -> void:
	_energy_button.visible = simulation.has_drink_machine()
	if not _energy_button.visible:
		return
	var now := simulation.clock.now()
	var energy := simulation.energy
	_energy_label.text = "%d/%d" % [energy.amount(now), energy.maximum()]
	var left := ceili(energy.seconds_to_next(now))
	_energy_next.text = "" if left <= 0 else "+1 %d:%02d" % [left / 60, left % 60]


## Texto do contador de energia ("7/10") e da recarga ("+1 0:42", vazio com ela cheia), para os testes.
func energy_texts() -> Array[String]:
	return [_energy_label.text, _energy_next.text] as Array[String]


func is_energy_visible() -> bool:
	return _energy_button.visible


func _refresh_daily() -> void:
	var ready := simulation.can_claim_daily()
	_daily_badge.visible = ready
	_daily_ready.visible = ready
	_daily_boxes.visible = not ready
	_daily_title.text = DAILY_READY_TITLE if ready else DAILY_TITLE
	if not ready:
		var left := ceili(simulation.seconds_until_daily())
		var parts := [left / 3600, (left % 3600) / 60, left % 60]
		for i in 3:
			_daily_digits[i].text = "%02d" % parts[i]


func _refresh_mission() -> void:
	var missions := simulation.missions
	var mission := missions.current()
	_mission_card.visible = mission != null and not _mission_collapsed
	if mission == null:
		return
	var progress := mini(missions.progress(), mission.target)
	_mission_header.text = "MISSÃO %d DE %d" % [missions.completed_count() + 1, missions.missions.size()]
	_mission_title.text = mission.title
	_mission_bar.value = float(progress) / mission.target
	_mission_count.text = "%d/%d" % [progress, mission.target]
	_mission_reward.text = "+%d" % mission.reward_gold
	_mission_hint.text = mission.hint
	_mission_card.reset_size()


## Mostra um aviso. Se já houver um na tela, este espera a vez.
func show_message(text: String) -> void:
	if _toast.visible:
		_toast_queue.append(text)
	else:
		_show_now(text)


func _show_now(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.reset_size()
	_toast.position.x = (_root.size.x - _toast.size.x) / 2.0
	_toast_time = TOAST_SECONDS + text.length() * TOAST_SECONDS_PER_CHAR
	Juice.pop_in(_toast)


## Avisos esperando a vez (para testes).
func queued_messages() -> Array[String]:
	return _toast_queue.duplicate()


func toast_text() -> String:
	return _toast.text if _toast.visible else ""


## Texto da missão atual (vazio quando não há missão ativa), mesmo com o cartão escondido.
func mission_text() -> String:
	var mission := simulation.missions.current() if simulation != null else null
	if mission == null:
		return ""
	var missions := simulation.missions
	return "Missão %d/%d: %s  (%d/%d)\n%s" % [missions.completed_count() + 1, missions.missions.size(), mission.title,
		mini(missions.progress(), mission.target), mission.target, mission.hint]


## Resumo do que a interface mostra, em texto: nível, XP, ouro, popularidade e beleza.
func stats_text() -> String:
	if simulation == null:
		return ""
	var progression := simulation.progression
	var xp := "%d XP (nível máximo)" % progression.xp if progression.is_max_level() \
		else "%d / %d XP" % [progression.xp, progression.table.xp_for_next(progression.level)]
	return "Nível %d | %s | %s: %d | Popularidade: %d%% | Beleza: %d" % [progression.level, xp, SOFT_CURRENCY_NAME,
		simulation.wallet.balance(Wallet.SOFT), roundi(simulation.popularity), simulation.beauty()]


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style
