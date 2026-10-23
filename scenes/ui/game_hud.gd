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
const DAILY_TITLE := "PRESENTE DIÁRIO EM"
const DAILY_READY_TITLE := "PRESENTE DIÁRIO"
const DAILY_READY := "Receber!"
const PAUSE_TEXT := "JOGO PAUSADO: mexa à vontade. Toque em ▶ para continuar."
const CLOSED_TEXT := "CAFÉ FECHADO: ninguém novo entra. Toque na porta verde para abrir."
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
## Onde fica o contador de cupons: embaixo do ouro, ou embaixo da energia quando ela aparece.
const COUPON_PILL_BELOW_GOLD := Vector2(28, 62)
const COUPON_PILL_BELOW_ENERGY := Vector2(28, 98)
var _energy_button: Button
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
var _stars: Array[TextureRect] = []
var _daily_title: Label
var _daily_digits: Array[Label] = []
var _daily_boxes: Control
var _daily_ready: Label
var _daily_badge: Control
var _toast: Label
var _toast_time := 0.0
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
	_build_gold()
	_build_energy()
	_build_coupons()
	_build_xp()
	_build_daily_timer()
	_build_side_buttons()
	_build_medallions()
	_build_rating()
	_build_toast()
	_build_dialogs()
	EventBus.message_posted.connect(show_message)


# --- Montagem ------------------------------------------------------------------

## Um nó posicionado a partir de um canto (ou do meio de cima) da tela.
func _anchored(node: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> Control:
	node.anchor_left = anchor.x
	node.anchor_right = anchor.x
	node.anchor_top = anchor.y
	node.anchor_bottom = anchor.y
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.offset_right = offset.x + size.x
	node.offset_bottom = offset.y + size.y
	_root.add_child(node)
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


func _build_gold() -> void:
	var group := _anchored(_group("Gold"), Vector2.ZERO, Vector2(12, 12), Vector2(212, 46))
	var pill := Panel.new()
	pill.add_theme_stylebox_override("panel", UiTheme.pill_box())
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(group, pill, Vector2(16, 0), Vector2(180, 34))
	_place(group, UiTheme.art("icone_moeda", Vector2(46, 46)), Vector2(-6, -6))
	_gold_label = UiTheme.outlined("0", 22)
	_gold_label.name = "GoldValue"
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(group, _gold_label, Vector2(46, 0), Vector2(146, 34))
	# "+" verde no fim do contador: abre a vitrine de Café Ouro.
	var buy := Button.new()
	buy.name = "BuyGoldButton"
	buy.text = "+"
	buy.tooltip_text = "Comprar Café Ouro"
	buy.focus_mode = Control.FOCUS_NONE
	var green := Color("3cc04e")
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var box := UiTheme.button_box(green.lightened(0.1) if state == "hover" else green, Color("177a28"))
		box.set_corner_radius_all(15)
		box.content_margin_top = 0
		box.content_margin_bottom = 2
		buy.add_theme_stylebox_override(state, box)
	buy.add_theme_font_size_override("font_size", 24)
	buy.add_theme_color_override("font_outline_color", Color("177a28"))
	buy.add_theme_constant_override("outline_size", 4)
	buy.pressed.connect(func() -> void: show_coin_shop())
	_place(group, buy, Vector2(178, 2), Vector2(30, 30))


## Contador de energia logo abaixo do ouro: o raio, "7/10" e quanto falta para o próximo ponto.
func _build_energy() -> void:
	_energy_button = Button.new()
	_energy_button.name = "EnergyButton"
	_energy_button.focus_mode = Control.FOCUS_NONE
	_energy_button.tooltip_text = "Energia das máquinas de bebida"
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_energy_button.add_theme_stylebox_override(state, UiTheme.pill_box())
	_energy_button.pressed.connect(func() -> void: show_message(ENERGY_HELP))
	_anchored(_energy_button, Vector2.ZERO, Vector2(28, 62), Vector2(150, 30))
	_place(_energy_button, UiTheme.art("icone_energia", Vector2(40, 40)), Vector2(-18, -5))
	_energy_label = UiTheme.outlined("0/0", 19)
	_energy_label.name = "EnergyValue"
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_energy_button, _energy_label, Vector2(26, 0), Vector2(64, 30))
	_energy_next = UiTheme.outlined("", 13, Color("bfe3ff"), UiTheme.NAVY, 0)
	_energy_next.name = "EnergyNext"
	_energy_next.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energy_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(_energy_button, _energy_next, Vector2(86, 0), Vector2(56, 30))


