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
##
## Movimento na tela (só visual: as regras continuam andando de piso em piso):
## o desenho segue o personagem com suavidade, então as curvas saem redondas e
## sentar ou levantar vira um passinho, sem pulo. Cada passada tem um quique e um
## balanço do corpo; parado ou sentado, o personagem respira de leve. Clientes
## chegam andando da calçada e, ao sair, voltam para ela e somem aos poucos.

## Pequeno desempate para o personagem ficar à frente do móvel do mesmo piso.
const SORT_NUDGE := 1.0
## Balões por cima de todo o salão (móveis e personagens ficam no z 0).
const OVERLAY_Z := 10
## O desenho persegue a posição do personagem com esta rapidez (1/s)...
const SMOOTHING := 10.0
## ...mas nunca mais rápido que isto vezes o passo dele (assim um salto vira caminhada).
const CATCH_UP := 1.6
## Abaixo desta velocidade (pisos/s) o desenho está parado.
const WALKING_SPEED := 0.35
## A esta distância da cadeira (pisos), o cliente já aparece sentado.
const SEAT_REACHED := 0.12
## Passadas por piso andado; cada passada alterna a perna da frente.
const STEPS_PER_CELL := 2.2
## Quadros do ciclo de andar da arte ("passo_0" a "passo_7"): duas passadas, uma de cada perna.
const WALK_FRAMES := 8
## Quanto o corpo sobe quando as pernas se cruzam no meio da passada (pixels de mundo).
## Sem balanço de lado: o corpo vai reto, quem anda são as pernas.
const BOUNCE := 2.0
## Esticar e achatar (cartum, sutil): ao arrancar o corpo estica para cima, ao frear achata.
## Quanto estica por piso/s² de aceleração, o limite e a suavização (por segundo).
const STRETCH_PER_ACCEL := 0.006
const STRETCH_MAX := 0.045
const STRETCH_SMOOTHING := 12.0
## Raio-X: z do filho que mostra a silhueta por cima dos móveis (abaixo dos balões) e a cor dela.
const XRAY_Z := 4
const XRAY_TINT := Color(0.33, 0.56, 1.0, 0.5)
## Respiração de quem está parado ou sentado: quanto estica e quantas vezes por segundo.
const BREATH := 0.012
const BREATH_RATE := 0.45
## Tempo para aparecer e para sumir (segundos).
const FADE_TIME := 0.35
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
## Balão de bebida (DT-052): borda verde, porque quem serve é o jogador, tocando no cliente.
const BALLOON_DRINK_EDGE := Color("26a93a")
## Quanto acima do corpo o toque ainda pega o cliente (o balão do pedido fica ali), em pixels de mundo.
const TAP_REACH_ABOVE := 70.0
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
## Qual cadeira (id do móvel): de costas, o encosto dela vai por cima da pessoa.
var seat_furniture: StringName = &""
## Saindo da cafeteria: o personagem já saiu das regras e o desenho termina a caminhada.
var exiting := false

## Posição desenhada, em pisos (a do personagem, suavizada) e a velocidade dela.
var shown := Vector2.ZERO
var velocity := Vector2.ZERO
var _traveled := 0.0
var _time := 0.0
var _alpha := 0.0
var _started := false
var _exit_target := Vector2.ZERO

## Selo do crítico ao lado da cabeça (DT-061): tamanho e onde fica, em relação ao alto da cabeça.
const CRITIC_BADGE_SIZE := 30.0
const CRITIC_BADGE_OFFSET := Vector2(24.0, 10.0)

static var _balloon_style: StyleBoxFlat
static var _drink_balloon_style: StyleBoxFlat
static var _balloon_shadow_style: StyleBoxFlat

