class_name BuildBar
extends CanvasLayer
## PLACEHOLDER_UI: barra inferior do protótipo.
##
## Mostra, conforme o estado da cafeteria:
## - nada selecionado: loja de móveis (preço, nível, guardados) e Expandir;
## - fogão selecionado: receitas para cozinhar (ou o tempo que falta), e as ações do móvel;
## - balcão selecionado: o que tem nele, e as ações do móvel;
## - outro móvel selecionado: Mover, Girar, Guardar e Fechar;
## - construindo: instrução ou motivo da recusa, preço, Girar, Confirmar e Cancelar.
##
## Os botões só são recriados quando o tipo de painel muda. Preços, bloqueios,
## tempos e mensagens são atualizados no lugar a cada frame, para um clique
## nunca se perder porque um cliente pagou no meio dele.

const BUTTON_MIN_SIZE := Vector2(112, 56)
const TWO_LINE_BUTTON_MIN_SIZE := Vector2(124, 64)
const FONT_SIZE := 18
const SMALL_FONT_SIZE := 15

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
}

var cafe: Cafe

var _message: Label
## Linha de cima: receitas do fogão ou "Levar ao balcão". Escondida quando vazia.
var _primary: HBoxContainer
## Linha de baixo: loja, ações do móvel ou controles de construção.
var _buttons: HBoxContainer
var _expand_dialog: ConfirmationDialog

var _rebuild_pending := false
## Identifica o tipo de painel mostrado; só muda de painel quando isto muda.
var _shown_signature: Array = []
## Texto da mensagem, recalculado a cada frame.
var _message_source: Callable
## Atualizadores dos botões (texto, bloqueio), chamados a cada frame.
var _updaters: Array[Callable] = []


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for side in ["left", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.05, 0.85)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	_message = Label.new()
	_message.name = "Message"
	_message.add_theme_font_size_override("font_size", FONT_SIZE)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_message)

	_primary = HBoxContainer.new()
	_primary.name = "Primary"
	_primary.alignment = BoxContainer.ALIGNMENT_CENTER
	_primary.add_theme_constant_override("separation", 8)
	column.add_child(_primary)

	_buttons = HBoxContainer.new()
	_buttons.name = "Buttons"
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)

	_expand_dialog = ConfirmationDialog.new()
	_expand_dialog.name = "ExpandDialog"
	_expand_dialog.title = "Expandir a cafeteria?"
	_expand_dialog.ok_button_text = "Expandir"
	_expand_dialog.cancel_button_text = "Cancelar"
	_expand_dialog.confirmed.connect(func() -> void: cafe.expand_cafe())
	add_child(_expand_dialog)


func bind(target_cafe: Cafe) -> void:
	cafe = target_cafe
	cafe.state_changed.connect(_request_rebuild)
	cafe.simulation.kitchen.changed.connect(_request_rebuild)
	_rebuild()


func message_text() -> String:
	return _message.text


func find_button(button_name: String) -> Button:
	var button := _primary.get_node_or_null(button_name) as Button
	return button if button != null else _buttons.get_node_or_null(button_name) as Button


func expand_dialog() -> ConfirmationDialog:
	return _expand_dialog


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
	for row in [_primary, _buttons]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_updaters.clear()

	if cafe.mode == Cafe.Mode.BUILD:
		_show_build_controls()
	elif _has_selection():
		_show_selection_controls()
	else:
		_show_shop()
	_primary.visible = _primary.get_child_count() > 0
	_refresh_in_place()


## O que define o painel: modo, móvel selecionado, estado do fogão e se há próxima expansão.
func _signature() -> Array:
	var stove_status := -1
	if _has_selection() and cafe.simulation.kitchen.is_stove(cafe.selected_id):
		stove_status = cafe.simulation.kitchen.stove_status(cafe.selected_id)
	return [cafe.mode, cafe.selected_id if _has_selection() else &"", stove_status,
		cafe.session != null and cafe.session.is_moving(), cafe.simulation.next_expansion().is_empty()]


