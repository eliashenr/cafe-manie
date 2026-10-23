extends SceneTree
## Vitrine dos personagens para conferência visual (precisa de janela: não use --headless).
##
## Uso (na pasta do projeto):
##   godot -s res://tools/showcase.gd -- <saida.png> [zoom] [id do piso] [id da parede] [foco x,y] [painel]
##
## O foco é a célula que fica no meio da foto (ex.: 1,1 para a cozinha).
## O painel de baixo pode começar em: loja, loja:FLOOR (ou outra aba), fogao, construir, reforma,
## reforma:<revestimento>, moedas (a vitrine de Café Ouro), missoes (a janela das missões), pausa (o jogo pausado) ou
## fechado (a placa FECHADO na porta), estragado (o café esquecido no fogão estragou, com o Jogar fora),
## temperos (a lasanha cozinhando com os temperos no painel), trofeu (um troféu de ouro entre os fogões, escolhido),
## trem (o Multifogão Trem completo, com a locomotiva escolhida), critico (o crítico sentado, a estrela numa mesa e os
## cupons), evento (a janela do Halloween na historinha; evento:missoes nas missões), noite (o café às 23h, com as
## luminárias acesas e o Fogão Lua Cheia), pomar (os pés de fruta maduros e a máquina de frozen), diversao (atrações
## com ouro e o show no palco), bebidas (as duas máquinas, um cliente pedindo bebida e a energia) ou
## livro:<aba>[:<página>[:<nível>]] (o livro de receitas aberto no fogão, no nível 13 se não disser outro, com estrelas de domínio)
## ou japones (o livro na aba Japão, aberto no Fogão Japonês, no nível 30).
##
## Monta uma cafeteria com o relógio parado e gente em cada situação: comendo
## (prato na mesa), esperando o pedido, pedindo, andando nas quatro direções,
## indo embora feliz e bravo, e o garçom com a bandeja. Não lê nem grava save.

