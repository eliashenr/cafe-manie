extends CafeTestCase
## O café no estilo Nova York (DT-081): o letreiro neon com o nome do café em cima da parede do fundo, o acabamento de
## madeira, a luz das janelas que some à noite e os itens de parede que acendem (a arandela nova e o neon de xícara).


func _cafe_at(hour: float) -> Cafe:
	var simulation := quiet_simulation()
	clock.offset = 0
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-25T00:00:00") + hour * 3600.0
	var cafe := await spawn_cafe(simulation)
	await settle()
	return cafe


func test_the_neon_sign_shows_the_cafe_name_and_follows_changes() -> void:
	var cafe := await _cafe_at(12.0)
	var sign := cafe.neon_sign
	assert_true(sign.get_parent() == cafe.wall_view, "o letreiro fica com as paredes (os móveis passam na frente)")
	assert_eq(sign.shown_text(), cafe.simulation.cafe_name, "o nome do café no letreiro")
	cafe.simulation.set_cafe_name("Café da Esquina")
	assert_eq(sign.shown_text(), "Café da Esquina", "trocar o nome troca o letreiro")
	var top_middle := IsoProjection.vertex_to_world(Vector2(cafe.layout.grid.size.x / 2.0, 0.0))
	assert_true(sign.anchor_point().is_equal_approx(top_middle - Vector2(0.0, cafe.wall_view.wall_height)),
		"em pé no alto da parede da direita, no meio dela")
	var empty := NeonSign.new()
	assert_eq(empty.shown_text(), NeonSign.EMPTY_TEXT, "sem nome ainda (o jogo novo), o letreiro diz só Café")
	empty.free()


func test_the_sign_moves_with_the_expansion() -> void:
	var simulation := quiet_simulation()
	simulation.expansions = load(CafeSimulation.EXPANSIONS_PATH)
	simulation.progression.add_xp(99999)
	simulation.wallet.earn(Wallet.SOFT, 100000, "teste")
	var cafe := await spawn_cafe(simulation)
	var before := cafe.neon_sign.anchor_point()
	assert_eq(simulation.expand(), ServiceResult.OK)
	await settle()
	assert_eq(cafe.neon_sign.grid_size, cafe.layout.grid.size)
	assert_false(cafe.neon_sign.anchor_point().is_equal_approx(before), "o café cresceu: o letreiro acompanha o meio da parede")


func test_the_neon_keeps_its_own_light_at_night() -> void:
	var day := await _cafe_at(12.0)
	assert_eq(day.neon_sign.night, 0.0)
	var night := await _cafe_at(23.0)
	assert_eq(night.neon_sign.night, 1.0, "à noite, o halo cresce")
	assert_eq(night.wall_view.night, 1.0, "as paredes sabem que é noite: a luz do sol pelas janelas some")


func test_wood_trim_on_the_walls_and_the_low_front_wall() -> void:
	for color: Color in [WallView.CAP_RIGHT, WallView.CAP_LEFT, WallView.END_RIGHT, WallView.END_LEFT, FrontView.CAP_TOP]:
		assert_true(color.r > color.g and color.g > color.b and color.v < 0.6, "madeira escura: %s" % color.to_html())
	assert_eq(FrontView.CAP_TOP, WallView.CAP_RIGHT, "a mureta e as paredes com a mesma madeira")


func test_wall_lights_glow_at_night() -> void:
	var cafe := await _cafe_at(12.0)
	var sconce: WallItemDefinition = cafe.simulation.wall_items.get_definition(&"arandela")
	assert_true(sconce != null and sconce.is_valid(), "a arandela industrial está no catálogo")
	assert_true(sconce.glows_at_night and not sconce.lets_light_in, "acende à noite, mas não é janela")
	assert_eq(sconce.collection, &"anos2010", "da coleção industrial")
	assert_true(sconce.glow_color.r > sconce.glow_color.b, "luz quente")
	assert_true(ArtSprites.get_sprite("enfeite_arandela_R") != null and ArtSprites.get_sprite("enfeite_arandela_L") != null,
		"desenhada para as duas paredes")
	assert_true((cafe.simulation.wall_items.get_definition(&"neon_xicara") as WallItemDefinition).glows_at_night,
		"o neon de xícara também acende")
	for item: WallItemDefinition in cafe.simulation.wall_items.all():
		assert_false(item.glows_at_night and item.lets_light_in, "%s: ou é janela, ou acende" % item.id)
	cafe.build_bar.show_shop_tab(BuildBar.ShopTab.WALL)
	cafe.build_bar.show_shop_collection(&"anos2010")
	await settle()
	assert_true(cafe.build_bar.shop_item_ids().has(&"arandela"), "à venda na aba Paredes")
