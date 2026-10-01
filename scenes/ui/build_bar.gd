class_name BuildBar
extends CanvasLayer
## Interface de baixo, no formato da v3 (o do jogo antigo, desenho nosso).
##
## Mostra, conforme o estado da cafeteria:
## - nada selecionado: a faixa de ícones (Loja, Reformar, Expandir, Missões,
##   Presentes, Conquistas); a Loja abre o painel em abas (Salão, Cozinha,
##   Decoração, Pisos, Paredes) com os quadradinhos dos itens;
## - fogão selecionado: receitas para cozinhar (ou o tempo que falta), e as ações do móvel;
## - balcão selecionado: o que tem nele, e as ações do móvel;
## - outro móvel selecionado: Mover, Girar, Guardar, Vender e Fechar;
## - construindo: instrução ou motivo da recusa, preço, Girar, Confirmar e Cancelar.
##
## Os botões só são recriados quando o tipo de painel muda. Preços, bloqueios,
## tempos e mensagens são atualizados no lugar a cada frame, para um clique
## nunca se perder porque um cliente pagou no meio dele.

const ICON_BUTTON_SIZE := Vector2(92, 74)
const RECIPE_BUTTON_SIZE := Vector2(132, 92)
const TAB_SIZE := Vector2(128, 50)
const MESSAGE_SIZE := 17

## Mensagens para o jogador em cada resultado de checagem de posição.
const CHECK_MESSAGES := {
	CafeLayout.Check.OK: "Toque de novo no piso ou em Confirmar",
	CafeLayout.Check.NO_TARGET: "Toque num piso para posicionar",
	CafeLayout.Check.OUT_OF_BOUNDS: "Não cabe aqui",
	CafeLayout.Check.OCCUPIED: "Já tem algo nesse lugar",
	CafeLayout.Check.BLOCKS_ENTRANCE: "A entrada precisa ficar livre",
	CafeLayout.Check.NO_ACCESS: "Ninguém conseguiria chegar até ele aqui",
	CafeLayout.Check.BLOCKS_ACCESS: "Isso deixaria outro móvel sem acesso",
	CafeLayout.Check.UNKNOWN_PLACEMENT: "Esse móvel não existe mais",
	CafeLayout.Check.IN_USE: "Está em uso agora, espere terminar",
	CafeLayout.Check.AGENT_IN_THE_WAY: "Tem alguém passando aí",
}

## Mensagens para o jogador em cada resultado de ação de cozinha, loja ou expansão.
const SERVICE_MESSAGES := {
	ServiceResult.OK: "",
	ServiceResult.NOT_A_STOVE: "Isso não é um fogão",
	ServiceResult.STOVE_BUSY: "O fogão já está ocupado",
	ServiceResult.NOT_READY: "Ainda não está pronto",
	ServiceResult.NO_COUNTER_SPACE: "Sem espaço no balcão: sirva ou coloque outro balcão",
	ServiceResult.RECIPE_LOCKED: "Receita ainda bloqueada",
	ServiceResult.NOT_ENOUGH_GOLD: "Café Ouro insuficiente",
	ServiceResult.UNKNOWN_RECIPE: "Receita desconhecida",
	ServiceResult.FURNITURE_LOCKED: "Móvel ainda bloqueado",
	ServiceResult.INVALID_PLACEMENT: "Não dá para colocar aqui",
	ServiceResult.NO_MORE_EXPANSIONS: "A cafeteria já está no tamanho máximo",
	ServiceResult.EXPANSION_LOCKED: "Expansão ainda bloqueada",
	ServiceResult.SURFACE_LOCKED: "Revestimento ainda bloqueado",
	ServiceResult.UNKNOWN_ITEM: "Item desconhecido",
	ServiceResult.IN_USE: "Está em uso agora, espere terminar",
	ServiceResult.LAST_ESSENTIAL: "É o último: sem ele não dá para cozinhar ou servir",
}

## Abas da loja.
enum ShopTab { SALON, KITCHEN, DECOR, FLOOR, WALL }

