class_name UiTheme
extends RefCounted
## Sistema de design "Nova York Futurista" (DT-077): painéis de vidro azul-marinho com borda azul, destaques em ciano,
## dourado para moedas, nível e prêmios, verde para comprar e confirmar. Texto claro sobre o escuro, sem contorno
## grosso (só uma sombra leve para ler em cima do cenário). Os ícones e botões quadrados vêm da arte (ArtSprites).

# --- Paleta (cada cor com uma função) -------------------------------------------------------------
## Fundo mais escuro (janelas, faixas).
const NAVY_DEEP := Color("071426")
## Painel de vidro escuro do HUD e das janelas.
const PANEL := Color(0.043, 0.094, 0.176, 0.93)
## Cartão dentro de um painel (itens da loja, cartões de vizinho).
const PANEL_RAISED := Color("0f2444")
## Borda dos painéis e cartões.
const PANEL_EDGE := Color("21508f")
## Azul tecnológico: botões principais e abas ativas.
const TECH_BLUE := Color("0878f9")
## Ciano luminoso: seleção, foco, brilho e destaques pequenos.
const CYAN := Color("31d7ff")
## Dourado premium: moedas, nível, prêmios.
const GOLD := Color("ffbe55")
## Madeira quente (detalhes do restaurante na interface).
const WOOD := Color("70452f")
## Branco suave: texto principal.
const WHITE_SOFT := Color("f5f7fa")
## Cinza metálico: texto secundário e ícones apagados.
const METAL := Color("8c9bad")
## Verde de sucesso: comprar, confirmar, satisfação alta.
const GREEN := Color("35c779")

# --- Nomes antigos, agora com as cores novas (o resto da interface herda o visual) ----------------
const NAVY := NAVY_DEEP
const TEXT := WHITE_SOFT
const TEXT_SOFT := Color("9fb3cc")
const BLUE := TECH_BLUE
const BLUE_LIGHT := Color("3a9bff")
const BLUE_DARK := Color("0a4fb0")
const CARD := PANEL_RAISED
const CARD_EDGE := PANEL_EDGE
const CARD_SOFT := Color("15325c")
const PILL := PANEL
const ORANGE := Color("ff9a3d")
const RED := Color("ff4d5e")
const GOLD_TEXT := GOLD
const DISABLED := Color("34465f")
const SHADOW := Color(0, 0, 0, 0.35)

# --- Tipografia e medidas -------------------------------------------------------------------------
const FONT_SIZE := 16
## Letras (licença OFL, em art/fonts com a licença): Fredoka para títulos, números e botões; Nunito para textos.
const FREDOKA_PATH := "res://art/fonts/Fredoka-Variable.ttf"
const NUNITO_PATH := "res://art/fonts/Nunito-Variable.ttf"
## Peso padrão da interface (as fontes são variáveis: 300 a 700 na Fredoka).
const WEIGHT := 600
const BOLD := 700
## Raios: painel grande, cartão e pílula.
const RADIUS_PANEL := 16
const RADIUS_CARD := 12
## Sombra do texto em cima do cenário.
const TEXT_SHADOW := Color(0, 0, 0, 0.55)

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
		_theme.set_stylebox(state, "Button", button_box(fill, fill.lightened(0.25) if state != "disabled" else DISABLED))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(color_name, "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", METAL)
	_theme.set_color("font_outline_color", "Button", BLUE_DARK)
	_theme.set_constant("outline_size", "Button", 0)
	_theme.set_constant("icon_max_width", "Button", 48)
	_theme.set_stylebox("panel", "PanelContainer", card_box())
	_theme.set_stylebox("panel", "AcceptDialog", glass_box(RADIUS_PANEL, 18))
	_theme.set_stylebox("panel", "ConfirmationDialog", glass_box(RADIUS_PANEL, 18))
	# Barra de título das janelas: azul-marinho com a linha ciano embaixo
	var border := glass_box(RADIUS_PANEL, 0, PANEL_EDGE)
	border.bg_color = NAVY_DEEP
	border.expand_margin_top = 34
	border.border_width_top = 2
	border.border_color = CYAN.darkened(0.25)
	_theme.set_stylebox("embedded_border", "Window", border)
	_theme.set_stylebox("embedded_unfocused_border", "Window", border)
	_theme.set_color("title_color", "Window", WHITE_SOFT)
	_theme.set_font("title_font", "Window", font(BOLD))
	_theme.set_font_size("title_font_size", "Window", 18)
	_theme.set_constant("title_height", "Window", 34)
	_theme.set_stylebox("normal", "LineEdit", card_box(10, 8))
	_theme.set_stylebox("focus", "LineEdit", card_box(10, 8, CYAN))
	_theme.set_color("font_color", "LineEdit", TEXT)
	_theme.set_color("font_placeholder_color", "LineEdit", TEXT_SOFT)
	_theme.set_color("caret_color", "LineEdit", CYAN)
	_theme.set_stylebox("background", "ProgressBar", bar_box(Color(1, 1, 1, 0.08)))
	_theme.set_stylebox("fill", "ProgressBar", bar_box(GREEN))
	_theme.set_color("font_color", "TooltipLabel", WHITE_SOFT)
	_theme.set_stylebox("panel", "TooltipPanel", glass_box(8, 8))
	return _theme


