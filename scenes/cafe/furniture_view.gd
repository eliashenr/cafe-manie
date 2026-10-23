class_name FurnitureView
extends Node2D
## Móvel desenhado com o sprite da arte v3 (ArtSprites). Na cozinha, o fogão que
## cozinha mostra a panela e o forno aceso, com um selo do prato, do progresso e do
## tempo; o balcão mostra a pilha de pratos com a quantidade. Móvel sem arte cai no
## PLACEHOLDER_FURNITURE: caixa isométrica colorida, com o nome em cima, um ponto
## marcando a frente (para a rotação ficar visível) e uma etiqueta de texto.
##
## O nó fica no vértice da frente do móvel. O desenho é cortado em faixas verticais (Slice), cada
## uma no y-sort do salão pela altura da borda da frente da pegada no meio dela: quem passa na frente
## de qualquer trecho do móvel (inclusive da metade de trás de um balcão de 2 pisos) é desenhado na
## frente daquele trecho. O que fica em cima (panela, pilha, pratos) é desenhado pelo próprio nó, no
## vértice da frente. Os selos ficam num filho com z_index alto.

enum Look { NORMAL, SELECTED, GHOST_VALID, GHOST_INVALID }


## Faixa vertical do desenho do móvel, no y-sort do salão pela posição dela.
class Slice:
	extends Node2D

	var sprite: ArtSprites.Sprite
	## Trecho do desenho que esta faixa mostra (pixels de mundo, relativo ao móvel).
	var span := Rect2()

	func _draw() -> void:
		var rect := sprite.draw_rect()
		var source := Rect2((span.position.x - rect.position.x) * sprite.density, 0.0, span.size.x * sprite.density,
			sprite.texture.get_size().y)
		draw_texture_rect_region(sprite.texture, Rect2(span.position - position, span.size), source)


## Quanto a caixa encolhe em relação às bordas das células (0 a 0.5).
const INSET := 0.12
const GHOST_VALID_MODULATE := Color(0.65, 1.0, 0.65, 0.8)
const GHOST_INVALID_MODULATE := Color(1.0, 0.5, 0.5, 0.8)
const SELECTED_OUTLINE := Color("f29f1f")
const EDGE_COLOR := Color(0.1, 0.06, 0.04, 0.45)
const LABEL_COLOR := Color(0.1, 0.06, 0.04)
const LABEL_SIZE := 13
const SELECTED_FILL := Color(0.95, 0.62, 0.12, 0.28)
## Troféu escolhido ou sendo posicionado (DT-057): as casas em volta que ele acelera, e o troféu gasto, apagado.
const TROPHY_AREA_FILL := Color(1.0, 0.85, 0.2, 0.22)
const TROPHY_AREA_EDGE := Color(1.0, 0.72, 0.1, 0.9)
const TROPHY_REACH := 1
const WORN_MODULATE := Color(0.62, 0.62, 0.66)
## Fruta madura no pé (DT-065): o selo branco com a fruta, acima do vaso.
const FRUIT_BADGE_LIFT := 96.0
const FRUIT_BADGE_RADIUS := 18.0
const FRUIT_ICON := 28.0
## Notas do show: de onde sobem, acima do meio do palco.
const NOTES_LIFT := 50.0
## Luz da luminária à noite (DT-064): cor quente, força no escuro total e altura acima do chão.
const LIGHT_COLOR := Color(1.0, 0.86, 0.55)
const LIGHT_ENERGY := 1.2
const LIGHT_LIFT := 60.0

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
## Prato estragado (DT-055): anel e etiqueta verde-oliva, e a comida e a panela esverdeadas.
const BADGE_SPOILED := Color("8a9a2a")
const BADGE_PILL_SPOILED_FILL := Color("7a6a3a")
const SPOILED_TINT := Color(0.62, 0.78, 0.42)
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
## Halo: cores (selecionado, prato pronto) e quanto o desenho cresce nas duas camadas do brilho.
const HALO_SELECTED := Color(1.0, 0.62, 0.12, 0.8)
const HALO_READY := Color(1.0, 0.86, 0.25, 0.85)
const HALO_SCALES: Array[float] = [1.1, 1.05]
## Largura das faixas do desenho (pixels de mundo, um quarto do piso). Quanto mais fina, mais perto
## da borda alguém pode passar sem ser desenhado atrás do móvel.
const SLICE_WIDTH := 32.0
## Pilha do balcão: de quantos pixels acima ela cai quando chega prato.
const STACK_POP_HEIGHT := 14.0
## Vapor: onde sai, na panela (fração da altura do desenho da panela, a partir do topo) e acima da
## pilha de pratos do balcão (pixels de mundo acima do tampo).
const STEAM_HEIGHT := 0.35
const STACK_STEAM_HEIGHT := 18.0

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
## O prato do fogão estragou: panela esverdeada, selo oliva e fumaça verde em vez de vapor.
var status_spoiled := false
## Troféu sem cargas (DT-057): desenhado apagado.
var worn := false
## Pé de fruta maduro (DT-065): mostra a fruta para colher.
var fruit_ready := false
## Ouro guardado na atração (DT-066): com ouro, mostra a moeda para coletar.
var attraction_gold := 0
var _notes: CPUParticles2D
## Receita no fogão ou no balcão (null = nada), o texto curto do selo do fogão
## ("0:12", "Pronto!") e quantas porções há no balcão.
var kitchen_recipe: RecipeDefinition
var kitchen_detail := ""
var kitchen_count := 0
## Pratos sobre o tampo (mesas), cada um [ponto no grid, RecipeDefinition]. O ponto
## usa a convenção do Agent: o centro da célula (x, y) é Vector2(x, y).
var dishes: Array = []

