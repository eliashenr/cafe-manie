extends TestCase
## Loja de troca (DT-062): itens exclusivos que só se trocam por cupons do crítico, em temporadas que giram a cada
## 2 semanas. Trocar gasta cupons (e não ouro); o item guardado volta de graça, mesmo fora da temporada.

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	sim = CafeSimulation.create_new_game(clock, 11)
	sim.wallet.earn(Wallet.SOFT, 1000, "teste")


func _exclusives() -> Array[FurnitureDefinition]:
	var result: Array[FurnitureDefinition] = []
	for definition in FurnitureCatalog.load_from().all():
		if definition.coupon_price > 0:
			result.append(definition)
	return result


func test_the_exclusive_items_are_valid_and_cover_every_season() -> void:
	var config: CriticConfig = load("res://data/config/critic.tres")
	var seasons := {}
	assert_true(_exclusives().size() >= 4)
	for item in _exclusives():
		assert_true(item.is_valid(), String(item.id))
		assert_false(item.sold_for_gold, "%s não se compra com ouro" % item.id)
		seasons[item.coupon_season] = true
	for season in config.shop_seasons:
		assert_true(seasons.has(season), "a temporada %d tem itens" % season)
	var broken: FurnitureDefinition = _exclusives()[0].duplicate()
	broken.sold_for_gold = true
	assert_false(broken.is_valid(), "item de cupom à venda por ouro")


func test_the_shop_changes_items_every_season() -> void:
	_setup()
	var first := sim.coupon_shop_items()
	assert_false(first.is_empty())
	for item in first:
		assert_true(item.coupon_season < 0 or item.coupon_season == sim.coupon_season())
	clock.advance(sim.seconds_until_new_season() + 1.0)
	var second := sim.coupon_shop_items()
	assert_true(sim.coupon_season() != first[0].coupon_season, "a temporada mudou")
	for item in second:
		assert_false(first.has(item) and item.coupon_season >= 0, "%s era da temporada passada" % item.id)


func test_trading_coupons_for_an_item() -> void:
	_setup()
	var item := sim.coupon_shop_items()[0]
	assert_eq(sim.can_acquire(item), ServiceResult.NOT_ENOUGH_COUPONS)
	sim.wallet.earn(Wallet.COUPONS, item.coupon_price + 3, "teste")
	var gold := sim.wallet.balance(Wallet.SOFT)
	assert_eq(sim.acquire_and_place(item, Vector2i(5, 5), 0), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.COUPONS), 3, "gastou os cupons")
	assert_true(sim.wallet.balance(Wallet.SOFT) >= gold, "e nenhum ouro gasto (só o prêmio de alguma missão de compra)")
	var off_season: FurnitureDefinition = null
	for other in _exclusives():
		if not sim.coupon_shop_items().has(other):
			off_season = other
	assert_eq(sim.can_acquire(off_season), ServiceResult.NOT_IN_SEASON)
	sim.store_furniture(sim.last_placed_id)
	clock.advance(sim.seconds_until_new_season() + 1.0)
	assert_false(sim.coupon_shop_items().has(item), "a temporada do item passou")
	assert_eq(sim.can_acquire(item), ServiceResult.OK, "o guardado volta de graça")
	assert_eq(sim.acquire_and_place(item, Vector2i(5, 5), 0), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.COUPONS), 3, "sem gastar cupons de novo")