## Contador de cupons (DT-061): aparece quando o jogador tem algum, embaixo da energia (ou do ouro).
func _build_coupons() -> void:
	_coupon_pill = Panel.new()
	_coupon_pill.name = "CouponPill"
	_coupon_pill.add_theme_stylebox_override("panel", UiTheme.pill_box())
	_coupon_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coupon_pill.tooltip_text = "Cupons do crítico: troque na Loja, aba Cupons"
	_anchored(_coupon_pill, Vector2.ZERO, COUPON_PILL_BELOW_GOLD, Vector2(110, 30))
	_place(_coupon_pill, UiTheme.art("icone_cupom", Vector2(40, 40)), Vector2(-18, -5))
	_coupon_label = UiTheme.outlined("0", 19)
	_coupon_label.name = "CouponValue"
	_coupon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_coupon_pill, _coupon_label, Vector2(26, 0), Vector2(80, 30))
	_coupon_pill.visible = false


func _refresh_coupons() -> void:
	var coupons := simulation.wallet.balance(Wallet.COUPONS)
	_coupon_pill.visible = coupons > 0
	_coupon_pill.position = COUPON_PILL_BELOW_ENERGY if _energy_button.visible else COUPON_PILL_BELOW_GOLD
	_coupon_label.text = UiTheme.thousands(coupons)


## Medalhão do evento (DT-063): aparece enquanto um evento vale, com os dias que faltam.
func _refresh_event() -> void:
	var event := simulation.current_event()
	_event_button.visible = event != null
	if event != null:
		var days := simulation.event_days_left()
		_event_days.text = "%dd" % days if days > 0 else "hoje"


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


func _build_xp() -> void:
	var group := _anchored(_group("Xp"), Vector2(0.5, 0.0), Vector2(-238, 8), Vector2(420, 60))
	_xp_bar = StripedBar.new()
	_xp_bar.name = "XpBar"
	_place(group, _xp_bar, Vector2(34, 10), Vector2(322, 26))
	_place(group, UiTheme.art("icone_estrela_chef", Vector2(68, 68)), Vector2(-12, -12))
	_level_label = UiTheme.outlined("1", 40, UiTheme.GOLD_TEXT, UiTheme.NAVY, 8)
	_level_label.name = "LevelValue"
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(group, _level_label, Vector2(352, -6), Vector2(72, 48))
	var caption := UiTheme.outlined("NÍVEL", 11, Color.WHITE, UiTheme.NAVY, 4)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(group, caption, Vector2(352, 38), Vector2(72, 16))
	var beauty := _anchored(_group("Beauty"), Vector2(0.5, 0.0), Vector2(202, 12), Vector2(150, 40))
	_beauty_bar = StripedBar.new()
	_beauty_bar.name = "BeautyBar"
	_beauty_bar.stripes = "listras_beleza"
	_beauty_bar.font_size = 14
	_place(beauty, _beauty_bar, Vector2(18, 8), Vector2(132, 22))
	_place(beauty, UiTheme.art("icone_flor", Vector2(42, 42)), Vector2(-9, -2))


func _build_daily_timer() -> void:
	var button := Button.new()
	button.name = "DailyButton"
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, UiTheme.pill_box(14))
	button.pressed.connect(func() -> void: daily_requested.emit())
	_anchored(button, Vector2(1.0, 0.0), Vector2(-226, 8), Vector2(214, 58))
	_place(button, UiTheme.art("icone_presente", Vector2(58, 58)), Vector2(-23, 1))
	_daily_title = UiTheme.outlined(DAILY_TITLE, 11, Color("bfe3ff"), UiTheme.NAVY, 0)
	_place(button, _daily_title, Vector2(42, 3), Vector2(166, 16))
	_daily_boxes = _group("Digits")
	_place(button, _daily_boxes, Vector2(42, 20), Vector2(166, 36))
	for i in 3:
		var box := Panel.new()
		var style := UiTheme.card_box(6, 0, UiTheme.TEXT)
		style.shadow_size = 0
		style.set_border_width_all(1)
		box.add_theme_stylebox_override("panel", style)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(_daily_boxes, box, Vector2(i * 56, 0), Vector2(44, 26))
		var digits := UiTheme.outlined("00", 19, UiTheme.TEXT, UiTheme.NAVY, 0)
		digits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place(box, digits, Vector2.ZERO, Vector2(44, 26))
		_daily_digits.append(digits)
		var unit := UiTheme.outlined(["H", "M", "S"][i], 9, Color("bfe3ff"), UiTheme.NAVY, 0)
		unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(_daily_boxes, unit, Vector2(i * 56, 25), Vector2(44, 12))
		if i < 2:
			_place(_daily_boxes, UiTheme.outlined(":", 18, Color.WHITE, UiTheme.NAVY, 0), Vector2(i * 56 + 46, 0), Vector2(10, 24))
	_daily_ready = UiTheme.outlined(DAILY_READY, 22, Color("8df06a"), UiTheme.NAVY, 6)
	_daily_ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(button, _daily_ready, Vector2(42, 18), Vector2(166, 34))