var _overlay := Node2D.new()
## Faixas do desenho e para que desenho e pegada foram cortadas (só recorta quando muda).
var _slices: Array[Slice] = []
var _sliced_for: Array = []
## Contorno laranja no chão (selecionado) e halo de brilho (selecionado ou fogão com prato pronto):
## os dois ficam no y-sort logo antes da primeira faixa, para aparecerem atrás do móvel.
var _floor_mark := Node2D.new()
var _halo := Node2D.new()
## O vapor fica num nó no vértice da frente, para sair por cima do desenho do fogão.
var _fx := Node2D.new()
var _steam: CPUParticles2D
var _stink: CPUParticles2D
var _light: PointLight2D
## Quanto a pilha de pratos do balcão está acima do lugar (anima quando chega prato).
var stack_pop := 0.0:
	set(value):
		stack_pop = value
		queue_redraw()


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	y_sort_enabled = true  # as faixas (filhas) entram no y-sort do salão, cada uma na sua altura
	_overlay.name = "Overlay"
	_overlay.z_index = OVERLAY_Z
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_floor_mark.name = "FloorMark"
	_floor_mark.draw.connect(_draw_floor_mark)
	add_child(_floor_mark)
	_halo.name = "Halo"
	_halo.visible = false
	_halo.material = FxMaterials.glow(HALO_SELECTED)
	_halo.draw.connect(_draw_halo)
	add_child(_halo)
	_fx.name = "Fx"
	add_child(_fx)


## Troca os pratos sobre o tampo; só redesenha se algo mudou.
func set_dishes(new_dishes: Array) -> void:
	if new_dishes == dishes:
		return
	dishes = new_dishes
	queue_redraw()


## Atualiza o estado da cozinha (texto, progresso, pronto, receita, texto curto e porções);
## só redesenha se algo mudou.
func set_status(text: String, progress := -1.0, ready := false, recipe: RecipeDefinition = null, detail := "",
		count := 0, spoiled := false) -> void:
	var rounded := snappedf(progress, 0.01)
	if text == status_text and rounded == status_progress and ready == status_ready and recipe == kitchen_recipe \
			and detail == kitchen_detail and count == kitchen_count and spoiled == status_spoiled:
		return
	if definition != null and definition.category == FurnitureDefinition.Category.COUNTER and count > kitchen_count \
			and is_inside_tree():
		Juice.settle(self, "stack_pop", -STACK_POP_HEIGHT, 0.0)
	status_text = text
	status_progress = rounded
	status_ready = ready
	status_spoiled = spoiled
	kitchen_recipe = recipe
	kitchen_detail = detail
	kitchen_count = count
	queue_redraw()
	_overlay.queue_redraw()
	_refresh_fx()


func configure(new_definition: FurnitureDefinition, new_origin: Vector2i, new_rotation_steps: int,
		new_look: Look) -> void:
	definition = new_definition
	origin = new_origin
	rotation_steps = new_rotation_steps
	look = new_look
	sprite = ArtSprites.furniture(definition.id, rotation_steps)
	position = IsoProjection.cell_top_vertex(origin + _footprint())
	_slice_sprite()
	_refresh_fx()
	_apply_modulate()
	queue_redraw()
	_overlay.queue_redraw()
	_floor_mark.queue_redraw()


