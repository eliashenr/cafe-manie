class_name ShopItemButton
extends Button
## Cartão da loja (DT-077): o desenho do item num cartão de vidro escuro, o nome, a etiqueta de preço com a moeda e
## o selo da coleção embaixo. Ao passar o mouse, a borda acende. Bloqueado, mostra o cadeado com "Nível N". No lugar
## do preço pode vir um aviso ("1 guardado", "Em uso", "Na entrada").
##
## O texto do botão (Button.text) guarda as mesmas informações em uma linha só, para quem lê a tela sem a imagem (e
## para os testes); ele não é desenhado.

const CARD_SIZE := Vector2(130, 140)
const ART_MARGIN := 7.0
const ART_BOTTOM := 62.0
const NAME_SIZE := 12
const PRICE_SIZE := 15
const NOTE_SIZE := 12
const TAG_SIZE := 10
const LOCK_SHADE := Color(0.02, 0.05, 0.11, 0.62)
const TOO_EXPENSIVE := Color("ff6b78")
const NOTE_COLOR := Color("4fe0a0")

## Desenho do item (móvel, piso ou parede) e quanto ampliar além do encaixe.
var art: ArtSprites.Sprite
var art_zoom := 1.0
var title := ""
var price := 0
## Nível que libera (0 = liberado).
var locked_level := 0
## Aviso no lugar do preço ("" = mostra o preço).
var note := ""
## O jogador tem ouro para comprar?
var affordable := true
## Selo da coleção embaixo do cartão ("" = sem selo) e a cor dela.
var tag_text := ""
var tag_color := UiTheme.METAL


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	clip_text = true  # o texto (não desenhado) não pode alargar o cartão
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color",
			"font_hover_pressed_color", "font_outline_color"]:
		add_theme_color_override(color_name, Color(0, 0, 0, 0))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


## Texto depois do preço (ex.: "/piso").
var price_suffix := ""
## Ícone ao lado do preço: a moeda, ou o cupom na loja de troca (DT-062).
var price_icon := "icone_moeda":
	set(value):
		price_icon = value
		queue_redraw()


## Atualiza o que aparece; só redesenha se algo mudou.
func show_state(new_price: int, new_locked_level: int, new_note: String, new_affordable: bool) -> void:
	if new_price == price and new_locked_level == locked_level and new_note == note and new_affordable == affordable:
		return
	price = new_price
	locked_level = new_locked_level
	note = new_note
	affordable = new_affordable
	queue_redraw()


func _draw() -> void:
	var card := Rect2(Vector2.ZERO, size)
	var edge := UiTheme.CYAN if is_hovered() and not disabled else UiTheme.CARD_EDGE
	draw_style_box(UiTheme.card_box(12, 0, edge), card)
	var art_area := Rect2(Vector2(ART_MARGIN, ART_MARGIN), size - Vector2(ART_MARGIN * 2.0, ART_MARGIN + ART_BOTTOM))
	draw_style_box(_soft_box(), art_area)
	if art != null:
		var texture_size := art.texture.get_size()
		var fit := minf(art_area.size.x / texture_size.x, art_area.size.y / texture_size.y) * art_zoom
		var drawn := texture_size * fit
		draw_texture_rect(art.texture, Rect2(art_area.get_center() - drawn / 2.0, drawn), false)
	var font := get_theme_default_font()
	_draw_centered(font, title, size.y - 46.0, NAME_SIZE, UiTheme.WHITE_SOFT)
	if locked_level > 0:
		draw_rect(art_area, LOCK_SHADE)
		var lock := ArtSprites.get_sprite("icone_cadeado")
		if lock != null:
			draw_texture_rect(lock.texture, Rect2(art_area.get_center() - Vector2(16, 24), Vector2(32, 32)), false)
		var pill := Rect2(Vector2(art_area.get_center().x - 30.0, art_area.get_center().y + 9.0), Vector2(60, 18))
		var pill_box := UiTheme.card_box(9, 0, UiTheme.GOLD)
		pill_box.bg_color = UiTheme.NAVY_DEEP
		pill_box.shadow_size = 0
		draw_style_box(pill_box, pill)
		_draw_centered(font, "Nível %d" % locked_level, pill.get_center().y + 4.0, 11, UiTheme.GOLD)
	if not note.is_empty():
		_draw_centered(font, note, size.y - 26.0, NOTE_SIZE, NOTE_COLOR)
	elif locked_level == 0:
		var text := UiTheme.thousands(price) + price_suffix
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_SIZE).x
		var coin := ArtSprites.get_sprite(price_icon)
		var left := (size.x - width - 22.0) / 2.0
		if coin != null:
			draw_texture_rect(coin.texture, Rect2(Vector2(left, size.y - 41.0), Vector2(18, 18)), false)
		draw_string(font, Vector2(left + 22.0, size.y - 26.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_SIZE,
			UiTheme.GOLD if affordable else TOO_EXPENSIVE)
	if not tag_text.is_empty():
		var strip := Rect2(Vector2(6.0, size.y - 19.0), Vector2(size.x - 12.0, 14.0))
		var tag_box := UiTheme.bar_box(Color(tag_color, 0.32), 5)
		draw_style_box(tag_box, strip)
		_draw_centered(font, tag_text, strip.position.y + 11.0, TAG_SIZE, tag_color.lightened(0.45))


## Texto centrado; se não couber no cartão, a letra diminui (até 9).
func _draw_centered(font: Font, text: String, baseline: float, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	while width > size.x - 8.0 and font_size > 9:
		font_size -= 1
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _soft_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = UiTheme.CARD_SOFT
	box.set_corner_radius_all(9)
	return box
