extends SceneTree
## Amostra visual da direção A: o mesmo café, na mesma câmera, com itens que já existem na loja, para comparar antes e
## depois ou revisar no jogo (precisa de janela: não use --headless; passe --resolution 1280x720).
##
## Uso (na pasta do projeto):
##   godot --resolution 1280x720 -s res://tools/art_sample.gd -- <saida.png> <variante> [dia|noite] [fixa|revisao]
##
## Variantes: inicial (jogo novo), madeira_tijolo, nostalgica, mistura (estilos diferentes no mesmo café) e reformado (o
## café depois de o jogador comprar os itens da amostra: mostra para onde a evolução leva).
## "fixa" trava a câmera num enquadramento que não depende da versão do jogo: é o que permite comparar a arte de duas
## versões. Sem ela, vale o enquadramento do próprio jogo.
## "revisao" deixa o jogo aberto e rodando, com clientes chegando, para o PO mexer. A tecla N troca entre dia e noite.
## Não grava foto nem fecha sozinho.
##
## Monta tudo em memória, sem ler nem gravar save, com o relógio num dia fora de evento.

## Dia fixo sem evento (Halloween é de 20/10 a 3/11), para o HUD não mudar entre as fotos.
const DAY := "2026-06-15T14:00:00"
const NIGHT := "2026-06-15T23:00:00"
const FIXED_ZOOM := 0.75
## Quanto o centro da câmera fixa fica acima do centro do chão: mostra o alto das paredes.
const FIXED_LIFT := 60.0
const HALF_DAY := 43200.0
## Quantos quadros o modo de revisão esconde as janelas de abertura (presente do dia, nome do café).
const REVIEW_HIDE_FRAMES := 30

var _cafe: Node
var _clock
var _output := ""
var _fixed_camera := false
var _review := false
var _frames := 20


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_output = args[0] if args.size() > 0 else "user://amostra.png"
	var variant: String = args[1] if args.size() > 1 else "inicial"
	var night := args.size() > 2 and args[2] == "noite"
	_fixed_camera = args.size() > 3 and args[3] == "fixa"
	_review = args.size() > 3 and args[3] == "revisao"
	if _review:
		_frames = REVIEW_HIDE_FRAMES
		root.title = "Amostra A: %s (tecla N: dia/noite)" % variant
		root.window_input.connect(_on_review_input)
	_clock = load("res://core/time/manual_clock.gd").new()
	_clock.time = Time.get_unix_time_from_datetime_string(NIGHT if night else DAY) - _clock.utc_offset_seconds()
	var simulation = load("res://core/service/cafe_simulation.gd").create_new_game(_clock, 7)
	simulation.set_cafe_name("Café Manie")
	if _review:
		simulation.wallet.earn(&"soft_currency", 2000, "revisão da amostra")
	else:
		simulation.customer_types.clear()  # ninguém chega sozinho: a foto fica parada
	_dress(simulation, variant)
	_populate(simulation)
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = simulation
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


## Só usa o que já existe na loja; a posse fica nesta simulação em memória.
func _dress(simulation, variant: String) -> void:
	var layout = simulation.layout
	var catalog = load("res://core/furniture/furniture_catalog.gd").load_from()
	var style = simulation.style
	var wear := func(surface_id: StringName) -> void:
		var surface = simulation.surfaces.get_definition(surface_id)
		style.own(surface.id)
		style.apply(surface)
	var place := func(id: StringName, cell: Vector2i, rotation := 0) -> void:
		if layout.place(catalog.get_definition(id), cell, rotation) == &"":
			printerr("Não coube na amostra: ", id, " em ", cell)
	match variant:
		"madeira_tijolo":
			wear.call(&"floor_wood")
			wear.call(&"wall_brick")
		"nostalgica":
			wear.call(&"floor_bistro")
			wear.call(&"wall_mint_stripes")
		"mistura":
			wear.call(&"floor_wood")
			wear.call(&"wall_cream")
			var kitchen: Array[Vector2i] = []
			for x in 8:
				for y in 3:
					kitchen.append(Vector2i(x, y))
			style.own(&"floor_bistro")
			style.paint_floor(kitchen, &"floor_bistro")
			var brick: Array[String] = []
			for i in 8:
				brick.append(style.segment(style.EDGE_TOP, i))
			style.own(&"wall_brick")
			style.paint_walls(brick, &"wall_brick")
			place.call(&"stove_mint", Vector2i(2, 0))
			place.call(&"counter_steel", Vector2i(4, 0))
			place.call(&"table_country_round", Vector2i(5, 6))
			place.call(&"chair_french_red", Vector2i(4, 6), 3)
			place.call(&"chair_tulip", Vector2i(6, 6), 1)
		"reformado":
			wear.call(&"floor_wood")
			# Tijolo na parede da cozinha e reboco na do salão, como na referência.
			var kitchen_wall: Array[String] = []
			for i in 8:
				kitchen_wall.append(style.segment(style.EDGE_TOP, i))
			style.own(&"wall_brick")
			style.paint_walls(kitchen_wall, &"wall_brick")
			for spot in [["top:1", &"arandela"], ["top:6", &"arandela"], ["left:0", &"arandela"], ["left:3", &"arandela"], ["left:6", &"arandela"]]:
				style.own(spot[1])
				style.hang([spot[0]] as Array[String], spot[1])
			place.call(&"counter_basic", Vector2i(4, 0))
			place.call(&"counter_basic", Vector2i(6, 0))
			place.call(&"table_round", Vector2i(5, 6))
			place.call(&"chair_wood", Vector2i(4, 6), 3)
			place.call(&"chair_wood", Vector2i(6, 6), 1)
			place.call(&"plant_pot", Vector2i(7, 7))


