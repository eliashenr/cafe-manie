class_name CafeTestCase
extends TestCase
## Base dos testes de integração da cena da cafeteria: sobe a cena e
## simula mouse, toque e teclado.
##
## As entradas vão com push_input(evento, true): a janela headless mede
## 64x64 e, sem o "true", as posições seriam reescaladas.

const CafeScene := preload("res://scenes/cafe/cafe.tscn")


func spawn_cafe() -> Cafe:
	var cafe: Cafe = add_to_tree(CafeScene.instantiate())
	await tree.process_frame
	return cafe


## Posição na tela do centro de uma célula, com a câmera atual.
func screen_of_cell(cafe: Cafe, cell: Vector2i) -> Vector2:
	var viewport_size := cafe.camera.get_viewport_rect().size
	return (IsoProjection.cell_center(cell) - cafe.camera.global_position) * cafe.camera.zoom + viewport_size / 2.0


func send(event: InputEvent) -> void:
	tree.root.push_input(event, true)


func click(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		send(event)


func click_cell(cafe: Cafe, cell: Vector2i) -> void:
	click(screen_of_cell(cafe, cell))


func hover(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	send(event)


func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	send(event)


func tap_cell(cafe: Cafe, cell: Vector2i) -> void:
	var position := screen_of_cell(cafe, cell)
	touch(0, position, true)
	touch(0, position, false)


func touch_drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	send(event)


func press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	send(event)


## Espera a barra de construção se reconstruir (ela reconstrói no fim do frame).
func settle() -> void:
	await tree.process_frame