func _build_side_buttons() -> void:
	_pause_button = UiTheme.icon_button("PauseButton", "pause", "", 42)
	_pause_button.pressed.connect(func() -> void: pause_toggled.emit())
	_anchored(_pause_button, Vector2(1.0, 0.0), Vector2(-52, 80), Vector2(48, 46))
	_build_pause_banner()
	_closed_button = UiTheme.icon_button("ClosedButton", "door_close", "", 42)
	_closed_button.pressed.connect(func() -> void: closed_toggled.emit())
	_anchored(_closed_button, Vector2(1.0, 0.0), Vector2(-52, 132), Vector2(48, 46))
	_closed_banner = _banner("ClosedBanner", "ClosedText", CLOSED_TEXT, UiTheme.RED, -248)  # acima da faixa da pausa
	var zoom_in := UiTheme.icon_button("ZoomInButton", "zoom_in", "", 42)
	zoom_in.tooltip_text = "Aproximar"
	zoom_in.pressed.connect(func() -> void: zoom_requested.emit(ZOOM_STEP))
	_anchored(zoom_in, Vector2(1.0, 0.0), Vector2(-52, 180), Vector2(48, 46))
	var zoom_out := UiTheme.icon_button("ZoomOutButton", "zoom_out", "", 42)
	zoom_out.tooltip_text = "Afastar"
	zoom_out.pressed.connect(func() -> void: zoom_requested.emit(1.0 / ZOOM_STEP))
	_anchored(zoom_out, Vector2(1.0, 0.0), Vector2(-52, 228), Vector2(48, 46))
	_sound_button = UiTheme.icon_button("SoundButton", "sound", "", 42)
	_sound_button.pressed.connect(func() -> void: mute_toggled.emit(not _muted))
	_anchored(_sound_button, Vector2(1.0, 0.0), Vector2(-52, 276), Vector2(48, 46))
	_music_button = UiTheme.icon_button("MusicButton", "music", "", 42)
	_music_button.pressed.connect(func() -> void: music_toggled.emit(not _music_muted))
	_anchored(_music_button, Vector2(1.0, 0.0), Vector2(-52, 324), Vector2(48, 46))
	var settings := UiTheme.icon_button("RestartButton", "gear", "", 42)
	settings.tooltip_text = "Recomeçar o jogo"
	settings.pressed.connect(ask_restart)
	_anchored(settings, Vector2(1.0, 0.0), Vector2(-52, 372), Vector2(48, 46))
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
	banner.add_theme_stylebox_override("panel", UiTheme.card_box(14, 8))
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_anchored(banner, Vector2(0.5, 1.0), Vector2(-250, bottom_offset), Vector2(500, 0))
	var label := UiTheme.outlined(text, 17, color, Color(0, 0, 0, 0), 0)
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


