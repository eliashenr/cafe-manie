class_name FurnitureView
extends Node2D
## Móvel desenhado com o sprite da arte v3 (FurnitureSprites). Móvel sem arte
## cai no PLACEHOLDER_FURNITURE: caixa isométrica colorida, com o nome em cima e
## um ponto marcando a frente (para a rotação ficar visível).
##
## O nó fica no vértice da frente do móvel, para que o y-sort da camada
## desenhe na ordem de profundidade.

enum Look { NORMAL, SELECTED, GHOST_VALID, GHOST_INVALID }

## Quanto a caixa encolhe em relação às bordas das células (0 a 0.5).
const INSET := 0.12
const GHOST_VALID_MODULATE := Color(0.65, 1.0, 0.65, 0.8)
const GHOST_INVALID_MODULATE := Color(1.0, 0.5, 0.5, 0.8)
const SELECTED_OUTLINE := Color("f29f1f")
const EDGE_COLOR := Color(0.1, 0.06, 0.04, 0.45)
const LABEL_COLOR := Color(0.1, 0.06, 0.04)
const LABEL_SIZE := 13
const SELECTED_FILL := Color(0.95, 0.62, 0.12, 0.28)

var definition: FurnitureDefinition
var origin := Vector2i.ZERO
## Quartos de volta (0 a 3). Não confundir com Node2D.rotation.
var rotation_steps := 0
var look := Look.NORMAL
## Arte do móvel nesta rotação; null = desenha o placeholder.
var sprite: FurnitureSprites.Sprite

## Etiqueta de estado acima do móvel (ex.: "Café 0:12", "Café ×6"). Vazia = sem etiqueta.
var status_text := ""
## Barra de progresso sob a etiqueta (0 a 1). Negativo = sem barra.
var status_progress := -1.0
## Destaca a etiqueta em verde (prato pronto para servir).
var status_ready := false

const STATUS_BG := Color(0.1, 0.07, 0.05, 0.85)
const STATUS_READY_BG := Color(0.2, 0.62, 0.3, 0.95)
const STATUS_TEXT := Color(1, 1, 1)
const STATUS_BAR_BG := Color(1, 1, 1, 0.25)
const STATUS_BAR_FILL := Color("f2b33d")
const STATUS_SIZE := 13


## Atualiza a etiqueta de estado; só redesenha se algo mudou.
func set_status(text: String, progress := -1.0, ready := false) -> void:
	var rounded := snappedf(progress, 0.01)
	if text == status_text and rounded == status_progress and ready == status_ready:
		return
	status_text = text
	status_progress = rounded
	status_ready = ready
	queue_redraw()


func configure(new_definition: FurnitureDefinition, new_origin: Vector2i, new_rotation_steps: int,
		new_look: Look) -> void:
	definition = new_definition
	origin = new_origin
	rotation_steps = new_rotation_steps
	look = new_look
	sprite = FurnitureSprites.lookup(definition.id, rotation_steps)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	position = IsoProjection.cell_top_vertex(origin + _footprint())
	match look:
		Look.GHOST_VALID:
			modulate = GHOST_VALID_MODULATE
		Look.GHOST_INVALID:
			modulate = GHOST_INVALID_MODULATE
		_:
			modulate = Color.WHITE
	queue_redraw()


func _footprint() -> Vector2i:
	return CafeLayout.rotated_footprint(definition.footprint, rotation_steps)


## Cantos da base (topo, direita, frente, esquerda), relativos ao nó.
func _base() -> PackedVector2Array:
	var fp := _footprint()
	var corners := [
		IsoProjection.cell_top_vertex(origin),
		IsoProjection.cell_top_vertex(origin + Vector2i(fp.x, 0)),
		IsoProjection.cell_top_vertex(origin + fp),
		IsoProjection.cell_top_vertex(origin + Vector2i(0, fp.y)),
	]
	var center: Vector2 = (corners[0] + corners[2]) / 2.0
	var base := PackedVector2Array()
	for corner: Vector2 in corners:
		base.append(corner.lerp(center, INSET) - position)
	return base


