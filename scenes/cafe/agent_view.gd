class_name AgentView
extends Node2D
## Personagem (cliente ou garçom) desenhado com a arte v3 (ArtSprites): em pé,
## andando ou sentado, de frente ou de costas, espelhado conforme a direção.
## Mostra o balão do pedido com a barra de paciência, a carinha de quem vai
## embora e o prato na bandeja do garçom. Sem arte, cai no
## PLACEHOLDER_CHARACTER: formas simples.
##
## O nó fica nos pés do personagem (sentado, no vértice da frente da cadeira),
## para o y-sort da camada do mundo desenhar na ordem de profundidade certa.
## Balões e carinhas ficam num filho com z_index alto: nada do salão os cobre.

## Pequeno desempate para o personagem ficar à frente do móvel do mesmo piso.
const SORT_NUDGE := 1.0
## Balões por cima de todo o salão (móveis e personagens ficam no z 0).
const OVERLAY_Z := 10
## Ciclo de andar: passo, em pé, outro passo, em pé. Troca de quadro a cada
## 1/WALK_FRAMES_PER_CELL de piso andado.
const WALK_CYCLE: Array[String] = ["andar", "em_pe", "andar2", "em_pe"]
const WALK_FRAMES_PER_CELL := 4.0
## Abaixo desta fração de paciência o cliente fica preocupado; abaixo da outra, bravo.
## São as mesmas faixas das cores da barra do balão.
const PATIENCE_WORRIED := 0.5
const PATIENCE_ANGRY := 0.25

const BALLOON_FOOD := 40.0  ## largura do prato dentro do balão, em pixels de mundo
const BALLOON_PAD := 7.0
const BALLOON_TAIL := 9.0
const BALLOON_BAR := 5.0
const BALLOON_FILL := Color.WHITE
const BALLOON_EDGE := Color("2a5fa8")
const BALLOON_SHADOW := Color(0.1, 0.16, 0.29, 0.18)
const BALLOON_TEXT := Color("1f7ae0")
const BALLOON_TEXT_SIZE := 13
const QUESTION_SIZE := 30
const PATIENCE_GOOD := Color("35c24a")
const PATIENCE_MID := Color("ffb400")
const PATIENCE_BAD := Color("ff3b3b")
const PATIENCE_TRACK := Color("d7e3f3")

const SKIN := Color("e8b894")
const HAIR := Color("4a3222")
const OUTLINE := Color(0.1, 0.06, 0.04, 0.6)
const SHADOW := Color(0, 0, 0, 0.18)
const WAITER_SHIRT := Color("f4f1ea")
const WAITER_APRON := Color("2f3a4a")
## PLACEHOLDER_CHARACTER: quanto o boneco simples sobe quando está sentado.
const SEAT_LIFT := 14.0

var agent: Agent
## Rotação da cadeira de quem está sentado (0 a 3); -1 = não está sentado.
var seat_rotation := -1

static var _balloon_style: StyleBoxFlat
static var _balloon_shadow_style: StyleBoxFlat

var _overlay := Node2D.new()


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_overlay.name = "Overlay"
	_overlay.z_index = OVERLAY_Z
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


## Lê o estado do agente e se reposiciona. Chamado a cada frame.
func refresh(target: Agent, new_seat_rotation := -1) -> void:
	agent = target
	seat_rotation = new_seat_rotation
	if _is_seated():
		# Sentado: ordena junto com a cadeira (logo à frente dela).
		position = IsoProjection.cell_top_vertex(agent.cell() + Vector2i.ONE) + Vector2(0, SORT_NUDGE)
	else:
		position = IsoProjection.grid_point_to_world(agent.position) + Vector2(0, SORT_NUDGE)
	queue_redraw()
	_overlay.queue_redraw()


## Nome do sprite do corpo e se ele sai espelhado. Ex.: ["cliente_03_frente_andar", true].
func pose() -> Array:
	var look := _look()
	if _is_seated():
		var rotation := seat_rotation if seat_rotation >= 0 else 3
		if rotation == 1 or rotation == 2:
			return ["%s_sentado_costas_r%d" % [look, rotation], false]
		return ["%s_sentado_%s" % [look, expression()], rotation == 0]
	var direction := _direction()
	var frame := "em_pe"
	if agent.is_moving():
		var phase := floori((agent.position.x + agent.position.y) * WALK_FRAMES_PER_CELL)
		frame = WALK_CYCLE[posmod(phase, WALK_CYCLE.size())]
	var sprite_name := "%s_%s_%s" % [look, "costas" if direction[0] else "frente", frame]
	if agent is Waiter and (agent as Waiter).carrying != null:
		sprite_name += "_bandeja"
	return [sprite_name, direction[1]]


