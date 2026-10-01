class_name FurnitureView
extends Node2D
## Móvel desenhado com o sprite da arte v3 (ArtSprites). Na cozinha, o fogão que
## cozinha mostra a panela e o forno aceso, com um selo do prato, do progresso e do
## tempo; o balcão mostra a pilha de pratos com a quantidade. Móvel sem arte cai no
## PLACEHOLDER_FURNITURE: caixa isométrica colorida, com o nome em cima, um ponto
## marcando a frente (para a rotação ficar visível) e uma etiqueta de texto.
##
## O nó fica no vértice da frente do móvel, para que o y-sort da camada
## desenhe na ordem de profundidade. Os selos ficam num filho com z_index alto.

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

const STATUS_BG := Color(0.1, 0.07, 0.05, 0.85)
const STATUS_READY_BG := Color(0.2, 0.62, 0.3, 0.95)
const STATUS_TEXT := Color(1, 1, 1)
const STATUS_BAR_BG := Color(1, 1, 1, 0.25)
const STATUS_BAR_FILL := Color("f2b33d")
const STATUS_SIZE := 13

## Largura do prato na mesa, em relação ao tamanho natural do sprite (como no canvas: 26 de 48).
const DISH_SCALE := 26.0 / 48.0
## O prato fica um pouco acima do tampo (centro do ícone), em pixels de mundo.
const DISH_LIFT := 5.0

## Selos por cima de todo o salão (como os balões dos clientes).
const OVERLAY_Z := 10
## Selo do fogão (medidas do canvas na escala do jogo, em pixels de mundo).
const BADGE_LIFT := 158.0
const BADGE_RADIUS := 22.9
const BADGE_RING := 6.4
const BADGE_FOOD := 33.0
const BADGE_PILL := Vector2(67.0, 27.4)
const BADGE_PILL_READY := Vector2(88.0, 27.4)
const BADGE_TEXT_SIZE := 18
const BADGE_FILL := Color.WHITE
const BADGE_EDGE := Color("2a5fa8")
const BADGE_TRACK := Color("d3e2f5")
const BADGE_PROGRESS := Color("1f7ae0")
const BADGE_READY := Color("35c24a")
const BADGE_PILL_FILL := Color("2b86e8")
const BADGE_PILL_READY_FILL := Color("3cc04e")
const BADGE_GLOW := Color(1.0, 0.965, 0.66, 0.45)
const BADGE_SHADOW := Color(0.1, 0.16, 0.29, 0.2)
## Pilha de pratos no balcão: prato, comida e o número (pixels de mundo).
const PLATE_RADII := Vector2(20.0, 7.2)
const PLATE_STEP := 2.9
const STACK_FOOD := 40.0
const STACK_SERVINGS_PER_PLATE := 4
const STACK_MAX_PLATES := 3
const COUNT_OFFSET := Vector2(21.3, -34.7)
const COUNT_SIZE := Vector2(34.7, 21.3)
const COUNT_EDGE := Color("1f6fd1")
const COUNT_TEXT_SIZE := 15
const ART_INK := Color("33283a")

var definition: FurnitureDefinition
var origin := Vector2i.ZERO
## Quartos de volta (0 a 3). Não confundir com Node2D.rotation.
var rotation_steps := 0
var look := Look.NORMAL
## Arte do móvel nesta rotação; null = desenha o placeholder.
var sprite: ArtSprites.Sprite

## Etiqueta de estado acima do móvel (ex.: "Café 0:12", "Café ×6"). Vazia = sem etiqueta.
var status_text := ""
## Barra de progresso sob a etiqueta (0 a 1). Negativo = sem barra.
var status_progress := -1.0
## Destaca a etiqueta em verde (prato pronto para servir).
var status_ready := false
## Receita no fogão ou no balcão (null = nada), o texto curto do selo do fogão
## ("0:12", "Pronto!") e quantas porções há no balcão.
var kitchen_recipe: RecipeDefinition
var kitchen_detail := ""
var kitchen_count := 0
## Pratos sobre o tampo (mesas), cada um [ponto no grid, RecipeDefinition]. O ponto
## usa a convenção do Agent: o centro da célula (x, y) é Vector2(x, y).
var dishes: Array = []

var _overlay := Node2D.new()


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_overlay.name = "Overlay"
	_overlay.z_index = OVERLAY_Z
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


