class_name BuildBar
extends CanvasLayer
## Interface de baixo, no formato da v3 (o do jogo antigo, desenho nosso).
##
## Mostra, conforme o estado da cafeteria:
## - nada selecionado: a faixa de ícones (Loja, Reformar, Expandir, Missões,
##   Presentes, Conquistas); a Loja abre o painel em abas (Salão, Cozinha,
##   Decoração, Pisos, Paredes) com os quadradinhos dos itens;
## - fogão selecionado: o livro de receitas, em abas (DT-053), com as estrelas de domínio de cada receita (ou o
##   tempo que falta), e as ações do móvel;
## - balcão selecionado: o que tem nele, e as ações do móvel;
## - outro móvel selecionado: Mover, Girar, Guardar, Vender e Fechar;
## - construindo: instrução ou motivo da recusa, preço, Girar, Confirmar e Cancelar.
##
## Os botões só são recriados quando o tipo de painel muda. Preços, bloqueios,
## tempos e mensagens são atualizados no lugar a cada frame, para um clique
## nunca se perder porque um cliente pagou no meio dele.

const ICON_BUTTON_SIZE := Vector2(92, 74)
## Quadradinhos por página da loja.
const ITEMS_PER_PAGE := 6
const RECIPE_BUTTON_SIZE := Vector2(132, 92)
## Receitas por página de uma aba do livro.
const RECIPES_PER_PAGE := 6
## Lado das estrelas de domínio no cartão da receita.
const MASTERY_STAR_SIZE := 16.0
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
	ServiceResult.NO_MORE_WAITERS: "A equipe de garçons já está completa",
	ServiceResult.WAITER_LOCKED: "O próximo garçom ainda está bloqueado",
	ServiceResult.NOT_WAITING_FOR_DRINK: "Esse cliente não pediu bebida",
	ServiceResult.NO_MACHINE: "Falta a máquina dessa bebida: compre na Loja, aba Cozinha",
	ServiceResult.NOT_ENOUGH_ENERGY: "Sem energia: ela volta sozinha, 1 ponto por minuto",
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
	ShopTab.KITCHEN: [FurnitureDefinition.Category.COOKING, FurnitureDefinition.Category.COUNTER,
		FurnitureDefinition.Category.MACHINE],
	ShopTab.DECOR: [FurnitureDefinition.Category.DECOR],
}

var cafe: Cafe
var shop_tab := ShopTab.SALON
## A loja está aberta (no lugar da faixa de ícones)?
var shop_open := false
## Coleção escolhida na loja (&"" = todas) e a página dos quadradinhos.
var shop_collection: StringName = &""
var shop_page := 0
## Aba do livro de receitas escolhida em cada fogão (id do fogão -> id da aba) e a página de cada aba. Sem escolha,
## o livro abre na aba de um prato que algum cliente espera (ou na primeira).
var _chosen_book := {}
var _recipe_page := {}

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
var _chips: HBoxContainer
var _items: HBoxContainer
var _prev_page: Button
var _remove_card: WallItemDefinition
var _next_page: Button
var _page_label: Label
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
	var shop_column := VBoxContainer.new()
	shop_column.add_theme_constant_override("separation", 8)
	shop_card.add_child(shop_column)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	shop_column.add_child(top_row)
	_chips = HBoxContainer.new()
	_chips.name = "Collections"
	_chips.add_theme_constant_override("separation", 5)
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_chips)
	var close := UiTheme.icon_button("CloseShopButton", "close", "", 34)
	close.tooltip_text = "Fechar a loja"
	close.pressed.connect(close_shop)
	top_row.add_child(close)
	var shop_row := HBoxContainer.new()
	shop_row.add_theme_constant_override("separation", 10)
	shop_column.add_child(shop_row)
	_prev_page = UiTheme.icon_button("PrevPageButton", "left", "", 36)
	_prev_page.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_prev_page.pressed.connect(func() -> void: show_shop_page(shop_page - 1))
	shop_row.add_child(_prev_page)
	_items = _row("Items")
	_items.custom_minimum_size = Vector2(ITEMS_PER_PAGE * (ShopItemButton.CARD_SIZE.x + 10) - 10, ShopItemButton.CARD_SIZE.y)
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_row.add_child(_items)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_row.add_child(right)
	_next_page = UiTheme.icon_button("NextPageButton", "right", "", 36)
	_next_page.pressed.connect(func() -> void: show_shop_page(shop_page + 1))
	right.add_child(_next_page)
	_page_label = Label.new()
	_page_label.name = "PageLabel"
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 13)
	_page_label.add_theme_color_override("font_color", UiTheme.TEXT_SOFT)
	right.add_child(_page_label)

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
	for row: Node in [_primary, _buttons, _tabs, _chips, _items]:
		var button := row.find_child(button_name, true, false) as Button
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


