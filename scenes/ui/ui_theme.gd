class_name UiTheme
extends RefCounted
## Visual da interface da v3 (formato do jogo antigo, desenho nosso): botões azuis
## brilhantes, cartões brancos de borda azul, contadores escuros de borda branca e
## texto com contorno. Os ícones e botões quadrados vêm da arte (ArtSprites).

const NAVY := Color("12254a")
const TEXT := Color("1d3563")
const TEXT_SOFT := Color("5a78a8")
const BLUE := Color("2a7de1")
const BLUE_LIGHT := Color("4a9cf0")
const BLUE_DARK := Color("15509c")
const CARD := Color("ffffff")
const CARD_EDGE := Color("9fc2ea")
const CARD_SOFT := Color("eaf4ff")
const PILL := Color(0.106, 0.18, 0.353, 0.86)
const ORANGE := Color("ff6b3d")
const GOLD_TEXT := Color("ffe34d")
const DISABLED := Color("aebdd0")
const SHADOW := Color(0, 0, 0, 0.16)
const FONT_SIZE := 16
## Letras das pranchas (licença OFL, em art/fonts com a licença): Fredoka para quase
## tudo, como no HUD do canvas; Nunito para textos corridos.
const FREDOKA_PATH := "res://art/fonts/Fredoka-Variable.ttf"
const NUNITO_PATH := "res://art/fonts/Nunito-Variable.ttf"
## Peso padrão da interface (as fontes são variáveis: 300 a 700 na Fredoka).
const WEIGHT := 600
const BOLD := 700

static var _theme: Theme
static var _fonts: Dictionary = {}


## Tema comum de toda a interface (cacheado).
static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font = font()
	_theme.default_font_size = FONT_SIZE
	_theme.set_color("font_color", "Label", TEXT)
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		var fill: Color = {"normal": BLUE, "hover": BLUE_LIGHT, "pressed": BLUE_DARK, "disabled": DISABLED,
			"focus": BLUE, "hover_pressed": BLUE_DARK}[state]
		_theme.set_stylebox(state, "Button", button_box(fill, DISABLED.darkened(0.25) if state == "disabled" else BLUE_DARK))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(color_name, "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", Color("f2f6fb"))
	_theme.set_color("font_outline_color", "Button", BLUE_DARK)
	_theme.set_constant("outline_size", "Button", 4)
	_theme.set_constant("icon_max_width", "Button", 48)
	_theme.set_stylebox("panel", "PanelContainer", card_box())
	_theme.set_stylebox("panel", "AcceptDialog", card_box(14, 16))
	_theme.set_stylebox("normal", "LineEdit", card_box(10, 8))
	_theme.set_stylebox("focus", "LineEdit", card_box(10, 8, BLUE))
	_theme.set_color("font_color", "LineEdit", TEXT)
	_theme.set_color("font_placeholder_color", "LineEdit", TEXT_SOFT)
	_theme.set_color("caret_color", "LineEdit", TEXT)
	return _theme


## Fonte das pranchas no peso pedido (Fredoka; [param body] = Nunito, para textos corridos).
## Sem os arquivos, cai na fonte padrão da Godot.
static func font(weight := WEIGHT, body := false) -> Font:
	var key := "%s_%d" % ["nunito" if body else "fredoka", weight]
	if _fonts.has(key):
		return _fonts[key]
	var path := NUNITO_PATH if body else FREDOKA_PATH
	var result: Font = ThemeDB.fallback_font
	if ResourceLoader.exists(path):
		var variation := FontVariation.new()
		variation.base_font = load(path)
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		result = variation
	_fonts[key] = result
	return result


## Botão brilhante: cor cheia, borda mais escura e uma "sola" embaixo, cantos redondos.
static func button_box(fill: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(2)
	box.border_width_bottom = 5
	box.set_corner_radius_all(12)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 10
	box.anti_aliasing = true
	return box


## Cartão branco de borda azul clara, com sombra leve.
static func card_box(radius := 12, padding := 12, edge := CARD_EDGE) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = CARD
	box.border_color = edge
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	box.shadow_color = SHADOW
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	box.anti_aliasing = true
	return box


## Contador escuro de borda branca (moedas, cronômetro).
static func pill_box(radius := 17) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PILL
	box.border_color = Color.WHITE
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.shadow_color = SHADOW
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	box.anti_aliasing = true
	return box


## Imagem da arte num retângulo do tamanho pedido (mantém a proporção).
static func art(sprite_name: String, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = sprite_name
	var sprite := ArtSprites.get_sprite(sprite_name)
	if sprite != null:
		rect.texture = sprite.texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = size
	rect.size = size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return rect


## Texto com contorno (para ficar legível em cima do cenário).
static func outlined(text: String, size: int, color := Color.WHITE, outline := NAVY, outline_size := 5) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", outline_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Botão quadrado da arte (azul, verde, vermelho...) com o texto embaixo, ou só o quadrado.
static func icon_button(button_name: String, kind: String, text := "", icon_size := 46) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	var sprite := ArtSprites.get_sprite("botao_" + kind)
	if sprite != null:
		button.icon = sprite.texture
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", icon_size)
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", BLUE)
	button.add_theme_color_override("font_pressed_color", BLUE_DARK)
	button.add_theme_color_override("font_disabled_color", DISABLED)
	button.add_theme_color_override("font_outline_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_font_size_override("font_size", 14)
	button.focus_mode = Control.FOCUS_NONE
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return button


## Formato brasileiro de milhar: 12480 -> "12.480".
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	while digits.length() > 3:
		out = "." + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out