## Troca os pratos sobre o tampo; só redesenha se algo mudou.
func set_dishes(new_dishes: Array) -> void:
	if new_dishes == dishes:
		return
	dishes = new_dishes
	queue_redraw()


## Atualiza o estado da cozinha (texto, progresso, pronto, receita, texto curto e porções);
## só redesenha se algo mudou.
func set_status(text: String, progress := -1.0, ready := false, recipe: RecipeDefinition = null, detail := "",
		count := 0) -> void:
	var rounded := snappedf(progress, 0.01)
	if text == status_text and rounded == status_progress and ready == status_ready and recipe == kitchen_recipe \
			and detail == kitchen_detail and count == kitchen_count:
		return
	status_text = text
	status_progress = rounded
	status_ready = ready
	kitchen_recipe = recipe
	kitchen_detail = detail
	kitchen_count = count
	queue_redraw()
	_overlay.queue_redraw()


func configure(new_definition: FurnitureDefinition, new_origin: Vector2i, new_rotation_steps: int,
		new_look: Look) -> void:
	definition = new_definition
	origin = new_origin
	rotation_steps = new_rotation_steps
	look = new_look
	sprite = ArtSprites.furniture(definition.id, rotation_steps)
	position = IsoProjection.cell_top_vertex(origin + _footprint())
	match look:
		Look.GHOST_VALID:
			modulate = GHOST_VALID_MODULATE
		Look.GHOST_INVALID:
			modulate = GHOST_INVALID_MODULATE
		_:
			modulate = Color.WHITE
	queue_redraw()
	_overlay.queue_redraw()


## A cozinha deste móvel aparece com arte (panela, pilha e selos) em vez da etiqueta de texto?
func shows_kitchen_art() -> bool:
	if sprite == null or kitchen_recipe == null or ArtSprites.food(kitchen_recipe.id) == null:
		return false
	match definition.category:
		FurnitureDefinition.Category.COOKING:
			return ArtSprites.cookware(kitchen_recipe.id) != null
		FurnitureDefinition.Category.COUNTER:
			return kitchen_count > 0
	return false


func _footprint() -> Vector2i:
	return CafeLayout.rotated_footprint(definition.footprint, rotation_steps)


## Meio da pegada no chão, relativo ao nó.
func _footprint_center() -> Vector2:
	return IsoProjection.vertex_to_world(Vector2(origin) + Vector2(_footprint()) / 2.0) - position


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
	_draw_dishes()
	if shows_kitchen_art():
		if definition.category == FurnitureDefinition.Category.COOKING:
			_draw_cooking()
		else:
			_draw_stack()
	else:
		_draw_status(Vector2((b[0].x + b[2].x) / 2.0, rect.position.y))


func _draw_dishes() -> void:
	var top := ArtSprites.table_top(definition.id)
	var placed: Array = []
	for dish: Array in dishes:
		var food := ArtSprites.food((dish[1] as RecipeDefinition).id)
		if food == null:
			continue
		var at := IsoProjection.grid_point_to_world(dish[0]) - position - Vector2(0.0, top + DISH_LIFT)
		placed.append([at, food])
	placed.sort_custom(func(a: Array, b: Array) -> bool: return a[0].y < b[0].y)
	for item: Array in placed:
		var food: ArtSprites.Sprite = item[1]
		draw_texture_rect(food.texture, food.rect_at(item[0], DISH_SCALE), false)


## Panela com a chama acesa e, quando a frente aparece, o forno aceso.
func _draw_cooking() -> void:
	var pot := ArtSprites.cookware(kitchen_recipe.id)
	draw_texture_rect(pot.texture, pot.draw_rect(), false)
	var glow := ArtSprites.stove_glow(rotation_steps)
	if glow != null:
		draw_texture_rect(glow.texture, glow.draw_rect(), false)


## Pilha de pratos com a comida no meio do tampo do balcão (um prato a cada 4 porções, até 3).
func _draw_stack() -> void:
	var at := _footprint_center() - Vector2(0.0, ArtSprites.counter_top())
	var plates := clampi(kitchen_count / STACK_SERVINGS_PER_PLATE, 1, STACK_MAX_PLATES)
	for i in plates:
		_draw_plate(at + Vector2(0.0, 1.3 - i * PLATE_STEP))
	var food := ArtSprites.food(kitchen_recipe.id)
	var food_at := at - Vector2(0.0, 8.0 + plates * 2.7)
	draw_texture_rect(food.texture, food.rect_at(food_at, STACK_FOOD / ArtSprites.food_width()), false)


