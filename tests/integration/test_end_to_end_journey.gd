extends CafeTestCase
## QA de ponta a ponta (FAÇA QA, 23/10): uma jornada inteira, do jogo novo aos recursos dos itens 9 e 10, jogada pela
## tela (botões, toques e janelas) e pelo relógio, fechando e reabrindo o jogo no meio. Nenhum erro pode aparecer no
## registro do Godot durante a jornada. O save fica numa pasta própria, nunca no do jogador.

var dir := ""


func _save_path() -> String:
	if dir.is_empty():
		dir = "user://test_saves/journey_%d_%d" % [Time.get_ticks_usec(), randi()]
		DirAccess.make_dir_recursive_absolute(dir)
	return dir.path_join("save.json")


func cleanup() -> void:
	super.cleanup()
	if dir.is_empty():
		return
	for file_name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file_name))
	DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(dir.get_base_dir())


func _open_game() -> Cafe:
	var cafe: Cafe = CafeScene.instantiate()
	cafe.save_service = SaveService.new(_save_path())
	cafe.game_clock = clock
	cafe.get_node("SoundBoard").settings_path = ""
	add_to_tree(cafe)
	await tree.process_frame
	return cafe


func _close_game(cafe: Cafe) -> void:
	cafe.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	cafe.get_parent().remove_child(cafe)
	cafe.queue_free()


## Passa o tempo do jogo: o relógio e a simulação andam juntos, em passos de 0,25 s.
func _play(cafe: Cafe, seconds: float, cook := true) -> void:
	var left := seconds
	var next_cook := 0.0
	while left > 0.0:
		if cook and next_cook <= 0.0:
			_cook_something(cafe.simulation)
			next_cook = 1.0
		clock.advance(0.25)
		cafe.simulation.tick(0.25)
		left -= 0.25
		next_cook -= 0.25
	await settle()


## Como o robô do balanceamento: o que foi pedido, senão café (rápido e sempre útil).
func _cook_something(sim: CafeSimulation) -> void:
	var demand := sim.waiting_demand()
	for placement in sim.layout.placements():
		if not sim.kitchen.is_stove(placement.id) or sim.kitchen.stove_status(placement.id) != Kitchen.StoveStatus.IDLE:
			continue
		var recipe := &"coffee"
		for id: StringName in demand:
			var wanted := sim.recipes.get_definition(id)
			if wanted != null and wanted.stove == &"" and not sim.kitchen.is_preparing(wanted):
				recipe = id
				break
		sim.start_cooking(placement.id, recipe)


func _first_stove(sim: CafeSimulation) -> CafeLayout.Placement:
	for placement in sim.layout.placements():
		if sim.kitchen.is_stove(placement.id):
			return placement
	return null


## Procura o botão na loja, passando as páginas.
func _shop_button(cafe: Cafe, tab: BuildBar.ShopTab, collection: StringName, button_name: String) -> Button:
	cafe.build_bar.show_shop_tab(tab)
	cafe.build_bar.show_shop_collection(collection)
	await settle()
	var button := cafe.build_bar.find_button(button_name)
	for page in 20:
		if button != null or cafe.build_bar.shop_page >= cafe.build_bar.shop_page_count() - 1:
			break
		cafe.build_bar.show_shop_page(cafe.build_bar.shop_page + 1)
		await settle()
		button = cafe.build_bar.find_button(button_name)
	return button


## Compra um móvel pela loja e põe no primeiro piso livre que aceitar (dois toques, como no celular).
func _buy_and_place(cafe: Cafe, tab: BuildBar.ShopTab, furniture_id: StringName) -> StringName:
	cafe.clear_selection()  # com um móvel escolhido, a barra mostra os controles dele, não a loja
	cafe.build_bar.open_shop(tab)
	var button := await _shop_button(cafe, tab, &"", "Build_" + String(furniture_id))
	assert_true(button != null and not button.disabled, "o móvel está à venda: " + String(furniture_id))
	if button == null:
		return &""
	buy_in_shop(cafe, button)
	await settle()
	var size := cafe.layout.grid.size
	var before := cafe.layout.count()
	for y in range(1, size.y - 1):
		for x in range(1, size.x - 1):
			tap_cell(cafe, Vector2i(x, y))
			tap_cell(cafe, Vector2i(x, y))
			if cafe.layout.count() > before:
				await settle()
				return cafe.layout.placement_at(Vector2i(x, y)).id
	return &""


