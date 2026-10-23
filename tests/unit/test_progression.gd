extends TestCase
## Níveis e XP.


func _table(values: Array) -> LevelTable:
	var table := LevelTable.new()
	table.xp_to_reach = PackedInt32Array(values)
	return table


func test_level_data_file_is_valid_up_to_level_30() -> void:
	var table: LevelTable = load("res://data/progression/levels.tres")
	assert_true(table.is_valid())
	assert_eq(table.max_level(), 30, "o PO pediu o nível máximo 30")
	assert_eq(table.xp_to_reach[4], 280, "os níveis 1 a 5 continuam rápidos, para prender quem começa (DT-075)")
	assert_eq(table.xp_to_reach[9], 3450, "o nível 10 leva umas 2 horas de jogo ativo (DT-075)")
	assert_true(table.xp_to_reach[29] < 99999, "add_xp(99999) nos testes ainda chega ao nível 30")
	for i in range(2, table.xp_to_reach.size()):
		var step := table.xp_to_reach[i] - table.xp_to_reach[i - 1]
		var before := table.xp_to_reach[i - 1] - table.xp_to_reach[i - 2]
		assert_true(step > before, "cada nível pede mais XP que o anterior (nível %d)" % (i + 1))


## O save antigo vai para a curva nova sem o jogador perder nível (DT-075).
func test_old_saves_keep_their_level_on_the_new_curve() -> void:
	var table: LevelTable = load("res://data/progression/levels.tres")
	assert_eq(Array(table.xp_to_reach), SaveCodec.XP_CURVE_V24, "a migração conhece a curva que o jogo usa")
	var old_table := LevelTable.new()
	old_table.xp_to_reach = PackedInt32Array(SaveCodec.XP_CURVE_V23)
	for old_xp in [0, 29, 30, 279, 280, 1000, 3000, 13680, 45000, 45530, 50000]:
		var new_xp := SaveCodec.convert_xp(old_xp, SaveCodec.XP_CURVE_V23, SaveCodec.XP_CURVE_V24)
		assert_eq(table.level_for_xp(new_xp), old_table.level_for_xp(old_xp), "o nível continua com %d de XP" % old_xp)
	assert_eq(SaveCodec.convert_xp(3000, SaveCodec.XP_CURVE_V23, SaveCodec.XP_CURVE_V24), 4650 + floori(600.0 / 680.0 * 1400),
		"a mesma fração do caminho até o próximo nível")
	assert_eq(SaveCodec.convert_xp(50000, SaveCodec.XP_CURVE_V23, SaveCodec.XP_CURVE_V24), 95200 + 4470, "acima do máximo, o que sobra passa igual")
	var old_save := {"save_version": 23, "xp": 3000}
	var migrated := SaveCodec.migrate(old_save)
	assert_eq(table.level_for_xp(int(migrated["xp"])), 11, "o save do nível 11 continua no nível 11")


func test_high_levels_pay_gold_and_the_first_ten_do_not() -> void:
	var table: LevelTable = load("res://data/progression/levels.tres")
	for level in range(1, 11):
		assert_eq(table.gold_for(level), 0, "até o 10 o nível libera receitas e móveis (nível %d)" % level)
	assert_eq(table.gold_for(11), 275)
	assert_eq(table.gold_for(30), 750)
	for level in range(12, 31):
		assert_true(table.gold_for(level) > table.gold_for(level - 1), "cada nível alto dá mais ouro")
	assert_eq(table.gold_for(31), 0, "fora da tabela não dá nada")


func test_level_gold_validation() -> void:
	var table := _table([0, 10, 30])
	table.level_up_gold = PackedInt32Array([0, 5])
	assert_false(table.is_valid(), "uma recompensa por nível")
	table.level_up_gold = PackedInt32Array([0, 5, -1])
	assert_false(table.is_valid(), "sem ouro negativo")
	table.level_up_gold = PackedInt32Array([0, 5, 9])
	assert_true(table.is_valid())


func test_table_validation() -> void:
	assert_true(_table([0, 10, 30]).is_valid())
	assert_false(_table([5, 10]).is_valid(), "precisa começar em 0")
	assert_false(_table([0, 10, 10]).is_valid(), "precisa ser crescente")
	assert_false(_table([]).is_valid())


func test_level_for_xp_at_boundaries() -> void:
	var table := _table([0, 10, 30])
	assert_eq(table.level_for_xp(0), 1)
	assert_eq(table.level_for_xp(9), 1)
	assert_eq(table.level_for_xp(10), 2)
	assert_eq(table.level_for_xp(29), 2)
	assert_eq(table.level_for_xp(30), 3)
	assert_eq(table.level_for_xp(9999), 3)


func test_add_xp_levels_up_and_emits_once_per_level() -> void:
	var progression := PlayerProgression.new(_table([0, 10, 30, 60]))
	var levels: Array[int] = []
	progression.leveled_up.connect(func(l: int) -> void: levels.append(l))
	assert_eq(progression.add_xp(5), 0)
	assert_eq(progression.add_xp(30), 2, "pulou do nível 1 para o 3 de uma vez")
	assert_eq(progression.level, 3)
	assert_eq(levels, [2, 3] as Array[int])


func test_progress_inside_a_level() -> void:
	var progression := PlayerProgression.new(_table([0, 10, 30]))
	progression.add_xp(20)
	assert_almost_eq(progression.level_progress(), 0.5, 0.001, "20 de 10→30 é metade")


func test_max_level_keeps_counting_xp_without_leveling() -> void:
	var progression := PlayerProgression.new(_table([0, 10]))
	progression.add_xp(500)
	assert_eq(progression.level, 2)
	assert_true(progression.is_max_level())
	assert_eq(progression.xp, 500)
	assert_almost_eq(progression.level_progress(), 1.0)
	assert_eq(progression.add_xp(10), 0)


func test_non_positive_xp_is_ignored() -> void:
	var progression := PlayerProgression.new(_table([0, 10]))
	assert_eq(progression.add_xp(0), 0)
	assert_eq(progression.add_xp(-5), 0)
	assert_eq(progression.xp, 0)
