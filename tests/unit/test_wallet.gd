extends TestCase
## Carteira: ganhos, gastos, recusas e registro de transações.


func test_starts_empty_for_any_currency() -> void:
	var wallet := Wallet.new()
	assert_eq(wallet.balance(Wallet.SOFT), 0)
	assert_eq(wallet.balance(Wallet.PREMIUM), 0)


func test_earn_and_spend_update_balance_and_notify() -> void:
	var wallet := Wallet.new()
	var seen: Array = []
	wallet.balance_changed.connect(func(c: StringName, b: int) -> void: seen.append([c, b]))
	assert_true(wallet.earn(Wallet.SOFT, 100, "teste"))
	assert_true(wallet.spend(Wallet.SOFT, 30, "teste"))
	assert_eq(wallet.balance(Wallet.SOFT), 70)
	assert_eq(seen, [[Wallet.SOFT, 100], [Wallet.SOFT, 70]])


func test_cannot_spend_more_than_balance() -> void:
	var wallet := Wallet.new()
	wallet.earn(Wallet.SOFT, 20, "teste")
	assert_false(wallet.spend(Wallet.SOFT, 21, "caro demais"))
	assert_eq(wallet.balance(Wallet.SOFT), 20, "recusa não mexe no saldo")
	assert_true(wallet.spend(Wallet.SOFT, 20, "exato"))
	assert_eq(wallet.balance(Wallet.SOFT), 0)


func test_rejects_zero_and_negative_amounts() -> void:
	var wallet := Wallet.new()
	wallet.earn(Wallet.SOFT, 10, "teste")
	assert_false(wallet.earn(Wallet.SOFT, 0, "zero"))
	assert_false(wallet.earn(Wallet.SOFT, -50, "negativo não pode virar ganho"))
	assert_false(wallet.spend(Wallet.SOFT, -50, "negativo não pode virar gasto"))
	assert_eq(wallet.balance(Wallet.SOFT), 10)


func test_currencies_are_independent() -> void:
	var wallet := Wallet.new()
	wallet.earn(Wallet.PREMIUM, 5, "teste")
	assert_false(wallet.spend(Wallet.SOFT, 1, "sem ouro"))
	assert_eq(wallet.balance(Wallet.PREMIUM), 5)


func test_history_records_every_change_with_reason() -> void:
	var wallet := Wallet.new()
	wallet.earn(Wallet.SOFT, 50, "cliente pagou")
	wallet.spend(Wallet.SOFT, 20, "ingredientes")
	wallet.spend(Wallet.SOFT, 999, "recusado não entra")
	var history := wallet.history()
	assert_eq(history.size(), 2)
	assert_eq(history[1], {"currency": Wallet.SOFT, "delta": -20, "balance": 30, "reason": "ingredientes"})


func test_history_is_capped() -> void:
	var wallet := Wallet.new()
	for i in Wallet.LOG_LIMIT + 10:
		wallet.earn(Wallet.SOFT, 1, "moeda %d" % i)
	assert_eq(wallet.history().size(), Wallet.LOG_LIMIT)
	assert_eq(wallet.history()[-1]["reason"], "moeda %d" % (Wallet.LOG_LIMIT + 9), "mantém as mais recentes")
