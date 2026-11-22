extends ShopItemButton
## Peça do chef: prévia do avatar montado, ou uma amostra de pele, com estado legível.
## Mantém Button.text e show_state() do cartão de compra para acessibilidade e testes.

var skin_swatch := false
var swatch_color := Color.WHITE
var equipped := false
var trying_on := false
var _portrait: AvatarPortrait
var _name_label: Label
var _state_label: Label


func _init() -> void:
	clip_contents = true
	_portrait = AvatarPortrait.new()
	_portrait.name = "PartPreview"
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	_name_label = Label.new()
	_name_label.name = "PartName"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", UiTheme.TEXT)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	_state_label = Label.new()
	_state_label.name = "PartState"
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 12)
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_state_label)
	resized.connect(_layout_preview)


func configure(layers: Array[String], is_skin: bool, color: Color, is_equipped: bool, is_trying: bool) -> void:
	skin_swatch = is_skin
	swatch_color = color
	equipped = is_equipped
	trying_on = is_trying
	_portrait.layers = [] as Array[String] if skin_swatch else layers
	_portrait.visible = not skin_swatch
	_portrait.modulate.a = 0.35 if locked_level > 0 else 1.0
	_name_label.text = title
	if locked_level > 0:
		_state_label.text = "Nível %d" % locked_level
	elif trying_on:
		_state_label.text = "Experimentando"
	elif not note.is_empty():
		_state_label.text = note
	else:
		_state_label.text = "%s ouro" % UiTheme.thousands(price)
	var ink := UiTheme.TEXT_SOFT
	if equipped:
		ink = UiTheme.GREEN
	elif trying_on:
		ink = UiTheme.GOLD
	elif locked_level > 0 or not affordable:
		ink = UiTheme.RED
	_state_label.add_theme_color_override("font_color", ink)
	_layout_preview()
	queue_redraw()


func preview_layers() -> Array[String]:
	return _portrait.layers


func _layout_preview() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	_portrait.position = Vector2(8, 5)
	_portrait.size = Vector2(size.x - 16, size.y - 60)
	_name_label.position = Vector2(6, size.y - 54)
	_name_label.size = Vector2(size.x - 12, 32)
	_state_label.position = Vector2(6, size.y - 22)
	_state_label.size = Vector2(size.x - 12, 18)


func _draw() -> void:
	var edge := UiTheme.GREEN if equipped else (UiTheme.GOLD if trying_on else UiTheme.CARD_EDGE)
	if is_hovered() and not disabled:
		edge = UiTheme.CYAN
	var box := UiTheme.card_box(12, 0, edge)
	box.set_border_width_all(2 if equipped or trying_on else 1)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var area := Rect2(Vector2(6, 5), Vector2(size.x - 12, size.y - 62))
	draw_style_box(_soft_box(), area)
	if skin_swatch:
		var center := area.get_center()
		var radius := minf(area.size.x, area.size.y) * 0.36
		draw_circle(center + Vector2(0, 2), radius + 2, Color(UiTheme.SHADOW, 0.12))
		draw_circle(center, radius + 2, UiTheme.CARD)
		draw_circle(center, radius, swatch_color)
	if equipped:
		var center := Vector2(size.x - 15, 15)
		draw_circle(center, 8, UiTheme.GREEN)
		draw_polyline(PackedVector2Array([center + Vector2(-4, 0), center + Vector2(-1, 3),
			center + Vector2(4, -3)]), Color.WHITE, 1.8, true)
