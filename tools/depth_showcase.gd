extends SceneTree
## Foto da ordem de desenho e de quem senta, para conferência visual (precisa de janela: não use --headless).
##
## Uso (na pasta do projeto):
##   godot -s res://tools/depth_showcase.gd -- <saida.png> [zoom] [foco x,y]
##
## Monta uma cafeteria parada com: o garçom na frente de um balcão,
## um vaso na frente de outro balcão, alguém atrás da estante (raio-X) e quatro clientes sentados
## em duas mesas, nas quatro direções, em banqueta e em cadeiras. Não lê nem grava save.

var _cafe: Node
var _output := ""
var _zoom := 1.6
var _frames := 20
var _focus := Vector2(3.0, 2.5)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_output = args[0] if args.size() > 0 else "user://profundidade.png"
	if args.size() > 1:
		_zoom = float(args[1])
	if args.size() > 2 and args[2].contains(","):
		_focus = Vector2(float(args[2].get_slice(",", 0)), float(args[2].get_slice(",", 1)))
	var clock = load("res://core/time/manual_clock.gd").new()
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var layout = load("res://core/cafe/cafe_layout.gd").new(Vector2i(8, 8), Vector2i(7, 4))
	var simulation = load("res://core/service/cafe_simulation.gd").with_game_data(clock, layout, catalog, 7)
	simulation.customer_types.clear()
	simulation.cafe_name = "Profundidade"
	var place := func(id: StringName, cell: Vector2i, rotation := 0) -> StringName:
		var placed: StringName = layout.place(catalog.get_definition(id), cell, rotation)
		if placed == &"":
			printerr("Não coube: %s em %s (%s)" % [id, cell, CafeLayout.Check.keys()[layout.check_placement(catalog.get_definition(id), cell, rotation)]])
		return placed
	place.call(&"stove_basic", Vector2i(0, 0))
	place.call(&"counter_basic", Vector2i(2, 0))
	place.call(&"counter_steel", Vector2i(4, 0))
	place.call(&"plant_pot", Vector2i(4, 1))
	place.call(&"bookshelf", Vector2i(0, 3), 3)
	place.call(&"table_round", Vector2i(4, 4))
	place.call(&"table_round", Vector2i(5, 6))
	var chairs := {
		&"stool_club": [Vector2i(3, 4), 3],
		&"chair_country": [Vector2i(4, 3), 0],
		&"chair_party": [Vector2i(5, 4), 1],
		&"chair_wood": [Vector2i(4, 6), 3],
		&"chair_tulip": [Vector2i(5, 7), 2],
	}
	var regular = load("res://data/customers/regular.tres")
	var serial := 20
	for chair_id: StringName in chairs:
		var spot: Array = chairs[chair_id]
		var chair: StringName = place.call(chair_id, spot[0], spot[1])
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = serial
		serial += 1
		customer.type = regular
		customer.seat_id = chair
		customer.seat_cell = spot[0]
		customer.position = Vector2(spot[0])
		customer.state = 3  # comendo
		customer.eat_left = 1000.0
		customer.order = simulation.recipes.get_definition(&"coffee")
		simulation.customers.append(customer)
	var behind = load("res://core/service/customer.gd").new()
	behind.serial = serial
	behind.type = regular
	behind.position = Vector2(-0.35, 3.4)
	behind.state = 4  # indo embora (em pé, parado)
	behind.speed = 0.0
	simulation.customers.append(behind)
	var waiter = simulation.waiters[0]
	waiter.position = Vector2(2.0, 1.05)
	waiter.facing = Vector2(1, 0)
	waiter.speed = 0.0
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = simulation
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


func _process(_delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("A foto não montou a cena.")
		quit(1)
		return true
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	var camera := _cafe.get_viewport().get_camera_2d()
	camera.zoom = Vector2(_zoom, _zoom)
	camera.global_position = IsoProjection.grid_point_to_world(_focus)
	_frames -= 1
	if _frames > 0:
		return false
	root.get_texture().get_image().save_png(_output)
	print("Foto em ", _output)
	return true
