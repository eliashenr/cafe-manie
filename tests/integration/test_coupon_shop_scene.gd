extends CafeTestCase
## Loja de troca na cena (DT-062): a aba Cupons mostra os itens da temporada com o preço em cupons, quantos cupons o
## jogador tem e quando chegam itens novos; trocar gasta os cupons.


func _coupon_cafe(coupons := 0) -> Cafe:
	var simulation := quiet_simulation()
	simulation.wallet.earn(Wallet.COUPONS, coupons, "teste")
	var cafe := await spawn_cafe(simulation)
	cafe.build_bar.open_shop(BuildBar.ShopTab.COUPONS)
	await settle()
	return cafe


func test_the_coupon_tab_shows_the_season_items() -> void:
	var cafe := await _coupon_cafe(7)
	assert_true(cafe.build_bar.find_button("Tab_COUPONS") != null, "a aba Cupons existe")
	var ids := cafe.build_bar.shop_item_ids()
	for item in cafe.simulation.coupon_shop_items():
		assert_true(ids.has(item.id), "%s está na aba" % item.id)
		var card := cafe.build_bar.find_button("Build_" + String(item.id))
		assert_true(card.text.contains("%d cupons" % item.coupon_price), card.text)
		assert_eq(card.disabled, item.coupon_price > 7, "apagado se faltam cupons")
	assert_true(cafe.build_bar.message_text().contains("você tem 7 cupons"), cafe.build_bar.message_text())
	assert_true(cafe.build_bar.message_text().contains("itens novos em"), cafe.build_bar.message_text())


func test_trading_from_the_tab_spends_coupons() -> void:
	var cafe := await _coupon_cafe(100)
	var item := cafe.simulation.coupon_shop_items()[0]
	buy_in_shop(cafe, cafe.build_bar.find_button("Build_" + String(item.id)))
	await settle()
	assert_eq(cafe.mode, Cafe.Mode.BUILD, "escolhido, vai para o lugar")
	cafe._on_tapped(IsoProjection.cell_center(Vector2i(5, 5)))
	cafe._on_tapped(IsoProjection.cell_center(Vector2i(5, 5)))
	await settle()
	assert_eq(cafe.simulation.wallet.balance(Wallet.COUPONS), 100 - item.coupon_price, "os cupons saem ao posicionar")