## Troca a aba da loja (e abre a loja, se estiver fechada). A coleção e a página voltam ao começo.
func show_shop_tab(tab: ShopTab) -> void:
	if tab != shop_tab:
		shop_collection = &""
		shop_page = 0
	open_shop(tab)


## Mostra só os itens de uma coleção (&"" = todas), a partir da primeira página.
func show_shop_collection(collection: StringName) -> void:
	shop_collection = collection
	shop_page = 0
	_request_rebuild()


func show_shop_page(page: int) -> void:
	shop_page = clampi(page, 0, shop_page_count() - 1)
	_request_rebuild()


## Ids de todos os itens da aba e da coleção escolhidas (em todas as páginas), na ordem da loja.
func shop_item_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for item: Resource in _shop_items():
		ids.append(item.id)
	return ids


func shop_page_count() -> int:
	return maxi(1, ceili(_shop_items().size() / float(ITEMS_PER_PAGE)))


## Definições da aba atual (móveis ou revestimentos), filtradas pela coleção.
func _shop_items() -> Array:
	var items: Array = []
	match shop_tab:
		ShopTab.FLOOR, ShopTab.WALL:
			var kind := SurfaceDefinition.Kind.FLOOR if shop_tab == ShopTab.FLOOR else SurfaceDefinition.Kind.WALL
			items.assign(cafe.simulation.surfaces.all(kind))
			if shop_tab == ShopTab.WALL:
				items.append_array(cafe.simulation.wall_items.all())
				items.append(_remove_item_card())
		_:
			for definition in cafe.catalog.all():
				if SHOP_TAB_CATEGORIES[shop_tab].has(definition.category):
					items.append(definition)
	if shop_collection != &"":
		items = items.filter(func(item: Resource) -> bool: return item.collection == shop_collection)
	return items


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
	for row: Node in [_primary, _buttons, _tabs, _chips, _items]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_updaters.clear()

	var showing_shop := false
	if cafe.mode == Cafe.Mode.BUILD:
		_show_build_controls()
	elif cafe.mode == Cafe.Mode.PAINT:
		_show_paint_controls()
	elif _has_selection():
		_show_selection_controls()
	elif shop_open:
		_show_shop()
		showing_shop = true
	else:
		_show_icon_bar()
	if showing_shop and not _shop.visible:
		Juice.fade_in(_shop)
	_shop.visible = showing_shop
	_bar.visible = not showing_shop
	_primary_card.visible = _primary.get_child_count() > 0
	_refresh_in_place()


## O que define o painel: modo, móvel selecionado, estado do fogão, se há próxima expansão e a loja.
func _signature() -> Array:
	var stove_status := -1
	if _has_selection() and cafe.simulation.kitchen.is_stove(cafe.selected_id):
		stove_status = cafe.simulation.kitchen.stove_status(cafe.selected_id)
	var book: StringName = _chosen_book.get(cafe.selected_id, &"") if _has_selection() else &""
	return [cafe.mode, cafe.selected_id if _has_selection() else &"", stove_status,
		cafe.session != null and cafe.session.is_moving(), cafe.simulation.next_expansion().is_empty(), shop_tab, shop_open,
		shop_collection, shop_page, book, _recipe_page.get(book, 0)]


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
	_add_hire_button()
	_add_icon(_buttons, "MissionsBarButton", "prancheta", "Missões", func() -> void: cafe.hud.show_missions())
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


## Contratar garçom: mostra o preço, o nível que falta ou que a equipe está completa.
func _add_hire_button() -> void:
	var simulation := cafe.simulation
	var hire := _add_icon(_buttons, "HireButton", "garcom", "", ask_hire_waiter)
	hire.custom_minimum_size = Vector2(100, ICON_BUTTON_SIZE.y)
	_updaters.append(func() -> void:
		var price := simulation.next_waiter_price()
		if price < 0:
			hire.text = "Garçons\nCompleto"
		elif simulation.next_waiter_level() > simulation.progression.level:
			hire.text = "Garçom\nNível %d" % simulation.next_waiter_level()
		else:
			hire.text = "Garçom\n%s" % UiTheme.thousands(price)
		hire.disabled = simulation.can_hire_waiter() != ServiceResult.OK)


