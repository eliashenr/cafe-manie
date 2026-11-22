class_name NeonSign
extends Node2D
## Letreiro neon com o nome do café (DT-081), preso no alto da parede do fundo da direita: uma placa escura, o nome
## em tubos de luz quente com o miolo marfim, detalhe de latão e halo suave. O neon tem luz própria: à noite ele não escurece
## com o resto (a cor vem compensada pelo NightTint) e o halo cresce.

const FONT_SIZE := 26
const TUBE_COLOR := Color("f3d59d")
const ACCENT_COLOR := Color("b99962")
const CORE_COLOR := Color("fff8e9")
const TUBE_WIDTH := 3
const BOARD_COLOR := Color("253e35ed")
const BOARD_EDGE := Color("bc996a99")
const BOARD_PADDING := Vector2(18, 10)
const BOARD_RADIUS := 8
## A placa fica presa no alto da parede: esta parte dela desce pela parede (o resto fica acima), para caber no
## enquadramento da câmera sem afastar o café.
const DROP := 14.0
## Halo: camadas, quanto cada uma alarga e a transparência de dia e no meio da noite.
const HALO_LAYERS := 3
const HALO_STEP := 3
const DAY_HALO := 0.06
const NIGHT_HALO := 0.16
## Sem nome escolhido, o letreiro diz só isto.
const EMPTY_TEXT := "Café"
## Direção da parede da direita na tela (a borda y = 0 desce para a direita): o letreiro segue a inclinação dela.
const WALL_SLOPE := Vector2(1.0, 0.5)

var text := "":
	set(value):
		text = value
		queue_redraw()

var grid_size := Vector2i.ZERO:
	set(value):
		grid_size = value
		queue_redraw()

var wall_height := 0.0:
	set(value):
		wall_height = value
		queue_redraw()

var night := 0.0
var night_tint := Color.WHITE


## Noite (DT-080): redesenha só quando a escuridão muda de um passo para outro.
func set_night(amount: float, tint: Color) -> void:
	var stepped := roundf(clampf(amount, 0.0, 1.0) * ExteriorView.NIGHT_STEPS) / ExteriorView.NIGHT_STEPS
	if is_equal_approx(stepped, night):
		return
	night = stepped
	night_tint = tint
	queue_redraw()


## O texto que aparece no letreiro.
func shown_text() -> String:
	return text if not text.is_empty() else EMPTY_TEXT


## Ponto do meio da base do letreiro (no alto da parede da direita, no meio dela), no mundo.
func anchor_point() -> Vector2:
	return IsoProjection.vertex_to_world(Vector2(grid_size.x / 2.0, 0.0)) - Vector2(0.0, wall_height)


func _draw() -> void:
	if grid_size == Vector2i.ZERO:
		return
	var font := UiTheme.font(UiTheme.BOLD)
	var label := shown_text()
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_set_transform_matrix(Transform2D(WALL_SLOPE, Vector2(0.0, 1.0), anchor_point()))
	var board := Rect2(-width / 2.0 - BOARD_PADDING.x, DROP - FONT_SIZE - BOARD_PADDING.y * 2.0,
		width + BOARD_PADDING.x * 2.0, FONT_SIZE + BOARD_PADDING.y * 2.0)
	var box := StyleBoxFlat.new()
	box.bg_color = BOARD_COLOR
	box.border_color = BOARD_EDGE
	box.set_border_width_all(1)
	box.set_corner_radius_all(BOARD_RADIUS)
	box.anti_aliasing = true
	draw_style_box(box, board)
	# o neon tem luz própria: a cor dividida pela do NightTint volta a ser a dela depois do escuro
	var lit := CityLights.glow_modulate(1.0, night_tint, 1.0)
	var baseline := Vector2(-width / 2.0, board.end.y - BOARD_PADDING.y - FONT_SIZE * 0.22)
	var underline_y := board.end.y - BOARD_PADDING.y * 0.55
	var halo := DAY_HALO + NIGHT_HALO * night
	for i in range(HALO_LAYERS, 0, -1):
		var size := TUBE_WIDTH + i * HALO_STEP * 2
		draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, size,
			Color(TUBE_COLOR, halo) * lit)
		draw_line(Vector2(-width / 2.0, underline_y), Vector2(width / 2.0, underline_y), Color(ACCENT_COLOR, halo) * lit,
			3.0 + i * HALO_STEP, true)
	draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TUBE_WIDTH, TUBE_COLOR * lit)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, CORE_COLOR * lit)
	draw_line(Vector2(-width / 2.0, underline_y), Vector2(width / 2.0, underline_y), ACCENT_COLOR * lit, 3.0, true)
	draw_line(Vector2(-width / 2.0, underline_y), Vector2(width / 2.0, underline_y), CORE_COLOR * lit, 1.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