func _medallion(button_name: String, art_name: String, label: String, center: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = label.capitalize()
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.pressed.connect(action)
	_anchored(button, Vector2.ZERO, center - Vector2(40, 34), Vector2(80, 86))
	_place(button, UiTheme.art("medalhao_" + art_name, Vector2(68, 68)), Vector2(6, 0))
	_place(button, UiTheme.art("fita_" + art_name, Vector2(110, 26)), Vector2(-15, 56))
	var text := UiTheme.outlined(label, 12, Color.WHITE, Color(0, 0, 0, 0.45), 3)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(button, text, Vector2(-15, 58), Vector2(110, 18))
	return button


func _build_medallions() -> void:
	_medallion("MissionsButton", "missoes", "MISSÕES", Vector2(46, 178), show_missions)
	var gift := _medallion("GiftButton", "presente", "PRESENTE", Vector2(46, 278), func() -> void: daily_requested.emit())
	_daily_badge = _badge("1")
	_place(gift, _daily_badge, Vector2(56, -4), Vector2(24, 24))
	_medallion("AchievementsButton", "conquistas", "CONQUISTAS", Vector2(46, 378), show_achievements)
	_event_button = _medallion("EventButton", "evento", "HALLOWEEN", Vector2(46, 478), func() -> void: event_requested.emit())
	_event_badge = _badge("")
	_place(_event_button, _event_badge, Vector2(50, -4), Vector2(36, 24))
	_event_days = _event_badge.get_child(0) as Label
	_event_days.name = "EventDays"
	_event_days.size = Vector2(36, 24)
	_event_button.visible = false
	_build_mission_card()


## Bolinha vermelha com um número (há algo esperando).
func _badge(text: String) -> Control:
	var badge := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e0303a")
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
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
	_mission_card.add_theme_stylebox_override("panel", UiTheme.card_box(12, 10))
	_anchored(_mission_card, Vector2.ZERO, Vector2(92, 140), Vector2(MISSION_CARD_WIDTH, 0))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 3)
	_mission_card.add_child(column)
	_mission_header = UiTheme.outlined("", 11, UiTheme.ORANGE, Color(0, 0, 0, 0), 0)
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
	_mission_bar.add_theme_stylebox_override("background", _bar_style(Color("dce8f7")))
	_mission_bar.add_theme_stylebox_override("fill", _bar_style(Color("3cc04e")))
	progress.add_child(_mission_bar)
	_mission_count = UiTheme.outlined("", 12, UiTheme.TEXT, Color(0, 0, 0, 0), 0)
	progress.add_child(_mission_count)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress.add_child(spacer)
	progress.add_child(UiTheme.art("icone_moeda", Vector2(20, 20)))
	_mission_reward = UiTheme.outlined("", 12, Color("e08a00"), Color(0, 0, 0, 0), 0)
	progress.add_child(_mission_reward)
	_mission_hint = UiTheme.outlined("", 13, UiTheme.TEXT_SOFT, Color(0, 0, 0, 0), 0)
	_mission_hint.name = "MissionHint"
	_mission_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_hint.custom_minimum_size = Vector2(MISSION_CARD_WIDTH - 24, 0)
	column.add_child(_mission_hint)


func _build_rating() -> void:
	var card := PanelContainer.new()
	card.name = "Rating"
	card.add_theme_stylebox_override("panel", UiTheme.card_box(12, 0))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchored(card, Vector2(0.0, 1.0), Vector2(12, -84), Vector2(196, 70))
	var inside := _group("Inside")
	card.add_child(inside)
	_place(inside, UiTheme.art("icone_sorriso", Vector2(40, 40)), Vector2(6, 7))
	_rating_label = UiTheme.outlined("0%", 22, UiTheme.TEXT, Color(0, 0, 0, 0), 0)
	_rating_label.name = "RatingValue"
	_place(inside, _rating_label, Vector2(52, 2), Vector2(70, 28))
	_place(inside, UiTheme.outlined("satisfeitos", 11, UiTheme.TEXT_SOFT, Color(0, 0, 0, 0), 0), Vector2(110, 10), Vector2(80, 16))
	for i in STARS:
		var star := UiTheme.art("icone_estrela", Vector2(18, 18))
		_place(inside, star, Vector2(52 + i * 17, 30))
		_stars.append(star)
	var strip := Panel.new()
	var strip_style := StyleBoxFlat.new()
	strip_style.bg_color = UiTheme.CARD_SOFT
	strip_style.set_corner_radius_all(8)
	strip.add_theme_stylebox_override("panel", strip_style)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(inside, strip, Vector2(8, 50), Vector2(180, 16))
	_name_button = Button.new()
	_name_button.name = "CafeNameButton"
	_name_button.flat = true
	_name_button.focus_mode = Control.FOCUS_NONE
	_name_button.tooltip_text = "Toque para trocar o nome"
	_name_button.clip_text = true
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_name_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_name_button.add_theme_font_size_override("font_size", 12)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_name_button.add_theme_color_override(color_name, Color("e0512a"))
	_name_button.add_theme_constant_override("outline_size", 0)
	_name_button.pressed.connect(func() -> void: ask_cafe_name(false))
	_place(inside, _name_button, Vector2(8, 47), Vector2(180, 22))