## Contratar custa caro: pede confirmação (o botão já selecionado é o Cancelar).
func ask_hire_waiter() -> void:
	var price := cafe.simulation.next_waiter_price()
	if price < 0:
		return
	_ask("Contratar garçom?", "Contratar mais um garçom por %s Café Ouro? Ele busca os pratos prontos nos fogões e serve as mesas." % [
		UiTheme.thousands(price)], "Contratar", func() -> void: cafe.hire_waiter())


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
	_show_collection_chips()
	shop_page = clampi(shop_page, 0, shop_page_count() - 1)
	var page := _shop_items().slice(shop_page * ITEMS_PER_PAGE, (shop_page + 1) * ITEMS_PER_PAGE)
	for item: Resource in page:
		if item is FurnitureDefinition:
			_add_furniture_item(item)
		elif item is WallItemDefinition:
			_add_wall_item(item)
		else:
			_add_surface_item(item)
	var pages := shop_page_count()
	_prev_page.disabled = shop_page == 0
	_next_page.disabled = shop_page >= pages - 1
	_prev_page.modulate.a = 0.35 if _prev_page.disabled else 1.0
	_next_page.modulate.a = 0.35 if _next_page.disabled else 1.0
	_page_label.text = "%d/%d" % [shop_page + 1, pages]


## Fileira de coleções: "Todas" e as que têm itens nesta aba, cada uma na sua cor.
func _show_collection_chips() -> void:
	var present := {}
	var saved := shop_collection
	shop_collection = &""
	for item: Resource in _shop_items():
		present[item.collection] = true
	shop_collection = saved
	_add_chip("Collection_all", "Todas", UiTheme.BLUE, shop_collection == &"", &"")
	for collection in cafe.simulation.collections.all():
		if present.has(collection.id):
			_add_chip("Collection_" + String(collection.id), collection.display_name, collection.color,
				shop_collection == collection.id, collection.id)


func _add_chip(chip_name: String, text: String, color: Color, active: bool, collection: StringName) -> void:
	var chip := Button.new()
	chip.name = chip_name
	chip.text = text
	chip.toggle_mode = true
	chip.button_pressed = active
	chip.focus_mode = Control.FOCUS_NONE
	chip.custom_minimum_size = Vector2(0, 30)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color if active else (Color.WHITE if state != "hover" else color.lightened(0.85))
		box.border_color = color.darkened(0.2)
		box.set_border_width_all(2)
		box.set_corner_radius_all(15)
		box.content_margin_left = 12
		box.content_margin_right = 12
		box.content_margin_top = 3
		box.content_margin_bottom = 3
		box.anti_aliasing = true
		chip.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		chip.add_theme_color_override(color_name, Color.WHITE if active else color.darkened(0.35))
	chip.add_theme_constant_override("outline_size", 3 if active else 0)
	chip.add_theme_color_override("font_outline_color", color.darkened(0.45))
	chip.add_theme_font_size_override("font_size", 14)
	chip.pressed.connect(func() -> void: show_shop_collection(collection))
	_chips.add_child(chip)


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


func _add_furniture_item(furniture: FurnitureDefinition) -> void:
	var simulation := cafe.simulation
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


## Escolheu um móvel na loja: a loja some enquanto ele é posicionado e volta depois, na mesma aba,
## coleção e página (para comprar a cadeira logo depois da mesa).
func _pick_furniture(furniture_id: StringName) -> void:
	cafe.start_placing(furniture_id)
	_request_rebuild()


## Cartão "Tirar enfeite" no fim da aba Paredes: um item sem id, que tira o que estiver pendurado.
func _remove_item_card() -> WallItemDefinition:
	if _remove_card == null:
		_remove_card = WallItemDefinition.new()
		_remove_card.display_name = "Tirar enfeite"
	return _remove_card


