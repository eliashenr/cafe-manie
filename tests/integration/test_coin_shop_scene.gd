extends CafeTestCase
## Na tela: o "+" do ouro abre a vitrine de pacotes; neste build a compra explica que ainda não existe;
## com um provedor que confirma, o ouro entra; faltando ouro numa compra, a vitrine é oferecida (sem insistir).


class FakeProvider:
	extends PaymentProvider

	func is_available() -> bool:
		return true

	func purchase(_product_id: String) -> int:
		return CoinShop.Result.OK


func test_plus_button_shows_the_packs_and_this_build_explains_it_is_not_available_yet() -> void:
	var cafe := await spawn_cafe()
	var buy := cafe.hud.find_child("BuyGoldButton", true, false) as Button
	assert_true(buy != null, "o contador de ouro tem o +")
	buy.pressed.emit()
	await settle()
	var dialog := cafe.hud.coin_dialog()
	assert_true(dialog.visible, "a vitrine abre")
	var packs := dialog.find_child("CoinPacks", true, false)
	assert_eq(packs.get_child_count(), 5)
	var first := packs.get_child(0) as Button
	assert_true(first.text.contains("R$ 4,90") and first.text.contains("500"), first.text)
	assert_true((packs.get_child(4) as Button).text.contains("+"), "os pacotes maiores mostram o bônus")
	assert_true(dialog.find_child("CoinNote", true, false).text.contains("Play Store"), "avisa que a compra ainda não existe")
	first.pressed.emit()
	await settle()
	assert_true(cafe.hud.coin_info_dialog().visible, "explica que nada foi cobrado")
	assert_false(dialog.visible)
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200, "nada de ouro")


func test_confirmed_payment_adds_the_gold() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.coin_shop.provider = FakeProvider.new()
	cafe.hud.show_coin_shop()
	await settle()
	(cafe.hud.coin_dialog().find_child("Pack_saco", true, false) as Button).pressed.emit()
	await settle()
	assert_eq(cafe.simulation.wallet.balance(Wallet.SOFT), 200 + cafe.simulation.coin_shop.get_pack(&"saco").gold)
	assert_false(cafe.hud.coin_dialog().visible)
	assert_true(all_messages(cafe).contains("Compra concluída"), all_messages(cafe))


func test_running_out_of_gold_offers_the_packs_once_in_a_while() -> void:
	var cafe := await spawn_cafe()
	cafe.simulation.wallet.spend(Wallet.SOFT, cafe.simulation.wallet.balance(Wallet.SOFT), "zerar")
	cafe.layout.place(cafe.catalog.get_definition(&"stove_basic"), Vector2i(0, 0), 3)
	cafe.select_at_world(IsoProjection.cell_center(Vector2i(0, 0)))
	assert_eq(cafe.cook_on_selected(&"coffee"), ServiceResult.NOT_ENOUGH_GOLD)
	await settle()
	assert_true(cafe.hud.coin_dialog().visible, "faltou ouro: a vitrine aparece")
	assert_true(cafe.hud.coin_dialog().find_child("CoinNote", true, false).text.begins_with("Faltou"))
	cafe.hud.coin_dialog().hide()
	cafe.cook_on_selected(&"coffee")
	await settle()
	assert_false(cafe.hud.coin_dialog().visible, "não insiste logo em seguida")
