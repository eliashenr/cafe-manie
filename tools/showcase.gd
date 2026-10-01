extends SceneTree
## Vitrine dos personagens para conferência visual (precisa de janela: não use --headless).
##
## Uso (na pasta do projeto):
##   godot -s res://tools/showcase.gd -- <saida.png> [zoom] [id do piso] [id da parede]
##
## Monta uma cafeteria com o relógio parado e gente em cada situação: comendo
## (prato na mesa), esperando o pedido, pedindo, andando nas quatro direções,
## indo embora feliz e bravo, e o garçom com a bandeja. Não lê nem grava save.

var _cafe: Node
var _output := ""
var _zoom := 1.0
var _frames := 20


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_output = args[0] if args.size() > 0 else "user://vitrine.png"
	if args.size() > 1:
		_zoom = float(args[1])
	var clock = load("res://core/time/manual_clock.gd").new()
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var layout = load("res://core/cafe/cafe_layout.gd").new(Vector2i(8, 8), Vector2i(7, 4))
	var simulation = load("res://core/service/cafe_simulation.gd").with_game_data(clock, layout, catalog, 7)
	simulation.customer_types.clear()  # ninguém chega sozinho: a vitrine fica parada
	simulation.cafe_name = "Vitrine"
	for surface_id in args.slice(2, 4):
		var surface = simulation.surfaces.get_definition(StringName(surface_id))
		if surface != null:
			simulation.style.own(surface.id)
			simulation.style.apply(surface)
	var place := func(id: StringName, cell: Vector2i, rotation := 0) -> StringName:
		return layout.place(catalog.get_definition(id), cell, rotation)
	place.call(&"stove_basic", Vector2i(0, 0), 3)
	place.call(&"counter_basic", Vector2i(0, 2), 3)
	place.call(&"plant_pot", Vector2i(0, 6))
	place.call(&"table_round", Vector2i(3, 2))
	var left_chair: StringName = place.call(&"chair_wood", Vector2i(2, 2), 3)
	var right_chair: StringName = place.call(&"chair_wood", Vector2i(4, 2), 1)
	place.call(&"table_long", Vector2i(3, 5))
	var back_chair: StringName = place.call(&"chair_wood", Vector2i(3, 4), 0)
	var front_chair: StringName = place.call(&"chair_wood", Vector2i(4, 6), 2)

	var recipes = simulation.recipes
	var regular = load("res://data/customers/regular.tres")
	var serial := [10]
	var seat := func(chair: StringName, state: int, recipe: StringName, patience: float):
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = serial[0]
		serial[0] += 1
		customer.type = regular
		customer.seat_id = chair
		customer.seat_cell = layout.get_placement(chair).origin
		customer.position = Vector2(customer.seat_cell)
		customer.state = state
		customer.patience_total = 100.0
		customer.patience_left = 100.0 * patience
		customer.eat_left = 1000.0
		if recipe != &"":
			customer.order = recipes.get_definition(recipe)
		simulation.customers.append(customer)
		return customer
	seat.call(left_chair, 3, &"coxinha", 1.0)    # comendo, de frente
	seat.call(right_chair, 2, &"lasagna", 0.4)   # esperando o prato, de costas, preocupada
	seat.call(back_chair, 1, &"", 0.9)           # esperando para pedir, de costas
	seat.call(front_chair, 3, &"coffee", 1.0)    # comendo, de costas
	var walker := func(cell: Vector2, facing: Vector2, state: int, happy := true):
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = serial[0]
		serial[0] += 1
		customer.type = regular
		customer.position = cell
		customer.facing = facing
		customer.state = state
		customer.happy = happy
		customer.speed = 0.0  # anda parado: só para a pose de andar aparecer
		customer.path.append(Vector2i(cell + facing))
		simulation.customers.append(customer)
	walker.call(Vector2(6.25, 1.0), Vector2(-1, 0), 0)          # chegando, de costas
	walker.call(Vector2(6.0, 3.0), Vector2(0, 1), 0)            # chegando, de frente
	walker.call(Vector2(5.5, 7.0), Vector2(1, 0), 4, true)      # indo embora feliz
	walker.call(Vector2(1.0, 4.5), Vector2(0, -1), 4, false)    # indo embora bravo
	var waiter = simulation.waiters[0]
	waiter.position = Vector2(2.0, 6.0)
	waiter.facing = Vector2(1, 0)
	waiter.carrying = recipes.get_definition(&"carrot_cake")
	waiter.speed = 0.0
	waiter.path.append(Vector2i(3, 6))

	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = simulation
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


func _process(_delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("A vitrine não montou a cena.")
		quit(1)
		return true
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	_cafe.get_viewport().get_camera_2d().zoom = Vector2(_zoom, _zoom)
	_frames -= 1
	if _frames > 0:
		return false
	root.get_texture().get_image().save_png(_output)
	print("Foto em ", _output)
	return true
