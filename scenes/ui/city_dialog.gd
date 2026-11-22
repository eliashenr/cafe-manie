class_name CityDialog
extends AcceptDialog
## Pela cidade (DT-072 e DT-074): o que fica fora da cafeteria, em duas abas.
## - Filial na praia: abrir, coletar o ouro que ela juntou e melhorar; as compras pedem confirmação ali mesmo, com
##   Cancelar já selecionado.
## - Vizinhos: um cartão por vizinho, com o retrato, a amizade e o botão de ajudar (uma vez por dia).

const ART_SIZE := Vector2(272, 190)
const TEXT_WIDTH := 408.0
const CONTENT_WIDTH := 720.0
const TAB_NAMES := {&"branch": "Filial", &"neighbors": "Vizinhos"}
const NEIGHBOR_COLUMNS := 3
const NEIGHBOR_PORTRAIT := Vector2(64, 70)

var simulation: CafeSimulation
## Aba na tela: &"branch" ou &"neighbors".
var tab: StringName = &"branch"
## Compra esperando confirmação: &"open" (abrir a filial), &"upgrade" (melhorar) ou &"" (nenhuma).
var pending: StringName = &""

var _tabs: HBoxContainer
var _branch_panel: HBoxContainer
var _neighbors: GridContainer
var _neighbors_scroll: ScrollContainer
var _neighbor_cards := {}
var _balance: Label
var _summary: Label
var _status: Label
var _reserve: Label
var _progress: ProgressBar
var _cost_hint: Label
var _art: TextureRect
var _heading: Label
var _info: Label
var _menu: Label
var _collect: Button
var _action: Button
var _confirm_row: PanelContainer
var _confirm_label: Label
var _cancel: Button
var _confirm: Button


func _init() -> void:
	name = "CityDialog"
	title = "Cidade"
	ok_button_text = "Fechar"
	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	root.add_theme_constant_override("separation", 12)
	add_child(root)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var heading := Label.new()
	heading.name = "CityHeading"
	heading.text = "Seu café pela cidade"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_override("font", UiTheme.font(UiTheme.BOLD))
	heading.add_theme_font_size_override("font_size", 25)
	header.add_child(heading)
	_balance = Label.new()
	_balance.name = "CityBalance"
	_balance.add_theme_color_override("font_color", UiTheme.GOLD_TEXT)
	header.add_child(_balance)
	var introduction := Label.new()
	introduction.name = "CityIntroduction"
	introduction.text = "Uma nova filial e boas amizades para fazer seu café crescer."
	introduction.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	root.add_child(introduction)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	root.add_child(_tabs)
	for tab_id: StringName in TAB_NAMES:
		var tab_button := Button.new()
		tab_button.name = "CityTab_" + String(tab_id)
		tab_button.text = TAB_NAMES[tab_id]
		tab_button.toggle_mode = true
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
		tab_button.focus_mode = Control.FOCUS_NONE
		UiTheme.role(tab_button, UiTheme.TAB_BUTTON)
		tab_button.pressed.connect(show_tab.bind(tab_id))
		_tabs.add_child(tab_button)
	_summary = Label.new()
	_summary.name = "CitySummary"
	_summary.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	root.add_child(_summary)
	var row := HBoxContainer.new()
	row.name = "BranchPanel"
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	_branch_panel = row
	_neighbors = GridContainer.new()
	_neighbors.name = "NeighborsPanel"
	_neighbors.columns = NEIGHBOR_COLUMNS
	_neighbors.add_theme_constant_override("h_separation", 10)
	_neighbors.add_theme_constant_override("v_separation", 10)
	_neighbors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_neighbors_scroll = ScrollContainer.new()
	_neighbors_scroll.name = "NeighborsScroll"
	_neighbors_scroll.custom_minimum_size = Vector2(CONTENT_WIDTH, 332)
	_neighbors_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_neighbors_scroll.add_child(_neighbors)
	root.add_child(_neighbors_scroll)
	_art = TextureRect.new()
	_art.custom_minimum_size = ART_SIZE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var art := ArtSprites.get_sprite("filial_praia")
	_art.texture = art.texture if art != null else null
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiTheme.card_box(14, 6))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var art_column := VBoxContainer.new()
	art_column.add_theme_constant_override("separation", 8)
	frame.add_child(art_column)
	art_column.add_child(_art)
	_status = _wrapped("BranchStatus", art_column)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_override("font", UiTheme.font(UiTheme.BOLD))
	_progress = ProgressBar.new()
	_progress.name = "BranchProgress"
	_progress.custom_minimum_size.y = 8
	_progress.show_percentage = false
	art_column.add_child(_progress)
	_reserve = _wrapped("BranchReserve", art_column)
	_reserve.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reserve.add_theme_font_size_override("font_size", 14)
	_reserve.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	row.add_child(frame)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.add_theme_font_size_override("font_size", 22)
	_heading.add_theme_font_override("font", UiTheme.font(UiTheme.BOLD))
	column.add_child(_heading)
	_info = _wrapped("Info", column)
	_menu = _wrapped("Menu", column)
	_menu.add_theme_color_override("font_color", UiTheme.CYAN)
	_cost_hint = _wrapped("BranchCostHint", column)
	_cost_hint.add_theme_font_size_override("font_size", 14)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_collect = UiTheme.role(_button("CollectBranch", buttons, collect), UiTheme.SUCCESS_BUTTON)
	_action = UiTheme.role(_button("BranchAction", buttons, ask_action), UiTheme.GHOST_BUTTON)
	_confirm_row = PanelContainer.new()
	_confirm_row.name = "ConfirmRow"
	_confirm_row.add_theme_stylebox_override("panel", UiTheme.card_box(12, 12, UiTheme.CYAN))
	_confirm_row.visible = false
	column.add_child(_confirm_row)
	var confirmation := VBoxContainer.new()
	confirmation.add_theme_constant_override("separation", 10)
	_confirm_row.add_child(confirmation)
	_confirm_label = _wrapped("ConfirmText", confirmation)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	confirmation.add_child(choices)
	_cancel = UiTheme.role(_button("BranchCancel", choices, cancel), UiTheme.GHOST_BUTTON)
	_cancel.text = "Cancelar"
	_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm = UiTheme.role(_button("BranchConfirm", choices, confirm), UiTheme.SUCCESS_BUTTON)
	_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func show_for(new_simulation: CafeSimulation) -> void:
	simulation = new_simulation
	pending = &""
	_refresh()
	popup_centered()
	get_ok_button().grab_focus()


