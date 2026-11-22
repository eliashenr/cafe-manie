class_name AvatarDialog
extends AcceptDialog
## Avatar do chef (DT-070): o retrato com as peças vestidas, as abas das partes do corpo e as peças de cada uma.
## Tocar numa peça que já é do jogador (ou grátis) veste na hora. Numa nova, ela aparece no retrato para provar e a
## compra pede confirmação ali mesmo, com Cancelar já selecionado.

const PORTRAIT_SIZE := Vector2(210, 255)
const CARD_SIZE := Vector2(128, 124)
const SKIN_CARD_SIZE := Vector2(94, 124)
const COLUMNS := 3
const AvatarPartCard := preload("res://scenes/ui/avatar_part_button.gd")
const TAB_NAMES := {
	AvatarPartDefinition.Slot.SKIN: "Pele",
	AvatarPartDefinition.Slot.HAIR: "Cabelo",
	AvatarPartDefinition.Slot.HAT: "Chapéu",
	AvatarPartDefinition.Slot.OUTFIT: "Roupa",
}

var simulation: CafeSimulation
## Parte do corpo cujas peças estão na tela.
var slot := AvatarPartDefinition.Slot.HAIR
## Peça nova que o jogador está provando (ainda não comprada), ou null.
var trying: AvatarPartDefinition

var _portrait: AvatarPortrait
var _portrait_status: Label
var _greeting: Button
var _greeting_hint: Label
var _section_hint: Label
var _tabs: HBoxContainer
var _grid: GridContainer
var _confirm_row: VBoxContainer
var _confirm_label: Label
var _buy: Button
var _cancel: Button


