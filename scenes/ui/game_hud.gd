class_name GameHud
extends CanvasLayer
## PLACEHOLDER_HUD: painel de cima com nível, XP, Café Ouro e popularidade,
## cartão da missão atual (canto direito), e um aviso central para mensagens
## curtas (subiu de nível, missão concluída, ação recusada).
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

const SOFT_CURRENCY_NAME := "Café Ouro"
const HINT := "Arraste para mover  •  Roda do mouse ou pinça para zoom  •  Toque num fogão para cozinhar"
const TOAST_SECONDS := 2.8
## Tempo extra de aviso por caractere, para textos longos darem tempo de ler.
const TOAST_SECONDS_PER_CHAR := 0.05
const MISSION_CARD_WIDTH := 330.0
const XP_BAR_BACKGROUND := Color(1, 1, 1, 0.18)
const XP_BAR_FILL := Color("8fd3ff")

var simulation: CafeSimulation

var _name_button: Button
var _sound_button: Button
var _muted := false
var _name_dialog: ConfirmationDialog
var _name_edit: LineEdit
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _gold_label: Label
var _popularity_label: Label
var _beauty_label: Label
var _toast: Label
var _toast_time := 0.0
var _restart_dialog: ConfirmationDialog
var _achievements_dialog: AcceptDialog
var _daily_dialog: AcceptDialog
var _daily_days: HBoxContainer
var _achievements_list: VBoxContainer
## Avisos esperando a vez: um aviso nunca apaga o outro.
var _toast_queue: Array[String] = []
var _mission_card: PanelContainer
var _mission_title: Label
var _mission_hint: Label


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "top", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.05, 0.8)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	_name_button = Button.new()
	_name_button.name = "CafeNameButton"
	_name_button.flat = true
	_name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_button.add_theme_font_size_override("font_size", 22)
	_name_button.add_theme_color_override("font_color", Color("ffd35c"))
	_name_button.focus_mode = Control.FOCUS_NONE
	_name_button.tooltip_text = "Toque para trocar o nome"
	_name_button.pressed.connect(func() -> void: ask_cafe_name(false))
	column.add_child(_name_button)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 20)
	column.add_child(stats)

	_level_label = _stat_label(stats, "Level")
	var xp_box := VBoxContainer.new()
	xp_box.add_theme_constant_override("separation", 0)
	stats.add_child(xp_box)
	_xp_bar = ProgressBar.new()
	_xp_bar.name = "XpBar"
	_xp_bar.custom_minimum_size = Vector2(140, 12)
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 1.0
	_xp_bar.step = 0.001
	_xp_bar.add_theme_stylebox_override("background", _bar_style(XP_BAR_BACKGROUND))
	_xp_bar.add_theme_stylebox_override("fill", _bar_style(XP_BAR_FILL))
	xp_box.add_child(_xp_bar)
	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 12)
	_xp_label.modulate = Color(1, 1, 1, 0.75)
	xp_box.add_child(_xp_label)
	_gold_label = _stat_label(stats, "Gold")
	_popularity_label = _stat_label(stats, "Popularity")
	_beauty_label = _stat_label(stats, "Beauty")

	var hint := Label.new()
	hint.text = HINT
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.65)
	column.add_child(hint)

	_toast = Label.new()
	_toast.name = "Toast"
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.position.y = 120
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 22)
	var toast_style := StyleBoxFlat.new()
	toast_style.bg_color = Color(0.1, 0.07, 0.05, 0.88)
	toast_style.set_corner_radius_all(12)
	toast_style.content_margin_left = 20
	toast_style.content_margin_right = 20
	toast_style.content_margin_top = 10
	toast_style.content_margin_bottom = 10
	_toast.add_theme_stylebox_override("normal", toast_style)
	_toast.visible = false
	add_child(_toast)

	_build_restart_controls()
	EventBus.message_posted.connect(show_message)


