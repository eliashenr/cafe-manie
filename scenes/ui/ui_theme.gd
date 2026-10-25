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
## Papéis dos botões (DT-079), como variações do tema: o padrão é o azul tecnológico (ação principal).
const SUCCESS_BUTTON := &"SuccessButton"
const GHOST_BUTTON := &"GhostButton"
const DANGER_BUTTON := &"DangerButton"
const TAB_BUTTON := &"TabButton"
## Botões das janelas: altura e largura mínimas (área de toque confortável).
const DIALOG_BUTTON_SIZE := Vector2(132, 46)
## Largura das perguntas: o texto quebra em linhas e os botões ficam perto um do outro.
const QUESTION_WIDTH := 500

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
	_theme.set_stylebox("fill", "ProgressBar", bar_box(CYAN))  # progresso em ciano; concluído, em verde
	_theme.set_color("font_color", "TooltipLabel", WHITE_SOFT)
	_theme.set_stylebox("panel", "TooltipPanel", glass_box(8, 8))
	_theme.set_constant("buttons_min_width", "AcceptDialog", int(DIALOG_BUTTON_SIZE.x))
	_theme.set_constant("buttons_min_height", "AcceptDialog", int(DIALOG_BUTTON_SIZE.y))
	_theme.set_constant("buttons_separation", "AcceptDialog", 12)
	_button_variation(SUCCESS_BUTTON, GREEN, Color.WHITE)
	_button_variation(DANGER_BUTTON, RED, Color.WHITE)
	_ghost_variation()
	_tab_variation()
	_tab_container_styles()
	_scroll_styles()
	return _theme


## Variação de botão de cor cheia (verde para comprar e confirmar, vermelho para apagar).
static func _button_variation(type: StringName, fill: Color, text: Color) -> void:
	_theme.set_type_variation(type, "Button")
	var states := {"normal": fill, "hover": fill.lightened(0.12), "pressed": fill.darkened(0.18),
		"hover_pressed": fill.darkened(0.18), "disabled": DISABLED}
	for state: String in states:
		var color: Color = states[state]
		_theme.set_stylebox(state, type, button_box(color, color.lightened(0.3) if state != "disabled" else DISABLED))
	_theme.set_stylebox("focus", type, _focus_ring())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		_theme.set_color(color_name, type, text)


## Botão "fantasma" (Fechar, Cancelar, Depois): vidro com borda, acende em ciano ao passar; com foco, o anel ciano.
static func _ghost_variation() -> void:
	_theme.set_type_variation(GHOST_BUTTON, "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := button_box(Color(1, 1, 1, 0.04), PANEL_EDGE.lightened(0.2))
		box.shadow_size = 0
		box.border_width_top = 1
		if state.begins_with("hover") or state == "pressed":
			box.bg_color = Color(CYAN, 0.1 if state == "hover" else 0.16)
			box.border_color = CYAN
		elif state == "disabled":
			box.border_color = DISABLED
		_theme.set_stylebox(state, GHOST_BUTTON, box)
	_theme.set_stylebox("focus", GHOST_BUTTON, _focus_ring())
	for color_name in ["font_color", "font_focus_color"]:
		_theme.set_color(color_name, GHOST_BUTTON, WHITE_SOFT)
	for color_name in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		_theme.set_color(color_name, GHOST_BUTTON, CYAN)


## Aba (botão que fica marcado): a escolhida em azul tecnológico com brilho ciano; as outras, transparentes.
static func _tab_variation() -> void:
	_theme.set_type_variation(TAB_BUTTON, "Button")
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var active: bool = state == "pressed" or state == "hover_pressed"
		var box := StyleBoxFlat.new()
		box.bg_color = TECH_BLUE if active else (Color(CYAN, 0.1) if state == "hover" else Color(0, 0, 0, 0.2))
		box.border_color = CYAN if active else (Color(CYAN, 0.55) if state == "hover" else Color(PANEL_EDGE, 0.9))
		box.set_border_width_all(1)
		box.set_corner_radius_all(RADIUS_CARD)
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 6
		box.content_margin_bottom = 6
		if active:
			box.shadow_color = Color(CYAN, 0.35)
			box.shadow_size = 8
		box.anti_aliasing = true
		_theme.set_stylebox(state, TAB_BUTTON, box)
	_theme.set_stylebox("focus", TAB_BUTTON, StyleBoxEmpty.new())
	for color_name in ["font_color", "font_focus_color"]:
		_theme.set_color(color_name, TAB_BUTTON, TEXT_SOFT)
	_theme.set_color("font_hover_color", TAB_BUTTON, WHITE_SOFT)
	for color_name in ["font_pressed_color", "font_hover_pressed_color"]:
		_theme.set_color(color_name, TAB_BUTTON, Color.WHITE)


## Abas das janelas com TabContainer (missões): o mesmo visual das abas de botão.
static func _tab_container_styles() -> void:
	for state in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled"]:
		var box := _theme.get_stylebox({"tab_selected": "pressed", "tab_hovered": "hover"}.get(state, "normal"),
			TAB_BUTTON).duplicate() as StyleBoxFlat
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.shadow_size = 0
		_theme.set_stylebox(state, "TabContainer", box)
	_theme.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	_theme.set_stylebox("panel", "TabContainer", StyleBoxEmpty.new())
	_theme.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
	_theme.set_constant("side_margin", "TabContainer", 0)
	_theme.set_constant("tab_separation", "TabContainer", 8)
	_theme.set_color("font_selected_color", "TabContainer", Color.WHITE)
	_theme.set_color("font_unselected_color", "TabContainer", TEXT_SOFT)
	_theme.set_color("font_hovered_color", "TabContainer", WHITE_SOFT)


## Barras de rolagem finas: trilho quase invisível e o puxador em ciano.
static func _scroll_styles() -> void:
	for type in ["VScrollBar", "HScrollBar"]:
		var track := bar_box(Color(1, 1, 1, 0.05), 4)
		track.set_content_margin_all(3)
		_theme.set_stylebox("scroll", type, track)
		var alphas := {"grabber": 0.45, "grabber_highlight": 0.7, "grabber_pressed": 0.9}
		for state: String in alphas:
			var grabber := bar_box(Color(CYAN, alphas[state]), 4)
			grabber.set_content_margin_all(3)
			_theme.set_stylebox(state, type, grabber)


## Anel ciano do foco (o botão já selecionado nas perguntas, como o Cancelar).
static func _focus_ring() -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = CYAN
	ring.set_border_width_all(2)
	ring.set_corner_radius_all(RADIUS_CARD + 2)
	ring.expand_margin_left = 3
	ring.expand_margin_right = 3
	ring.expand_margin_top = 3
	ring.expand_margin_bottom = 3
	ring.anti_aliasing = true
	return ring


## Dá ao botão um papel do sistema de design (DT-079): SUCCESS_BUTTON, GHOST_BUTTON, DANGER_BUTTON ou TAB_BUTTON.
static func role(button: Button, variation: StringName) -> Button:
	button.theme_type_variation = variation
	return button


## Janela no padrão (DT-079): o botão de OK com o papel pedido e, nas perguntas, o Cancelar como botão fantasma.
static func style_dialog(dialog: AcceptDialog, ok_role: StringName) -> void:
	role(dialog.get_ok_button(), ok_role)
	if dialog is ConfirmationDialog:
		role((dialog as ConfirmationDialog).get_cancel_button(), GHOST_BUTTON)
		dialog.dialog_autowrap = true
		dialog.min_size = Vector2i(QUESTION_WIDTH, 0)


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
