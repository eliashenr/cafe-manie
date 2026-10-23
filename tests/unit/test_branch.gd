extends TestCase
## Filial na praia (DT-072): abrir custa ouro (a partir de um nível); aberta, ela junta ouro por hora até o limite do
## nível, também com o jogo fechado; coletar dá o ouro e um pouco de XP; melhorar aumenta o rendimento e o cardápio.

var clock: ManualClock
var sim: CafeSimulation

const HOUR := 3600.0


func _setup() -> void:
	clock = ManualClock.new()
	clock.time = 1_000_000
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 5)
	sim.customer_types.clear()


## Abre a filial com nível e ouro de sobra; devolve o ouro que sobrou.
func _open() -> int:
	sim.progression.add_xp(99999)
	sim.wallet.earn(Wallet.SOFT, sim.branch_config.open_price, "teste")
	assert_eq(sim.open_branch(), ServiceResult.OK)
	return sim.wallet.balance(Wallet.SOFT)


func test_the_branch_config_is_valid() -> void:
	var config: BranchConfig = load("res://data/config/branch.tres")
	assert_true(config.is_valid())
	assert_eq(config.max_level(), 4)
	var broken: BranchConfig = config.duplicate()
	broken.dishes = ["Só um"] as Array[String]
	assert_false(broken.is_valid(), "um prato por nível")
	broken = config.duplicate()
	broken.income_per_hour = [240, 200, 660, 960] as Array[int]
	assert_false(broken.is_valid(), "melhorar não pode render menos")
	broken = config.duplicate()
	broken.upgrade_prices = [1] as Array[int]
	assert_false(broken.is_valid(), "um preço por melhoria")


func test_opening_checks_level_and_gold_and_charges_once() -> void:
	_setup()
	assert_eq(sim.open_branch(), ServiceResult.BRANCH_LOCKED)
	sim.progression.add_xp(99999)
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "teste")
	assert_eq(sim.open_branch(), ServiceResult.NOT_ENOUGH_GOLD)
	assert_false(sim.branch.opened)
	sim.wallet.earn(Wallet.SOFT, sim.branch_config.open_price + 5, "teste")
	assert_eq(sim.open_branch(), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 5, "cobrou a abertura")
	assert_true(sim.branch.opened)
	assert_eq(sim.branch.level, 1)
	assert_eq(sim.branch.dishes(), ["Açaí na tigela"] as Array[String], "um prato no começo")
	assert_eq(sim.open_branch(), ServiceResult.ALREADY_BUILT)
	assert_eq(sim.wallet.balance(Wallet.SOFT), 5)


func test_gold_builds_up_by_the_hour_until_the_cap() -> void:
	_setup()
	assert_eq(sim.collect_branch(), ServiceResult.BRANCH_CLOSED)
	sim.wallet.earn(Wallet.SOFT, 99999, "teste")
	assert_eq(sim.upgrade_branch(), ServiceResult.BRANCH_CLOSED, "fechada não melhora")
	assert_eq(sim.branch.gold_ready(clock.now()), 0, "fechada não junta ouro")
	assert_eq(sim.branch.level, 1)
	_open()
	assert_eq(sim.collect_branch(), ServiceResult.NOTHING_TO_COLLECT, "recém-aberta, nada guardado")
	clock.advance(HOUR * 2)
	assert_eq(sim.branch.gold_ready(clock.now()), 2 * sim.branch.income_per_hour(), "duas horas de ouro")
	clock.advance(HOUR * 100)
	var cap := floori(sim.branch.capacity_hours() * sim.branch.income_per_hour())
	assert_eq(sim.branch.gold_ready(clock.now()), cap, "para no limite do nível")
	assert_eq(sim.branch.seconds_until_full(clock.now()), 0.0)


func test_collecting_gives_gold_and_xp_and_starts_over() -> void:
	_setup()
	var gold := _open()
	clock.advance(HOUR * 3)
	var amount := sim.branch.gold_ready(clock.now())
	var xp := sim.progression.xp
	var collected := []
	sim.branch_collected.connect(func(value: int) -> void: collected.append(value))
	assert_eq(sim.collect_branch(), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + amount)
	assert_eq(sim.progression.xp, xp + amount * sim.branch_config.xp_per_100_gold / 100)
	assert_eq(collected, [amount])
	assert_eq(sim.branch.gold_ready(clock.now()), 0, "a conta recomeça")
	assert_almost_eq(sim.branch.seconds_until_full(clock.now()), sim.branch.capacity_hours() * HOUR, 1.0)


func test_upgrading_collects_first_and_raises_income_and_menu() -> void:
	_setup()
	_open()
	clock.advance(HOUR)
	var waiting := sim.branch.gold_ready(clock.now())
	var price := sim.branch.upgrade_price()
	var income := sim.branch.income_per_hour()
	sim.wallet.spend(Wallet.SOFT, sim.wallet.balance(Wallet.SOFT), "teste")
	sim.wallet.earn(Wallet.SOFT, price - waiting - 1, "teste")
	assert_eq(sim.upgrade_branch(), ServiceResult.NOT_ENOUGH_GOLD, "o ouro guardado não conta antes de coletar")
	assert_eq(sim.branch.level, 1)
	sim.wallet.earn(Wallet.SOFT, waiting + 1, "teste")
	assert_eq(sim.upgrade_branch(), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), waiting, "coletou o guardado e pagou a melhoria")
	assert_eq(sim.branch.level, 2)
	assert_true(sim.branch.income_per_hour() > income, "rende mais")
	assert_eq(sim.branch.dishes().size(), 2, "mais um prato no cardápio")
	assert_eq(sim.branch.gold_ready(clock.now()), 0)
	assert_eq(sim.branch.upgrade_price(), sim.branch_config.upgrade_prices[1], "a próxima melhoria tem o preço do nível 2")
	clock.advance(HOUR)
	assert_eq(sim.branch.gold_ready(clock.now()), sim.branch_config.income_per_hour[1], "o ouro novo vem no rendimento do nível 2")
	sim.wallet.earn(Wallet.SOFT, 999999, "teste")
	for i in sim.branch_config.max_level():  # no máximo uma melhoria por nível
		if sim.branch.is_max_level():
			break
		assert_eq(sim.upgrade_branch(), ServiceResult.OK)
	assert_eq(sim.branch.level, sim.branch_config.max_level())
	assert_eq(sim.upgrade_branch(), ServiceResult.NO_MORE_UPGRADES)


func test_a_clock_set_back_does_not_freeze_the_branch() -> void:
	_setup()
	_open()
	clock.advance(-2.0 * 86400.0)  # alguém atrasou o relógio do aparelho em 2 dias
	assert_eq(sim.branch.gold_ready(clock.now()), 0)
	clock.advance(HOUR)
	assert_eq(sim.branch.gold_ready(clock.now()), sim.branch.income_per_hour(), "uma hora depois, já rendeu uma hora")


func test_the_save_keeps_the_branch() -> void:
	_setup()
	_open()
	sim.wallet.earn(Wallet.SOFT, 99999, "teste")
	sim.upgrade_branch()
	clock.advance(HOUR * 2)
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 5).simulation
	assert_true(loaded.branch.opened)
	assert_eq(loaded.branch.level, 2)
	assert_eq(loaded.branch.gold_ready(clock.now()), sim.branch.gold_ready(clock.now()), "o ouro guardado continua")
	var old := SaveCodec.encode(sim)
	old["save_version"] = 21
	old.erase("branch")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["branch"], {}, "a migração começa com a filial fechada")
	assert_false(SaveCodec.decode(migrated, clock, 5).simulation.branch.opened)
