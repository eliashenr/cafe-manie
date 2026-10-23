extends CafeTestCase
## Vizinhos na cena (DT-074): a aba Vizinhos da janela da cidade mostra um cartão por vizinho, com o retrato; ajudar
## faz o ouro subir, avisa o que o jogador fez e apaga o botão até o dia seguinte.


func test_every_neighbor_has_a_portrait() -> void:
	var cafe := await spawn_cafe()
	for neighbor: NeighborDefinition in cafe.simulation.neighbors.all():
		assert_true(ArtSprites.get_sprite("vizinho_" + neighbor.art) != null, neighbor.art)


func test_helping_a_neighbor_from_the_city() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	cafe.build_bar.find_button("CityBarButton").pressed.emit()
	await settle()
	var dialog := cafe.hud.city_dialog()
	(dialog.find_child("CityTab_neighbors", true, false) as Button).pressed.emit()
	await settle()
	for neighbor: NeighborDefinition in sim.neighbors.all():
		assert_true(dialog.neighbor_button(neighbor.id) != null, "um cartão para " + neighbor.display_name)
	var button := dialog.neighbor_button(&"beto")
	var reward := sim.neighbor_reward(&"beto")
	assert_true(button.text.contains(str(reward)) and not button.disabled, button.text)
	var gold := sim.wallet.balance(Wallet.SOFT)
	button.pressed.emit()
	await settle()
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + reward)
	assert_true(all_messages(cafe).contains("temperou os pratos no Lanchonete do Beto"), all_messages(cafe))
	button = dialog.neighbor_button(&"beto")
	assert_true(button.disabled and button.text.contains("Visitado hoje"), button.text)
	assert_true((dialog.find_child("Neighbor_beto", true, false).find_child("Friendship", true, false) as Label).text.contains("1/"))