var _overlay := Node2D.new()
## Esticar e achatar atual (positivo estica, negativo achata) e a velocidade do quadro anterior.
var _stretch := 0.0
var _previous_velocity := Vector2.ZERO
## Raio-X: o pai recorta (só desenha os filhos dentro do formato dos móveis que tampam o personagem);
## o filho desenha o corpo como silhueta.
var _xray := Node2D.new()
var _xray_body := Node2D.new()
var _occluders: Array = []


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	modulate.a = 0.0  # aparece aos poucos (advance)
	_overlay.name = "Overlay"
	_overlay.z_index = OVERLAY_Z
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_xray.name = "XRay"
	_xray.z_index = XRAY_Z
	_xray.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_xray.visible = false
	_xray.draw.connect(_draw_xray_mask)
	add_child(_xray)
	_xray_body.name = "XRayBody"
	_xray_body.material = FxMaterials.silhouette(XRAY_TINT)
	_xray_body.draw.connect(_draw_xray_body)
	_xray.add_child(_xray_body)


## Lê o estado do agente. Chamado a cada frame; o desenho anda em advance().
func refresh(target: Agent, new_seat_rotation := -1, new_seat_furniture: StringName = &"") -> void:
	agent = target
	seat_rotation = new_seat_rotation
	seat_furniture = new_seat_furniture
	if not _started:
		_started = true
		shown = agent.position
	_place()
	queue_redraw()
	_overlay.queue_redraw()