## Expressão do cliente sentado: comendo, ou conforme a paciência que sobra.
func expression() -> String:
	var customer := agent as Customer
	if customer.state == Customer.State.EATING:
		return "comendo"
	var patience := customer.patience_fraction()
	if patience < PATIENCE_ANGRY:
		return "bravo"
	if patience < PATIENCE_WORRIED:
		return "esperando"
	return "feliz"


func _draw() -> void:
	if agent == null:
		return
	var body_pose := pose()
	var sprite := ArtSprites.get_sprite(body_pose[0])
	if sprite == null:
		_draw_placeholder()
		return
	draw_set_transform(Vector2(0.0, -SORT_NUDGE), 0.0, Vector2(-1.0 if body_pose[1] else 1.0, 1.0))
	draw_texture_rect(sprite.texture, sprite.draw_rect(), false)
	_draw_tray_food()
	draw_set_transform(Vector2.ZERO)


## Balão ou carinha do cliente, no filho que fica por cima de tudo.
func _draw_overlay() -> void:
	if not agent is Customer:
		return
	var sprite := ArtSprites.get_sprite(pose()[0])
	var head_top: Vector2
	if sprite != null:
		head_top = Vector2(0.0, -SORT_NUDGE + sprite.draw_rect().position.y)
	else:
		head_top = IsoProjection.grid_point_to_world(agent.position) - position + Vector2(0.0, -56.0)
		if _is_seated():
			head_top.y -= SEAT_LIFT
	_draw_customer_overlay(head_top)


## Visual do personagem: o do garçom ou um dos clientes, fixo pelo número de série.
func _look() -> String:
	var info := ArtSprites.characters()
	if agent is Waiter:
		return info.get("waiter", "")
	var looks: Array = info.get("customers", [])
	return "" if looks.is_empty() else looks[posmod(agent.serial, looks.size())]


## [de costas?, espelhado?] pela última direção de movimento. A arte olha para a
## direita da tela: +x (sudeste) de frente e -y (nordeste) de costas saem como estão.
func _direction() -> Array:
	var facing := agent.facing
	if absf(facing.x) >= absf(facing.y):
		return [false, false] if facing.x >= 0.0 else [true, true]
	return [false, true] if facing.y >= 0.0 else [true, false]


## Prato na bandeja (no espaço já espelhado do corpo).
func _draw_tray_food() -> void:
	var waiter := agent as Waiter
	if waiter == null or waiter.carrying == null:
		return
	var food := ArtSprites.food(waiter.carrying.id)
	var tray: Array = ArtSprites.characters().get("tray_food", [])
	if food == null or tray.size() < 3:
		return
	draw_texture_rect(food.texture, food.rect_at(Vector2(tray[0], tray[1]), tray[2] / ArtSprites.food_width()), false)


## Balão do pedido ou carinha de quem vai embora, acima da cabeça (desenha no filho _overlay).
func _draw_customer_overlay(head_top: Vector2) -> void:
	var customer := agent as Customer
	var tip := head_top + Vector2(0.0, -4.0)
	match customer.state:
		Customer.State.WAITING_TO_ORDER:
			_draw_balloon(tip, null, "?", customer.patience_fraction())
		Customer.State.WAITING_FOR_FOOD:
			_draw_balloon(tip, ArtSprites.food(customer.order.id), customer.order.display_name,
				customer.patience_fraction())
		Customer.State.LEAVING:
			var face := ArtSprites.get_sprite("humor_feliz" if customer.happy else "humor_bravo")
			if face != null:
				_overlay.draw_texture_rect(face.texture, face.rect_at(tip - Vector2(0.0, face.world_size().y / 2.0)), false)


