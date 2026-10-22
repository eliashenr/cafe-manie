extends TestCase
## Energia das máquinas de bebida (DT-052): começa cheia, cada bebida gasta, recarrega 1 ponto por intervalo
## (também com o jogo fechado) sem passar do máximo, e o máximo cresce com o nível.

var config: EnergyConfig
var clock: ManualClock


func _setup() -> Energy:
	config = load("res://data/config/energy.tres")
	clock = ManualClock.new()
	return Energy.new(config, clock.now())


func test_maximum_grows_with_the_level() -> void:
	config = load("res://data/config/energy.tres")
	assert_true(config.is_valid())
	assert_eq(config.max_at(1), config.base_max)
	assert_eq(config.max_at(1 + config.levels_per_extra_point), config.base_max + 1)
	assert_true(config.max_at(30) > config.max_at(10), "nível alto, mais energia")


func test_starts_full_and_spending_takes_points() -> void:
	var energy := _setup()
	assert_eq(energy.amount(clock.now()), config.base_max, "começa cheia")
	assert_true(energy.spend(3, clock.now()))
	assert_eq(energy.amount(clock.now()), config.base_max - 3)


func test_cannot_spend_more_than_there_is() -> void:
	var energy := _setup()
	assert_true(energy.spend(config.base_max - 1, clock.now()))
	assert_false(energy.spend(2, clock.now()), "faltou energia")
	assert_eq(energy.amount(clock.now()), 1, "e nada foi gasto")


func test_recharges_one_point_per_interval_up_to_the_maximum() -> void:
	var energy := _setup()
	energy.spend(4, clock.now())
	clock.advance(config.seconds_per_point * 0.99)
	assert_eq(energy.amount(clock.now()), config.base_max - 4, "ainda não deu o tempo de um ponto")
	clock.advance(config.seconds_per_point * 0.01 + 0.001)
	assert_eq(energy.amount(clock.now()), config.base_max - 3, "um ponto")
	clock.advance(config.seconds_per_point * 2.5)
	assert_eq(energy.amount(clock.now()), config.base_max - 1, "mais dois; o meio ponto continua contando")
	clock.advance(config.seconds_per_point * 10.0)
	assert_eq(energy.amount(clock.now()), config.base_max, "não passa do máximo")


func test_a_full_bar_does_not_bank_time() -> void:
	var energy := _setup()
	clock.advance(config.seconds_per_point * 50.0)  # cheia esse tempo todo
	energy.spend(2, clock.now())
	assert_eq(energy.amount(clock.now()), config.base_max - 2, "o tempo cheia não vira crédito")
	assert_almost_eq(energy.seconds_to_next(clock.now()), config.seconds_per_point, 0.001, "a recarga começa agora")


func test_seconds_to_next_point() -> void:
	var energy := _setup()
	assert_eq(energy.seconds_to_next(clock.now()), 0.0, "cheia: nada a esperar")
	energy.spend(1, clock.now())
	clock.advance(config.seconds_per_point / 4.0)
	assert_almost_eq(energy.seconds_to_next(clock.now()), config.seconds_per_point * 0.75, 0.001)


func test_recharges_while_the_game_is_closed() -> void:
	var energy := _setup()
	energy.spend(5, clock.now())
	var data: Dictionary = JSON.parse_string(JSON.stringify(energy.to_data()))
	clock.advance(config.seconds_per_point * 3.0)  # jogo fechado
	var loaded := Energy.new(config, clock.now())
	loaded.restore(data, clock.now())
	assert_eq(loaded.amount(clock.now()), config.base_max - 2, "3 pontos voltaram com o jogo fechado")


func test_a_clock_moved_back_gives_no_energy() -> void:
	var energy := _setup()
	clock.time = 1000.0
	energy = Energy.new(config, clock.now())
	energy.spend(3, clock.now())
	clock.time = 400.0  # relógio do aparelho voltou
	assert_eq(energy.amount(clock.now()), config.base_max - 3, "nada de energia de graça")
	clock.advance(config.seconds_per_point)
	assert_eq(energy.amount(clock.now()), config.base_max - 2, "e a recarga segue a partir daí")


func test_new_level_raises_the_maximum_and_refill_fills_it() -> void:
	var energy := _setup()
	energy.spend(6, clock.now())
	var level := 1 + config.levels_per_extra_point * 2
	energy.set_level(level, clock.now())
	assert_eq(energy.maximum(), config.max_at(level))
	assert_eq(energy.amount(clock.now()), config.base_max - 6, "o máximo cresce, a energia não")
	energy.refill(clock.now())
	assert_eq(energy.amount(clock.now()), config.max_at(level), "refill enche até o máximo novo")
