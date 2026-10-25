class_name MissionsPanel
extends AcceptDialog
## Janela das missões (DT-047): as diárias, as semanais e as do começo (o tutorial), cada uma numa aba,
## com o progresso, a recompensa e quanto falta para recomeçar. Enquanto está aberta, atualiza sozinha
## uma vez por segundo (o relógio da contagem e o progresso).

const LIST_SIZE := Vector2(620, 380)
const ROW_TITLE_SIZE := 15
const REFRESH_SECONDS := 1.0
const DONE_COLOR := UiTheme.GREEN
const LOCKED_COLOR := UiTheme.METAL
const BAR_BACK := Color(1, 1, 1, 0.08)
const BAR_FILL := UiTheme.CYAN
const TAB_DAILY := 0
const TAB_WEEKLY := 1
const TAB_START := 2

var simulation: CafeSimulation
var _tabs: TabContainer
var _lists: Array[VBoxContainer] = []
var _headers: Array[Label] = []
var _refresh_left := 0.0


func _init() -> void:
	name = "MissionsDialog"
	title = "Missões"
	ok_button_text = "Fechar"
	_tabs = TabContainer.new()
	_tabs.name = "MissionTabs"
	_tabs.add_theme_font_size_override("font_size", 15)
	add_child(_tabs)
	for tab_name in ["Daily", "Weekly", "Start"]:
		var column := VBoxContainer.new()
		column.name = tab_name
		column.add_theme_constant_override("separation", 8)
		_tabs.add_child(column)
		var header := Label.new()
		header.name = "Header"
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		column.add_child(header)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = LIST_SIZE
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		column.add_child(scroll)
		var list := VBoxContainer.new()
		list.name = "List"
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 8)
		scroll.add_child(list)
		_lists.append(list)
		_headers.append(header)


## Abre a janela com as missões de agora.
func show_for(target: CafeSimulation) -> void:
	simulation = target
	rebuild()
	popup_centered()


func _process(delta: float) -> void:
	if not visible or simulation == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		rebuild()


## Refaz as três abas a partir do estado das missões.
func rebuild() -> void:
	_refresh_left = REFRESH_SECONDS
	var daily := simulation.daily_missions
	var weekly := simulation.weekly_missions
	_fill_board(TAB_DAILY, daily, "Diárias", simulation.clock.seconds_to_next_local_day())
	_fill_board(TAB_WEEKLY, weekly, "Semanais", simulation.seconds_until_new_week())
	_fill_start()


func _fill_board(tab: int, board: MissionBoard, label: String, seconds_left: float) -> void:
	var list := _lists[tab]
	_clear(list)
	_tabs.set_tab_title(tab, "%s %d/%d" % [label, board.completed_count(), board.size()])
	_headers[tab].text = "%d de %d concluídas. Novas em %s." % [board.completed_count(), board.size(),
		MissionsPanel.time_text(seconds_left)]
	for entry in board.entries():
		var state := "locked" if entry.locked else ("done" if entry.done() else "open")
		list.add_child(_row(String(entry.mission.id), entry.title(), entry.progress, entry.target, entry.reward_gold,
			entry.reward_xp, state, entry.mission.min_level, MissionsPanel.spice_reward_text(simulation.spices, entry.mission)))


## Aba do começo: a sequência do tutorial, com a atual em andamento; some quando acaba.
func _fill_start() -> void:
	var tracker := simulation.missions
	_tabs.set_tab_hidden(TAB_START, tracker.all_done() or tracker.missions.is_empty())
	_tabs.set_tab_title(TAB_START, "Começo %d/%d" % [tracker.completed_count(), tracker.missions.size()])
	_headers[TAB_START].text = "As primeiras missões ensinam o jogo, uma de cada vez."
	var list := _lists[TAB_START]
	_clear(list)
	for i in tracker.missions.size():
		var mission := tracker.missions[i]
		var done := i < tracker.completed_count()
		var progress := mission.target if done else (tracker.progress() if i == tracker.completed_count() else 0)
		list.add_child(_row(String(mission.id), mission.title, mini(progress, mission.target), mission.target,
			mission.reward_gold, mission.reward_xp, "done" if done else "open", 1,
			MissionsPanel.spice_reward_text(simulation.spices, mission)))


func _row(id: String, text: String, progress: int, target: int, gold: int, xp: int, state: String,
		min_level: int, spice := "") -> Control:
	var panel := PanelContainer.new()
	panel.name = "Mission_" + id
	panel.add_theme_stylebox_override("panel", UiTheme.card_box(12, 10, DONE_COLOR.darkened(0.2) if state == "done"
		else UiTheme.CARD_EDGE))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(column)
	var heading := Label.new()
	heading.name = "Title"
	heading.text = ("✓ " if state == "done" else "") + text
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", ROW_TITLE_SIZE)
	if state == "done":
		heading.add_theme_color_override("font_color", DONE_COLOR)
	column.add_child(heading)
	var progress_line := HBoxContainer.new()
	progress_line.add_theme_constant_override("separation", 10)
	column.add_child(progress_line)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(300, 10)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = 1.0
	bar.step = 0.001
	bar.value = float(progress) / maxf(target, 1)
	bar.add_theme_stylebox_override("background", _bar_style(BAR_BACK))
	bar.add_theme_stylebox_override("fill", _bar_style(DONE_COLOR if state == "done" else BAR_FILL))
	progress_line.add_child(bar)
	var count := Label.new()
	count.name = "Count"
	count.add_theme_font_size_override("font_size", 13)
	count.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	count.text = "Libera no nível %d" % min_level if state == "locked" else "%s/%s" % [UiTheme.thousands(progress),
		UiTheme.thousands(target)]
	progress_line.add_child(count)
	line.add_child(UiTheme.art("icone_moeda", Vector2(24, 24)))
	var reward := Label.new()
	reward.name = "Reward"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reward.add_theme_color_override("font_color", UiTheme.GOLD)
	reward.text = "+%s ouro" % UiTheme.thousands(gold) + ("\n+%d XP" % xp if xp > 0 else "") \
		+ ("\n" + spice if not spice.is_empty() else "")
	line.add_child(reward)
	if state == "locked":
		panel.modulate = Color(1, 1, 1, 0.55)
		heading.add_theme_color_override("font_color", LOCKED_COLOR)
	return panel


## "+1 Sal da Fartura" para a missão que dá tempero (DT-056), ou "".
static func spice_reward_text(spices: SpiceCatalog, mission: MissionDefinition) -> String:
	var spice := spices.get_definition(mission.reward_spice)
	return "+%d %s" % [mission.reward_spice_amount, spice.display_name] if spice != null else ""


static func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style


static func _clear(list: Control) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()


## "5h 12min", "2 dias e 3h" ou "menos de 1min".
static func time_text(seconds: float) -> String:
	var total := maxi(ceili(seconds / 60.0), 0)
	var days := total / 1440
	var hours := (total % 1440) / 60
	var minutes := total % 60
	if days > 0:
		return "%d dia%s e %dh" % [days, "s" if days > 1 else "", hours]
	if hours > 0:
		return "%dh %02dmin" % [hours, minutes]
	return "%dmin" % minutes if minutes > 0 else "menos de 1min"
