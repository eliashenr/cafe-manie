class_name BuildBar
extends CanvasLayer
## PLACEHOLDER_UI: barra inferior de construção do protótipo.
##
## Mostra, conforme o estado da cafeteria:
## - nada selecionado: botões para posicionar cada móvel do catálogo;
## - móvel selecionado: Mover, Girar, Remover e Fechar;
## - construindo: instrução ou motivo da recusa, Girar, Confirmar e Cancelar.

const BUTTON_MIN_SIZE := Vector2(112, 56)
const FONT_SIZE := 18

## Mensagens para o jogador em cada resultado de checagem.
const CHECK_MESSAGES := {
	CafeLayout.Check.OK: "Toque de novo no piso ou em Confirmar",
	CafeLayout.Check.NO_TARGET: "Toque num piso para posicionar",
	CafeLayout.Check.OUT_OF_BOUNDS: "Não cabe aqui",
	CafeLayout.Check.OCCUPIED: "Já tem algo nesse lugar",
	CafeLayout.Check.BLOCKS_ENTRANCE: "A entrada precisa ficar livre",
	CafeLayout.Check.NO_ACCESS: "Ninguém conseguiria chegar até ele aqui",
	CafeLayout.Check.BLOCKS_ACCESS: "Isso deixaria outro móvel sem acesso",
	CafeLayout.Check.UNKNOWN_PLACEMENT: "Esse móvel não existe mais",
}

var cafe: Cafe

var _message: Label
var _buttons: HBoxContainer
var _rebuild_pending := false


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

	_buttons = HBoxContainer.new()
	_buttons.name = "Buttons"
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 8)
	column.add_child(_buttons)


func bind(target_cafe: Cafe) -> void:
	cafe = target_cafe
	cafe.state_changed.connect(_request_rebuild)
	_rebuild()


func message_text() -> String:
	return _message.text


func find_button(button_name: String) -> Button:
	return _buttons.get_node_or_null(button_name) as Button


## Reconstrói no fim do frame: vários avisos no mesmo frame viram uma reconstrução
## só, e nenhum botão é removido durante o próprio clique.
func _request_rebuild() -> void:
	if not _rebuild_pending:
		_rebuild_pending = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()

	if cafe.mode == Cafe.Mode.BUILD:
		_show_build_controls()
	elif cafe.selected_id != &"":
		_show_selection_controls()
	else:
		_show_catalog()


func _show_catalog() -> void:
	_message.text = "Construir"
	for definition in cafe.catalog.all():
		var id: StringName = definition.id
		_add_button("Build_" + String(id), definition.display_name, func() -> void: cafe.start_placing(id))


func _show_selection_controls() -> void:
	var placement := cafe.layout.get_placement(cafe.selected_id)
	var text := placement.definition.display_name
	if cafe.last_check != CafeLayout.Check.OK:
		text += "  —  " + CHECK_MESSAGES[cafe.last_check]
	_message.text = text
	_add_button("MoveButton", "Mover", cafe.start_moving_selected)
	_add_button("RotateButton", "Girar", cafe.rotate_selected)
	_add_button("RemoveButton", "Remover", cafe.remove_selected)
	_add_button("CloseButton", "Fechar", cafe.clear_selection)


func _show_build_controls() -> void:
	var session := cafe.session
	var verb := "Movendo" if session.is_moving() else "Posicionando"
	_message.text = "%s: %s  —  %s" % [verb, session.definition.display_name, CHECK_MESSAGES[cafe.last_check]]
	_add_button("RotateButton", "Girar", cafe.rotate_placement)
	var confirm := _add_button("ConfirmButton", "Confirmar", cafe.confirm_placement)
	confirm.disabled = cafe.last_check != CafeLayout.Check.OK
	_add_button("CancelButton", "Cancelar", cafe.cancel_placement)


func _add_button(button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = BUTTON_MIN_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: action.call())
	_buttons.add_child(button)
	return button