## Houve uma transação com este motivo e este valor desde [param since] (os clientes continuam pagando enquanto a
## jornada roda, então o saldo exato varia).
func _paid(sim: CafeSimulation, since: int, reason: String, delta: int) -> bool:
	var history := sim.wallet.history()
	for i in range(maxi(history.size() - since, 0), history.size()):
		var entry: Dictionary = history[i]
		if entry["currency"] == Wallet.SOFT and String(entry["reason"]).contains(reason) and int(entry["delta"]) == delta:
			return true
	return false


func _confirm(cafe: Cafe) -> void:
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.get_cancel_button().has_focus(), "a compra pergunta antes, com Cancelar selecionado")
	dialog.get_ok_button().pressed.emit()
	await settle()


func test_the_whole_journey() -> void:
	var errors := SmokeCheck.ErrorCounter.new()
	OS.add_logger(errors)
	clock = ManualClock.new()
	clock.time = Time.get_unix_time_from_datetime_string("2026-03-03T10:00:00")
	var cafe := await _open_game()
	var sim := cafe.simulation

	# 1. Jogo novo: dar nome ao café, cozinhar um café pela tela e ver o prato ficar pronto.
	assert_eq(sim.progression.level, 1, "começa no nível 1")
	await settle()
	var name_dialog := cafe.hud.find_child("NameDialog", true, false) as ConfirmationDialog
	assert_true(name_dialog.visible, "a primeira abertura pergunta o nome do café")
	var name_edit := name_dialog.find_child("NameEdit", true, false) as LineEdit
	name_edit.text = "Café da Jornada"
	name_edit.text_changed.emit(name_edit.text)
	name_dialog.get_ok_button().pressed.emit()
	await settle()
	assert_eq(sim.cafe_name, "Café da Jornada")
	var daily := cafe.hud.daily_dialog()
	assert_true(daily.visible, "depois do nome, o presente do primeiro dia")
	var gold_before_gift := sim.wallet.balance(Wallet.SOFT)
	daily.get_ok_button().pressed.emit()
	await settle()
	assert_true(sim.wallet.balance(Wallet.SOFT) > gold_before_gift, "o presente do dia 1 deu ouro")
	assert_false(cafe.is_dialog_open(), "respondido o nome e recebido o presente, o jogo libera os toques")
	var stove := _first_stove(sim)
	tap_cell(cafe, stove.origin)
	await settle()
	var cook := cafe.build_bar.find_button("Cook_coffee")
	assert_true(cook != null, "o fogão livre abre o livro com o café")
	cook.pressed.emit()
	await settle()
	assert_eq(sim.kitchen.stove_status(stove.id), Kitchen.StoveStatus.COOKING, "o café está no fogão")
	await _play(cafe, 20.0, false)
	assert_true(sim.kitchen.servings_of(sim.recipes.get_definition(&"coffee")) > 0 \
		or sim.kitchen.stove_status(stove.id) == Kitchen.StoveStatus.READY, "o café ficou pronto")

	# 2. Alguns minutos de atendimento: clientes pagam, missões andam, o nível sobe.
	await _play(cafe, 240.0)
	assert_true(sim.stats.value(PlayerStats.CUSTOMERS_SERVED) >= 10, "clientes servidos: %d" % sim.stats.value(PlayerStats.CUSTOMERS_SERVED))
	assert_true(sim.progression.level >= 3, "subiu de nível: %d" % sim.progression.level)
	assert_true(sim.missions.completed_count() > 0, "o tutorial andou")

	# 3. Comprar uma mesa e uma cadeira pela loja.
	var table := await _buy_and_place(cafe, BuildBar.ShopTab.SALON, &"table_round")
	assert_true(table != &"", "a mesa foi posta")
	var table_price := sim.furniture.get_definition(&"table_round").price
	assert_true(_paid(sim, 60, "Mesa", -table_price) or _paid(sim, 60, "mesa", -table_price), "e cobrada: %s" % [sim.wallet.history().slice(-8)])

	# 4. Pular para o meio do jogo (atalho de QA) e expandir e contratar pela barra.
	sim.progression.add_xp(sim.progression.table.xp_to_reach[9] - sim.progression.xp)  # nível 10
	sim.wallet.earn(Wallet.SOFT, 80000, "QA")
	cafe.build_bar.close_shop()
	cafe.clear_selection()
	await settle()
	var size := sim.layout.grid.size
	cafe.build_bar.find_button("ExpandButton").pressed.emit()
	await _confirm(cafe)
	assert_true(sim.layout.grid.size != size, "o café cresceu")
	cafe.build_bar.find_button("HireButton").pressed.emit()
	await _confirm(cafe)
	assert_eq(sim.waiters.size(), 2, "segundo garçom")

	# 5. Porta da coleção Anos 70.
	cafe.build_bar.open_shop(BuildBar.ShopTab.WALL)
	var door := await _shop_button(cafe, BuildBar.ShopTab.WALL, &"anos70", "Door_door_anos70")
	buy_in_shop(cafe, door)
	await _confirm(cafe)
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_anos70_L", "a porta nova na fachada")

	# 6. Terraço.
	var terrace := await _shop_button(cafe, BuildBar.ShopTab.FLOOR, &"classico", "Terrace")
	buy_in_shop(cafe, terrace)
	await _confirm(cafe)
	assert_true(sim.has_terrace() and cafe.front_view.terrace, "terraço pronto, com a cerca")
	cafe.build_bar.close_shop()
	await settle()

	# 7. Chão sujo: a mancha aparece e o toque limpa.
	var spot := Vector2i(size.x / 2, size.y / 2)
	for y in range(1, sim.layout.grid.size.y - 1):
		if sim.dirt.add(Vector2i(spot.x, y)):
			spot = Vector2i(spot.x, y)
			break
	await settle()
	tap_cell(cafe, spot)
	await settle()
	assert_false(sim.dirt.has_spot(spot), "o toque limpou a mancha")

	# 8. Avatar: provar e comprar a boina.
	cafe.build_bar.find_button("ChefBarButton").pressed.emit()
	await settle()
	var avatar := cafe.hud.avatar_dialog()
	avatar.show_slot(AvatarPartDefinition.Slot.HAT)
	await settle()
	avatar.card(&"hat_boina").pressed.emit()
	await settle()
	(avatar.find_child("AvatarBuy", true, false) as Button).pressed.emit()
	await settle()
	assert_eq(sim.avatar_part(AvatarPartDefinition.Slot.HAT).id, &"hat_boina")
	avatar.hide()
	await settle()

	# 9. Entregas: Balcão de Entregas pela loja, um pedido mandado com as porções do balcão.
	var delivery := await _buy_and_place(cafe, BuildBar.ShopTab.KITCHEN, &"delivery_counter")
	assert_true(delivery != &"", "o Balcão de Entregas foi posto")
	cafe.build_bar.close_shop()
	await _play(cafe, 1.0, false)
	assert_false(sim.delivery.orders.is_empty(), "chegou um pedido")
	var order: DeliveryBoard.Order = sim.delivery.orders[0]
	var counter: StringName = &""
	for placement in sim.layout.placements():
		if sim.kitchen.is_counter(placement.id) and sim.kitchen.counter_stack(placement.id) == null:
			counter = placement.id
	if counter == &"":
		counter = await _buy_and_place(cafe, BuildBar.ShopTab.KITCHEN, &"counter_basic")
		cafe.build_bar.close_shop()
	cafe.set_paused(true)  # o café anda a cada frame: sem a pausa, um garçom podia levar a porção da entrega a um cliente
	assert_true(sim.kitchen.restore_counter(counter, order.recipe, order.servings), "porções do pedido no balcão")
	cafe.select_at_world(IsoProjection.cell_center(sim.layout.get_placement(delivery).origin))
	await settle()
	cafe.build_bar.find_button("Delivery_0").pressed.emit()
	await settle()
	assert_true(_paid(sim, 40, "Entrega", order.gold), "a entrega pagou (resultado %d)" % cafe.last_service_result)
	cafe.set_paused(false)
	cafe.clear_selection()
	await settle()

	# 10. Filial na praia (nível 15) e vizinhos, pela janela da Cidade.
	sim.progression.add_xp(sim.progression.table.xp_to_reach[14] - sim.progression.xp)  # nível 15
	await settle()
	cafe.build_bar.find_button("CityBarButton").pressed.emit()
	await settle()
	var city := cafe.hud.city_dialog()
	(city.find_child("BranchAction", true, false) as Button).pressed.emit()
	await settle()
	(city.find_child("BranchConfirm", true, false) as Button).pressed.emit()
	await settle()
	assert_true(sim.branch.opened, "filial aberta")
	await _play(cafe, 3600.0, false)
	(city.find_child("CollectBranch", true, false) as Button).pressed.emit()
	await settle()
	assert_true(_paid(sim, 40, sim.branch_config.display_name, sim.branch.income_per_hour()), "a filial juntou uma hora de ouro")
	(city.find_child("CityTab_neighbors", true, false) as Button).pressed.emit()
	await settle()
	city.neighbor_button(&"ana").pressed.emit()
	await settle()
	assert_false(sim.can_visit_neighbor(&"ana"), "ajudou a Ana hoje")
	city.hide()
	await settle()

	# 11. Fechar e reabrir: tudo continua igual.
	var expected := {
		"level": sim.progression.level, "gold": sim.wallet.balance(Wallet.SOFT), "size": sim.layout.grid.size,
		"count": sim.layout.count(), "waiters": sim.waiters.size(), "door": sim.current_door().id,
		"hat": sim.avatar_part(AvatarPartDefinition.Slot.HAT).id, "orders": sim.delivery.orders.size(),
		"branch_level": sim.branch.level,
	}
	_close_game(cafe)
	await settle()
	clock.advance(5.0)
	var again := await _open_game()
	var loaded := again.simulation
	assert_eq(loaded.progression.level, expected["level"], "nível")
	var loaded_gold := loaded.wallet.balance(Wallet.SOFT)
	assert_true(loaded_gold >= int(expected["gold"]) and loaded_gold <= int(expected["gold"]) + 300,
		"nenhum ouro perdido ao reabrir (só o dos clientes que terminaram de pagar): %d → %d" % [expected["gold"], loaded_gold])
	assert_eq(loaded.layout.grid.size, expected["size"], "tamanho do café")
	assert_eq(loaded.layout.count(), expected["count"], "móveis")
	assert_eq(loaded.waiters.size(), expected["waiters"], "garçons")
	assert_eq(loaded.current_door().id, expected["door"], "porta")
	assert_eq(again.front_view.door_sprite_name(), "enfeite_porta_anos70_L", "a fachada desenha a porta salva")
	assert_true(loaded.has_terrace() and again.front_view.terrace, "terraço")
	assert_eq(loaded.avatar_part(AvatarPartDefinition.Slot.HAT).id, expected["hat"], "avatar")
	assert_eq(loaded.delivery.orders.size(), expected["orders"], "pedidos de entrega")
	assert_true(loaded.branch.opened and loaded.branch.level == expected["branch_level"], "filial")
	assert_false(loaded.can_visit_neighbor(&"ana"), "a visita de hoje continua")
	await _play(again, 30.0)
	_close_game(again)
	await settle()
	OS.remove_logger(errors)
	assert_eq(errors.messages, [] as Array[String], "nenhum erro durante a jornada")