func _init() -> void:
	name = "AvatarDialog"
	title = "Avatar do Chef"
	ok_button_text = "Fechar"
	var content := VBoxContainer.new()
	content.name = "AvatarContent"
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	content.add_child(row)
	var stage := PanelContainer.new()
	stage.name = "Stage"
	stage.add_theme_stylebox_override("panel", UiTheme.glass_box(18, 12, UiTheme.PANEL_EDGE))
	stage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(stage)
	var stage_content := VBoxContainer.new()
	stage_content.add_theme_constant_override("separation", 6)
	stage.add_child(stage_content)
	_portrait_status = Label.new()
	_portrait_status.name = "PortraitStatus"
	_portrait_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_status.add_theme_font_size_override("font_size", 17)
	_portrait_status.add_theme_color_override("font_color", UiTheme.CYAN)
	stage_content.add_child(_portrait_status)
	_greeting = Button.new()
	_greeting.name = "GreetChefButton"
	_greeting.custom_minimum_size = PORTRAIT_SIZE
	_greeting.tooltip_text = "Toque para cumprimentar"
	_greeting.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		_greeting.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	stage_content.add_child(_greeting)
	_portrait = AvatarPortrait.new()
	_portrait.name = "Portrait"
	_portrait.animated = true
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_greeting.add_child(_portrait)
	_greeting.pressed.connect(func() -> void: _portrait.react())
	_greeting_hint = Label.new()
	_greeting_hint.name = "GreetingHint"
	_greeting_hint.text = "Toque para cumprimentar"
	_greeting_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_greeting_hint.add_theme_font_size_override("font_size", 12)
	_greeting_hint.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	stage_content.add_child(_greeting_hint)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	row.add_child(column)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	column.add_child(_tabs)
	for tab_slot: AvatarPartDefinition.Slot in TAB_NAMES:
		var tab := Button.new()
		tab.name = "AvatarTab_" + AvatarPartDefinition.Slot.keys()[tab_slot]
		tab.text = TAB_NAMES[tab_slot]
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
		tab.focus_mode = Control.FOCUS_NONE
		UiTheme.role(tab, UiTheme.TAB_BUTTON)
		tab.pressed.connect(show_slot.bind(tab_slot))
		_tabs.add_child(tab)
	_section_hint = Label.new()
	_section_hint.name = "SectionHint"
	_section_hint.add_theme_font_size_override("font_size", 13)
	_section_hint.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	column.add_child(_section_hint)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	column.add_child(_grid)
	_confirm_row = VBoxContainer.new()
	_confirm_row.name = "ConfirmRow"
	_confirm_row.add_theme_constant_override("separation", 6)
	_confirm_row.visible = false
	content.add_child(_confirm_row)
	_confirm_label = Label.new()
	_confirm_label.name = "ConfirmText"
	_confirm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.add_theme_font_size_override("font_size", 14)
	_confirm_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_confirm_row.add_child(_confirm_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	_confirm_row.add_child(actions)
	_cancel = Button.new()
	_cancel.name = "AvatarCancel"
	_cancel.text = "Cancelar"
	_cancel.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
	UiTheme.role(_cancel, UiTheme.GHOST_BUTTON)
	_cancel.pressed.connect(cancel_try)
	actions.add_child(_cancel)
	_buy = Button.new()
	_buy.name = "AvatarBuy"
	_buy.text = "Comprar"
	_buy.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
	UiTheme.role(_buy, UiTheme.SUCCESS_BUTTON)
	_buy.pressed.connect(buy_trying)
	actions.add_child(_buy)


func show_for(new_simulation: CafeSimulation) -> void:
	simulation = new_simulation
	show_slot(slot)
	popup_centered()
	get_ok_button().grab_focus()


func show_slot(new_slot: AvatarPartDefinition.Slot) -> void:
	slot = new_slot
	trying = null
	_refresh()


## Toque numa peça: a que já é do jogador (ou grátis) veste; a nova vai para o retrato, esperando a confirmação.
func choose(part_id: StringName) -> void:
	var part: AvatarPartDefinition = simulation.avatar_parts.get_definition(part_id)
	if part == null:
		return
	if simulation.avatar.owns(part_id) or part.price == 0:
		trying = null
		simulation.use_avatar_part(part_id)
	else:
		trying = part
	_refresh()
	if trying != null:
		_cancel.grab_focus()


func buy_trying() -> void:
	if trying == null:
		return
	var part := trying
	trying = null
	var result := simulation.use_avatar_part(part.id)
	if result == ServiceResult.OK:
		EventBus.message_posted.emit("Novo visual: %s! -%d ouro" % [part.display_name, part.price])
	else:
		EventBus.message_posted.emit(BuildBar.SERVICE_MESSAGES.get(result, "Não deu para comprar"))
	_refresh()


func cancel_try() -> void:
	trying = null
	_refresh()


## Peças no retrato agora: as vestidas, com a que está sendo provada por cima.
func shown_parts() -> Dictionary:
	var parts := {}
	for part_slot: AvatarPartDefinition.Slot in TAB_NAMES:
		parts[part_slot] = simulation.avatar_part(part_slot)
	if trying != null:
		parts[trying.slot] = trying
	return parts


func portrait_layers() -> Array[String]:
	return _portrait.layers


func confirm_text() -> String:
	return _confirm_label.text if _confirm_row.visible else ""


func _refresh() -> void:
	if simulation == null:
		return
	for tab: Button in _tabs.get_children():
		tab.button_pressed = tab.name == "AvatarTab_" + AvatarPartDefinition.Slot.keys()[slot]
	var shown := shown_parts()
	_portrait.layers = AvatarPortrait.layer_names(shown)
	var can_greet := _portrait.uses_approved_chef()
	_greeting.disabled = not can_greet
	_greeting_hint.text = "Toque para cumprimentar" if can_greet else "Prévia do visual"
	_greeting.tooltip_text = _greeting_hint.text
	_portrait_status.text = "Experimentando" if trying != null else "Seu visual"
	_section_hint.text = "Escolha seu tom de pele. A mudança é grátis." if slot == AvatarPartDefinition.Slot.SKIN \
		else "Peças suas vestem ao tocar; novas peças você experimenta."
	_grid.columns = 4 if slot == AvatarPartDefinition.Slot.SKIN else COLUMNS
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for part: AvatarPartDefinition in simulation.avatar_parts_for(slot):
		_add_card(part, shown)
	_confirm_row.visible = trying != null
	if trying != null:
		var affordable := simulation.wallet.can_afford(Wallet.SOFT, trying.price)
		_confirm_label.text = "Comprar %s por %d ouro?" % [trying.display_name, trying.price] if affordable \
			else "%s custa %d ouro: falta ouro" % [trying.display_name, trying.price]
		_buy.disabled = not affordable
	if visible:
		_fit_dialog.call_deferred()


## O rodapé de compra cresce para baixo; recentrar evita corte em uma tela de 960×540.
func _fit_dialog() -> void:
	if not visible:
		return
	reset_size()
	popup_centered()
	if trying != null:
		_cancel.grab_focus()


func _add_card(part: AvatarPartDefinition, shown: Dictionary) -> void:
	var card := AvatarPartCard.new()
	card.name = "AvatarPart_" + String(part.id)
	card.title = part.display_name
	card.custom_minimum_size = SKIN_CARD_SIZE if part.slot == AvatarPartDefinition.Slot.SKIN else CARD_SIZE
	var preview := shown.duplicate()
	preview[part.slot] = part
	var layers := AvatarPortrait.layer_names(preview)
	var owned := simulation.avatar.owns(part.id)
	var locked := not owned and part.min_level > simulation.progression.level
	if simulation.avatar_part(part.slot) == part:
		card.text = "%s\nUsando" % part.display_name
		card.show_state(0, 0, "Usando", true)
	elif owned or part.price == 0:
		card.text = "%s\nÉ seu" % part.display_name
		card.show_state(0, 0, "É seu", true)
	elif locked:
		card.text = "%s\nNível %d" % [part.display_name, part.min_level]
		card.show_state(part.price, part.min_level, "", false)
	else:
		card.text = "%s\n%d ouro" % [part.display_name, part.price]
		card.show_state(part.price, 0, "", simulation.wallet.can_afford(Wallet.SOFT, part.price))
	card.disabled = locked
	var is_skin := part.slot == AvatarPartDefinition.Slot.SKIN
	card.configure(layers, is_skin, AvatarPortrait.skin_color(part.art) if is_skin else Color.WHITE,
		simulation.avatar_part(part.slot) == part, trying == part)
	card.pressed.connect(choose.bind(part.id))
	_grid.add_child(card)


## Botão de uma peça (para os testes).
func card(part_id: StringName) -> ShopItemButton:
	return _grid.get_node_or_null("AvatarPart_" + String(part_id)) as ShopItemButton
