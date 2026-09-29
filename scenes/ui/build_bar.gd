class_name BuildBar
extends CanvasLayer
## PLACEHOLDER_UI: barra inferior do protótipo.
##
## Mostra, conforme o estado da cafeteria:
## - nada selecionado: botões para posicionar cada móvel do catálogo;
## - fogão selecionado: receitas para cozinhar (ou o tempo que falta), e as ações do móvel;
## - balcão selecionado: o que tem nele, e as ações do móvel;
## - outro móvel selecionado: Mover, Girar, Remover e Fechar;
## - construindo: instrução ou motivo da recusa, Girar, Confirmar e Cancelar.

const BUTTON_MIN_SIZE := Vector2(112, 56)
const RECIPE_BUTTON_MIN_SIZE := Vector2(128, 64)
const FONT_SIZE := 18
const RECIPE_FONT_SIZE := 15

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

## Mensagens para o jogador em cada resultado de ação da cozinha.
const SERVICE_MESSAGES := {
	ServiceResult.OK: "",
	ServiceResult.NOT_A_STOVE: "Isso não é um fogão",
	ServiceResult.STOVE_BUSY: "O fogão já está ocupado",
	ServiceResult.NOT_READY: "Ainda não está pronto",
	ServiceResult.NO_COUNTER_SPACE: "Sem espaço no balcão: sirva ou coloque outro balcão",
	ServiceResult.RECIPE_LOCKED: "Receita ainda bloqueada",
	ServiceResult.NOT_ENOUGH_GOLD: "Café Ouro insuficiente",
	ServiceResult.UNKNOWN_RECIPE: "Receita desconhecida",
}

var cafe: Cafe

var _message: Label
## Linha de cima: receitas do fogão. Fica escondida quando não há o que mostrar.
var _primary: HBoxContainer
## Linha de baixo: catálogo, ações do móvel ou controles de construção.
var _buttons: HBoxContainer
var _rebuild_pending := false
## Estado do fogão selecionado na última reconstrução, para reconstruir quando ele mudar sozinho.
var _shown_stove_status := -1


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


## O tempo do fogão muda sem nenhum aviso: a mensagem é atualizada aqui, e a
## barra se reconstrói quando o prato fica pronto.
func _process(_delta: float) -> void:
	if cafe == null or cafe.mode != Cafe.Mode.VIEW or not _selected_is_stove():
		return
	var status := cafe.simulation.kitchen.stove_status(cafe.selected_id)
	if status != _shown_stove_status:
		_request_rebuild()
	elif status == Kitchen.StoveStatus.COOKING:
		_message.text = _with_problem(_stove_message())


## Reconstrói no fim do frame: vários avisos no mesmo frame viram uma reconstrução
## só, e nenhum botão é removido durante o próprio clique.
func _request_rebuild() -> void:
	if not _rebuild_pending:
		_rebuild_pending = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	for row in [_primary, _buttons]:
		for child in row.get_children():
			row.remove_child(child)
			child.queue_free()
	_shown_stove_status = -1

	if cafe.mode == Cafe.Mode.BUILD:
		_show_build_controls()
	elif cafe.selected_id != &"" and cafe.layout.get_placement(cafe.selected_id) != null:
		_show_selection_controls()
	else:
		_show_catalog()
	_primary.visible = _primary.get_child_count() > 0


func _show_catalog() -> void:
	_message.text = "Construir"
	for definition in cafe.catalog.all():
		var id: StringName = definition.id
		_add_button(_buttons, "Build_" + String(id), definition.display_name, func() -> void: cafe.start_placing(id))