const SHOP_TAB_NAMES := {
	ShopTab.SALON: "Salão",
	ShopTab.KITCHEN: "Cozinha",
	ShopTab.DECOR: "Decoração",
	ShopTab.FLOOR: "Pisos",
	ShopTab.WALL: "Paredes",
}
## Cor de cada aba (como nas pranchas: uma cor por seção da loja).
const SHOP_TAB_COLORS := {
	ShopTab.SALON: Color("ff5a5f"),
	ShopTab.KITCHEN: Color("3d8ee8"),
	ShopTab.DECOR: Color("3cc04e"),
	ShopTab.FLOOR: Color("9b5cff"),
	ShopTab.WALL: Color("2ec4b6"),
}
## Categorias de móvel em cada aba de móveis.
const SHOP_TAB_CATEGORIES := {
	ShopTab.SALON: [FurnitureDefinition.Category.TABLE, FurnitureDefinition.Category.SEATING],
	ShopTab.KITCHEN: [FurnitureDefinition.Category.COOKING, FurnitureDefinition.Category.COUNTER],
	ShopTab.DECOR: [FurnitureDefinition.Category.DECOR],
}

var cafe: Cafe
var shop_tab := ShopTab.SALON
## A loja está aberta (no lugar da faixa de ícones)?
var shop_open := false

var _root: Control
var _stack: VBoxContainer
var _message: Label
## Cartão de cima: receitas do fogão ou "Levar ao balcão". Escondido quando vazio.
var _primary_card: PanelContainer
var _primary: HBoxContainer
## Faixa de baixo: ícones, ações do móvel ou controles de construção.
var _bar: PanelContainer
var _buttons: HBoxContainer
## Loja aberta: abas e quadradinhos.
var _shop: VBoxContainer
var _tabs: HBoxContainer
var _items: HBoxContainer
## Confirmação de compras que acontecem na hora (expansão, revestimento): seção 32.
var _confirm_dialog: ConfirmationDialog
var _pending_confirm: Callable

var _rebuild_pending := false
## Identifica o tipo de painel mostrado; só muda de painel quando isto muda.
var _shown_signature: Array = []
## Texto da mensagem, recalculado a cada frame.
var _message_source: Callable
## Atualizadores dos botões (texto, bloqueio), chamados a cada frame.
var _updaters: Array[Callable] = []