## Fonte no peso pedido (Fredoka; [param body] = Nunito, para textos corridos). Sem os arquivos, cai na padrão.
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


## Botão: cor cheia, borda um tom mais clara (o brilho de cima) e uma "sola" escura embaixo, cantos redondos.
static func button_box(fill: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.border_width_top = 2
	box.set_corner_radius_all(RADIUS_CARD)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 9
	box.shadow_color = Color(fill.darkened(0.6), 0.55)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 3)
	box.anti_aliasing = true
	return box


## Cartão dentro de um painel: azul escuro com borda azul e sombra.
static func card_box(radius := RADIUS_CARD, padding := 12, edge := CARD_EDGE) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = CARD
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	box.shadow_color = SHADOW
	box.shadow_size = 5
	box.shadow_offset = Vector2(0, 2)
	box.anti_aliasing = true
	return box


## Painel de vidro escuro (HUD e janelas), com um leve brilho ciano em volta quando [param glow].
static func glass_box(radius := RADIUS_PANEL, padding := 12, edge := PANEL_EDGE, glow := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL
	box.border_color = edge
	box.set_border_width_all(1)
	box.border_width_top = 2
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	box.shadow_color = Color(CYAN, 0.28) if glow else SHADOW
	box.shadow_size = 10 if glow else 8
	box.shadow_offset = Vector2.ZERO if glow else Vector2(0, 3)
	box.anti_aliasing = true
	return box


## Contador do HUD (moedas, energia, cupons): pílula de vidro escuro.
static func pill_box(radius := 18) -> StyleBoxFlat:
	var box := glass_box(radius, 0)
	box.shadow_size = 5
	return box


## Trilho ou recheio de barra (XP, missão, satisfação).
static func bar_box(color: Color, radius := 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
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


## Texto legível em cima do cenário: contorno fino (um terço do pedido) e sombra leve, no lugar do contorno grosso.
static func outlined(text: String, size: int, color := Color.WHITE, outline := NAVY, outline_size := 5) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline)
	label.add_theme_constant_override("outline_size", roundi(outline_size / 3.0))
	if outline_size > 0:
		label.add_theme_color_override("font_shadow_color", TEXT_SHADOW)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("shadow_outline_size", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Rótulo pequeno em caixa alta (títulos de seção do HUD: "PRESENTE DIÁRIO", "MISSÃO 1 DE 6").
static func caption(text: String, color := TEXT_SOFT, size := 11) -> Label:
	var label := outlined(text, size, color, Color(0, 0, 0, 0), 0)
	label.uppercase = true
	return label


## Botão quadrado da arte (vidro escuro com o símbolo) com o texto embaixo, ou só o quadrado.
## Menor área de toque de um botão (px da tela de 1280x720, cerca de 9 mm num celular comum).
const MIN_TOUCH := 48.0


static func icon_button(button_name: String, kind: String, text := "", icon_size := 46) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	# A área de toque cresce até MIN_TOUCH; o ícone fica do tamanho pedido, no meio (fundo transparente).
	button.custom_minimum_size = Vector2.ONE * maxf(icon_size, MIN_TOUCH)
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
	button.add_theme_color_override("font_hover_color", CYAN)
	button.add_theme_color_override("font_pressed_color", CYAN.darkened(0.2))
	button.add_theme_color_override("font_disabled_color", METAL)
	button.add_theme_color_override("font_outline_color", NAVY_DEEP)
	button.add_theme_constant_override("outline_size", 2)
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