## Balão branco de borda azul, com o prato (ou um texto) e a barra de paciência.
func _draw_balloon(tip: Vector2, food: ArtSprites.Sprite, text: String, patience: float) -> void:
	var font := ThemeDB.fallback_font
	var text_size := 0 if food != null else (QUESTION_SIZE if text == "?" else BALLOON_TEXT_SIZE)
	var inner := Vector2(BALLOON_FOOD, BALLOON_FOOD)
	if food == null and text != "?":
		inner.x = maxf(inner.x, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x)
	var size := inner + Vector2(BALLOON_PAD * 2.0, BALLOON_PAD * 2.0 + BALLOON_BAR + 3.0)
	var box := Rect2(tip - Vector2(size.x / 2.0, size.y + BALLOON_TAIL), size)
	_ensure_styles()
	_overlay.draw_style_box(_balloon_shadow_style, Rect2(box.position + Vector2(1.5, 2.5), box.size))
	_overlay.draw_style_box(_balloon_style, box)
	var base_y := box.end.y - 1.0
	_overlay.draw_colored_polygon(PackedVector2Array([Vector2(tip.x - 5.0, base_y), Vector2(tip.x + 6.0, base_y), tip]),
		BALLOON_FILL)
	_overlay.draw_polyline(PackedVector2Array([Vector2(tip.x - 5.0, base_y + 0.5), tip, Vector2(tip.x + 6.0, base_y + 0.5)]),
		BALLOON_EDGE, 2.0, true)
	var center := box.position + Vector2(size.x / 2.0, BALLOON_PAD + inner.y / 2.0)
	if food != null:
		_overlay.draw_texture_rect(food.texture, food.rect_at(center, BALLOON_FOOD / ArtSprites.food_width()), false)
	else:
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
		_overlay.draw_string(font, center + Vector2(-width / 2.0, text_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			text_size, BALLOON_TEXT)
	var bar := Rect2(box.position.x + 8.0, box.end.y - BALLOON_PAD - BALLOON_BAR + 1.0, size.x - 16.0, BALLOON_BAR)
	_overlay.draw_rect(bar, PATIENCE_TRACK)
	var color := PATIENCE_GOOD if patience > PATIENCE_WORRIED else (PATIENCE_MID if patience > PATIENCE_ANGRY else PATIENCE_BAD)
	_overlay.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(patience, 0.0, 1.0), bar.size.y)), color)


static func _ensure_styles() -> void:
	if _balloon_style != null:
		return
	_balloon_style = StyleBoxFlat.new()
	_balloon_style.bg_color = BALLOON_FILL
	_balloon_style.border_color = BALLOON_EDGE
	_balloon_style.set_border_width_all(2)
	_balloon_style.set_corner_radius_all(11)
	_balloon_style.anti_aliasing = true
	_balloon_shadow_style = StyleBoxFlat.new()
	_balloon_shadow_style.bg_color = BALLOON_SHADOW
	_balloon_shadow_style.set_corner_radius_all(11)


func _is_seated() -> bool:
	return agent is Customer and (agent as Customer).is_seated()


## PLACEHOLDER_CHARACTER: corpo e cabeça em formas simples (para personagem sem arte).
func _draw_placeholder() -> void:
	var feet := IsoProjection.grid_point_to_world(agent.position) - position
	if _is_seated():
		feet.y -= SEAT_LIFT
	else:
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 14.0, SHADOW, true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
	var body_color := WAITER_SHIRT
	if agent is Customer:
		body_color = (agent as Customer).type.placeholder_color
	_draw_rounded(Rect2(feet + Vector2(-10.0, -34.0), Vector2(20.0, 30.0)), body_color, 8.0)
	if agent is Waiter:
		_draw_rounded(Rect2(feet + Vector2(-8.0, -22.0), Vector2(16.0, 18.0)), WAITER_APRON, 4.0)
	var head := feet + Vector2(0.0, -44.0)
	draw_circle(head, 10.0, SKIN, true, -1.0, true)
	draw_arc(head, 10.0, 0.0, TAU, 24, OUTLINE, 1.0, true)
	draw_arc(head + Vector2(0, -1), 10.0, PI * 1.05, PI * 1.95, 12, HAIR, 5.0, true)
	if agent is Waiter and (agent as Waiter).carrying != null:
		var plate := feet + Vector2(12.0, -30.0)
		draw_circle(plate, 8.0, Color.WHITE, true, -1.0, true)
		draw_circle(plate, 5.0, (agent as Waiter).carrying.placeholder_color, true, -1.0, true)


func _draw_rounded(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	style.border_color = OUTLINE
	style.set_border_width_all(1)
	draw_style_box(style, rect)