## Cozinha trabalhando, dois clientes (um comendo, outro esperando) e o garçom com o prato: conferem a legibilidade.
func _populate(simulation) -> void:
	var layout = simulation.layout
	var clock = simulation.clock
	var recipes = simulation.recipes
	var lasagna = recipes.get_definition(&"lasagna")
	var coffee = recipes.get_definition(&"coffee")
	simulation.kitchen.restore_stove(layout.placement_at(Vector2i(0, 0)).id, lasagna, clock.now() - lasagna.cook_time * 0.6)
	simulation.kitchen.restore_stove(layout.placement_at(Vector2i(1, 0)).id, coffee, clock.now() - coffee.cook_time - 1.0)
	simulation.kitchen.restore_counter(layout.placement_at(Vector2i(3, 0)).id, recipes.get_definition(&"coxinha"), 9)
	var regular = load("res://data/customers/regular.tres")
	var seat := func(cell: Vector2i, serial: int, state: int, recipe: StringName, patience: float) -> void:
		var customer = load("res://core/service/customer.gd").new()
		customer.serial = serial
		customer.type = regular
		customer.seat_id = layout.placement_at(cell).id
		customer.seat_cell = cell
		customer.position = Vector2(cell)
		customer.state = state
		customer.patience_total = 100.0
		customer.patience_left = 100.0 * patience
		customer.eat_left = 1000.0
		customer.order = recipes.get_definition(recipe)
		simulation.customers.append(customer)
	seat.call(Vector2i(3, 4), 10, 3, &"coxinha", 1.0)  # comendo
	seat.call(Vector2i(5, 4), 11, 2, &"lasagna", 0.6)  # esperando o prato
	seat.call(Vector2i(1, 6), 12, 2, &"coffee", 0.3)   # esperando, já preocupado
	if _review:
		return
	var waiter = simulation.waiters[0]
	waiter.position = Vector2(4.0, 2.0)
	waiter.facing = Vector2(0, 1)
	waiter.carrying = recipes.get_definition(&"carrot_cake")
	waiter.speed = 0.0
	waiter.path.append(Vector2i(4, 3))


func _process(delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("A amostra não montou a cena.")
		quit(1)
		return true
	if _frames > 0:
		for window: Window in _cafe.find_children("*", "Window", true, false):
			window.hide()
	if _review:
		_frames -= 1
		_clock.time += delta  # o relógio anda de verdade
		return false
	if _fixed_camera:
		var camera := _cafe.get_viewport().get_camera_2d()
		camera.zoom = Vector2(FIXED_ZOOM, FIXED_ZOOM)
		camera.global_position = IsoProjection.grid_bounds(Vector2i(8, 8)).get_center() - Vector2(0.0, FIXED_LIFT)
	_frames -= 1
	if _frames > 0:
		return false
	root.get_texture().get_image().save_png(_output)
	print("Foto em ", _output)
	return true


## Tecla N: pula meio dia, para ver o café de dia e à noite.
func _on_review_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_N:
		_clock.time += HALF_DAY
