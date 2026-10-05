extends SceneTree
## Foto de uma coleção da loja montada num salão, para conferência visual (precisa de janela: não use --headless).
##
## Uso (na pasta do projeto):
##   godot -s res://tools/collection_showcase.gd -- <saida.png> <id da coleção> [zoom]
##
## Põe o piso e a parede da coleção, uma mesa com as quatro cadeiras viradas para ela (gente sentada
## em todas, para ver o encosto de quem senta de costas), uma segunda mesa e todos os enfeites.
## Relógio parado; não lê nem grava save.

var _cafe: Node
var _output := ""
var _zoom := 1.25
var _frames := 20


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_output = args[0] if args.size() > 0 else "user://colecao.png"
	var collection := StringName(args[1]) if args.size() > 1 else &"classico"
	if args.size() > 2:
		_zoom = float(args[2])
	var clock = load("res://core/time/manual_clock.gd").new()
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var layout = load("res://core/cafe/cafe_layout.gd").new(Vector2i(8, 8), Vector2i(7, 4))
	var simulation = load("res://core/service/cafe_simulation.gd").with_game_data(clock, layout, catalog, 7)
	simulation.customer_types.clear()
	simulation.cafe_name = "Coleção"
	for surface in simulation.surfaces.all():
		if surface.collection == collection:
			simulation.style.own(surface.id)
			simulation.style.apply(surface)
	var by_category := {}
	for definition in catalog.all():
		if definition.collection == collection:
			by_category.get_or_add(definition.category, []).append(definition)
	var chairs: Array = by_category.get(FurnitureDefinition.Category.SEATING, [])
	var tables: Array = by_category.get(FurnitureDefinition.Category.TABLE, [])
	var decor: Array = by_category.get(FurnitureDefinition.Category.DECOR, [])
	if chairs.is_empty() or tables.is_empty():
		printerr("Coleção sem cadeira ou mesa: ", collection)
		quit(1)
		return
	layout.place(catalog.get_definition(&"stove_basic"), Vector2i(0, 0), 3)
	# Duas mesas (uma mesa cercada pelas quatro cadeiras fica sem acesso para o garçom). Cada cadeira
	# virada para a sua mesa, cobrindo as quatro rotações: 0 = +y, 1 = -x, 2 = -y, 3 = +x.
	layout.place(tables[0], Vector2i(3, 2), 0)
	layout.place(tables[0], Vector2i(3, 5), 0)
	var seats := [layout.place(chairs[0], Vector2i(3, 1), 0), layout.place(chairs[0], Vector2i(4, 2), 1),
		layout.place(chairs[0], Vector2i(3, 6), 2), layout.place(chairs[0], Vector2i(2, 2), 3)]
	layout.place(chairs[0], Vector2i(4, 5), 1)
	var cells := [Vector2i(0, 6), Vector2i(1, 6), Vector2i(6, 1), Vector2i(6, 6), Vector2i(0, 3), Vector2i(5, 0)]
	for i in decor.size():
		layout.place(decor[i], cells[i % cells.size()], 0)
	var regular = load("res://data/customers/regular.tres")
	var recipes = simulation.recipes
	for i in seats.size():
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = 10 + i
		customer.type = regular
		customer.seat_id = seats[i]
		customer.seat_cell = layout.get_placement(seats[i]).origin
		customer.position = Vector2(customer.seat_cell)
		customer.state = 3 if i % 2 == 0 else 2  # comendo / esperando o prato
		customer.patience_total = 100.0
		customer.patience_left = 100.0
		customer.eat_left = 1000.0
		customer.order = recipes.get_definition(&"coffee")
		simulation.customers.append(customer)
	simulation.wallet.earn(&"soft_currency", 480, "vitrine")
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = simulation
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


func _process(_delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("A foto da coleção não montou a cena.")
		quit(1)
		return true
	for window: Window in _cafe.find_children("*", "Window", true, false):
		window.hide()
	var camera := _cafe.get_viewport().get_camera_2d()
	camera.zoom = Vector2(_zoom, _zoom)
	camera.global_position = IsoProjection.grid_point_to_world(Vector2(3.5, 3.5))
	_frames -= 1
	if _frames > 0:
		return false
	root.get_texture().get_image().save_png(_output)
	print("Foto em ", _output)
	return true