## Corta o desenho em faixas de SLICE_WIDTH. A faixa fica na altura (y) da borda da frente da pegada
## no meio do trecho dela: a borda desce 1 pixel a cada 2 do vértice da esquerda até o da frente
## (o nó) e sobe do mesmo jeito até o da direita. O que passa dos vértices dos lados (folhas, sombra)
## vai junto com a faixa da ponta.
func _slice_sprite() -> void:
	var fp := _footprint()
	if _sliced_for == [sprite, fp]:
		return
	_sliced_for = [sprite, fp]
	for old in _slices:
		old.queue_free()
	_slices.clear()
	if sprite == null:
		return
	var rect := sprite.draw_rect()
	# vértices da esquerda (origem + (0, fp.y)) e da direita (origem + (fp.x, 0)), relativos ao da frente
	var left := -fp.x * IsoProjection.HALF_TILE.x
	var right := fp.y * IsoProjection.HALF_TILE.x
	var cuts: Array[float] = [rect.position.x]
	var cut := ceilf((maxf(left, rect.position.x) + 0.01) / SLICE_WIDTH) * SLICE_WIDTH
	while cut < minf(right, rect.end.x) - 0.01:
		cuts.append(cut)
		cut += SLICE_WIDTH
	cuts.append(rect.end.x)
	var slope := IsoProjection.HALF_TILE.y / IsoProjection.HALF_TILE.x
	for i in cuts.size() - 1:
		var middle := (clampf(cuts[i], left, right) + clampf(cuts[i + 1], left, right)) / 2.0
		var slice := Slice.new()
		slice.name = "Slice%d" % i
		slice.sprite = sprite
		slice.span = Rect2(cuts[i], rect.position.y, cuts[i + 1] - cuts[i], rect.size.y)
		slice.position = Vector2(0.0, -absf(middle) * slope)
		add_child(slice)
		_slices.append(slice)
	var behind := Vector2(0.0, _slices.reduce(func(low: float, s: Slice) -> float: return minf(low, s.position.y), 0.0) - 1.0)
	_floor_mark.position = behind
	_halo.position = behind


## Faixas do desenho (no y-sort do salão, cada uma na sua altura).
func slices() -> Array[Slice]:
	return _slices


## O ponto do grid (centro da célula (x, y) = Vector2(x, y)) está na frente do móvel? Na frente é
## depois da borda da frente da pegada em x ou em y (a câmera olha de +x, +y).
func is_in_front(point: Vector2) -> bool:
	var far := Vector2(origin + _footprint()) - Vector2(0.5, 0.5)
	return point.x > far.x or point.y > far.y


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


## O que fica em cima da arte do móvel (o desenho dele está nas faixas): pratos, panela, pilha ou etiqueta.
func _draw_sprite() -> void:
	var b := _base()
	var rect := sprite.draw_rect()
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


## Panela com a chama acesa e, quando a frente aparece, o forno aceso. Estragado: panela esverdeada, forno apagado.
func _draw_cooking() -> void:
	var pot := ArtSprites.cookware(kitchen_recipe.id)
	draw_texture_rect(pot.texture, pot.draw_rect(), false, SPOILED_TINT if status_spoiled else Color.WHITE)
	if status_spoiled:
		return
	var glow := ArtSprites.stove_glow(rotation_steps)
	if glow != null:
		draw_texture_rect(glow.texture, glow.draw_rect(), false)


## Pausa: o vapor fica parado no ar (o desenho e as animações de surgir continuam).
func set_frozen(value: bool) -> void:
	_fx.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT


## Brilho: está aceso? (selecionado, ou fogão com prato pronto esperando)
func glowing() -> bool:
	return _halo.visible


## Vapor saindo? (panela do fogão cozinhando ou com prato pronto, ou pratos quentes no balcão)
func steaming() -> bool:
	return _steam != null and _steam.emitting


## Fumaça verde saindo? (prato estragado no fogão)
func stinking() -> bool:
	return _stink != null and _stink.emitting


