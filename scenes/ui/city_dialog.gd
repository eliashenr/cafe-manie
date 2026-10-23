class_name CityDialog
extends AcceptDialog
## Pela cidade (DT-072 e DT-074): o que fica fora da cafeteria, em duas abas.
## - Filial na praia: abrir, coletar o ouro que ela juntou e melhorar; as compras pedem confirmação ali mesmo, com
##   Cancelar já selecionado.
## - Vizinhos: um cartão por vizinho, com o retrato, a amizade e o botão de ajudar (uma vez por dia).

const ART_SIZE := Vector2(300, 196)
const TEXT_WIDTH := 380.0
const TAB_NAMES := {&"branch": "Filial na praia", &"neighbors": "Vizinhos"}
const NEIGHBOR_COLUMNS := 4
const NEIGHBOR_PORTRAIT := Vector2(82, 86)

var simulation: CafeSimulation
## Aba na tela: &"branch" ou &"neighbors".
var tab: StringName = &"branch"
## Compra esperando confirmação: &"open" (abrir a filial), &"upgrade" (melhorar) ou &"" (nenhuma).
var pending: StringName = &""

var _tabs: HBoxContainer
var _branch_panel: HBoxContainer
var _neighbors: GridContainer
var _art: TextureRect
var _heading: Label
var _info: Label
var _menu: Label
var _collect: Button
var _action: Button
var _confirm_row: HBoxContainer
var _confirm_label: Label
var _cancel: Button
var _confirm: Button


func _init() -> void:
	name = "CityDialog"
	title = "Pela cidade"
	ok_button_text = "Fechar"
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	_tabs = HBoxContainer.new()
	root.add_child(_tabs)
	for tab_id: StringName in TAB_NAMES:
		var tab_button := Button.new()
		tab_button.name = "CityTab_" + String(tab_id)
		tab_button.text = TAB_NAMES[tab_id]
		tab_button.toggle_mode = true
		tab_button.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
		tab_button.pressed.connect(show_tab.bind(tab_id))
		_tabs.add_child(tab_button)
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
	root.add_child(_neighbors)
	_art = TextureRect.new()
	_art.custom_minimum_size = ART_SIZE
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art := ArtSprites.get_sprite("filial_praia")
	_art.texture = art.texture if art != null else null
	row.add_child(_art)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(TEXT_WIDTH, 0)
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)
	_heading = Label.new()
	_heading.name = "Heading"
	_heading.add_theme_font_size_override("font_size", 20)
	column.add_child(_heading)
	_info = _wrapped("Info", column)
	_menu = _wrapped("Menu", column)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	_collect = _button("CollectBranch", buttons, collect)
	_action = _button("BranchAction", buttons, ask_action)
	_confirm_row = HBoxContainer.new()
	_confirm_row.name = "ConfirmRow"
	_confirm_row.visible = false
	column.add_child(_confirm_row)
	_confirm_label = _wrapped("ConfirmText", _confirm_row)
	_confirm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cancel = _button("BranchCancel", _confirm_row, cancel)
	_cancel.text = "Cancelar"
	_confirm = _button("BranchConfirm", _confirm_row, confirm)


func show_for(new_simulation: CafeSimulation) -> void:
	simulation = new_simulation
	pending = &""
	_refresh()
	popup_centered()
	get_ok_button().grab_focus()


func show_tab(tab_id: StringName) -> void:
	tab = tab_id
	pending = &""
	_refresh()


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
	_neighbors.visible = tab == &"neighbors"
	_refresh_neighbors()
	var config := simulation.branch_config
	var branch := simulation.branch
	var locked := config.unlock_level > simulation.progression.level
	_collect.visible = branch.opened
	_menu.visible = branch.opened
	if not branch.opened:
		_heading.text = config.display_name
		_info.text = "Um segundo café, na praia, que trabalha sozinho e rende ouro por hora, até com o jogo fechado." \
			+ ("\nLibera no nível %d." % config.unlock_level if locked else "")
		_action.text = "Abrir · %s ouro" % UiTheme.thousands(config.open_price)
		_action.visible = true
		_action.disabled = locked
	else:
		_heading.text = "%s · nível %d" % [config.display_name, branch.level]
		_info.text = "Rende %s ouro por hora e guarda até %d horas." % [UiTheme.thousands(branch.income_per_hour()),
			roundi(branch.capacity_hours())]
		_menu.text = "Cardápio: " + ", ".join(branch.dishes())
		_action.visible = not branch.is_max_level()
		_action.text = "Melhorar · %s ouro" % UiTheme.thousands(branch.upgrade_price())
		_action.disabled = false
	_confirm_row.visible = pending != &""
	if pending == &"open":
		_confirm_label.text = "Abrir a filial por %s ouro?" % UiTheme.thousands(config.open_price)
		_confirm.text = "Abrir"
	elif pending == &"upgrade":
		_confirm_label.text = "Melhorar para o nível %d por %s ouro? Entra no cardápio: %s." % [branch.level + 1,
			UiTheme.thousands(branch.upgrade_price()), config.dishes[branch.level]]
		_confirm.text = "Melhorar"
	_refresh_numbers()


func _refresh_numbers() -> void:
	var gold := simulation.branch.gold_ready(simulation.clock.now())
	_collect.text = "Coletar %s ouro" % UiTheme.thousands(gold)
	_collect.disabled = gold <= 0


## Um cartão por vizinho: retrato, nome e nível do café, amizade e o botão de ajudar (ou "Visitado hoje").
func _refresh_neighbors() -> void:
	for child in _neighbors.get_children():
		_neighbors.remove_child(child)
		child.queue_free()
	if tab != &"neighbors":
		return
	var config := simulation.neighbors_config
	for neighbor: NeighborDefinition in simulation.neighbors.all():
		var card := VBoxContainer.new()
		card.name = "Neighbor_" + String(neighbor.id)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = NEIGHBOR_PORTRAIT
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var art := ArtSprites.get_sprite("vizinho_" + neighbor.art)
		portrait.texture = art.texture if art != null else null
		card.add_child(portrait)
		var title := Label.new()
		title.text = "%s · nível %d" % [neighbor.display_name, neighbor.level]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(title)
		var friendship := Label.new()
		friendship.name = "Friendship"
		friendship.text = "Amizade %d/%d" % [simulation.neighbor_visits.friendship(neighbor.id), config.max_friendship]
		friendship.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		friendship.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
		card.add_child(friendship)
		var can_visit := simulation.can_visit_neighbor(neighbor.id)
		var button := _button("Visit_" + String(neighbor.id), card, visit.bind(neighbor.id))
		button.text = "Ajudar · +%s ouro" % UiTheme.thousands(simulation.neighbor_reward(neighbor.id)) if can_visit \
			else "Visitado hoje"
		button.disabled = not can_visit
		_neighbors.add_child(card)


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
