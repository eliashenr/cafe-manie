class_name AgentView
extends Node2D
## PLACEHOLDER_CHARACTER: personagem desenhado com formas simples até
## existir arte final. Mostra cliente ou garçom, o balão do pedido com a
## barra de paciência e o prato que o garçom carrega.
##
## O nó fica nos pés do personagem, para o y-sort da camada do mundo
## desenhar na ordem de profundidade certa.

const SKIN := Color("e8b894")
const HAIR := Color("4a3222")
const OUTLINE := Color(0.1, 0.06, 0.04, 0.6)
const SHADOW := Color(0, 0, 0, 0.18)
const WAITER_SHIRT := Color("f4f1ea")
const WAITER_APRON := Color("2f3a4a")
const BUBBLE_BG := Color(1, 1, 1, 0.95)
const BUBBLE_TEXT := Color(0.12, 0.08, 0.05)
const ANGRY := Color("d9453b")
const PATIENCE_OK := Color("4caf50")
const PATIENCE_LOW := Color("e53935")
const BUBBLE_SIZE := 12
## Quanto o personagem sobe quando está sentado (altura do assento).
const SEAT_LIFT := 14.0
## Pequeno desempate para o personagem ficar à frente do móvel do mesmo piso.
const SORT_NUDGE := 1.0

var agent: Agent


## Lê o estado do agente e se reposiciona. Chamado a cada frame.
func refresh(target: Agent) -> void:
	agent = target
	var feet := IsoProjection.grid_point_to_world(agent.position)
	if _is_seated():
		# Sentado: ordena junto com a cadeira (logo à frente dela) e sobe na altura do assento.
		position = IsoProjection.cell_top_vertex(agent.cell() + Vector2i.ONE) + Vector2(0, SORT_NUDGE)
	else:
		position = feet + Vector2(0, SORT_NUDGE)
	queue_redraw()


func _draw() -> void:
	if agent == null:
		return
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
	var body := Rect2(feet + Vector2(-10.0, -34.0), Vector2(20.0, 30.0))
	_draw_rounded(body, body_color, 8.0)
	if agent is Waiter:
		_draw_rounded(Rect2(feet + Vector2(-8.0, -22.0), Vector2(16.0, 18.0)), WAITER_APRON, 4.0)
	var head := feet + Vector2(0.0, -44.0)
	draw_circle(head, 10.0, SKIN, true, -1.0, true)
	draw_arc(head, 10.0, 0.0, TAU, 24, OUTLINE, 1.0, true)
	draw_arc(head + Vector2(0, -1), 10.0, PI * 1.05, PI * 1.95, 12, HAIR, 5.0, true)

	if agent is Waiter:
		_draw_waiter_extras(feet)
	elif agent is Customer:
		_draw_customer_bubble(feet + Vector2(0.0, -62.0))


func _draw_waiter_extras(feet: Vector2) -> void:
	var waiter := agent as Waiter
	if waiter.carrying != null:
		var plate := feet + Vector2(12.0, -30.0)
		draw_circle(plate, 8.0, Color.WHITE, true, -1.0, true)
		draw_circle(plate, 5.0, waiter.carrying.placeholder_color, true, -1.0, true)


func _draw_customer_bubble(anchor: Vector2) -> void:
	var customer := agent as Customer
	match customer.state:
		Customer.State.WAITING_TO_ORDER:
			_draw_bubble(anchor, "?", customer.patience_fraction(), false)
		Customer.State.WAITING_FOR_FOOD:
			_draw_bubble(anchor, customer.order.display_name, customer.patience_fraction(), false)
		Customer.State.EATING:
			var plate := anchor + Vector2(0.0, 30.0)
			draw_circle(plate, 7.0, Color.WHITE, true, -1.0, true)
			draw_circle(plate, 4.5, customer.order.placeholder_color, true, -1.0, true)
		Customer.State.LEAVING:
			if not customer.happy:
				_draw_bubble(anchor, "Demorou!", -1.0, true)


## Balão com texto e barra de paciência (verde → vermelho).
func _draw_bubble(anchor: Vector2, text: String, patience: float, angry: bool) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_SIZE).x + 14.0
	var height := 20.0 + (6.0 if patience >= 0.0 else 0.0)
	var box := Rect2(anchor - Vector2(width / 2.0, height), Vector2(width, height))
	_draw_rounded(box, ANGRY if angry else BUBBLE_BG, 7.0)
	draw_colored_polygon(PackedVector2Array([
		anchor + Vector2(-5, 0), anchor + Vector2(5, 0), anchor + Vector2(0, 6)]), ANGRY if angry else BUBBLE_BG)
	draw_string(font, box.position + Vector2(7.0, 15.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, BUBBLE_SIZE,
		Color.WHITE if angry else BUBBLE_TEXT)
	if patience >= 0.0:
		var bar := Rect2(box.position + Vector2(6.0, height - 7.0), Vector2(width - 12.0, 3.0))
		draw_rect(bar, Color(0, 0, 0, 0.15))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * patience, bar.size.y)), PATIENCE_LOW.lerp(PATIENCE_OK, patience))


func _is_seated() -> bool:
	return agent is Customer and (agent as Customer).is_seated()


func _draw_rounded(rect: Rect2, color: Color, radius: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	style.border_color = OUTLINE
	style.set_border_width_all(1)
	draw_style_box(style, rect)
