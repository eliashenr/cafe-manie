extends TestCase
## Pacotes de Café Ouro por dinheiro de verdade: dados válidos, taxa que melhora nos pacotes maiores e
## ouro que só entra quando o provedor de pagamento confirma.


## Provedor de mentira (só nos testes): responde o que o teste mandar.
class FakeProvider:
	extends PaymentProvider
	var answer := CoinShop.Result.OK
	var asked: Array[String] = []

	func is_available() -> bool:
		return true

	func purchase(product_id: String) -> int:
		asked.append(product_id)
		return answer


func test_packs_load_valid_in_order_and_bigger_packs_give_more_gold_per_real() -> void:
	var shop := CoinShop.load_from(Wallet.new())
	var packs := shop.packs()
	assert_eq(packs.size(), 5)
	var last_rate := 0.0
	var last_price := 0
	var products := {}
	for pack in packs:
		assert_true(pack.is_valid(), "%s inválido" % pack.id)
		assert_true(pack.price_cents > last_price, "do mais barato ao mais caro")
		assert_true(pack.gold_per_real() > last_rate, "%s dá mais ouro por real que o anterior" % pack.id)
		last_rate = pack.gold_per_real()
		last_price = pack.price_cents
		products[pack.product_id] = true
	assert_eq(products.size(), packs.size(), "cada pacote com o seu produto na loja")
	assert_eq(packs[0].price_text(), "R$ 4,90")
	assert_true(packs[0].gold_per_real() >= 90.0 and packs[0].gold_per_real() <= 120.0, "uns 100 de ouro por real no menor")


func test_this_build_never_hands_out_gold() -> void:
	var wallet := Wallet.new()
	var shop := CoinShop.load_from(wallet)
	assert_false(shop.is_available(), "sem Play Store, sem compra")
	assert_eq(shop.buy(&"punhado"), CoinShop.Result.UNAVAILABLE)
	assert_eq(wallet.balance(Wallet.SOFT), 0, "nada de ouro sem pagamento")


func test_gold_only_arrives_when_the_payment_is_confirmed() -> void:
	var wallet := Wallet.new()
	var provider := FakeProvider.new()
	var shop := CoinShop.load_from(wallet, provider)
	var finished := []
	shop.purchase_finished.connect(func(pack: CoinPack, result: int) -> void: finished.append([pack.id, result]))
	provider.answer = CoinShop.Result.CANCELLED
	assert_eq(shop.buy(&"saco"), CoinShop.Result.CANCELLED)
	provider.answer = CoinShop.Result.FAILED
	assert_eq(shop.buy(&"saco"), CoinShop.Result.FAILED)
	assert_eq(wallet.balance(Wallet.SOFT), 0, "cancelada ou recusada: nada muda")
	provider.answer = CoinShop.Result.OK
	assert_eq(shop.buy(&"saco"), CoinShop.Result.OK)
	assert_eq(wallet.balance(Wallet.SOFT), shop.get_pack(&"saco").gold)
	assert_eq(provider.asked, ["cafe_ouro_1200", "cafe_ouro_1200", "cafe_ouro_1200"] as Array[String], "cobra pelo produto da loja")
	assert_eq(finished.size(), 3)
	assert_eq(shop.buy(&"nao_existe"), CoinShop.Result.UNKNOWN_PACK)


func test_shop_rejects_bad_packs() -> void:
	var shop := CoinShop.new(Wallet.new())
	var pack := CoinPack.new()
	pack.id = &"x"
	pack.display_name = "X"
	pack.product_id = "x"
	pack.gold = 10
	pack.price_cents = 100
	assert_true(shop.add(pack))
	assert_false(shop.add(pack), "id repetido")
	var free := pack.duplicate()
	free.id = &"y"
	free.price_cents = 0
	assert_false(shop.add(free), "pacote de graça não existe")