func _show_selection_controls() -> void:
	var placement := cafe.layout.get_placement(cafe.selected_id)
	var kitchen := cafe.simulation.kitchen
	var text := placement.definition.display_name
	if kitchen.is_stove(placement.id):
		_shown_stove_status = kitchen.stove_status(placement.id)
		text = _stove_message()
		_show_stove_controls(placement.id)
	elif kitchen.is_counter(placement.id):
		var stack := kitchen.counter_stack(placement.id)
		text = "Balcão vazio" if stack == null else "Balcão: %s ×%d" % [stack.recipe.display_name, stack.servings]
	_message.text = _with_problem(text)
	_add_button(_buttons, "MoveButton", "Mover", cafe.start_moving_selected)
	_add_button(_buttons, "RotateButton", "Girar", cafe.rotate_selected)
	_add_button(_buttons, "RemoveButton", "Remover", cafe.remove_selected)
	_add_button(_buttons, "CloseButton", "Fechar", cafe.clear_selection)


func _show_stove_controls(stove_id: StringName) -> void:
	var simulation := cafe.simulation
	match simulation.kitchen.stove_status(stove_id):
		Kitchen.StoveStatus.IDLE:
			for recipe in simulation.recipes.all():
				var id: StringName = recipe.id
				var locked := recipe.unlock_level > simulation.progression.level
				var text := "%s\n%s · %d ouro" % [recipe.display_name, WorldLayer.format_time(recipe.cook_time), recipe.ingredient_cost]
				if locked:
					text = "%s\nNível %d" % [recipe.display_name, recipe.unlock_level]
				var button := _add_button(_primary, "Cook_" + String(id), text, func() -> void: cafe.cook_on_selected(id))
				button.custom_minimum_size = RECIPE_BUTTON_MIN_SIZE
				button.add_theme_font_size_override("font_size", RECIPE_FONT_SIZE)
				button.disabled = locked or not simulation.wallet.can_afford(Wallet.SOFT, recipe.ingredient_cost)
		Kitchen.StoveStatus.READY:
			_add_button(_primary, "ServeButton", "Levar ao balcão", func() -> void: cafe.collect_stove(stove_id))


func _stove_message() -> String:
	var kitchen := cafe.simulation.kitchen
	var id := cafe.selected_id
	match kitchen.stove_status(id):
		Kitchen.StoveStatus.COOKING:
			return "Fogão: %s fica pronto em %s" % [kitchen.stove_recipe(id).display_name, WorldLayer.format_time(kitchen.time_left(id))]
		Kitchen.StoveStatus.READY:
			return "Fogão: %s pronto! Toque no fogão para levar ao balcão" % kitchen.stove_recipe(id).display_name
	return "Fogão livre: escolha o que cozinhar"


## Acrescenta o motivo da última recusa, se houver. Usado também na
## atualização contínua do tempo, para a explicação não sumir.
func _with_problem(text: String) -> String:
	var problem := _problem_text()
	return text if problem.is_empty() else "%s  —  %s" % [text, problem]


## Motivo da última recusa (posição ou cozinha), ou vazio.
func _problem_text() -> String:
	if cafe.last_check != CafeLayout.Check.OK:
		return CHECK_MESSAGES[cafe.last_check]
	return SERVICE_MESSAGES.get(cafe.last_service_result, "")


func _selected_is_stove() -> bool:
	return cafe.selected_id != &"" and cafe.simulation.kitchen.is_stove(cafe.selected_id)


func _show_build_controls() -> void:
	var session := cafe.session
	var verb := "Movendo" if session.is_moving() else "Posicionando"
	_message.text = "%s: %s  —  %s" % [verb, session.definition.display_name, CHECK_MESSAGES[cafe.last_check]]
	_add_button(_buttons, "RotateButton", "Girar", cafe.rotate_placement)
	var confirm := _add_button(_buttons, "ConfirmButton", "Confirmar", cafe.confirm_placement)
	confirm.disabled = cafe.last_check != CafeLayout.Check.OK
	_add_button(_buttons, "CancelButton", "Cancelar", cafe.cancel_placement)


func _add_button(row: HBoxContainer, button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = BUTTON_MIN_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: action.call())
	row.add_child(button)
	return button