func _draw() -> void:
	if definition == null:
		return
	if sprite != null:
		_draw_sprite()
		return
	var b := _base()
	var up := Vector2(0.0, -definition.placeholder_height)
	var top := PackedVector2Array([b[0] + up, b[1] + up, b[2] + up, b[3] + up])
	var color := definition.placeholder_color

	# Faces visíveis: esquerda (mais escura), direita e tampo.
	var left_face := PackedVector2Array([b[3], b[2], b[2] + up, b[3] + up])
	var right_face := PackedVector2Array([b[2], b[1], b[1] + up, b[2] + up])
	draw_colored_polygon(left_face, color.darkened(0.35))
	draw_colored_polygon(right_face, color.darkened(0.18))
	draw_colored_polygon(top, color.lightened(0.05))

	var outline := EDGE_COLOR
	var width := 1.0
	if look == Look.SELECTED:
		outline = SELECTED_OUTLINE
		width = 3.0
	draw_polyline(PackedVector2Array([top[0], top[1], top[2], top[3], top[0]]), outline, width, true)
	draw_polyline(PackedVector2Array([top[3], b[3], b[2], b[1], top[1]]), outline, width, true)
	draw_line(top[2], b[2], outline, width, true)

	_draw_front_marker(top)
	_draw_label(top)
	_draw_status(Vector2((top[0].x + top[2].x) / 2.0, top[0].y))


## Arte do móvel; selecionado, ganha um contorno laranja no chão, embaixo dele.
func _draw_sprite() -> void:
	var b := _base()
	if look == Look.SELECTED:
		draw_colored_polygon(b, SELECTED_FILL)
		draw_polyline(PackedVector2Array([b[0], b[1], b[2], b[3], b[0]]), SELECTED_OUTLINE, 3.0, true)
	var rect := sprite.draw_rect()
	draw_texture_rect(sprite.texture, rect, false)
	_draw_status(Vector2((b[0].x + b[2].x) / 2.0, rect.position.y))


## Etiqueta arredondada acima do móvel, com barra de progresso opcional.
## top_center: ponto mais alto do desenho, no meio do móvel.
func _draw_status(top_center: Vector2) -> void:
	if status_text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, STATUS_SIZE)
	var has_bar := status_progress >= 0.0
	var box_size := Vector2(text_size.x + 14.0, 20.0 + (6.0 if has_bar else 0.0))
	var anchor := top_center - Vector2(0.0, 8.0)
	var box := Rect2(anchor - Vector2(box_size.x / 2.0, box_size.y), box_size)
	draw_style_box(_status_style(), box)
	draw_string(font, Vector2(box.position.x + 7.0, box.position.y + 15.0), status_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, STATUS_SIZE, STATUS_TEXT)
	if has_bar:
		var bar := Rect2(box.position + Vector2(6.0, box_size.y - 7.0), Vector2(box_size.x - 12.0, 3.0))
		draw_rect(bar, STATUS_BAR_BG)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * status_progress, bar.size.y)), STATUS_BAR_FILL)


func _status_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = STATUS_READY_BG if status_ready else STATUS_BG
	style.set_corner_radius_all(6)
	return style


## Ponto no tampo, na borda voltada para a "frente" do móvel.
## 0 = sudoeste, 1 = noroeste, 2 = nordeste, 3 = sudeste (sentido horário).
func _draw_front_marker(top: PackedVector2Array) -> void:
	var edges := [[top[2], top[3]], [top[3], top[0]], [top[0], top[1]], [top[1], top[2]]]
	var edge: Array = edges[posmod(rotation_steps, 4)]
	var center := (top[0] + top[2]) / 2.0
	var point: Vector2 = ((edge[0] + edge[1]) / 2.0).lerp(center, 0.3)
	draw_circle(point, 4.0, EDGE_COLOR.darkened(0.3), true, -1.0, true)


func _draw_label(top: PackedVector2Array) -> void:
	var font := ThemeDB.fallback_font
	var text := definition.display_name
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var center := (top[0] + top[2]) / 2.0
	draw_string(font, center + Vector2(-text_width / 2.0, LABEL_SIZE / 3.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, LABEL_COLOR)