func _ready() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiTheme.theme()
	add_child(_root)

	_stack = VBoxContainer.new()
	_stack.name = "Panel"
	_stack.anchor_left = 0.5
	_stack.anchor_right = 0.5
	_stack.anchor_top = 1.0
	_stack.anchor_bottom = 1.0
	_stack.offset_bottom = -12
	_stack.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_stack.alignment = BoxContainer.ALIGNMENT_END
	_stack.add_theme_constant_override("separation", 8)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stack)

	_message = Label.new()
	_message.name = "Message"
	_message.add_theme_font_size_override("font_size", MESSAGE_SIZE)
	_message.add_theme_color_override("font_color", UiTheme.TEXT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var message_style := UiTheme.card_box(14, 8)
	message_style.content_margin_left = 18
	message_style.content_margin_right = 18
	_message.add_theme_stylebox_override("normal", message_style)
	_message.mouse_filter = Control.MOUSE_FILTER_STOP
	_stack.add_child(_message)

	_primary_card = _card("PrimaryCard")
	_primary = _row("Primary")
	_primary_card.add_child(_primary)
	_stack.add_child(_primary_card)

	_bar = _card("Bar", 18)
	_buttons = _row("Buttons")
	_bar.add_child(_buttons)
	_stack.add_child(_bar)

	_shop = VBoxContainer.new()
	_shop.name = "Shop"
	_shop.add_theme_constant_override("separation", 0)
	_stack.add_child(_shop)
	_tabs = HBoxContainer.new()
	_tabs.name = "Tabs"
	_tabs.add_theme_constant_override("separation", 6)
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_shop.add_child(_tabs)
	var shop_card := _card("ShopCard", 16)
	shop_card.size_flags_horizontal = Control.SIZE_FILL  # tão largo quanto a fileira de abas
	_shop.add_child(shop_card)
	var shop_row := HBoxContainer.new()
	shop_row.add_theme_constant_override("separation", 12)
	shop_card.add_child(shop_row)
	_items = _row("Items")
	_items.custom_minimum_size = Vector2(0, ShopItemButton.CARD_SIZE.y)
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_row.add_child(_items)
	var close := UiTheme.icon_button("CloseShopButton", "close", "", 40)
	close.tooltip_text = "Fechar a loja"
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close.pressed.connect(close_shop)
	shop_row.add_child(close)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.name = "ConfirmDialog"
	_confirm_dialog.cancel_button_text = "Cancelar"
	_confirm_dialog.theme = UiTheme.theme()
	_confirm_dialog.confirmed.connect(func() -> void:
		if _pending_confirm.is_valid():
			_pending_confirm.call())
	add_child(_confirm_dialog)


func _card(card_name: String, radius := 14) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("panel", UiTheme.card_box(radius, 10))
	return card


func _row(row_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = row_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	return row


func bind(target_cafe: Cafe) -> void:
	cafe = target_cafe
	cafe.state_changed.connect(_request_rebuild)
	cafe.simulation.kitchen.changed.connect(_request_rebuild)
	_rebuild()


func message_text() -> String:
	return _message.text


func find_button(button_name: String) -> Button:
	for row: Node in [_primary, _buttons, _tabs, _items]:
		var button := row.get_node_or_null(button_name) as Button
		if button != null:
			return button
	return null


func confirm_dialog() -> ConfirmationDialog:
	return _confirm_dialog


## Mesma janela de confirmação (mantido para os testes da expansão).
func expand_dialog() -> ConfirmationDialog:
	return _confirm_dialog


## Abre a loja na aba pedida (no lugar da faixa de ícones).
func open_shop(tab := shop_tab) -> void:
	shop_tab = tab
	shop_open = true
	_request_rebuild()


func close_shop() -> void:
	shop_open = false
	_request_rebuild()


## Troca a aba da loja (e abre a loja, se estiver fechada).
func show_shop_tab(tab: ShopTab) -> void:
	open_shop(tab)


func _process(_delta: float) -> void:
	if cafe == null:
		return
	if _signature() != _shown_signature:
		_request_rebuild()
		return
	_refresh_in_place()


## Reconstrói no fim do frame, e só se o tipo de painel mudou.
func _request_rebuild() -> void:
	if not _rebuild_pending:
		_rebuild_pending = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	var signature := _signature()
	if signature == _shown_signature:
		_refresh_in_place()
		return
	_shown_signature = signature
	for row: Node in [_primary, _buttons, _tabs, _items]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_updaters.clear()

	var showing_shop := false
	if cafe.mode == Cafe.Mode.BUILD:
		_show_build_controls()
	elif _has_selection():
		_show_selection_controls()
	elif shop_open:
		_show_shop()
		showing_shop = true
	else:
		_show_icon_bar()
	_shop.visible = showing_shop
	_bar.visible = not showing_shop
	_primary_card.visible = _primary.get_child_count() > 0
	_refresh_in_place()


## O que define o painel: modo, móvel selecionado, estado do fogão, se há próxima expansão e a loja.
func _signature() -> Array:
	var stove_status := -1
	if _has_selection() and cafe.simulation.kitchen.is_stove(cafe.selected_id):
		stove_status = cafe.simulation.kitchen.stove_status(cafe.selected_id)
	return [cafe.mode, cafe.selected_id if _has_selection() else &"", stove_status,
		cafe.session != null and cafe.session.is_moving(), cafe.simulation.next_expansion().is_empty(), shop_tab, shop_open]


func _refresh_in_place() -> void:
	if _message_source.is_valid():
		_message.text = _message_source.call()
	_message.visible = not _message.text.is_empty()
	for updater in _updaters:
		updater.call()


func _has_selection() -> bool:
	return cafe.selected_id != &"" and cafe.layout.get_placement(cafe.selected_id) != null


# --- Faixa de ícones -------------------------------------------------------------

func _show_icon_bar() -> void:
	_message_source = func() -> String: return _problem_text()
	_add_icon(_buttons, "ShopButton", "loja", "Loja", func() -> void: open_shop(ShopTab.SALON))
	_add_icon(_buttons, "RenovateButton", "rolo", "Reformar", func() -> void: open_shop(ShopTab.FLOOR))
	_add_expand_button()
	_add_icon(_buttons, "MissionsBarButton", "prancheta", "Missões", func() -> void:
		var missions := cafe.hud.find_child("MissionsButton", true, false) as Button
		if missions != null:
			missions.pressed.emit())
	_add_icon(_buttons, "GiftsBarButton", "presente", "Presentes", func() -> void: cafe.hud.daily_requested.emit())
	_add_icon(_buttons, "AchievementsBarButton", "trofeu", "Conquistas", func() -> void: cafe.hud.show_achievements())


## Botão da faixa: o ícone da arte em cima e o nome embaixo.
func _add_icon(row: HBoxContainer, button_name: String, icon: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	var sprite := ArtSprites.get_sprite("icone_" + icon)
	if sprite != null:
		button.icon = sprite.texture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", 44)
	button.custom_minimum_size = ICON_BUTTON_SIZE
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", UiTheme.TEXT)
	button.add_theme_color_override("font_hover_color", UiTheme.BLUE)
	button.add_theme_color_override("font_pressed_color", UiTheme.BLUE_DARK)
	button.add_theme_color_override("font_disabled_color", UiTheme.DISABLED)
	button.add_theme_color_override("font_outline_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_size_override("font_size", 13)
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.pressed.connect(func() -> void: action.call())
	row.add_child(button)
	return button


func _add_expand_button() -> void:
	var simulation := cafe.simulation
	if simulation.next_expansion().is_empty():
		return
	var expand := _add_icon(_buttons, "ExpandButton", "expandir", "", ask_expand)
	expand.custom_minimum_size = Vector2(108, ICON_BUTTON_SIZE.y)
	_updaters.append(func() -> void:
		var next := simulation.next_expansion()
		if next.is_empty():
			return
		var size: Vector2i = next["size"]
		if int(next["level"]) > simulation.progression.level:
			expand.text = "Expandir\nNível %d" % int(next["level"])
		else:
			expand.text = "Expandir\n%d×%d · %d" % [size.x, size.y, int(next["price"])]
		expand.disabled = simulation.can_expand() != ServiceResult.OK)


# --- Loja ------------------------------------------------------------------

func _show_shop() -> void:
	_message_source = func() -> String: return _problem_text()
	for tab in SHOP_TAB_NAMES:
		var this_tab: ShopTab = tab
		var button := Button.new()
		button.name = "Tab_" + ShopTab.keys()[tab]
		button.text = SHOP_TAB_NAMES[tab]
		button.toggle_mode = true
		button.button_pressed = tab == shop_tab
		button.custom_minimum_size = TAB_SIZE
		button.focus_mode = Control.FOCUS_NONE
		var color: Color = SHOP_TAB_COLORS[tab]
		var active: bool = tab == shop_tab
		for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			button.add_theme_stylebox_override(state, _tab_box(Color.WHITE if active else color, color.darkened(0.3),
				state == "hover" and not active))
		button.add_theme_color_override("font_color", UiTheme.TEXT if active else Color.WHITE)
		button.add_theme_color_override("font_hover_color", UiTheme.TEXT if active else Color.WHITE)
		button.add_theme_color_override("font_pressed_color", UiTheme.TEXT)
		button.add_theme_color_override("font_outline_color", Color.WHITE if active else color.darkened(0.45))
		button.add_theme_constant_override("outline_size", 0 if active else 4)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(func() -> void: show_shop_tab(this_tab))
		_tabs.add_child(button)
	match shop_tab:
		ShopTab.SALON, ShopTab.KITCHEN, ShopTab.DECOR:
			_show_furniture(SHOP_TAB_CATEGORIES[shop_tab])
		ShopTab.FLOOR:
			_show_surfaces(SurfaceDefinition.Kind.FLOOR)
		ShopTab.WALL:
			_show_surfaces(SurfaceDefinition.Kind.WALL)


## Aba como as das pranchas: cantos de cima redondos, a ativa branca (emendada no painel).
func _tab_box(fill: Color, edge: Color, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill.lightened(0.12) if hover else fill
	box.border_color = edge
	box.set_border_width_all(2)
	box.border_width_bottom = 0
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.anti_aliasing = true
	return box


func _show_furniture(categories: Array) -> void:
	var simulation := cafe.simulation
	for definition in cafe.catalog.all():
		if not categories.has(definition.category):
			continue
		var furniture := definition
		var item := _add_item("Build_" + String(furniture.id), furniture.display_name,
			ArtSprites.furniture(furniture.id, 3), func() -> void: _pick_furniture(furniture.id))
		_updaters.append(func() -> void:
			var stored := simulation.inventory.count(furniture.id)
			var locked := furniture.min_level > simulation.progression.level
			if stored > 0:
				item.text = "%s\n%d guardado%s" % [furniture.display_name, stored, "" if stored == 1 else "s"]
				item.show_state(furniture.price, 0, "%d guardado%s" % [stored, "" if stored == 1 else "s"], true)
			elif locked:
				item.text = "%s\nNível %d" % [furniture.display_name, furniture.min_level]
				item.show_state(furniture.price, furniture.min_level, "", false)
			else:
				item.text = "%s\n%d ouro" % [furniture.display_name, furniture.price]
				item.show_state(furniture.price, 0, "", simulation.wallet.can_afford(Wallet.SOFT, furniture.price))
			item.disabled = simulation.can_acquire(furniture) != ServiceResult.OK)


## Escolheu um móvel na loja: a loja fecha para o salão aparecer e a construção começa.
func _pick_furniture(furniture_id: StringName) -> void:
	if cafe.start_placing(furniture_id):
		shop_open = false
	_request_rebuild()


func _show_surfaces(kind: SurfaceDefinition.Kind) -> void:
	var simulation := cafe.simulation
	for definition in simulation.surfaces.all(kind):
		var surface := definition
		var art := ArtSprites.floor_tile(surface.id, Vector2i.ZERO) if kind == SurfaceDefinition.Kind.FLOOR \
			else ArtSprites.wall_panel(surface.id, "R")
		var item := _add_item("Surface_" + String(surface.id), surface.display_name, art,
			func() -> void: ask_use_surface(surface.id))
		_updaters.append(func() -> void:
			var in_use := simulation.style.current(surface.kind) == surface.id
			var locked := surface.min_level > simulation.progression.level
			if in_use:
				item.text = "%s\nEm uso" % surface.display_name
				item.show_state(surface.price, 0, "Em uso", true)
			elif simulation.style.owns(surface.id):
				item.text = "%s\nAplicar" % surface.display_name
				item.show_state(surface.price, 0, "Aplicar", true)
			elif locked:
				item.text = "%s\nNível %d" % [surface.display_name, surface.min_level]
				item.show_state(surface.price, surface.min_level, "", false)
			else:
				item.text = "%s\n%d ouro" % [surface.display_name, surface.price]
				item.show_state(surface.price, 0, "", simulation.wallet.can_afford(Wallet.SOFT, surface.price))
			item.disabled = in_use or simulation.can_use_surface(surface) != ServiceResult.OK)


func _add_item(button_name: String, title: String, art: ArtSprites.Sprite, action: Callable) -> ShopItemButton:
	var item := ShopItemButton.new()
	item.name = button_name
	item.title = title
	item.art = art
	item.pressed.connect(func() -> void: action.call())
	_items.add_child(item)
	return item


## Pede confirmação antes de gastar com a expansão (seção 32: nada de compra acidental).
func ask_expand() -> void:
	var step := cafe.simulation.next_expansion()
	if step.is_empty():
		return
	var size: Vector2i = step["size"]
	_ask("Expandir a cafeteria?", "Aumentar a cafeteria para %d×%d por %d Café Ouro?" % [size.x, size.y, int(step["price"])],
		"Expandir", func() -> void: cafe.expand_cafe())


## Venda sempre pede confirmação: ela não tem volta.
func ask_sell_selected() -> void:
	var placement := cafe.layout.get_placement(cafe.selected_id)
	if placement == null:
		return
	var check := cafe.simulation.can_sell(placement.id)
	if check != ServiceResult.OK:
		cafe.last_service_result = check
		_refresh_in_place()
		return
	var definition := placement.definition
	_ask("Vender móvel?", "Vender %s por %d Café Ouro? Ele sai da cafeteria de vez. (Para só tirar do lugar, use Guardar.)" % [
		definition.display_name, cafe.simulation.sell_price(definition)], "Vender", cafe.sell_selected)


## Revestimento já comprado: aplica na hora. Ainda não comprado: pede confirmação.
func ask_use_surface(surface_id: StringName) -> void:
	var surface := cafe.simulation.surfaces.get_definition(surface_id)
	if surface == null:
		return
	if cafe.simulation.style.owns(surface_id) or surface.price == 0:
		cafe.use_surface(surface_id)
		return
	_ask("Comprar revestimento?", "Comprar %s por %d Café Ouro? Depois de comprado, trocar é grátis." % [surface.display_name, surface.price],
		"Comprar", func() -> void: cafe.use_surface(surface_id))


func _ask(title: String, text: String, ok_text: String, action: Callable) -> void:
	_pending_confirm = action
	_confirm_dialog.title = title
	_confirm_dialog.dialog_text = text
	_confirm_dialog.ok_button_text = ok_text
	_confirm_dialog.popup_centered()
	# O botão já selecionado é o seguro: um Enter sem querer não gasta nada.
	_confirm_dialog.get_cancel_button().grab_focus()


# --- Móvel selecionado ---------------------------------------------------------

func _show_selection_controls() -> void:
	var placement := cafe.layout.get_placement(cafe.selected_id)
	var kitchen := cafe.simulation.kitchen
	var id := placement.id
	if kitchen.is_stove(id):
		_message_source = func() -> String: return _with_problem(_stove_message(id))
		_show_stove_controls(id)
	elif kitchen.is_counter(id):
		_message_source = func() -> String:
			var stack := kitchen.counter_stack(id)
			return _with_problem("Balcão vazio" if stack == null else "Balcão: %s ×%d" % [stack.recipe.display_name, stack.servings])
	else:
		var name := placement.definition.display_name
		_message_source = func() -> String: return _with_problem(name)
	_add_square(_buttons, "MoveButton", "move", "Mover", cafe.start_moving_selected)
	_add_square(_buttons, "RotateButton", "rotate", "Girar", cafe.rotate_selected)
	_add_square(_buttons, "RemoveButton", "store", "Guardar", cafe.remove_selected)
	_add_square(_buttons, "SellButton", "sell", "Vender", ask_sell_selected)
	_add_square(_buttons, "CloseButton", "close", "Fechar", cafe.clear_selection)


## Botão quadrado da arte com o nome embaixo.
func _add_square(row: HBoxContainer, button_name: String, kind: String, text: String, action: Callable) -> Button:
	var button := UiTheme.icon_button(button_name, kind, text, 48)
	button.custom_minimum_size = ICON_BUTTON_SIZE
	button.pressed.connect(func() -> void: action.call())
	row.add_child(button)
	return button


func _show_stove_controls(stove_id: StringName) -> void:
	var simulation := cafe.simulation
	match simulation.kitchen.stove_status(stove_id):
		Kitchen.StoveStatus.IDLE:
			for recipe in simulation.recipes.all():
				var dish := recipe
				var button := _add_recipe(dish, func() -> void: cafe.cook_on_selected(dish.id))
				_updaters.append(func() -> void:
					var locked := dish.unlock_level > simulation.progression.level
					if locked:
						button.text = "%s\nNível %d" % [dish.display_name, dish.unlock_level]
					else:
						button.text = "%s\n%s · %d ouro" % [dish.display_name, WorldLayer.format_time(dish.cook_time), dish.ingredient_cost]
					button.disabled = locked or not simulation.wallet.can_afford(Wallet.SOFT, dish.ingredient_cost))
		Kitchen.StoveStatus.READY:
			var serve := Button.new()
			serve.name = "ServeButton"
			serve.text = "Levar ao balcão"
			serve.custom_minimum_size = Vector2(200, 56)
			serve.focus_mode = Control.FOCUS_NONE
			var green := Color("3cc04e")
			for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
				serve.add_theme_stylebox_override(state, UiTheme.button_box(green.lightened(0.1) if state == "hover" else green, Color("177a28")))
			serve.add_theme_color_override("font_outline_color", Color("177a28"))
			serve.add_theme_font_size_override("font_size", 18)
			var dish_icon := ArtSprites.food(simulation.kitchen.stove_recipe(stove_id).id)
			if dish_icon != null:
				serve.icon = dish_icon.texture
				serve.add_theme_constant_override("icon_max_width", 34)
			serve.pressed.connect(func() -> void: cafe.collect_stove(stove_id))
			_primary.add_child(serve)


## Cartão da receita: o desenho do prato em cima, o nome e o tempo e o custo embaixo.
func _add_recipe(dish: RecipeDefinition, action: Callable) -> Button:
	var button := Button.new()
	button.name = "Cook_" + String(dish.id)
	var food := ArtSprites.food(dish.id)
	if food != null:
		button.icon = food.texture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", 44)
	button.custom_minimum_size = RECIPE_BUTTON_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var normal := UiTheme.card_box(12, 6)
	normal.shadow_size = 2
	var hover := UiTheme.card_box(12, 6, UiTheme.BLUE)
	hover.shadow_size = 2
	var disabled := UiTheme.card_box(12, 6)
	disabled.bg_color = Color("f1f4f8")
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("hover_pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", disabled)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color_name, UiTheme.TEXT)
	button.add_theme_color_override("font_disabled_color", UiTheme.DISABLED)
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(func() -> void: action.call())
	_primary.add_child(button)
	return button


func _stove_message(id: StringName) -> String:
	var kitchen := cafe.simulation.kitchen
	match kitchen.stove_status(id):
		Kitchen.StoveStatus.COOKING:
			return "Fogão: %s fica pronto em %s" % [kitchen.stove_recipe(id).display_name, WorldLayer.format_time(kitchen.time_left(id))]
		Kitchen.StoveStatus.READY:
			return "Fogão: %s pronto! Toque no fogão para levar ao balcão" % kitchen.stove_recipe(id).display_name
	return "Fogão livre: escolha o que cozinhar"


# --- Construção ------------------------------------------------------------------

func _show_build_controls() -> void:
	var simulation := cafe.simulation
	_message_source = func() -> String:
		var session := cafe.session
		if session == null:
			return ""
		var verb := "Movendo" if session.is_moving() else "Posicionando"
		var cost := ""
		if not session.is_moving():
			cost = " (guardado)" if simulation.inventory.count(session.definition.id) > 0 \
				else " (%d ouro)" % session.definition.price
		var problem: String = CHECK_MESSAGES[cafe.last_check]
		if cafe.last_check == CafeLayout.Check.OK and cafe.last_service_result != ServiceResult.OK:
			problem = SERVICE_MESSAGES.get(cafe.last_service_result, "")
		return "%s: %s%s  —  %s" % [verb, session.definition.display_name, cost, problem]
	_add_square(_buttons, "RotateButton", "rotate", "Girar", cafe.rotate_placement)
	var confirm := _add_square(_buttons, "ConfirmButton", "check", "Confirmar", cafe.confirm_placement)
	_updaters.append(func() -> void:
		confirm.disabled = cafe.last_check != CafeLayout.Check.OK
		confirm.modulate = Color(1, 1, 1, 0.45) if confirm.disabled else Color.WHITE)
	_add_square(_buttons, "CancelButton", "close", "Cancelar", cafe.cancel_placement)


# --- Comum -----------------------------------------------------------------------

## Acrescenta o motivo da última recusa, se houver.
func _with_problem(text: String) -> String:
	var problem := _problem_text()
	return text if problem.is_empty() else "%s  —  %s" % [text, problem]


## Motivo da última recusa (posição ou cozinha/loja), ou vazio.
func _problem_text() -> String:
	if cafe.last_check != CafeLayout.Check.OK:
		return CHECK_MESSAGES[cafe.last_check]
	return SERVICE_MESSAGES.get(cafe.last_service_result, "")
