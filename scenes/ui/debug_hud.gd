extends CanvasLayer
## PLACEHOLDER_HUD: painel de protótipo que mostra a célula selecionada
## e como controlar a câmera. Será substituído pelo HUD real.

const HINT := "Arraste para mover  •  Roda do mouse ou pinça para zoom  •  Toque num piso para selecionar"

var _cell_label: Label


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "top", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.05, 0.75)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	margin.add_child(panel)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	_cell_label = Label.new()
	_cell_label.add_theme_font_size_override("font_size", 22)
	column.add_child(_cell_label)

	var hint := Label.new()
	hint.text = HINT
	hint.add_theme_font_size_override("font_size", 15)
	hint.modulate = Color(1, 1, 1, 0.7)
	column.add_child(hint)

	_show_cell(CafeGrid.NO_CELL)
	EventBus.cell_selected.connect(_show_cell)


func cell_text() -> String:
	return _cell_label.text


func _show_cell(cell: Vector2i) -> void:
	if cell == CafeGrid.NO_CELL:
		_cell_label.text = "Nenhum piso selecionado"
	else:
		_cell_label.text = "Piso selecionado: (%d, %d)" % [cell.x, cell.y]