func show_tab(tab_id: StringName) -> void:
	if not TAB_NAMES.has(tab_id):
		return
	tab = tab_id
	pending = &""
	_refresh()
	if visible:  # as abas têm tamanhos diferentes: a janela se ajusta e volta para o meio
		reset_size()
		move_to_center()


## Visita o vizinho e ajuda no café dele: o aviso conta o que o jogador fez e quanto ganhou.
func visit(neighbor_id: StringName) -> void:
	var neighbor: NeighborDefinition = simulation.neighbors.get_definition(neighbor_id)
	var gold := simulation.neighbor_reward(neighbor_id)
	var result := simulation.visit_neighbor(neighbor_id)
	if result == ServiceResult.OK:
		EventBus.message_posted.emit("Você %s no %s: +%s ouro, +%d XP" % [neighbor.help_text, neighbor.cafe_name,
			UiTheme.thousands(gold), simulation.neighbors_config.visit_xp])
	else:
		EventBus.message_posted.emit(BuildBar.SERVICE_MESSAGES.get(result, "Não deu certo"))
	_refresh()


## Botão de ajudar de um vizinho (para os testes).
func neighbor_button(neighbor_id: StringName) -> Button:
	return _neighbors.find_child("Visit_" + String(neighbor_id), true, false) as Button


func _process(_delta: float) -> void:
	if visible and simulation != null:
		_refresh_numbers()


## Coleta o ouro que a filial juntou.
func collect() -> void:
	var amount := simulation.branch.gold_ready(simulation.clock.now())
	if simulation.collect_branch() == ServiceResult.OK:
		EventBus.message_posted.emit("%s: +%s ouro" % [simulation.branch_config.display_name, UiTheme.thousands(amount)])
	_refresh()


## Abrir ou melhorar: a pergunta aparece embaixo, com Cancelar já selecionado.
func ask_action() -> void:
	pending = &"upgrade" if simulation.branch.opened else &"open"
	_refresh()
	_cancel.grab_focus()


func confirm() -> void:
	if pending == &"":
		return  # nada esperando confirmação (um toque a mais não compra nada)
	var branch := simulation.branch
	var result: int
	if pending == &"open":
		result = simulation.open_branch()
		if result == ServiceResult.OK:
			EventBus.message_posted.emit("%s aberta! Ela junta ouro sozinha, até com o jogo fechado." % simulation.branch_config.display_name)
	else:
		result = simulation.upgrade_branch()
		if result == ServiceResult.OK:
			EventBus.message_posted.emit("Filial no nível %d! Novo prato no cardápio: %s" % [branch.level, branch.dishes()[-1]])
	if result != ServiceResult.OK:
		EventBus.message_posted.emit(BuildBar.SERVICE_MESSAGES.get(result, "Não deu certo"))
	pending = &""
	_refresh()