func _refresh_in_place() -> void:
	if _message_source.is_valid():
		_message.text = _message_source.call()
	for updater in _updaters:
		updater.call()


func _has_selection() -> bool:
	return cafe.selected_id != &"" and cafe.layout.get_placement(cafe.selected_id) != null


# --- Loja ------------------------------------------------------------------

func _show_shop() -> void:
	_message_source = func() -> String: return _with_problem("Loja de móveis")
	var simulation := cafe.simulation
	for definition in cafe.catalog.all():
		var furniture := definition
		var button := _add_button(_buttons, "Build_" + String(furniture.id), "", func() -> void: cafe.start_placing(furniture.id), true)
		_updaters.append(func() -> void:
			var stored := simulation.inventory.count(furniture.id)
			if stored > 0:
				button.text = "%s\n%d guardado%s" % [furniture.display_name, stored, "" if stored == 1 else "s"]
			elif furniture.min_level > simulation.progression.level:
				button.text = "%s\nNível %d" % [furniture.display_name, furniture.min_level]
			else:
				button.text = "%s\n%d ouro" % [furniture.display_name, furniture.price]
			button.disabled = simulation.can_acquire(furniture) != ServiceResult.OK)

	var step := simulation.next_expansion()
	if not step.is_empty():
		var expand := _add_button(_buttons, "ExpandButton", "", ask_expand, true)
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


## Pede confirmação antes de gastar com a expansão (seção 32: nada de compra acidental).
func ask_expand() -> void:
	var step := cafe.simulation.next_expansion()
	if step.is_empty():
		return
	var size: Vector2i = step["size"]
	_expand_dialog.dialog_text = "Aumentar a cafeteria para %d×%d por %d Café Ouro?" % [size.x, size.y, int(step["price"])]
	_expand_dialog.popup_centered()
	_expand_dialog.get_cancel_button().grab_focus()


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
	_add_button(_buttons, "MoveButton", "Mover", cafe.start_moving_selected)
	_add_button(_buttons, "RotateButton", "Girar", cafe.rotate_selected)
	_add_button(_buttons, "RemoveButton", "Guardar", cafe.remove_selected)
	_add_button(_buttons, "CloseButton", "Fechar", cafe.clear_selection)


func _show_stove_controls(stove_id: StringName) -> void:
	var simulation := cafe.simulation
	match simulation.kitchen.stove_status(stove_id):
		Kitchen.StoveStatus.IDLE:
			for recipe in simulation.recipes.all():
				var dish := recipe
				var button := _add_button(_primary, "Cook_" + String(dish.id), "", func() -> void: cafe.cook_on_selected(dish.id), true)
				_updaters.append(func() -> void:
					var locked := dish.unlock_level > simulation.progression.level
					if locked:
						button.text = "%s\nNível %d" % [dish.display_name, dish.unlock_level]
					else:
						button.text = "%s\n%s · %d ouro" % [dish.display_name, WorldLayer.format_time(dish.cook_time), dish.ingredient_cost]
					button.disabled = locked or not simulation.wallet.can_afford(Wallet.SOFT, dish.ingredient_cost))
		Kitchen.StoveStatus.READY:
			_add_button(_primary, "ServeButton", "Levar ao balcão", func() -> void: cafe.collect_stove(stove_id))


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
	_add_button(_buttons, "RotateButton", "Girar", cafe.rotate_placement)
	var confirm := _add_button(_buttons, "ConfirmButton", "Confirmar", cafe.confirm_placement)
	_updaters.append(func() -> void: confirm.disabled = cafe.last_check != CafeLayout.Check.OK)
	_add_button(_buttons, "CancelButton", "Cancelar", cafe.cancel_placement)


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


func _add_button(row: HBoxContainer, button_name: String, text: String, action: Callable, two_lines := false) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = TWO_LINE_BUTTON_MIN_SIZE if two_lines else BUTTON_MIN_SIZE
	button.add_theme_font_size_override("font_size", SMALL_FONT_SIZE if two_lines else FONT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: action.call())
	row.add_child(button)
	return button