## Botão "Recomeçar" no canto de cima, sempre com confirmação: apagar progresso
## não pode acontecer por um toque acidental (mesmo princípio da seção 32).
func _build_restart_controls() -> void:
	var corner := MarginContainer.new()
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.add_theme_constant_override("margin_top", 16)
	corner.add_theme_constant_override("margin_right", 16)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 10)
	corner.add_child(column)
	var button := Button.new()
	button.name = "RestartButton"
	button.text = "Recomeçar"
	button.custom_minimum_size = Vector2(120, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(ask_restart)
	var buttons := HBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_END
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	var achievements := Button.new()
	achievements.name = "AchievementsButton"
	achievements.text = "Conquistas"
	achievements.custom_minimum_size = Vector2(120, 44)
	achievements.focus_mode = Control.FOCUS_NONE
	achievements.pressed.connect(show_achievements)
	buttons.add_child(achievements)
	_sound_button = Button.new()
	_sound_button.name = "SoundButton"
	_sound_button.custom_minimum_size = Vector2(150, 44)
	_sound_button.focus_mode = Control.FOCUS_NONE
	_sound_button.pressed.connect(func() -> void: mute_toggled.emit(not _muted))
	buttons.add_child(_sound_button)
	buttons.add_child(button)
	show_sound_state(false)
	_build_achievements_dialog()
	_build_daily_dialog()
	_build_name_dialog()
	_build_mission_card(column)

	_restart_dialog = ConfirmationDialog.new()
	_restart_dialog.name = "RestartDialog"
	_restart_dialog.title = "Recomeçar do zero?"
	_restart_dialog.dialog_text = "Isso apaga todo o seu progresso: móveis, Café Ouro, nível e o que está cozinhando."
	_restart_dialog.ok_button_text = "Apagar e recomeçar"
	_restart_dialog.cancel_button_text = "Cancelar"
	_restart_dialog.confirmed.connect(func() -> void: restart_requested.emit())
	add_child(_restart_dialog)


## Cartão da missão atual: as missões iniciais são o tutorial (seção 143),
## então a dica fica sempre à vista.
func _build_mission_card(parent: Control) -> void:
	_mission_card = PanelContainer.new()
	_mission_card.name = "MissionCard"
	_mission_card.custom_minimum_size = Vector2(MISSION_CARD_WIDTH, 0)
	_mission_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.05, 0.8)
	style.border_color = Color("ffd35c")
	style.border_width_left = 4
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	_mission_card.add_theme_stylebox_override("panel", style)
	parent.add_child(_mission_card)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	_mission_card.add_child(column)
	_mission_title = Label.new()
	_mission_title.name = "MissionTitle"
	_mission_title.add_theme_font_size_override("font_size", 17)
	_mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mission_title)
	_mission_hint = Label.new()
	_mission_hint.name = "MissionHint"
	_mission_hint.add_theme_font_size_override("font_size", 14)
	_mission_hint.modulate = Color(1, 1, 1, 0.75)
	_mission_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_mission_hint)


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
	add_child(_achievements_dialog)


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
	_sound_button.text = "Som: desligado" if muted else "Som: ligado"


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
	rules.modulate = Color(1, 1, 1, 0.7)
	column.add_child(rules)
	_name_dialog.confirmed.connect(func() -> void: name_chosen.emit(_name_edit.text))
	_name_dialog.canceled.connect(func() -> void: name_skipped.emit())
	add_child(_name_dialog)


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


func _build_daily_dialog() -> void:
	_daily_dialog = AcceptDialog.new()
	_daily_dialog.name = "DailyDialog"
	_daily_dialog.title = "Recompensa diária"
	_daily_dialog.ok_button_text = "Receber"
	_daily_dialog.confirmed.connect(func() -> void: daily_claim_requested.emit())
	_daily_days = HBoxContainer.new()
	_daily_days.add_theme_constant_override("separation", 6)
	_daily_dialog.add_child(_daily_days)
	add_child(_daily_dialog)


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
		card.custom_minimum_size = Vector2(96, 96)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_content_margin_all(6)
		style.bg_color = Color(1, 1, 1, 0.08)
		if i + 1 == today:
			style.bg_color = Color("ffd35c", 0.25)
			style.border_color = Color("ffd35c")
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
	return "\n".join(parts)


func daily_dialog() -> AcceptDialog:
	return _daily_dialog


func achievements_dialog() -> AcceptDialog:
	return _achievements_dialog


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
	_level_label.text = "Nível %d" % progression.level
	_xp_bar.value = progression.level_progress()
	if progression.is_max_level():
		_xp_label.text = "%d XP (nível máximo)" % progression.xp
	else:
		_xp_label.text = "%d / %d XP" % [progression.xp, progression.table.xp_for_next(progression.level)]
	_gold_label.text = "%s: %d" % [SOFT_CURRENCY_NAME, simulation.wallet.balance(Wallet.SOFT)]
	_popularity_label.text = "Popularidade: %d%%" % roundi(simulation.popularity)
	_beauty_label.text = "Beleza: %d" % simulation.beauty()
	_refresh_mission()


func _refresh_mission() -> void:
	var missions := simulation.missions
	var mission := missions.current()
	_mission_card.visible = mission != null
	if mission == null:
		return
	var progress := mini(missions.progress(), mission.target)
	_mission_title.text = "Missão %d/%d: %s  (%d/%d)" % [
		missions.completed_count() + 1, missions.missions.size(), mission.title, progress, mission.target]
	_mission_hint.text = mission.hint


## Mostra um aviso. Se já houver um na tela, este espera a vez.
func show_message(text: String) -> void:
	if _toast.visible:
		_toast_queue.append(text)
	else:
		_show_now(text)


func _show_now(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_time = TOAST_SECONDS + text.length() * TOAST_SECONDS_PER_CHAR


## Avisos esperando a vez (para testes).
func queued_messages() -> Array[String]:
	return _toast_queue.duplicate()


func toast_text() -> String:
	return _toast.text if _toast.visible else ""


## Texto do cartão de missão (vazio quando não há missão ativa).
func mission_text() -> String:
	return "%s\n%s" % [_mission_title.text, _mission_hint.text] if _mission_card.visible else ""


func stats_text() -> String:
	return "%s | %s | %s | %s | %s" % [_level_label.text, _xp_label.text, _gold_label.text, _popularity_label.text, _beauty_label.text]


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	return style


func _stat_label(parent: Control, node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_size_override("font_size", 20)
	parent.add_child(label)
	return label
