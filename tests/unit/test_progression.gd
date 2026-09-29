extends TestCase
## Níveis e XP.


func _table(values: Array) -> LevelTable:
	var table := LevelTable.new()
	table.xp_to_reach = PackedInt32Array(values)
	return table


func test_level_data_file_is_valid_with_ten_levels() -> void:
	var table: LevelTable = load("res://data/progression/levels.tres")
	assert_true(table.is_valid())
	assert_eq(table.max_level(), 10, "o MVP vai até o nível 10 (seção 119)")


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