func _draw_plate(center: Vector2) -> void:
	var squash := PLATE_RADII.y / PLATE_RADII.x
	draw_set_transform(center, 0.0, Vector2(1.0, squash))
	draw_circle(Vector2.ZERO, PLATE_RADII.x, Color.WHITE, true, -1.0, true)
	draw_arc(Vector2.ZERO, PLATE_RADII.x, 0.0, TAU, 32, ART_INK, 1.2 / squash, true)
	draw_set_transform(Vector2.ZERO)


## Selos no filho de cima: o do fogão (prato, progresso e tempo) e o número do balcão.
func _draw_overlay() -> void:
	if definition == null or not shows_kitchen_art() or look in [Look.GHOST_VALID, Look.GHOST_INVALID]:
		return
	if definition.category == FurnitureDefinition.Category.COOKING:
		_draw_stove_badge(_footprint_center() - Vector2(0.0, BADGE_LIFT))
	else:
		var at := _footprint_center() - Vector2(0.0, ArtSprites.counter_top()) + COUNT_OFFSET
		_draw_count_badge(at)


func _draw_stove_badge(center: Vector2) -> void:
	var canvas := _overlay
	if status_ready:
		canvas.draw_circle(center, BADGE_RADIUS + 13.0, BADGE_GLOW, true, -1.0, true)
	canvas.draw_circle(center + Vector2(1.8, 3.3), BADGE_RADIUS, BADGE_SHADOW, true, -1.0, true)
	canvas.draw_circle(center, BADGE_RADIUS, BADGE_FILL, true, -1.0, true)
	canvas.draw_arc(center, BADGE_RADIUS, 0.0, TAU, 48, BADGE_EDGE, 2.4, true)
	var ring := BADGE_RADIUS - 5.2
	canvas.draw_arc(center, ring, 0.0, TAU, 48, BADGE_TRACK, BADGE_RING, true)
	var progress := 1.0 if status_ready else clampf(status_progress, 0.0, 1.0)
	if progress > 0.0:
		canvas.draw_arc(center, ring, -PI / 2.0, -PI / 2.0 + TAU * progress, 48,
			BADGE_READY if status_ready else BADGE_PROGRESS, BADGE_RING, true)
	var food := ArtSprites.food(kitchen_recipe.id)
	canvas.draw_texture_rect(food.texture, food.rect_at(center + Vector2(0.0, 1.5), BADGE_FOOD / ArtSprites.food_width()), false)
	var pill_size := BADGE_PILL_READY if status_ready else BADGE_PILL
	var pill := Rect2(center + Vector2(-pill_size.x / 2.0, BADGE_RADIUS - 7.6), pill_size)
	canvas.draw_style_box(_pill_style(BADGE_PILL_READY_FILL if status_ready else BADGE_PILL_FILL, Color.WHITE), pill)
	_draw_centered_text(kitchen_detail, pill, BADGE_TEXT_SIZE, Color.WHITE)


func _draw_count_badge(center: Vector2) -> void:
	var box := Rect2(center - COUNT_SIZE / 2.0, COUNT_SIZE)
	_overlay.draw_style_box(_pill_style(Color.WHITE, COUNT_EDGE), box)
	_draw_centered_text(str(kitchen_count), box, COUNT_TEXT_SIZE, COUNT_EDGE)


func _draw_centered_text(text: String, box: Rect2, size: int, color: Color) -> void:
	var font := UiTheme.font(UiTheme.BOLD)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := box.position.y + (box.size.y + font.get_ascent(size) - font.get_descent(size)) / 2.0
	_overlay.draw_string(font, Vector2(box.get_center().x - width / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		size, color)


func _pill_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.anti_aliasing = true
	return style


## PLACEHOLDER_FURNITURE: etiqueta arredondada acima do móvel, com barra de progresso opcional.
## top_center: ponto mais alto do desenho, no meio do móvel.
func _draw_status(top_center: Vector2) -> void:
	if status_text.is_empty():
		return
	var font := UiTheme.font(UiTheme.BOLD)
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
	var font := UiTheme.font(UiTheme.BOLD)
	var text := definition.display_name
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var center := (top[0] + top[2]) / 2.0
	draw_string(font, center + Vector2(-text_width / 2.0, LABEL_SIZE / 3.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE, LABEL_COLOR)