var _cafe: Node
var _output := ""
var _zoom := 1.0
var _frames := 20
var _focus := Vector2(-1, -1)
var _panel := ""
var _stoves: Array[StringName] = []
## Janela que a foto deixa aberta (as outras são escondidas para a foto ficar limpa).
var _keep_window := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_output = args[0] if args.size() > 0 else "user://vitrine.png"
	if args.size() > 1:
		_zoom = float(args[1])
	if args.size() > 4 and args[4].contains(","):
		_focus = Vector2(float(args[4].get_slice(",", 0)), float(args[4].get_slice(",", 1)))
	if args.size() > 5:
		_panel = args[5]
	var japanese := _panel == "japones"
	if japanese:
		_panel = "livro:japao:1:30"
	var clock = load("res://core/time/manual_clock.gd").new()
	if _panel == "noite":
		clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T23:00:00") - clock.utc_offset_seconds()
	if _panel.begins_with("evento"):
		clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T12:00:00")  # durante o Halloween
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
	var cooking_stove: StringName = place.call(&"stove_basic", Vector2i(0, 0), 3)
	var ready_stove: StringName = place.call(&"stove_basic", Vector2i(1, 0), 0)
	var counter: StringName = place.call(&"counter_basic", Vector2i(0, 2), 3)
	var free_stove: StringName = place.call(&"stove_blue" if japanese else &"stove_basic", Vector2i(2, 0), 0)
	_stoves = [free_stove]
	place.call(&"plant_pot", Vector2i(0, 6))
	place.call(&"table_round", Vector2i(3, 2))
	var left_chair: StringName = place.call(&"chair_wood", Vector2i(2, 2), 3)
	var right_chair: StringName = place.call(&"chair_wood", Vector2i(4, 2), 1)
	place.call(&"table_long", Vector2i(3, 5))
	var back_chair: StringName = place.call(&"chair_wood", Vector2i(3, 4), 0)
	var front_chair: StringName = place.call(&"chair_wood", Vector2i(4, 6), 2)

	var recipes = simulation.recipes
	# Cozinha: lasanha no meio do preparo, café pronto e coxinhas no balcão.
	var lasagna = recipes.get_definition(&"lasagna")
	simulation.kitchen.restore_stove(cooking_stove, lasagna, clock.now() - lasagna.cook_time * 0.6)
	var coffee = recipes.get_definition(&"coffee")
	var forgotten: float = simulation.kitchen.spoil_time(coffee) if _panel == "estragado" else 0.0
	simulation.kitchen.restore_stove(ready_stove, coffee, clock.now() - coffee.cook_time - forgotten - 1.0)
	if _panel == "estragado":
		_stoves = [ready_stove]
	if _panel == "trem":
		simulation.progression.add_xp(46000)  # nível 30
		_stoves = [place.call(&"train_locomotive", Vector2i(3, 0), 0)]
		place.call(&"train_wagon", Vector2i(4, 0), 0)
		place.call(&"train_dining", Vector2i(5, 0), 0)
	if _panel == "trofeu":
		simulation.progression.add_xp(20000)  # nível 22: o troféu de ouro está liberado
		_stoves = [place.call(&"trophy_gold", Vector2i(2, 1))]
	if _panel == "temperos":
		_stoves = [cooking_stove]
		simulation.progression.add_xp(7100)  # nível 16: todos os temperos à venda
		simulation.wallet.earn(&"soft_currency", 5000, "vitrine")
		simulation.spice_shelf.add(&"salt", 2)
		simulation.spice_shelf.add(&"pepper", 1)
	simulation.kitchen.restore_counter(counter, recipes.get_definition(&"coxinha"), 9)
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
	var worried = seat.call(right_chair, 2, &"lasagna", 0.4)   # esperando o prato, de costas, preocupada
	seat.call(back_chair, 1, &"", 0.9)           # esperando para pedir, de costas
	seat.call(front_chair, 3, &"coffee", 1.0)    # comendo, de costas
	if _panel == "noite":
		simulation.progression.add_xp(46000)  # nível 30
		_stoves = [place.call(&"stove_moon", Vector2i(3, 0), 0)]
		place.call(&"floor_lamp", Vector2i(1, 6))
		place.call(&"paris_lamp", Vector2i(6, 3))
	if _panel == "diversao":
		simulation.progression.add_xp(9000)  # nível 16
		var claw: StringName = place.call(&"claw_machine", Vector2i(6, 2))
		place.call(&"ring_toss", Vector2i(6, 4))
		place.call(&"stage", Vector2i(5, 6))
		simulation.attractions.add_play(claw)
		simulation.show_left = simulation.stage_config.show_duration  # show acontecendo
	if _panel == "pomar":
		simulation.progression.add_xp(1000)  # nível 8
		place.call(&"tree_strawberry", Vector2i(1, 6))
		place.call(&"tree_mango", Vector2i(6, 2))
		place.call(&"tree_blueberry", Vector2i(6, 4))
		place.call(&"machine_frozen", Vector2i(5, 6), 0)
		clock.advance(1800.0)  # todos maduros (e a lasanha da vitrine ainda não estraga)
		worried.state = 7  # Customer.State.WAITING_FOR_DRINK
		worried.order = null
		worried.drink = simulation.drinks.get_definition(&"frozen_mango")
		simulation.fruit_stock.add(&"mango", 3)
	if _panel == "critico":
		simulation.progression.add_xp(680)  # nível 8
		worried.critic = true
		simulation.critic_star = {"cell": Vector2i(4, 6), "gold": 200, "xp": 50, "coupons": 3}
		simulation.wallet.earn(&"coupons", 7, "vitrine")
	if _panel == "entregas":
		simulation.progression.add_xp(1000)  # nível 8
		_stoves = [place.call(&"delivery_counter", Vector2i(0, 4), 3)]
		simulation.refresh_delivery()
		simulation.delivery.orders[0] = simulation.delivery.make_order(recipes.get_definition(&"coxinha"), 4)  # já no balcão
		simulation.delivery.orders.append(simulation.delivery.make_order(recipes.get_definition(&"pastel"), 6))
		simulation.delivery.orders.append(simulation.delivery.make_order(recipes.get_definition(&"coffee"), 8))
	if _panel == "terraco":
		simulation.progression.add_xp(46000)  # nível 30
		simulation.wallet.earn(&"soft_currency", 5000, "vitrine")
		simulation.build_terrace()
		place.call(&"table_round", Vector2i(2, 7))
		place.call(&"chair_wood", Vector2i(1, 7), 3)
		place.call(&"flower_vase", Vector2i(6, 7))
	if _panel == "sujo":
		for cell in [Vector2i(2, 3), Vector2i(5, 5), Vector2i(2, 6)]:
			simulation.dirt.add(cell)
	if _panel == "portas":
		simulation.progression.add_xp(46000)  # nível 30
		simulation.wallet.earn(&"soft_currency", 5000, "vitrine")
		simulation.use_door(&"door_japones")
		place.call(&"counter_bamboo", Vector2i(0, 3), 3)
		var style_script = load("res://core/cafe/cafe_style.gd")
		for i in [2, 5]:
			simulation.style.own(&"janela_shoji")
			simulation.style.hang([style_script.segment(style_script.EDGE_TOP, i)] as Array[String], &"janela_shoji")
	if _panel == "bebidas":
		simulation.progression.add_xp(280)  # nível 5
		place.call(&"machine_coffee", Vector2i(0, 4), 3)
		place.call(&"machine_juice", Vector2i(0, 5), 3)
		worried.state = 7  # Customer.State.WAITING_FOR_DRINK
		worried.order = null
		worried.drink = simulation.drinks.get_definition(&"cappuccino")
		simulation.energy.spend(3, clock.now())
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

	simulation.wallet.earn(&"soft_currency", 480, "vitrine")
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = simulation
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


