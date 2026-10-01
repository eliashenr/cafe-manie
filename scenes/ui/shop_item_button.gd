class_name ShopItemButton
extends Button
## Quadradinho da loja da v3: o desenho do item num cartão branco, o nome e a
## etiqueta de preço com a moeda. Bloqueado, mostra o cadeado com "Nível N". No
## lugar do preço pode vir um aviso ("1 guardado", "Em uso", "Aplicar").
##
## O texto do botão (Button.text) guarda as mesmas informações em uma linha só,
## para quem lê a tela sem a imagem (e para os testes); ele não é desenhado.

const CARD_SIZE := Vector2(108, 136)
const ART_MARGIN := 8.0
const ART_BOTTOM := 52.0
const NAME_SIZE := 12
const PRICE_SIZE := 16
const NOTE_SIZE := 13
const HOVER_EDGE := Color("2a7de1")
const LOCK_SHADE := Color(0.114, 0.208, 0.388, 0.45)
const TOO_EXPENSIVE := Color("e0303a")
const NOTE_COLOR := Color("1a8a3e")

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
	var box := UiTheme.card_box(12, 0, HOVER_EDGE if is_hovered() and not disabled else UiTheme.CARD_EDGE)
	draw_style_box(box, card)
	var art_area := Rect2(Vector2(ART_MARGIN, ART_MARGIN), size - Vector2(ART_MARGIN * 2.0, ART_MARGIN + ART_BOTTOM))
	draw_style_box(_soft_box(), art_area)
	if art != null:
		var texture_size := art.texture.get_size()
		var fit := minf(art_area.size.x / texture_size.x, art_area.size.y / texture_size.y) * art_zoom
		var drawn := texture_size * fit
		draw_texture_rect(art.texture, Rect2(art_area.get_center() - drawn / 2.0, drawn), false)
	var font := get_theme_default_font()
	_draw_centered(font, title, size.y - 36.0, NAME_SIZE, UiTheme.TEXT)
	if locked_level > 0:
		draw_rect(art_area, LOCK_SHADE)
		var lock := ArtSprites.get_sprite("icone_cadeado")
		if lock != null:
			draw_texture_rect(lock.texture, Rect2(art_area.get_center() - Vector2(18, 26), Vector2(36, 36)), false)
		var pill := Rect2(Vector2(art_area.get_center().x - 32.0, art_area.get_center().y + 10.0), Vector2(64, 20))
		var pill_box := UiTheme.card_box(10, 0, UiTheme.TEXT)
		pill_box.shadow_size = 0
		draw_style_box(pill_box, pill)
		_draw_centered(font, "Nível %d" % locked_level, pill.get_center().y + 4.5, 12, UiTheme.TEXT)
	if not note.is_empty():
		_draw_centered(font, note, size.y - 12.0, NOTE_SIZE, NOTE_COLOR)
	elif locked_level == 0:
		var text := UiTheme.thousands(price)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_SIZE).x
		var coin := ArtSprites.get_sprite("icone_moeda")
		var left := (size.x - width - 24.0) / 2.0
		if coin != null:
			draw_texture_rect(coin.texture, Rect2(Vector2(left, size.y - 30.0), Vector2(20, 20)), false)
		draw_string(font, Vector2(left + 24.0, size.y - 14.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, PRICE_SIZE,
			UiTheme.TEXT if affordable else TOO_EXPENSIVE)


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