func _add_wall_item(wall_item: WallItemDefinition) -> void:
	var simulation := cafe.simulation
	var art := ArtSprites.get_sprite("enfeite_%s_R" % wall_item.art) if wall_item.id != &"" else ArtSprites.get_sprite("botao_close")
	var item := _add_item("WallItem_" + (String(wall_item.id) if wall_item.id != &"" else "remove"), wall_item.display_name, art,
		func() -> void: cafe.start_hanging(wall_item.id))
	_updaters.append(func() -> void:
		var locked := wall_item.min_level > simulation.progression.level
		if wall_item.id == &"":
			item.show_state(0, 0, "Grátis", true)
		elif locked:
			item.show_state(wall_item.price, wall_item.min_level, "", false)
		else:
			item.show_state(wall_item.price, 0, "", simulation.wallet.can_afford(Wallet.SOFT, wall_item.price))
		item.disabled = locked)


func _add_surface_item(surface: SurfaceDefinition) -> void:
	var simulation := cafe.simulation
	var art := ArtSprites.floor_tile(surface.id, Vector2i.ZERO) if surface.kind == SurfaceDefinition.Kind.FLOOR \
		else ArtSprites.wall_panel(surface.id, "R")
	var item := _add_item("Surface_" + String(surface.id), surface.display_name, art,
		func() -> void: cafe.start_painting(surface.id))
	var unit := "/piso" if surface.kind == SurfaceDefinition.Kind.FLOOR else "/parede"
	item.price_suffix = unit
	_updaters.append(func() -> void:
		var price := simulation.paint_price(surface)
		var locked := not simulation.style.owns(surface.id) and surface.min_level > simulation.progression.level
		if locked:
			item.text = "%s\nNível %d" % [surface.display_name, surface.min_level]
			item.show_state(price, surface.min_level, "", false)
		elif price == 0:
			item.text = "%s\nGrátis" % surface.display_name
			item.show_state(0, 0, "Grátis", true)
		else:
			item.text = "%s\n%d ouro%s" % [surface.display_name, price, unit]
			item.show_state(price, 0, "", simulation.wallet.can_afford(Wallet.SOFT, price))
		item.disabled = locked)


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
			var cards := _show_recipe_book(stove_id)
			for recipe in _book_page(current_book(stove_id)):
				var dish := recipe
				var button := _add_recipe(dish, func() -> void: cafe.cook_on_selected(dish.id), cards)
				_add_mastery_stars(button, dish)
				var badge := _add_demand_badge(button)
				_updaters.append(func() -> void:
					var waiting := int(simulation.waiting_demand().get(dish.id, 0))
					badge.visible = waiting > 0
					badge.text = str(waiting)
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
## Bolinha vermelha no canto da receita: quantos clientes esperam esse prato (que não está no balcão).
# --- Reforma ---------------------------------------------------------------------

## Reforma: marcar pisos (ou trechos de parede) tocando neles, Tudo, Limpar, Confirmar e Cancelar.
func _show_paint_controls() -> void:
	var floor := cafe.is_painting_floor()
	var hanging := cafe.hanging_items
	_message_source = func() -> String:
		var count := cafe.paint_target_count()
		var cost := cafe.paint_cost()
		var where := "pisos" if floor else ("paredes do fundo" if hanging else "trechos de parede")
		var text := "%s: %s — toque nos %s para marcar" % ["Parede" if hanging else "Reforma", cafe.paint_subject(), where]
		text += "  (%d marcados · %s)" % [count, "%s ouro" % UiTheme.thousands(cost) if cost > 0 else "grátis"]
		var problem := _problem_text()
		return text + ("  —  " + problem if not problem.is_empty() else "")
	_add_text_button("PaintAllButton", "Tudo", cafe.paint_all)
	_add_text_button("PaintClearButton", "Limpar", cafe.clear_paint)
	var confirm := _add_square(_buttons, "ConfirmButton", "check", "Confirmar", ask_confirm_paint)
	_updaters.append(func() -> void: confirm.disabled = cafe.paint_target_count() == 0)
	_add_square(_buttons, "CancelButton", "close", "Cancelar", cafe.cancel_paint)


## Reforma paga pede confirmação (Cancelar já selecionado); de graça, aplica direto.
func ask_confirm_paint() -> void:
	var count := cafe.paint_target_count()
	if count == 0:
		return
	var cost := cafe.paint_cost()
	if cost == 0:
		cafe.confirm_paint()
		return
	if cafe.hanging_items:
		_ask("Pendurar?", "Pendurar %s em %d trecho(s) de parede por %s Café Ouro? O que estiver lá sai." % [
			cafe.paint_subject(), count, UiTheme.thousands(cost)], "Pendurar", func() -> void: cafe.confirm_paint())
		return
	var what := "pisos" if cafe.is_painting_floor() else "trechos de parede"
	_ask("Reformar?", "Pintar %d %s com %s por %s Café Ouro?" % [count, what, cafe.paint_subject(), UiTheme.thousands(cost)],
		"Reformar", func() -> void: cafe.confirm_paint())


func _add_text_button(button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = Vector2(96, 52)
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, UiTheme.button_box(UiTheme.BLUE.lightened(0.1) if state == "hover" else UiTheme.BLUE,
			UiTheme.BLUE_DARK))
	button.add_theme_color_override("font_outline_color", UiTheme.BLUE_DARK)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(func() -> void: action.call())
	_buttons.add_child(button)
	return button


func _add_demand_badge(button: Button) -> Label:
	var badge := Label.new()
	badge.name = "DemandBadge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(24, 24)
	badge.position = Vector2(RECIPE_BUTTON_SIZE.x - 20, -6)
	badge.tooltip_text = "Clientes esperando este prato"
	var box := StyleBoxFlat.new()
	box.bg_color = Color("e0303a")
	box.border_color = Color.WHITE
	box.set_border_width_all(2)
	box.set_corner_radius_all(12)
	box.anti_aliasing = true
	badge.add_theme_stylebox_override("normal", box)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_font_size_override("font_size", 14)
	badge.visible = false
	button.add_child(badge)
	return badge


## Aba do livro aberta no fogão: a escolhida pelo jogador, ou a de um prato que algum cliente espera, ou a primeira.
func current_book(stove_id: StringName) -> StringName:
	var recipes := cafe.simulation.recipes
	var chosen: StringName = _chosen_book.get(stove_id, &"")
	if recipes.get_book(chosen) != null:
		return chosen
	var demand := cafe.simulation.waiting_demand()
	for recipe in recipes.all():
		if demand.has(recipe.id) and recipes.get_book(recipe.book) != null:
			return recipe.book
	var books := recipes.books()
	return books[0].id if not books.is_empty() else &""


## Abre outra aba do livro de receitas no fogão escolhido.
func show_recipe_book(book_id: StringName) -> void:
	if _has_selection():
		_chosen_book[cafe.selected_id] = book_id
		_request_rebuild()


## Troca a página da aba do livro aberta no fogão escolhido.
func show_recipe_page(page: int) -> void:
	if not _has_selection():
		return
	var book := current_book(cafe.selected_id)
	_recipe_page[book] = clampi(page, 0, recipe_page_count(book) - 1)
	_request_rebuild()


func recipe_page_count(book_id: StringName) -> int:
	return maxi(1, ceili(cafe.simulation.recipes.in_book(book_id).size() / float(RECIPES_PER_PAGE)))


## Receitas da página atual da aba.
func _book_page(book_id: StringName) -> Array[RecipeDefinition]:
	var recipes := cafe.simulation.recipes.in_book(book_id)
	var page := clampi(int(_recipe_page.get(book_id, 0)), 0, recipe_page_count(book_id) - 1)
	return recipes.slice(page * RECIPES_PER_PAGE, (page + 1) * RECIPES_PER_PAGE)


## O livro de receitas no cartão de cima: as abas (com uma bolinha onde há prato esperado) e a fileira dos cartões,
## com as setas de página quando a aba não cabe numa fileira só. Retorna a fileira dos cartões.
func _show_recipe_book(stove_id: StringName) -> HBoxContainer:
	var simulation := cafe.simulation
	var book := current_book(stove_id)
	var column := VBoxContainer.new()
	column.name = "RecipeBook"
	column.add_theme_constant_override("separation", 8)
	_primary.add_child(column)
	var tabs := HBoxContainer.new()
	tabs.name = "RecipeBooks"
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	column.add_child(tabs)
	for entry in simulation.recipes.books():
		var book_id := entry.id
		var chip := _book_chip(entry, book_id == book)
		chip.pressed.connect(func() -> void: show_recipe_book(book_id))
		tabs.add_child(chip)
		var dot := _add_demand_badge(chip)
		dot.name = "BookDemand"
		dot.position = Vector2(-8, -8)
		dot.tooltip_text = "Clientes esperando um prato desta aba"
		_updaters.append(func() -> void:
			var waiting := 0
			var demand := simulation.waiting_demand()
			for recipe in simulation.recipes.in_book(book_id):
				waiting += int(demand.get(recipe.id, 0))
			dot.visible = waiting > 0
			dot.text = str(waiting))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var pages := recipe_page_count(book)
	var page := clampi(int(_recipe_page.get(book, 0)), 0, pages - 1)
	if pages > 1:
		var prev := UiTheme.icon_button("RecipePrevButton", "left", "", 32)
		prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		prev.disabled = page == 0
		prev.pressed.connect(func() -> void: show_recipe_page(page - 1))
		row.add_child(prev)
	var cards := HBoxContainer.new()
	cards.name = "Recipes"
	cards.add_theme_constant_override("separation", 10)
	row.add_child(cards)
	if pages > 1:
		var next := UiTheme.icon_button("RecipeNextButton", "right", "", 32)
		next.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		next.disabled = page >= pages - 1
		next.pressed.connect(func() -> void: show_recipe_page(page + 1))
		row.add_child(next)
	return cards


## Aba do livro: pílula na cor da aba, cheia quando é a aberta.
func _book_chip(book: RecipeBookDefinition, active: bool) -> Button:
	var chip := Button.new()
	chip.name = "Book_" + String(book.id)
	chip.text = book.display_name
	chip.toggle_mode = true
	chip.button_pressed = active
	chip.focus_mode = Control.FOCUS_NONE
	chip.custom_minimum_size = Vector2(92, 32)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = book.color if active else (Color.WHITE if state != "hover" else book.color.lightened(0.85))
		box.border_color = book.color.darkened(0.2)
		box.set_border_width_all(2)
		box.set_corner_radius_all(16)
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.anti_aliasing = true
		chip.add_theme_stylebox_override(state, box)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		chip.add_theme_color_override(color_name, Color.WHITE if active else book.color.darkened(0.35))
	chip.add_theme_constant_override("outline_size", 3 if active else 0)
	chip.add_theme_color_override("font_outline_color", book.color.darkened(0.45))
	chip.add_theme_font_size_override("font_size", 15)
	return chip


## Estrelas de domínio no canto do cartão da receita (acesas as ganhas) e quanto falta, na dica.
func _add_mastery_stars(button: Button, dish: RecipeDefinition) -> void:
	var mastery := cafe.simulation.mastery
	var stars := HBoxContainer.new()
	stars.name = "Stars"
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stars.add_theme_constant_override("separation", 0)
	stars.position = Vector2(4, 3)
	button.add_child(stars)
	for i in mastery.config.max_stars():
		var star := TextureRect.new()
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.custom_minimum_size = Vector2(MASTERY_STAR_SIZE, MASTERY_STAR_SIZE)
		stars.add_child(star)
	_updaters.append(func() -> void:
		var earned := mastery.stars(dish.id)
		for i in stars.get_child_count():
			var sprite := ArtSprites.get_sprite("icone_estrela" if i < earned else "icone_estrela_vazia")
			if sprite != null:
				(stars.get_child(i) as TextureRect).texture = sprite.texture
		var goal := mastery.next_goal(dish.id)
		if goal < 0:
			button.tooltip_text = "Domínio completo: %d estrelas" % earned
		else:
			button.tooltip_text = "Domínio: %d de %d pratos para a próxima estrela" % [mastery.count(dish.id), goal])


func _add_recipe(dish: RecipeDefinition, action: Callable, parent: Control = null) -> Button:
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
	(parent if parent != null else _primary).add_child(button)
	return button


func _stove_message(id: StringName) -> String:
	var kitchen := cafe.simulation.kitchen
	match kitchen.stove_status(id):
		Kitchen.StoveStatus.COOKING:
			return "Fogão: %s fica pronto em %s" % [kitchen.stove_recipe(id).display_name, WorldLayer.format_time(kitchen.time_left(id))]
		Kitchen.StoveStatus.READY:
			return "Fogão: %s pronto! O garçom leva ao balcão (ou toque no fogão)" % kitchen.stove_recipe(id).display_name
	var waiting := _demand_text()
	return "Fogão livre: escolha o que cozinhar" + ("  —  Clientes esperando: " + waiting if not waiting.is_empty() else "")


## "Café ×2, Pão de Queijo ×1": pratos pedidos que não estão em nenhum balcão.
func _demand_text() -> String:
	var parts: Array[String] = []
	var demand := cafe.simulation.waiting_demand()
	for recipe in cafe.simulation.recipes.all():
		if demand.has(recipe.id):
			parts.append("%s ×%d" % [recipe.display_name, demand[recipe.id]])
	return ", ".join(parts)


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
