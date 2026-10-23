class_name AvatarDialog
extends AcceptDialog
## Avatar do chef (DT-070): o retrato com as peças vestidas, as abas das partes do corpo e as peças de cada uma.
## Tocar numa peça que já é do jogador (ou grátis) veste na hora. Numa nova, ela aparece no retrato para provar e a
## compra pede confirmação ali mesmo, com Cancelar já selecionado.

const PORTRAIT_SIZE := Vector2(210, 255)
const CARD_SIZE := Vector2(118, 132)
const COLUMNS := 3
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
var _tabs: HBoxContainer
var _grid: GridContainer
var _confirm_row: HBoxContainer
var _confirm_label: Label
var _buy: Button
var _cancel: Button


func _init() -> void:
	name = "AvatarDialog"
	title = "Avatar do Chef"
	ok_button_text = "Fechar"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	_portrait = AvatarPortrait.new()
	_portrait.name = "Portrait"
	_portrait.custom_minimum_size = PORTRAIT_SIZE
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	row.add_child(column)
	_tabs = HBoxContainer.new()
	column.add_child(_tabs)
	for tab_slot: AvatarPartDefinition.Slot in TAB_NAMES:
		var tab := Button.new()
		tab.name = "AvatarTab_" + AvatarPartDefinition.Slot.keys()[tab_slot]
		tab.text = TAB_NAMES[tab_slot]
		tab.toggle_mode = true
		tab.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
		tab.pressed.connect(show_slot.bind(tab_slot))
		_tabs.add_child(tab)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	column.add_child(_grid)
	_confirm_row = HBoxContainer.new()
	_confirm_row.name = "ConfirmRow"
	_confirm_row.visible = false
	column.add_child(_confirm_row)
	_confirm_label = Label.new()
	_confirm_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_row.add_child(_confirm_label)
	_cancel = Button.new()
	_cancel.name = "AvatarCancel"
	_cancel.text = "Cancelar"
	_cancel.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
	_cancel.pressed.connect(cancel_try)
	_confirm_row.add_child(_cancel)
	_buy = Button.new()
	_buy.name = "AvatarBuy"
	_buy.text = "Comprar"
	_buy.custom_minimum_size = Vector2(0, UiTheme.MIN_TOUCH)
	_buy.pressed.connect(buy_trying)
	_confirm_row.add_child(_buy)


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


func _add_card(part: AvatarPartDefinition, shown: Dictionary) -> void:
	var card := ShopItemButton.new()
	card.name = "AvatarPart_" + String(part.id)
	card.title = part.display_name
	card.custom_minimum_size = CARD_SIZE
	var preview := shown.duplicate()
	preview[part.slot] = part
	var layers := AvatarPortrait.layer_names(preview)
	card.art = ArtSprites.get_sprite(layers[0] if part.slot == AvatarPartDefinition.Slot.OUTFIT \
		else layers[2] if part.slot == AvatarPartDefinition.Slot.HAT else layers[1])
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
	card.pressed.connect(choose.bind(part.id))
	_grid.add_child(card)


## Botão de uma peça (para os testes).
func card(part_id: StringName) -> ShopItemButton:
	return _grid.get_node_or_null("AvatarPart_" + String(part_id)) as ShopItemButton
