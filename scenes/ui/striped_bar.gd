class_name StripedBar
extends Control
## Barra do HUD (XP, beleza): trilho escuro discreto, preenchimento em degradê (DT-077) ou listrado (arte "listras_*"),
## com brilho, e o texto no meio.

## Textura das listras (arte "listras_xp" ou "listras_beleza"); vazio = usa o degradê.
var stripes := "listras_xp":
	set(new_stripes):
		stripes = new_stripes
		queue_redraw()
## Cores do degradê (da esquerda para a direita), quando não há listras.
var gradient: Array[Color] = [UiTheme.TECH_BLUE, UiTheme.CYAN]:
	set(new_gradient):
		gradient = new_gradient
		queue_redraw()
## Quanto está cheia (0 a 1).
var value := 0.0:
	set(new_value):
		new_value = clampf(new_value, 0.0, 1.0)
		if not is_equal_approx(new_value, value):
			value = new_value
			queue_redraw()
var text := "":
	set(new_text):
		if new_text != text:
			text = new_text
			queue_redraw()
var font_size := 15
## Lado da textura das listras, em px da interface.
var stripe_period := 32.0

const TRACK := Color(0.02, 0.05, 0.11, 0.85)
const TRACK_EDGE := Color(1, 1, 1, 0.14)
const GLOSS := Color(1, 1, 1, 0.22)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _draw() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = TRACK
	track.border_color = TRACK_EDGE
	track.set_border_width_all(1)
	track.set_corner_radius_all(int(size.y / 2.0))
	track.anti_aliasing = true
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var inner := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
	if value > 0.0:
		var width := maxf(inner.size.y, inner.size.x * value)
		var fill := _capsule(Rect2(inner.position, Vector2(width, inner.size.y)))
		var sprite := ArtSprites.get_sprite(stripes) if not stripes.is_empty() else null
		if sprite != null:
			var uvs := PackedVector2Array()
			for point in fill:
				uvs.append(point / stripe_period)
			draw_polygon(fill, PackedColorArray([Color.WHITE]), uvs, sprite.texture)
		else:
			var colors := PackedColorArray()
			for point in fill:
				colors.append(gradient[0].lerp(gradient[-1], clampf((point.x - inner.position.x) / inner.size.x, 0.0, 1.0)))
			draw_polygon(fill, colors)
		var shine := _capsule(Rect2(inner.position + Vector2(inner.size.y * 0.25, 1.0),
			Vector2(maxf(width - inner.size.y * 0.5, 2.0), inner.size.y * 0.36)))
		draw_colored_polygon(shine, GLOSS)
	if not text.is_empty():
		var font := get_theme_default_font()
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := (size.y + font.get_ascent(font_size) - font.get_descent(font_size)) / 2.0
		var at := Vector2((size.x - text_width) / 2.0, baseline)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, UiTheme.NAVY)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## Retângulo de pontas redondas (meio círculo em cada lado), como polígono.
static func _capsule(rect: Rect2) -> PackedVector2Array:
	var radius := minf(rect.size.y, rect.size.x) / 2.0
	var points := PackedVector2Array()
	var steps := 10
	var right := Vector2(rect.end.x - radius, rect.position.y + rect.size.y / 2.0)
	var left := Vector2(rect.position.x + radius, right.y)
	for i in steps + 1:
		var angle := -PI / 2.0 + PI * i / steps
		points.append(right + Vector2(cos(angle), sin(angle)) * radius)
	for i in steps + 1:
		var angle := PI / 2.0 + PI * i / steps
		points.append(left + Vector2(cos(angle), sin(angle)) * radius)
	return points
