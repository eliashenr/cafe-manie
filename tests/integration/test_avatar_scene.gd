extends CafeTestCase
## Avatar do chef na cena (DT-070): o botão Chef abre a janela com o retrato em camadas; peça que já é do jogador
## veste na hora; peça nova aparece no retrato para provar e a compra pede confirmação, com Cancelar selecionado.

const Slot := AvatarPartDefinition.Slot


func _open(cafe: Cafe) -> AvatarDialog:
	cafe.build_bar.find_button("ChefBarButton").pressed.emit()
	await settle()
	return cafe.hud.avatar_dialog()


func test_every_avatar_layer_has_art() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	assert_true(ArtSprites.get_sprite("icone_chef") != null, "ícone do botão Chef")
	for skin in sim.avatar_parts_for(Slot.SKIN):
		for hair in sim.avatar_parts_for(Slot.HAIR):
			var head := "avatar_cabeca_%s_%s" % [skin.art, hair.art]
			assert_true(ArtSprites.get_sprite(head) != null, head)
	for hat in sim.avatar_parts_for(Slot.HAT):
		assert_true(ArtSprites.get_sprite("avatar_chapeu_" + hat.art) != null, hat.art)
	for outfit in sim.avatar_parts_for(Slot.OUTFIT):
		assert_true(ArtSprites.get_sprite("avatar_roupa_" + outfit.art) != null, outfit.art)


func test_the_chef_button_opens_the_portrait() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	assert_true(dialog.visible, "o botão Chef abre o avatar")
	assert_true(cafe.is_dialog_open(), "conta como janela aberta: nada abre por cima (uma por vez)")
	assert_eq(dialog.portrait_layers(), ["avatar_roupa_branca", "avatar_cabeca_clara_curto_castanho", "avatar_chapeu_toque"] as Array[String],
		"o retrato empilha a roupa, a cabeça e o chapéu")
	var locked := dialog.card(&"hair_longo_rosa")
	assert_true(locked.disabled and locked.text.contains("Nível 12"), "cabelo bloqueado no começo: " + locked.text)
	assert_true(dialog.card(&"hair_curto_castanho").text.contains("Usando"))


func test_an_owned_or_free_part_is_worn_at_once() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	dialog.card(&"hair_rabo_preto").pressed.emit()
	await settle()
	assert_eq(cafe.simulation.avatar_part(Slot.HAIR).id, &"hair_rabo_preto", "grátis: veste na hora")
	assert_eq(dialog.confirm_text(), "", "sem pergunta")
	assert_eq(dialog.portrait_layers()[1], "avatar_cabeca_clara_rabo_preto")
	dialog.show_slot(Slot.SKIN)
	await settle()
	dialog.card(&"skin_parda").pressed.emit()
	await settle()
	assert_eq(dialog.portrait_layers()[1], "avatar_cabeca_parda_rabo_preto", "a pele troca e o cabelo fica")


func test_a_new_part_is_tried_on_and_bought_after_confirming() -> void:
	var cafe := await spawn_cafe()
	var sim := cafe.simulation
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, 1000, "teste")
	var dialog := await _open(cafe)
	dialog.show_slot(Slot.HAT)
	await settle()
	var gold := sim.wallet.balance(Wallet.SOFT)
	dialog.card(&"hat_boina").pressed.emit()
	await settle()
	assert_eq(dialog.portrait_layers()[2], "avatar_chapeu_boina", "a boina aparece no retrato para provar")
	assert_true(dialog.confirm_text().contains("Boina francesa"), dialog.confirm_text())
	assert_true((dialog.find_child("AvatarCancel", true, false) as Button).has_focus(), "Cancelar já selecionado")
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_toque", "nada comprado antes de confirmar")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold)
	(dialog.find_child("AvatarCancel", true, false) as Button).pressed.emit()
	await settle()
	assert_eq(dialog.portrait_layers()[2], "avatar_chapeu_toque", "cancelar volta o retrato")
	assert_eq(dialog.confirm_text(), "")
	dialog.card(&"hat_boina").pressed.emit()
	await settle()
	(dialog.find_child("AvatarBuy", true, false) as Button).pressed.emit()
	await settle()
	assert_eq(sim.avatar_part(Slot.HAT).id, &"hat_boina")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold - sim.avatar_parts.get_definition(&"hat_boina").price)
	assert_true(all_messages(cafe).contains("Novo visual"), all_messages(cafe))
	assert_true(dialog.card(&"hat_boina").text.contains("Usando"))