## Liga e desliga o halo e o vapor conforme o estado (seleção e cozinha). O fantasma da compra nunca
## está selecionado nem recebe o estado da cozinha, então nunca brilha nem solta vapor.
func _refresh_fx() -> void:
	if definition == null:
		return
	var ready_stove := definition.category == FurnitureDefinition.Category.COOKING and status_ready
	var glow := sprite != null and (look == Look.SELECTED or ready_stove)
	if glow != _halo.visible or glow:
		_halo.material.set_shader_parameter("glow_color", HALO_SELECTED if look == Look.SELECTED else HALO_READY)
		_halo.visible = glow
		_halo.queue_redraw()
	var on_stove := definition.category == FurnitureDefinition.Category.COOKING and kitchen_recipe != null
	var cooking := on_stove and not status_spoiled
	var hot_dishes := definition.category == FurnitureDefinition.Category.COUNTER and kitchen_count > 0
	var hot := cooking or hot_dishes
	var spoiled := on_stove and status_spoiled
	if hot and _steam == null:
		_steam = FxParticles.steam()
		_fx.add_child(_steam)
	if spoiled and _stink == null:
		_stink = FxParticles.stink()
		_fx.add_child(_stink)
	var pot_top := Vector2.ZERO
	if on_stove and ArtSprites.cookware(kitchen_recipe.id) != null:
		var rect := ArtSprites.cookware(kitchen_recipe.id).draw_rect()
		pot_top = rect.position + Vector2(rect.size.x / 2.0, rect.size.y * STEAM_HEIGHT)
	if _steam != null:
		if cooking:
			_steam.position = pot_top
		elif hot_dishes:
			_steam.position = _footprint_center() - Vector2(0.0, ArtSprites.counter_top() + STACK_STEAM_HEIGHT)
		_steam.emitting = hot
	if _stink != null:
		_stink.position = pot_top
		_stink.emitting = spoiled


## Halo: o próprio desenho, maior, numa cor só e pulsando (o shader), atrás do móvel.
func _draw_halo() -> void:
	if sprite == null:
		return
	var rect := sprite.draw_rect()
	var center := rect.get_center() - _halo.position
	for grow in HALO_SCALES:
		_halo.draw_texture_rect(sprite.texture, Rect2(center - rect.size * grow / 2.0, rect.size * grow), false)


## Acende a luminária com a força da escuridão (0 = apagada). O fantasma da compra não acende.
func set_light(darkness: float) -> void:
	var on := darkness > 0.0 and look in [Look.NORMAL, Look.SELECTED]
	if not on and _light == null:
		return
	if _light == null:
		_light = PointLight2D.new()
		_light.name = "Light"
		_light.texture = FxParticles.soft_dot()
		_light.texture_scale = definition.light_radius / (FxParticles.soft_dot().get_width() / 2.0)
		_light.color = LIGHT_COLOR
		_light.position = _footprint_center() - Vector2(0.0, LIGHT_LIFT)
		_fx.add_child(_light)
	_light.enabled = on
	_light.energy = LIGHT_ENERGY * darkness


## A luminária está acesa?
func light_on() -> bool:
	return _light != null and _light.enabled


## Troféu gasto: apagado (o fantasma da compra nunca fica gasto).
func set_worn(value: bool) -> void:
	if value == worn:
		return
	worn = value
	_apply_modulate()


func _apply_modulate() -> void:
	match look:
		Look.GHOST_VALID:
			modulate = GHOST_VALID_MODULATE
		Look.GHOST_INVALID:
			modulate = GHOST_INVALID_MODULATE
		_:
			modulate = WORN_MODULATE if worn else Color.WHITE


## Mostra no chão as casas que o troféu acelera? (escolhido ou sendo posicionado)
func shows_trophy_area() -> bool:
	return definition != null and definition.is_trophy() and look in [Look.SELECTED, Look.GHOST_VALID, Look.GHOST_INVALID]


## As casas em volta do troféu (as 8 de um troféu de 1 piso), em dourado clarinho.
func _draw_trophy_area() -> void:
	var fp := _footprint()
	var reach := Vector2i.ONE * TROPHY_REACH
	var corners := PackedVector2Array([
		IsoProjection.cell_top_vertex(origin - reach),
		IsoProjection.cell_top_vertex(origin + Vector2i(fp.x + TROPHY_REACH, -TROPHY_REACH)),
		IsoProjection.cell_top_vertex(origin + fp + reach),
		IsoProjection.cell_top_vertex(origin + Vector2i(-TROPHY_REACH, fp.y + TROPHY_REACH)),
	])
	for i in corners.size():
		corners[i] -= position + _floor_mark.position
	_floor_mark.draw_colored_polygon(corners, TROPHY_AREA_FILL)
	_floor_mark.draw_polyline(PackedVector2Array([corners[0], corners[1], corners[2], corners[3], corners[0]]), TROPHY_AREA_EDGE,
		2.0, true)


