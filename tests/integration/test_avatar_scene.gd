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


func test_approved_chef_is_used_in_the_real_dialog_and_static_hud() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	var hero := dialog.find_child("Portrait", true, false) as AvatarPortrait
	var approved := hero.get_node("ApprovedChef") as ChefAnimatedPortrait
	assert_true(hero.uses_approved_chef())
	assert_true(approved.visible and approved.is_processing(), "a janela real usa o chef animado aprovado")
	assert_false((hero.get_node("Layers") as CanvasItem).visible, "nenhuma peça antiga cobre gola ou chapéu")
	assert_eq(approved.visual_state()["base_path"], ChefAnimatedPortrait.BASE_PATH)
	var before := SaveCodec.encode(cafe.simulation)
	await _tap_in_dialog(dialog, dialog.find_child("GreetChefButton", true, false))
	assert_true(float(approved.visual_state()["greeting_age"]) >= 0.0)
	assert_eq(SaveCodec.encode(cafe.simulation), before)
	var profile := cafe.hud.find_child("ChefPortrait", true, false) as AvatarPortrait
	assert_true(profile.uses_approved_chef(), "o HUD também usa a base aprovada")
	assert_false((profile.get_node("ApprovedChef") as ChefAnimatedPortrait).is_processing(), "HUD estático")
	dialog.hide()
	await settle()
	assert_false(approved.is_processing(), "fechar a janela interrompe o movimento")


func test_trying_another_hat_and_cancelling_restores_the_approved_chef() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(99999)
	var dialog := await _open(cafe)
	var hero := dialog.find_child("Portrait", true, false) as AvatarPortrait
	var before := SaveCodec.encode(cafe.simulation)
	dialog.show_slot(Slot.HAT)
	dialog.card(&"hat_boina").pressed.emit()
	await settle()
	assert_false(hero.uses_approved_chef(), "outro chapéu mantém sua aparência e contrato de personalização")
	assert_true((hero.get_node("Layers") as CanvasItem).visible)
	assert_eq(SaveCodec.encode(cafe.simulation), before, "provar não compra")
	dialog.cancel_try()
	await settle()
	assert_true(hero.uses_approved_chef())
	assert_false((hero.get_node("Layers") as CanvasItem).visible)
	assert_true((hero.get_node("ApprovedChef") as ChefAnimatedPortrait).is_processing())


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


func _tap_in_dialog(dialog: AvatarDialog, control: Control) -> void:
	var at := Vector2(dialog.position) + control.get_global_rect().get_center()
	touch(0, at, true)
	touch(0, at, false)
	await settle()


func test_skin_choices_are_swatches_and_a_touch_changes_only_the_skin() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	dialog.show_slot(Slot.SKIN)
	await settle()
	var equipped := dialog.shown_parts()
	for part in cafe.simulation.avatar_parts_for(Slot.SKIN):
		var swatch := dialog.card(part.id)
		assert_true(swatch.get("skin_swatch"), "a pele é representada por uma amostra de cor")
		assert_eq(swatch.get("swatch_color"), AvatarPortrait.skin_color(part.art))
		var preview := swatch.find_child("PartPreview", true, false) as AvatarPortrait
		assert_false(preview.visible, "não repete a cabeça do chef nos tons de pele")
		assert_true(preview.layers.is_empty())
	await _tap_in_dialog(dialog, dialog.card(&"skin_negra"))
	assert_eq(cafe.simulation.avatar_part(Slot.SKIN).id, &"skin_negra")
	for other in [Slot.HAIR, Slot.HAT, Slot.OUTFIT]:
		assert_eq(cafe.simulation.avatar_part(other), equipped[other], "mudar a pele preserva as demais escolhas")
	assert_true(dialog.card(&"skin_negra").get("equipped"), "o tom equipado tem destaque")
	assert_true(dialog.card(&"skin_negra").text.contains("Usando"))


func test_part_cards_show_static_portrait_previews_and_accept_touch() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	var hero := dialog.find_child("Portrait", true, false) as AvatarPortrait
	assert_true(hero.animated, "só o retrato principal tem animação contínua")
	for part in cafe.simulation.avatar_parts_for(Slot.HAIR):
		var card := dialog.card(part.id)
		var preview := card.find_child("PartPreview", true, false) as AvatarPortrait
		var expected := dialog.shown_parts()
		expected[Slot.HAIR] = part
		assert_eq(preview.layers, AvatarPortrait.layer_names(expected), "a miniatura mostra a combinação atual com este cabelo")
		assert_false(preview.animated, "a grade não tem animações concorrentes")
		assert_true(card.art == null, "a miniatura não desenha a antiga cabeça fundida")
	await _tap_in_dialog(dialog, dialog.card(&"hair_rabo_preto"))
	assert_eq(cafe.simulation.avatar_part(Slot.HAIR).id, &"hair_rabo_preto", "o filho de prévia não engole o toque")


func test_greeting_by_touch_does_not_change_the_saved_game() -> void:
	var cafe := await spawn_cafe()
	var dialog := await _open(cafe)
	var before := SaveCodec.encode(cafe.simulation)
	var greeting := dialog.find_child("GreetChefButton", true, false) as Button
	var greeted := [false]
	greeting.pressed.connect(func() -> void: greeted[0] = true)
	await _tap_in_dialog(dialog, greeting)
	assert_true(greeted[0], "o retrato responde ao toque")
	assert_eq(SaveCodec.encode(cafe.simulation), before, "cumprimentar não compra, equipa, gasta ou muda o save")
	assert_eq(dialog.confirm_text(), "")


func test_closing_an_unbought_preview_restores_the_equipped_look_on_reopening() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(99999)
	var dialog := await _open(cafe)
	var before := SaveCodec.encode(cafe.simulation)
	dialog.show_slot(Slot.HAT)
	dialog.card(&"hat_boina").pressed.emit()
	await settle()
	assert_eq((dialog.find_child("PortraitStatus", true, false) as Label).text, "Experimentando")
	var title_height := dialog.get_theme_constant("title_height", "Window")
	var framed := Rect2(Vector2(dialog.position) - Vector2(0, title_height),
		Vector2(dialog.size) + Vector2(0, title_height))
	assert_true(cafe.get_viewport_rect().encloses(framed),
		"a janela e seu título cabem na área lógica, antes da escala para a tela: " + str(framed))
	var bounds := Rect2(Vector2.ZERO, Vector2(dialog.size))
	for control_name in ["Stage", "AvatarBuy", "AvatarCancel"]:
		var control := dialog.find_child(control_name, true, false) as Control
		assert_true(bounds.encloses(control.get_global_rect()), control_name + " não é cortado")
	dialog.get_ok_button().pressed.emit()
	await settle()
	assert_false(dialog.visible)
	dialog = await _open(cafe)
	assert_eq(dialog.portrait_layers()[2], "avatar_chapeu_toque")
	assert_eq(dialog.confirm_text(), "")
	assert_eq((dialog.find_child("PortraitStatus", true, false) as Label).text, "Seu visual")
	assert_eq(SaveCodec.encode(cafe.simulation), before)