func cancel() -> void:
	pending = &""
	_refresh()


func heading_text() -> String:
	return _heading.text


func info_text() -> String:
	return _info.text


func menu_text() -> String:
	return _menu.text if _menu.visible else ""


func confirm_text() -> String:
	return _confirm_label.text if _confirm_row.visible else ""


func _refresh() -> void:
	if simulation == null:
		return
	for tab_button: Button in _tabs.get_children():
		tab_button.button_pressed = tab_button.name == "CityTab_" + String(tab)
	_branch_panel.visible = tab == &"branch"
	_neighbors_scroll.visible = tab == &"neighbors"
	_refresh_neighbors()
	var config := simulation.branch_config
	var branch := simulation.branch
	var locked := config.unlock_level > simulation.progression.level
	_collect.visible = branch.opened
	_menu.visible = branch.opened
	if not branch.opened:
		_heading.text = config.display_name
		_info.text = "Um café à beira-mar que junta ouro sozinho, até com o jogo fechado.\n\n" \
			+ "Ao abrir: %s ouro/h · reserva de %d horas.\nPrimeiro prato: %s." % [
			UiTheme.thousands(config.income_per_hour[0]), roundi(config.capacity_hours[0]), config.dishes[0]]
		if locked:
			_info.text += "\nLibera no nível %d." % config.unlock_level
		_action.text = "Abrir · %s ouro" % UiTheme.thousands(config.open_price)
		_action.visible = true
		UiTheme.role(_action, UiTheme.SUCCESS_BUTTON)
	else:
		_heading.text = "%s · nível %d" % [config.display_name, branch.level]
		_info.text = "Rende %s ouro por hora, mesmo com o jogo fechado. Guarda até %d horas de produção." % [UiTheme.thousands(branch.income_per_hour()),
			roundi(branch.capacity_hours())]
		_menu.text = "No cardápio\n" + " · ".join(branch.dishes())
		_action.visible = not branch.is_max_level()
		_action.text = "Melhorar · %s ouro" % UiTheme.thousands(branch.upgrade_price())
		UiTheme.role(_action, UiTheme.GHOST_BUTTON)
	_confirm_row.visible = pending != &""
	_action.visible = _action.visible and pending == &""
	if pending == &"open":
		_confirm_label.text = "Abrir a filial por %s ouro?" % UiTheme.thousands(config.open_price)
		_confirm.text = "Abrir"
	elif pending == &"upgrade":
		_confirm_label.text = "Melhorar para o nível %d por %s ouro? Entra no cardápio: %s." % [branch.level + 1,
			UiTheme.thousands(branch.upgrade_price()), config.dishes[branch.level]]
		_confirm.text = "Melhorar"
	_refresh_numbers()


func _refresh_numbers() -> void:
	var branch := simulation.branch
	var config := simulation.branch_config
	var balance := simulation.wallet.balance(Wallet.SOFT)
	var gold := branch.gold_ready(simulation.clock.now())
	var locked := not branch.opened and config.unlock_level > simulation.progression.level
	var price := branch.upgrade_price() if branch.opened else config.open_price
	_balance.text = "%s ouro disponíveis" % UiTheme.thousands(balance)
	_collect.text = "Coletar %s ouro" % UiTheme.thousands(gold)
	_collect.disabled = gold <= 0
	_action.disabled = locked or balance < price
	_confirm.disabled = locked or balance < price
	_cost_hint.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	if locked:
		_status.text = "Disponível no nível %d" % config.unlock_level
		_status.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		_progress.max_value = config.unlock_level
		_progress.value = simulation.progression.level
		_reserve.text = "Seu café: nível %d de %d" % [simulation.progression.level, config.unlock_level]
		_cost_hint.text = "Continue cumprindo missões para chegar à praia."
	elif not branch.opened:
		_status.text = "Pronta para abrir"
		_status.add_theme_color_override("font_color", UiTheme.GREEN)
		_progress.max_value = 1
		_progress.value = 1
		_reserve.text = "Desbloqueada para o seu café"
		_cost_hint.text = "A abertura será confirmada antes da compra."
	else:
		var capacity := roundi(branch.income_per_hour() * branch.capacity_hours())
		_status.text = "Reserva cheia · hora de coletar" if gold >= capacity else ("Ouro pronto para coletar" if gold > 0 else "Sua filial está trabalhando")
		_status.add_theme_color_override("font_color", UiTheme.GREEN)
		_progress.max_value = capacity
		_progress.value = gold
		_reserve.text = "%s / %s ouro guardados" % [UiTheme.thousands(gold), UiTheme.thousands(capacity)]
		_cost_hint.text = "Filial completa · todos os pratos disponíveis" if branch.is_max_level() else \
			"Próximo nível: %s ouro/h + %s." % [UiTheme.thousands(config.income_per_hour[branch.level]), config.dishes[branch.level]]
	if not locked and (not branch.opened or not branch.is_max_level()) and balance < price:
		_cost_hint.text += "\nFaltam %s ouro." % UiTheme.thousands(price - balance)
		_cost_hint.add_theme_color_override("font_color", UiTheme.ORANGE)
	_summary.text = "Renda da filial · colete quando quiser, antes de encher a reserva."
	if not branch.opened:
		_summary.text = "Seu próximo endereço · uma filial com renda própria."
	if tab == &"neighbors":
		_refresh_neighbor_numbers()