## Selecionado: contorno laranja no chão, embaixo do móvel (e, no troféu, as casas que ele acelera).
func _draw_floor_mark() -> void:
	if sprite != null and shows_trophy_area():
		_draw_trophy_area()
	if sprite == null or look != Look.SELECTED:
		return
	var b := _base()
	for i in b.size():
		b[i] -= _floor_mark.position
	_floor_mark.draw_colored_polygon(b, SELECTED_FILL)
	_floor_mark.draw_polyline(PackedVector2Array([b[0], b[1], b[2], b[3], b[0]]), SELECTED_OUTLINE, 3.0, true)


## Pilha de pratos com a comida no meio do tampo do balcão (um prato a cada 4 porções, até 3).
func _draw_stack() -> void:
	var at := _footprint_center() - Vector2(0.0, ArtSprites.counter_top() - stack_pop)
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


func set_attraction_gold(value: int) -> void:
	if value == attraction_gold:
		return
	attraction_gold = value
	_overlay.queue_redraw()


## Show no palco: as notas sobem enquanto ele dura.
func set_show(on: bool) -> void:
	if not on and _notes == null:
		return
	if _notes == null:
		var note := ArtSprites.get_sprite("icone_nota")
		_notes = FxParticles.notes(note.texture if note != null else FxParticles.soft_dot())
		_notes.position = _footprint_center() - Vector2(0.0, NOTES_LIFT)
		_fx.add_child(_notes)
	_notes.emitting = on


## As notas do show estão subindo?
func showing() -> bool:
	return _notes != null and _notes.emitting


func set_fruit_ready(value: bool) -> void:
	if value == fruit_ready:
		return
	fruit_ready = value
	_overlay.queue_redraw()


## Selos no filho de cima: o do fogão (prato, progresso e tempo), o número do balcão e a fruta madura do pé.
func _draw_overlay() -> void:
	if attraction_gold > 0 and definition != null and definition.attraction_gold > 0:
		var spot := _footprint_center() - Vector2(0.0, FRUIT_BADGE_LIFT)
		_overlay.draw_circle(spot, FRUIT_BADGE_RADIUS, BADGE_FILL, true, -1.0, true)
		_overlay.draw_arc(spot, FRUIT_BADGE_RADIUS, 0.0, TAU, 40, BADGE_READY, 2.4, true)
		var coin := ArtSprites.get_sprite("icone_moeda")
		if coin != null:
			var size := Vector2.ONE * FRUIT_ICON
			_overlay.draw_texture_rect(coin.texture, Rect2(spot - size / 2.0, size), false)
		return
	if fruit_ready and definition != null and definition.fruit != &"":
		var center := _footprint_center() - Vector2(0.0, FRUIT_BADGE_LIFT)
		_overlay.draw_circle(center, FRUIT_BADGE_RADIUS, BADGE_FILL, true, -1.0, true)
		_overlay.draw_arc(center, FRUIT_BADGE_RADIUS, 0.0, TAU, 40, BADGE_READY, 2.4, true)
		var icon := ArtSprites.fruit(definition.fruit)
		if icon != null:
			_overlay.draw_texture_rect(icon.texture, icon.rect_at(center + Vector2(0.0, 2.0), FRUIT_ICON / ArtSprites.food_width()), false)
		return
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
	var progress := 1.0 if status_ready or status_spoiled else clampf(status_progress, 0.0, 1.0)
	var ring_color := BADGE_SPOILED if status_spoiled else (BADGE_READY if status_ready else BADGE_PROGRESS)
	if progress > 0.0:
		canvas.draw_arc(center, ring, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, ring_color, BADGE_RING, true)
	var food := ArtSprites.food(kitchen_recipe.id)
	canvas.draw_texture_rect(food.texture, food.rect_at(center + Vector2(0.0, 1.5), BADGE_FOOD / ArtSprites.food_width()), false,
		SPOILED_TINT if status_spoiled else Color.WHITE)
	var pill_size := BADGE_PILL_READY if status_ready or status_spoiled else BADGE_PILL
	var pill := Rect2(center + Vector2(-pill_size.x / 2.0, BADGE_RADIUS - 7.6), pill_size)
	var pill_fill := BADGE_PILL_SPOILED_FILL if status_spoiled else (BADGE_PILL_READY_FILL if status_ready else BADGE_PILL_FILL)
	canvas.draw_style_box(_pill_style(pill_fill, Color.WHITE), pill)
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
