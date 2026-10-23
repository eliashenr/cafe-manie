extends CafeTestCase
## Portas na loja e na fachada (DT-067): a aba Paredes vende uma porta por coleção, comprar pede confirmação,
## a fachada desenha a porta escolhida (aberta e fechada) e trocar para uma já comprada é na hora.


func _door_button(cafe: Cafe, collection: StringName, door_id: String) -> Button:
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	cafe.build_bar.show_shop_collection(collection)
	await settle()
	return cafe.build_bar.find_button("Door_" + door_id)


func test_every_door_has_its_art_open_and_closed() -> void:
	var cafe := await spawn_cafe()
	for door: DoorDefinition in cafe.simulation.doors.all():
		assert_true(ArtSprites.get_sprite(door.sprite_base + "_L") != null, "porta aberta: " + door.sprite_base)
		assert_true(ArtSprites.get_sprite(door.sprite_base + "_fechada_L") != null, "porta fechada: " + door.sprite_base)


func test_the_shop_shows_the_doors_with_their_state() -> void:
	var cafe := await spawn_cafe()
	var classic := await _door_button(cafe, &"classico", "door_classico")
	assert_true(classic != null and classic.text.contains("Na entrada"), "a clássica está na entrada")
	assert_true(classic.disabled, "a que já está na entrada não se toca")
	var groovy := await _door_button(cafe, &"anos70", "door_anos70")
	assert_true(groovy != null and groovy.disabled and groovy.text.contains("Nível 3"), "bloqueada no começo")


func test_buying_a_door_asks_and_the_front_draws_it() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 1000, "teste")
	var door: DoorDefinition = sim.doors.get_definition(&"door_anos70")
	var button := await _door_button(cafe, &"anos70", "door_anos70")
	assert_true(button.text.contains("%d ouro" % door.price), button.text)
	var gold := sim.wallet.balance(Wallet.SOFT)
	button.pressed.emit()
	var dialog := cafe.build_bar.confirm_dialog()
	assert_true(dialog.visible and dialog.get_cancel_button().has_focus(), "comprar pede confirmação, com Cancelar selecionado")
	assert_eq(sim.current_door().id, &"door_classico", "nada muda antes de confirmar")
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_eq(sim.current_door(), door)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - door.price)
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_anos70_L", "a fachada desenha a porta nova")
	assert_true(all_messages(cafe).contains("na entrada"), all_messages(cafe))
	cafe.set_closed(true)
	await settle()
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_anos70_fechada_L", "fechado, com a plaquinha")
	assert_true(button.text.contains("Na entrada"), button.text)


func test_switching_back_to_an_owned_door_is_instant() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 1000, "teste")
	sim.use_door(&"door_festa")
	await settle()
	var classic := await _door_button(cafe, &"classico", "door_classico")
	assert_false(classic.disabled)
	var gold := sim.wallet.balance(Wallet.SOFT)
	classic.pressed.emit()
	await settle()
	assert_false(cafe.build_bar.confirm_dialog().visible, "a já comprada troca sem perguntar")
	assert_eq(sim.current_door().id, &"door_classico")
	assert_eq(cafe.front_view.door_sprite_name(), "enfeite_porta_L")
	var festa := await _door_button(cafe, &"festa", "door_festa")
	assert_true(festa.text.contains("Comprada"), festa.text)
	festa.pressed.emit()
	await settle()
	assert_eq(sim.current_door().id, &"door_festa")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold, "de graça")