## Um cartão por vizinho: retrato, nome e nível do café, amizade e o botão de ajudar (ou "Visitado hoje").
func _refresh_neighbors() -> void:
	_neighbor_cards.clear()
	for child in _neighbors.get_children():
		_neighbors.remove_child(child)
		child.queue_free()
	if tab != &"neighbors":
		return
	for neighbor: NeighborDefinition in simulation.neighbors.all():
		var frame := PanelContainer.new()
		frame.name = "Neighbor_" + String(neighbor.id)
		frame.custom_minimum_size.x = 226
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame.add_theme_stylebox_override("panel", UiTheme.card_box(14, 10))
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 7)
		frame.add_child(content)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		content.add_child(row)
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_theme_constant_override("separation", 2)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = NEIGHBOR_PORTRAIT
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var art := ArtSprites.get_sprite("vizinho_" + neighbor.art)
		portrait.texture = art.texture if art != null else null
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(portrait)
		row.add_child(card)
		var title := Label.new()
		title.text = neighbor.display_name
		title.add_theme_font_size_override("font_size", 19)
		title.add_theme_font_override("font", UiTheme.font(UiTheme.BOLD))
		card.add_child(title)
		var cafe_name := Label.new()
		cafe_name.name = "CafeName"
		cafe_name.text = "%s\nNível %d" % [neighbor.cafe_name, neighbor.level]
		cafe_name.custom_minimum_size.x = 118
		cafe_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cafe_name.add_theme_font_size_override("font_size", 13)
		cafe_name.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		card.add_child(cafe_name)
		var friendship := Label.new()
		friendship.name = "Friendship"
		friendship.add_theme_font_size_override("font_size", 13)
		friendship.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		content.add_child(friendship)
		var progress := ProgressBar.new()
		progress.name = "FriendshipProgress"
		progress.custom_minimum_size.y = 5
		progress.show_percentage = false
		content.add_child(progress)
		var button := UiTheme.role(_button("Visit_" + String(neighbor.id), content, visit.bind(neighbor.id)),
			UiTheme.SUCCESS_BUTTON)
		button.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
		button.add_theme_font_size_override("font_size", 14)
		var visit_status := Label.new()
		visit_status.name = "VisitStatus"
		visit_status.add_theme_font_size_override("font_size", 12)
		visit_status.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		content.add_child(visit_status)
		_neighbor_cards[neighbor.id] = {"friendship": friendship, "progress": progress, "button": button, "status": visit_status}
		_neighbors.add_child(frame)
	_refresh_neighbor_numbers()


func _refresh_neighbor_numbers() -> void:
	var available := 0
	var config := simulation.neighbors_config
	for neighbor: NeighborDefinition in simulation.neighbors.all():
		var can_visit := simulation.can_visit_neighbor(neighbor.id)
		if can_visit:
			available += 1
		if not _neighbor_cards.has(neighbor.id):
			continue
		var card: Dictionary = _neighbor_cards[neighbor.id]
		var friendship := simulation.neighbor_visits.friendship(neighbor.id)
		card.friendship.text = "Amizade %d/%d" % [friendship, config.max_friendship]
		card.progress.max_value = config.max_friendship
		card.progress.value = friendship
		card.button.text = "Ajudar · +%s ouro" % UiTheme.thousands(simulation.neighbor_reward(neighbor.id)) if can_visit else "Visitado hoje"
		card.button.disabled = not can_visit
		card.status.text = "+%d XP · uma ajuda por dia" % config.visit_xp if can_visit else "Nova ajuda disponível amanhã"
	_summary.text = "%d de %d visitas disponíveis hoje · personagens da cidade" % [available, simulation.neighbors.all().size()]


func _wrapped(label_name: String, parent: Control) -> Label:
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_WIDTH * 0.6, 0)
	parent.add_child(label)
	return label


func _button(button_name: String, parent: Control, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
