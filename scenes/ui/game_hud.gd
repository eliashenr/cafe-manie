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

const SOFT_CURRENCY_NAME := "Café Ouro"
const HINT := "Arraste para mover  •  Roda do mouse ou pinça para zoom  •  Toque num fogão para cozinhar"
const TOAST_SECONDS := 2.8
## Tempo extra de aviso por caractere, para textos longos darem tempo de ler.
const TOAST_SECONDS_PER_CHAR := 0.05
const MISSION_CARD_WIDTH := 330.0
const XP_BAR_BACKGROUND := Color(1, 1, 1, 0.18)
const XP_BAR_FILL := Color("8fd3ff")

var simulation: CafeSimulation

var _level_label: Label
var _xp_bar: ProgressBar
var _xp_label: Label
var _gold_label: Label
var _popularity_label: Label
var _toast: Label
var _toast_time := 0.0
var _restart_dialog: ConfirmationDialog
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
	column.add_child(button)
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


func refresh() -> void:
	if simulation == null:
		return
	var progression := simulation.progression
	_level_label.text = "Nível %d" % progression.level
	_xp_bar.value = progression.level_progress()
	if progression.is_max_level():
		_xp_label.text = "%d XP (nível máximo)" % progression.xp
	else:
		_xp_label.text = "%d / %d XP" % [progression.xp, progression.table.xp_for_next(progression.level)]
	_gold_label.text = "%s: %d" % [SOFT_CURRENCY_NAME, simulation.wallet.balance(Wallet.SOFT)]
	_popularity_label.text = "Popularidade: %d%%" % roundi(simulation.popularity)
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


func show_message(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_time = TOAST_SECONDS + text.length() * TOAST_SECONDS_PER_CHAR


func toast_text() -> String:
	return _toast.text if _toast.visible else ""


## Texto do cartão de missão (vazio quando não há missão ativa).
func mission_text() -> String:
	return "%s\n%s" % [_mission_title.text, _mission_hint.text] if _mission_card.visible else ""


func stats_text() -> String:
	return "%s | %s | %s | %s" % [_level_label.text, _xp_label.text, _gold_label.text, _popularity_label.text]


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