## Pausa: o desenho para onde está. Quem ainda estava aparecendo aos poucos aparece inteiro na hora,
## para ninguém ficar invisível durante a pausa (quem está indo embora fica como está).
func set_frozen(value: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
	if value and not exiting:
		_alpha = 1.0
		modulate.a = 1.0


## Cliente novo: o desenho começa em [param point] (na calçada) e vem andando.
func arrive_from(point: Vector2) -> void:
	shown = point
	_place()


## O personagem saiu: o desenho anda até [param point] (na calçada), some aos poucos e se apaga.
func begin_exit(point: Vector2) -> void:
	exiting = true
	_exit_target = point


func _process(delta: float) -> void:
	advance(delta)


## Anda o desenho [param delta] segundos atrás da posição do personagem.
func advance(delta: float) -> void:
	if agent == null or delta <= 0.0:
		return
	_time += delta
	var walk := maxf(agent.speed, 0.5)
	var target := _exit_target if exiting else agent.position
	var to_target := target - shown
	var step: Vector2
	if exiting:
		step = to_target.limit_length(walk * delta)
	else:
		step = to_target * (1.0 - exp(-SMOOTHING * delta))
		step = step.limit_length(walk * CATCH_UP * delta)
	shown += step
	velocity = step / delta
	_traveled += step.length()
	_update_stretch(delta)
	if _xray.visible:
		_xray.queue_redraw()
		_xray_body.queue_redraw()
	if exiting and shown.distance_to(_exit_target) < 0.05:
		_alpha -= delta / FADE_TIME
		if _alpha <= 0.0:
			queue_free()
	else:
		_alpha = minf(1.0, _alpha + delta / FADE_TIME)
	modulate.a = clampf(_alpha, 0.0, 1.0)
	_place()
	queue_redraw()
	_overlay.queue_redraw()


## Sentado: ordena junto com a cadeira (logo à frente dela). Senão, pelos pés desenhados.
func _place() -> void:
	if seated_on_screen():
		position = IsoProjection.cell_top_vertex(agent.cell() + Vector2i.ONE) + Vector2(0, SORT_NUDGE)
	else:
		position = IsoProjection.grid_point_to_world(shown) + Vector2(0, SORT_NUDGE)


## Aparece sentado: está sentado nas regras e o desenho já chegou na cadeira.
func seated_on_screen() -> bool:
	return _is_seated() and not exiting and shown.distance_to(agent.position) <= SEAT_REACHED


## O desenho está andando?
func walking() -> bool:
	return velocity.length() > WALKING_SPEED


## Quanto o corpo está subindo na passada atual (px): no alto quando as pernas se cruzam, embaixo
## quando o pé da frente toca o chão.
func step_motion() -> float:
	if not walking():
		return 0.0
	return sin(fposmod(_traveled * STEPS_PER_CELL * PI, PI)) * BOUNCE


## Nome do sprite do corpo e se ele sai espelhado. Ex.: ["cliente_03_frente_andar", true].
func pose() -> Array:
	var look := _look()
	if seated_on_screen():
		var rotation := seat_rotation if seat_rotation >= 0 else 3
		if rotation == 1 or rotation == 2:
			return ["%s_sentado_costas_r%d" % [look, rotation], false]
		return ["%s_sentado_%s" % [look, expression()], rotation == 0]
	var direction := _direction()
	var sprite_name := "%s_%s_%s" % [look, "costas" if direction[0] else "frente", _frame()]
	if agent is Waiter and (agent as Waiter).carrying != null:
		sprite_name += "_bandeja"
	return [sprite_name, direction[1]]


## Quadro das pernas, pelo quanto o desenho andou: o ciclo de 8 quadros dá duas passadas (uma de
## cada perna), então o pé não escorrega no chão. Parado, em pé.
func _frame() -> String:
	if not walking():
		return "em_pe"
	var cycle := fposmod(_traveled * STEPS_PER_CELL * PI, TAU) / TAU
	return "passo_%d" % (floori(cycle * WALK_FRAMES) % WALK_FRAMES)


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
	var breath := 1.0
	if not walking():
		breath += sin((_time * BREATH_RATE + agent.serial * 0.37) * TAU) * BREATH
	_draw_body(self, sprite, body_pose[1], breath)
	_draw_tray_food()  # na bandeja: segue o corpo (mesma transformação)
	draw_set_transform(Vector2.ZERO)
	var chair_back := backrest()
	if chair_back != null:
		draw_texture_rect(chair_back.texture, chair_back.rect_at(Vector2(0.0, -SORT_NUDGE)), false)


## Corpo com quique, respiração, espelho e esticar/achatar (o mesmo para o desenho e para o raio-X).
func _draw_body(canvas: CanvasItem, sprite: ArtSprites.Sprite, mirrored: bool, breath: float) -> void:
	var squash := 1.0 - _stretch * 0.5
	canvas.draw_set_transform(Vector2(0.0, -SORT_NUDGE - step_motion()), 0.0,
		Vector2((-1.0 if mirrored else 1.0) * squash, breath * (1.0 + _stretch)))
	canvas.draw_texture_rect(sprite.texture, sprite.draw_rect(), false)


## Esticar e achatar pela aceleração do desenho: arrancando estica, freando achata; parado, volta ao normal.
func _update_stretch(delta: float) -> void:
	var speeding_up := velocity.length() >= _previous_velocity.length()
	var acceleration := (velocity - _previous_velocity).length() / delta
	_previous_velocity = velocity
	var target := clampf(acceleration * STRETCH_PER_ACCEL, 0.0, STRETCH_MAX) * (1.0 if speeding_up else -1.0)
	if seated_on_screen():
		target = 0.0
	_stretch = lerpf(_stretch, target, 1.0 - exp(-STRETCH_SMOOTHING * delta))


## Quanto o corpo está esticado agora (positivo estica, negativo achata; 0 = normal).
func stretch() -> float:
	return _stretch


## Retângulo do corpo desenhado, no mundo (vazio se não há arte).
func body_rect() -> Rect2:
	if agent == null:
		return Rect2()
	var sprite := ArtSprites.get_sprite(pose()[0])
	if sprite == null:
		return Rect2()
	var rect := sprite.draw_rect()
	return Rect2(position + rect.position - Vector2(0.0, SORT_NUDGE), rect.size)


## Área de toque do personagem: o corpo e o espaço do balão acima da cabeça.
func tap_rect() -> Rect2:
	var body := body_rect()
	return body.grow_side(SIDE_TOP, TAP_REACH_ABOVE) if body.size != Vector2.ZERO else body


## Móveis que tampam o personagem agora (a silhueta aparece no formato deles).
func set_occluders(views: Array) -> void:
	if views == _occluders:
		return
	_occluders = views
	_xray.visible = not views.is_empty()
	_xray.queue_redraw()
	_xray_body.queue_redraw()


func occluders() -> Array:
	return _occluders


func shows_xray() -> bool:
	return _xray.visible


## Máscara do raio-X: o desenho dos móveis que tampam, na posição deles (o nó em si não aparece).
func _draw_xray_mask() -> void:
	for view: FurnitureView in _occluders:
		if is_instance_valid(view) and view.sprite != null:
			var rect := view.sprite.draw_rect()
			_xray.draw_texture_rect(view.sprite.texture, Rect2(rect.position + view.position - position, rect.size), false)


func _draw_xray_body() -> void:
	if agent == null:
		return
	var body_pose := pose()
	var sprite := ArtSprites.get_sprite(body_pose[0])
	if sprite != null:
		_draw_body(_xray_body, sprite, body_pose[1], 1.0)


## Encosto desenhado por cima de quem senta de costas: o da cadeira em que sentou. A arte só tem
## encosto nas rotações 1 e 2; de frente, em pé ou na banqueta sem encosto, é null.
func backrest() -> ArtSprites.Sprite:
	return ArtSprites.chair_backrest(seat_furniture, seat_rotation) if seated_on_screen() else null


## Balão ou carinha do cliente, no filho que fica por cima de tudo.
func _draw_overlay() -> void:
	if not agent is Customer:
		return
	var sprite := ArtSprites.get_sprite(pose()[0])
	var head_top: Vector2
	if sprite != null:
		head_top = Vector2(0.0, -SORT_NUDGE - step_motion() + sprite.draw_rect().position.y)
	else:
		head_top = IsoProjection.grid_point_to_world(shown) - position + Vector2(0.0, -56.0)
		if seated_on_screen():
			head_top.y -= SEAT_LIFT
	_draw_customer_overlay(head_top)


## Visual do personagem: o do garçom ou um dos clientes, fixo pelo número de série.
func _look() -> String:
	var info := ArtSprites.characters()
	if agent is Waiter:
		return info.get("waiter", "")
	var looks: Array = info.get("customers", [])
	return "" if looks.is_empty() else looks[posmod(agent.serial, looks.size())]


## [de costas?, espelhado?] pela direção em que o desenho anda (parado, a última do
## personagem). A arte olha para a direita da tela: +x (sudeste) de frente e -y
## (nordeste) de costas saem como estão.
func _direction() -> Array:
	var facing := velocity if walking() else agent.facing
	if absf(facing.x) >= absf(facing.y):
		return [false, false] if facing.x >= 0.0 else [true, true]
	return [false, true] if facing.y >= 0.0 else [true, false]


## Onde vai o prato na bandeja: [x, y, largura] a partir dos pés. De costas, a bandeja da arte 3D aparece em outro
## lugar da tela (DT-084); sem essa medida, vale a de frente.
func tray_food() -> Array:
	var info := ArtSprites.characters()
	var front: Array = info.get("tray_food", [])
	return info.get("tray_food_back", front) if _direction()[0] else front


## Prato na bandeja (no espaço já espelhado do corpo).
func _draw_tray_food() -> void:
	var waiter := agent as Waiter
	if waiter == null or waiter.carrying == null:
		return
	var food := ArtSprites.food(waiter.carrying.id)
	var tray := tray_food()
	if food == null or tray.size() < 3:
		return
	draw_texture_rect(food.texture, food.rect_at(Vector2(tray[0], tray[1]), tray[2] / ArtSprites.food_width()), false)


## Balão do pedido ou carinha de quem vai embora, acima da cabeça (desenha no filho _overlay).
func _draw_customer_overlay(head_top: Vector2) -> void:
	var customer := agent as Customer
	var tip := head_top + Vector2(0.0, -4.0)
	if customer.critic:
		_draw_critic_badge(head_top)
	match customer.state:
		Customer.State.WAITING_TO_ORDER:
			_draw_balloon(tip, null, "?", customer.patience_fraction())
		Customer.State.WAITING_FOR_FOOD:
			_draw_balloon(tip, ArtSprites.food(customer.order.id), customer.order.display_name,
				customer.patience_fraction())
		Customer.State.WAITING_FOR_DRINK:
			_draw_balloon(tip, ArtSprites.drink(customer.drink.id), customer.drink.display_name,
				customer.patience_fraction(), true)
		Customer.State.QUEUED:
			# Na fila, o balão só aparece quando a paciência começa a acabar (para a fila não virar um varal de balões).
			if customer.patience_fraction() < PATIENCE_WORRIED:
				_draw_balloon(tip, null, "...", customer.patience_fraction())
		Customer.State.LEAVING, Customer.State.GONE:
			var face := ArtSprites.get_sprite("humor_feliz" if customer.happy else "humor_bravo")
			if face != null:
				_overlay.draw_texture_rect(face.texture, face.rect_at(tip - Vector2(0.0, face.world_size().y / 2.0)), false)


## O selo do crítico (DT-061), ao lado da cabeça, para ele se destacar dos outros clientes.
func _draw_critic_badge(head_top: Vector2) -> void:
	var badge := ArtSprites.get_sprite("icone_critico")
	if badge == null:
		return
	var size := Vector2.ONE * CRITIC_BADGE_SIZE
	_overlay.draw_texture_rect(badge.texture, Rect2(head_top + CRITIC_BADGE_OFFSET - size / 2.0, size), false)


## Balão branco de borda azul, com o prato (ou um texto) e a barra de paciência.
func _draw_balloon(tip: Vector2, food: ArtSprites.Sprite, text: String, patience: float, drink := false) -> void:
	var font := UiTheme.font(UiTheme.BOLD)
	var text_size := 0 if food != null else (QUESTION_SIZE if text == "?" else BALLOON_TEXT_SIZE)
	var inner := Vector2(BALLOON_FOOD, BALLOON_FOOD)
	if food == null and text != "?":
		inner.x = maxf(inner.x, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x)
	var size := inner + Vector2(BALLOON_PAD * 2.0, BALLOON_PAD * 2.0 + BALLOON_BAR + 3.0)
	var box := Rect2(tip - Vector2(size.x / 2.0, size.y + BALLOON_TAIL), size)
	_ensure_styles()
	_overlay.draw_style_box(_balloon_shadow_style, Rect2(box.position + Vector2(1.5, 2.5), box.size))
	_overlay.draw_style_box(_drink_balloon_style if drink else _balloon_style, box)
	var base_y := box.end.y - 1.0
	_overlay.draw_colored_polygon(PackedVector2Array([Vector2(tip.x - 5.0, base_y), Vector2(tip.x + 6.0, base_y), tip]),
		BALLOON_FILL)
	_overlay.draw_polyline(PackedVector2Array([Vector2(tip.x - 5.0, base_y + 0.5), tip, Vector2(tip.x + 6.0, base_y + 0.5)]),
		BALLOON_DRINK_EDGE if drink else BALLOON_EDGE, 2.0, true)
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
	_drink_balloon_style = _balloon_style.duplicate()
	_drink_balloon_style.border_color = BALLOON_DRINK_EDGE
	_drink_balloon_style.set_border_width_all(3)
	_balloon_shadow_style = StyleBoxFlat.new()
	_balloon_shadow_style.bg_color = BALLOON_SHADOW
	_balloon_shadow_style.set_corner_radius_all(11)


func _is_seated() -> bool:
	return agent is Customer and (agent as Customer).is_seated()


## PLACEHOLDER_CHARACTER: corpo e cabeça em formas simples (para personagem sem arte).
func _draw_placeholder() -> void:
	var feet := IsoProjection.grid_point_to_world(shown) - position
	if seated_on_screen():
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
