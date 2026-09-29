class_name CafeCamera
extends Camera2D
## Câmera da cafeteria.
##
## Mouse: arrastar com o botão esquerdo move; roda do mouse dá zoom.
## Toque: arrastar com um dedo move; pinça com dois dedos dá zoom.
## Um clique/toque curto, sem arrastar, vira um "tap" (usado para seleção).

## Emitido num clique/toque curto, com a posição no mundo onde ele aconteceu.
signal tapped(world_position: Vector2)
## Emitido quando o mouse se move sem botão pressionado (não existe em toque).
signal hovered(world_position: Vector2)

@export var min_zoom := 0.5
@export var max_zoom := 2.0
## Multiplicador de zoom por "clique" da roda do mouse.
@export var wheel_zoom_step := 1.1
## Distância, em pixels de tela, a partir da qual um toque vira arrasto e deixa de ser tap.
@export var drag_threshold := 12.0

var _bounds := Rect2()

# Estado do gesto de um ponteiro (mouse ou um dedo).
var _press_active := false
var _dragging := false
var _press_origin := Vector2.ZERO
var _last_pointer := Vector2.ZERO

# Estado do toque multi-dedo.
var _touches: Dictionary = {}  # índice do dedo -> posição na tela
var _pinch_start_distance := 0.0
var _pinch_start_zoom := 1.0
var _pinch_last_center := Vector2.ZERO


## Área do mundo onde o centro da câmera pode ficar.
func set_bounds(rect: Rect2) -> void:
	_bounds = rect
	_clamp_position()


## Enquadra [param rect] na área da tela livre de interface: entre
## [param top_inset] e [param bottom_inset] pixels das bordas. Nunca aproxima
## além do zoom 1 (numa tela grande a cafeteria não fica gigante).
func frame(rect: Rect2, top_inset: float, bottom_inset: float) -> void:
	var viewport_size := get_viewport_rect().size
	var available := Vector2(viewport_size.x, maxf(viewport_size.y - top_inset - bottom_inset, 1.0))
	var fit := minf(available.x / rect.size.x, available.y / rect.size.y)
	var z := clampf(minf(fit, 1.0), min_zoom, max_zoom)
	zoom = Vector2(z, z)
	# O centro da área livre fica deslocado do centro da tela quando as faixas têm alturas diferentes.
	global_position = rect.get_center() - Vector2(0.0, (top_inset - bottom_inset) / 2.0) / z
	_clamp_position()


func screen_to_world(screen_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	return global_position + (screen_position - viewport_size / 2.0) / zoom


## Aplica zoom mantendo fixo o ponto do mundo que está sob [param screen_position].
func zoom_at(screen_position: Vector2, target_zoom: float) -> void:
	var anchor := screen_to_world(screen_position)
	var z := clampf(target_zoom, min_zoom, max_zoom)
	zoom = Vector2(z, z)
	var viewport_size := get_viewport_rect().size
	global_position = anchor - (screen_position - viewport_size / 2.0) / zoom
	_clamp_position()


## Move a câmera como se o conteúdo fosse arrastado [param screen_delta] pixels.
func pan_by_screen(screen_delta: Vector2) -> void:
	global_position -= screen_delta / zoom
	_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _press_active:
			_move_press(event.position)
		else:
			hovered.emit(screen_to_world(event.position))
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event)
	elif event is InputEventMagnifyGesture:
		zoom_at(event.position, zoom.x * event.factor)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				zoom_at(event.position, zoom.x * wheel_zoom_step)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				zoom_at(event.position, zoom.x / wheel_zoom_step)
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_press(event.position)
			else:
				_end_press(event.position)


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_begin_press(event.position)
		elif _touches.size() == 2:
			_begin_pinch()
		return

	_touches.erase(event.index)
	if _touches.is_empty():
		_end_press(event.position)
	elif _touches.size() == 1:
		# A pinça terminou e sobrou um dedo: ele continua movendo a câmera,
		# mas ao ser solto não deve contar como tap.
		_press_active = true
		_dragging = true
		_last_pointer = _touches.values()[0]


func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	_touches[event.index] = event.position
	if _touches.size() >= 2:
		_update_pinch()
	elif _press_active:
		_move_press(event.position)


func _begin_press(screen_position: Vector2) -> void:
	_press_active = true
	_dragging = false
	_press_origin = screen_position
	_last_pointer = screen_position


func _move_press(screen_position: Vector2) -> void:
	if not _dragging:
		if screen_position.distance_to(_press_origin) <= drag_threshold:
			return
		_dragging = true
		_last_pointer = _press_origin
	pan_by_screen(screen_position - _last_pointer)
	_last_pointer = screen_position


func _end_press(screen_position: Vector2) -> void:
	var was_tap := _press_active and not _dragging
	_press_active = false
	_dragging = false
	if was_tap:
		tapped.emit(screen_to_world(screen_position))


func _begin_pinch() -> void:
	# Um segundo dedo cancela o tap em andamento.
	_press_active = false
	_dragging = false
	var points := _first_two_touches()
	_pinch_start_distance = points[0].distance_to(points[1])
	_pinch_start_zoom = zoom.x
	_pinch_last_center = (points[0] + points[1]) / 2.0


func _update_pinch() -> void:
	var points := _first_two_touches()
	var center := (points[0] + points[1]) / 2.0
	if _pinch_start_distance > 0.0:
		var distance := points[0].distance_to(points[1])
		zoom_at(center, _pinch_start_zoom * distance / _pinch_start_distance)
	pan_by_screen(center - _pinch_last_center)
	_pinch_last_center = center


func _first_two_touches() -> Array[Vector2]:
	var keys := _touches.keys()
	keys.sort()
	var points: Array[Vector2] = [_touches[keys[0]], _touches[keys[1]]]
	return points


func _clamp_position() -> void:
	if _bounds.has_area():
		global_position = global_position.clamp(_bounds.position, _bounds.end)