## Deixa o painel de baixo no estado pedido (depois de a cena ficar pronta).
func _set_panel() -> void:
	match _panel.get_slice(":", 0):
		"loja":
			var tab := _panel.get_slice(":", 1)
			_cafe.build_bar.open_shop(_cafe.build_bar.ShopTab.get(tab, 0) if not tab.is_empty() else 0)
		"fogao", "estragado", "temperos", "trofeu", "trem", "noite", "entregas":
			var stove = _cafe.layout.get_placement(_stoves[0])
			_cafe.select_at_world(IsoProjection.cell_center(stove.origin))
			if _panel == "noite":
				_cafe.build_bar.show_recipe_book(&"noite")
		"construir":
			_cafe.start_placing(&"table_round")
			_cafe._on_tapped(IsoProjection.cell_center(Vector2i(5, 2)))  # o toque do modo de construção
		"moedas":
			_keep_window = "CoinShopDialog"
			_cafe.hud.show_coin_shop(true)
		"pausa":
			_cafe.set_paused(true)
		"cidade":
			_keep_window = "CityDialog"
			for window: Window in _cafe.find_children("*", "Window", true, false):
				window.hide()
			var sim = _cafe.simulation
			sim.progression.add_xp(9000)  # nível 16
			sim.wallet.earn(&"soft_currency", 30000, "vitrine")
			sim.open_branch()
			sim.upgrade_branch()
			sim.branch.since -= 3.5 * 3600.0  # três horas e meia juntando ouro
			_cafe.hud.show_city()
		"avatar":
			_keep_window = "AvatarDialog"
			for window: Window in _cafe.find_children("*", "Window", true, false):
				window.hide()
			var sim = _cafe.simulation
			sim.progression.add_xp(9000)  # nível 16
			sim.wallet.earn(&"soft_currency", 5000, "vitrine")
			for part in [&"skin_morena_clara", &"hair_coque_loiro", &"outfit_vermelha"]:
				sim.use_avatar_part(part)
			_cafe.hud.show_avatar()
			var dialog = _cafe.hud.avatar_dialog()
			dialog.show_slot(2)  # chapéus
			dialog.choose(&"hat_boina")  # provando a boina, com a pergunta de compra
		"portas":
			_cafe.build_bar.open_shop(_cafe.build_bar.ShopTab.WALL)
			_cafe.build_bar.show_shop_collection(&"japones")
		"fechado":
			_cafe.set_closed(true)
		"livro":
			var level := int(_panel.get_slice(":", 3)) if _panel.get_slice_count(":") > 3 else 13
			var table: LevelTable = load("res://data/progression/levels.tres")
			_cafe.simulation.progression.add_xp(table.xp_to_reach[level - 1])
			for i in 25:
				_cafe.simulation.mastery.record(&"coxinha")
			for i in 6:
				_cafe.simulation.mastery.record(&"pastel")
			var stove = _cafe.layout.get_placement(_stoves[0])
			_cafe.select_at_world(IsoProjection.cell_center(stove.origin))
			var tab := _panel.get_slice(":", 1)
			if not tab.is_empty():
				_cafe.build_bar.show_recipe_book(StringName(tab))
			if _panel.get_slice_count(":") > 2:
				_cafe.build_bar.show_recipe_page(int(_panel.get_slice(":", 2)) - 1)
		"evento":
			_keep_window = "EventDialog"
			for window: Window in _cafe.find_children("*", "Window", true, false):
				window.hide()
			if _panel.get_slice(":", 1) == "missoes":
				_cafe.simulation.mark_event_story_seen()
			_cafe.hud.show_event()
		"missoes":
			_keep_window = "MissionsDialog"
			for window: Window in _cafe.find_children("*", "Window", true, false):
				window.hide()
			_cafe.simulation.refresh_mission_periods()
			_cafe.simulation.claim_daily()
			_cafe.hud.show_missions()
		"reforma":
			# Piso e parede já misturados, e uma reforma em andamento com alguns pisos marcados.
			var style = _cafe.simulation.style
			var mixed: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5), Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6)]
			style.paint_floor(mixed, &"floor_70s")
			var walls: Array[String] = ["top:4", "top:5", "left:3", "bottom:2", "bottom:3", "right:1"]
			style.paint_walls(walls, &"wall_brick")
			for spot in [["top:1", &"tv"], ["top:6", &"janelao"], ["left:4", &"neon_xicara"], ["left:6", &"lousa"], ["top:3", &"radio"]]:
				style.hang([spot[0]] as Array[String], spot[1])
			_cafe.start_painting(StringName(_panel.get_slice(":", 1)) if _panel.contains(":") else &"floor_wood")
			for cell in [Vector2i(5, 2), Vector2i(6, 2), Vector2i(5, 3), Vector2i(6, 3)]:
				_cafe.toggle_paint_at(IsoProjection.cell_center(cell))
	_panel = ""


func _process(_delta: float) -> bool:
	if _cafe == null or not _cafe.is_inside_tree():
		printerr("A vitrine não montou a cena.")
		quit(1)
		return true
	for window: Window in _cafe.find_children("*", "Window", true, false):
		if window.name != _keep_window:
			window.hide()
	if not _panel.is_empty():
		_set_panel()
	var camera := _cafe.get_viewport().get_camera_2d()
	camera.zoom = Vector2(_zoom, _zoom)
	if _focus.x >= 0.0:
		camera.global_position = IsoProjection.grid_point_to_world(_focus)
	_frames -= 1
	if _frames > 0:
		return false
	root.get_texture().get_image().save_png(_output)
	print("Foto em ", _output)
	return true