func _build_toast() -> void:
	_toast = Label.new()
	_toast.name = "Toast"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 20)
	_toast.add_theme_color_override("font_color", UiTheme.TEXT)
	var style := UiTheme.card_box(14, 10, UiTheme.BLUE)
	style.content_margin_left = 22
	style.content_margin_right = 22
	_toast.add_theme_stylebox_override("normal", style)
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_anchored(_toast, Vector2(0.5, 0.0), Vector2(0, 92), Vector2.ZERO)


func _build_dialogs() -> void:
	_build_achievements_dialog()
	_event_dialog = EventDialog.new()
	_add_dialog(_event_dialog)
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
	_add_dialog(_restart_dialog)


func _add_dialog(dialog: AcceptDialog) -> void:
	dialog.theme = UiTheme.theme()
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
		var label := Label.new()
		label.name = "Achievement_" + String(achievement.id)
		label.text = achievement_text(achievement)
		label.add_theme_font_size_override("font_size", 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_achievements_list.add_child(label)
	_achievements_dialog.popup_centered()


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
	_add_dialog(_name_dialog)


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
	_coin_note.custom_minimum_size = Vector2(560, 0)
	_coin_note.add_theme_font_size_override("font_size", 16)
	column.add_child(_coin_note)
	_coin_packs = HBoxContainer.new()
	_coin_packs.name = "CoinPacks"
	_coin_packs.add_theme_constant_override("separation", 8)
	column.add_child(_coin_packs)
	_coin_dialog.add_child(column)
	_add_dialog(_coin_dialog)
	_coin_info_dialog = AcceptDialog.new()
	_coin_info_dialog.name = "CoinInfoDialog"
	_coin_info_dialog.title = "Compra de Café Ouro"
	_coin_info_dialog.ok_button_text = "Entendi"
	_coin_info_dialog.dialog_autowrap = true
	_coin_info_dialog.dialog_text = COIN_UNAVAILABLE_TEXT
	_add_dialog(_coin_info_dialog)


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
	for pack in shop.packs():
		var chosen := pack.id
		var button := Button.new()
		button.name = "Pack_" + String(pack.id)
		var bonus := roundi((pack.gold_per_real() / cheapest - 1.0) * 100.0)
		button.text = "%s\n%s ouro\n%s%s" % [pack.display_name, UiTheme.thousands(pack.gold), pack.price_text(),
			"\n+%d%%" % bonus if bonus > 0 else "\n"]
		button.custom_minimum_size = Vector2(118, 120)
		button.focus_mode = Control.FOCUS_NONE
		var coin := ArtSprites.get_sprite("icone_moeda")
		if coin != null:
			button.icon = coin.texture
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.add_theme_constant_override("icon_max_width", 34)
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(func() -> void: coin_pack_chosen.emit(chosen))
		_coin_packs.add_child(button)
	_coin_dialog.popup_centered()


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
	_daily_days.add_theme_constant_override("separation", 6)
	_daily_dialog.add_child(_daily_days)
	_add_dialog(_daily_dialog)


## Mostra os dias da sequência, com o de hoje em destaque.
func show_daily_reward() -> void:
	for child in _daily_days.get_children():
		_daily_days.remove_child(child)
		child.queue_free()
	var days := simulation.daily.calendar.days
	var today := simulation.daily_day_number()
	for i in days.size():
		var card := PanelContainer.new()
		card.name = "Day%d" % (i + 1)
		card.custom_minimum_size = Vector2(96, 110)
		var style := UiTheme.card_box(10, 6)
		style.shadow_size = 0
		if i + 1 == today:
			style.bg_color = Color("fff6c2")
			style.border_color = Color("ffb400")
			style.set_border_width_all(3)
		card.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = "Dia %d\n%s" % [i + 1, reward_text(days[i])]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Largura fixa: sem ela o texto quebraria letra a letra e a janela cresceria.
		label.custom_minimum_size = Vector2(84, 0)
		label.add_theme_font_size_override("font_size", 14)
		if i + 1 < today:
			label.modulate = Color(1, 1, 1, 0.45)
		card.add_child(label)
		_daily_days.add_child(card)
	_daily_dialog.reset_size()
	_daily_dialog.popup_centered()
	_daily_dialog.get_ok_button().grab_focus()


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
	_beauty_bar.text = str(beauty)
	_beauty_bar.value = beauty / 100.0
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
