extends CafeTestCase
## A integração do chef aprovado não troca a arte nem o encaixe das personalizações anteriores.

const Slot := AvatarPartDefinition.Slot


func _assert_legacy_commands(portrait: AvatarPortrait) -> void:
	var canvas := portrait.get_node("Layers") as AvatarPortrait.LegacyLayers
	var commands := canvas.draw_commands()
	assert_true(canvas.visible, "as variantes são desenhadas no canvas legado real")
	assert_true(canvas.material == null, "sem shader de pele ou composição modular")
	assert_vec_almost_eq(canvas.position, Vector2.ZERO)
	assert_vec_almost_eq(canvas.size, portrait.size)
	assert_vec_almost_eq(canvas.scale, Vector2.ONE)
	assert_eq(commands.size(), portrait.layers.size())
	# Contrato de cac07e8, independente do seletor de chef aprovado.
	var scale := minf(portrait.size.x / 140.0, portrait.size.y / 170.0)
	var origin := (portrait.size - Vector2(140, 170) * scale) / 2.0 + Vector2(70, 110) * scale
	for index in mini(commands.size(), portrait.layers.size()):
		var original := ArtSprites.get_sprite(portrait.layers[index])
		assert_true(original != null, portrait.layers[index])
		if original == null:
			continue
		assert_eq(commands[index]["texture"], original.texture, "a textura original participa do desenho, sem substituição")
		var rect: Rect2 = commands[index]["rect"]
		assert_vec_almost_eq(rect.position, origin - original.anchor / original.density * scale,
			0.0001, "âncora original de " + portrait.layers[index])
		assert_vec_almost_eq(rect.size, original.texture.get_size() / original.density * scale,
			0.0001, "densidade original de " + portrait.layers[index])


func test_variants_keep_original_textures_anchors_and_order_at_different_sizes() -> void:
	var simulation := quiet_simulation()
	var portrait := AvatarPortrait.new()
	portrait.animated = true
	add_to_tree(portrait)
	await settle()
	var approved := portrait.get_node("ApprovedChef") as ChefAnimatedPortrait
	for skin in simulation.avatar_parts_for(Slot.SKIN):
		for hair in simulation.avatar_parts_for(Slot.HAIR):
			portrait.layers = ["avatar_roupa_branca", "avatar_cabeca_%s_%s" % [skin.art, hair.art],
				"avatar_chapeu_boina"] as Array[String]
			for dimensions: Vector2 in [Vector2(140, 170), Vector2(210, 255), Vector2(120, 70)]:
				portrait.size = dimensions
				_assert_legacy_commands(portrait)
			assert_false(portrait.uses_approved_chef())
			assert_false(approved.visible or approved.is_processing(), "não há animação escondida nas variantes")
			assert_false(portrait.is_processing(), "o renderer legado permanece estático")
	portrait.layers = [] as Array[String]
	assert_true((portrait.get_node("Layers") as AvatarPortrait.LegacyLayers).draw_commands().is_empty(),
		"limpar a seleção não deixa a textura anterior")


func test_trying_a_variant_and_cancelling_restores_approved_chef_without_save_changes() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.progression.add_xp(99999)
	cafe.build_bar.find_button("ChefBarButton").pressed.emit()
	await settle()
	var dialog := cafe.hud.avatar_dialog()
	var portrait := dialog.find_child("Portrait", true, false) as AvatarPortrait
	var approved := portrait.get_node("ApprovedChef") as ChefAnimatedPortrait
	var saved := SaveCodec.encode(cafe.simulation)
	var greeting := dialog.find_child("GreetChefButton", true, false) as Button
	var hint := dialog.find_child("GreetingHint", true, false) as Label
	var greetings := [0]
	greeting.pressed.connect(func() -> void: greetings[0] += 1)
	assert_true(portrait.uses_approved_chef() and approved.is_processing())
	assert_false(greeting.disabled)
	assert_eq(hint.text, "Toque para cumprimentar")
	assert_eq(greeting.tooltip_text, hint.text)
	var at := Vector2(dialog.position) + greeting.get_global_rect().get_center()
	touch(0, at, true)
	touch(0, at, false)
	await settle()
	assert_eq(greetings[0], 1, "o chef canônico oferece cumprimento por toque")
	dialog.show_slot(Slot.HAT)
	dialog.card(&"hat_boina").pressed.emit()
	await settle()
	_assert_legacy_commands(portrait)
	assert_false(approved.visible or approved.is_processing())
	assert_true(greeting.disabled, "o retrato legado não promete uma ação indisponível")
	assert_eq(hint.text, "Prévia do visual")
	assert_eq(greeting.tooltip_text, hint.text)
	assert_true(greeting.get_theme_stylebox("disabled") is StyleBoxEmpty, "o estado estático preserva o palco")
	at = Vector2(dialog.position) + greeting.get_global_rect().get_center()
	touch(0, at, true)
	touch(0, at, false)
	await settle()
	assert_eq(greetings[0], 1, "tocar a prévia estática não dispara cumprimento")
	portrait.react()
	assert_eq(SaveCodec.encode(cafe.simulation), saved, "provar e cumprimentar não compram nem equipam")
	dialog.cancel_try()
	await settle()
	assert_true(portrait.uses_approved_chef())
	assert_false(greeting.disabled, "cancelar também restaura a ação do chef canônico")
	assert_eq(hint.text, "Toque para cumprimentar")
	assert_eq(greeting.tooltip_text, hint.text)
	assert_true(approved.visible and approved.is_processing())
	assert_false((portrait.get_node("Layers") as CanvasItem).visible)
	assert_eq(SaveCodec.encode(cafe.simulation), saved, "cancelar devolve o visual sem alterar a partida")
	dialog.hide()
	await settle()
	assert_false(approved.is_processing(), "o chef aprovado também para quando a janela fecha")
