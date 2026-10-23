extends TestCase
## QA (23/10): save estragado ou editado à mão nos campos novos (portas, terraço, chão sujo, avatar, entregas, filial e
## vizinhos) carrega sem erro de script e cai em valores seguros.


func _broken_values() -> Array:
	return ["texto", 12, -5, [1, 2], {"x": 1}, null, true, 3.5]


func test_wrong_types_in_the_new_fields_load_safely() -> void:
	var clock := ManualClock.new()
	clock.time = 2_000_000
	var sim := CafeSimulation.create_new_game(clock, 3)
	for value in _broken_values():
		var data := SaveCodec.encode(sim)
		data["dirt"] = value
		data["avatar"] = value
		data["delivery"] = value
		data["branch"] = value
		data["neighbors"] = value
		var style: Dictionary = data["style"]
		style["door"] = value
		style["terrace"] = value
		var decoded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock, 3)
		assert_true(decoded != null and decoded.simulation != null, "carregou com %s" % [value])
		var loaded := decoded.simulation
		assert_eq(loaded.current_door().id, &"door_classico", "porta segura com %s" % [value])
		assert_true(loaded.avatar_part(AvatarPartDefinition.Slot.HAT) != null)
		assert_true(loaded.branch.level >= 1 and loaded.branch.level <= loaded.branch_config.max_level())
		assert_true(loaded.dirt.count() <= loaded.dirt_config.max_spots)


func test_wrong_types_inside_the_new_fields_load_safely() -> void:
	var clock := ManualClock.new()
	clock.time = 2_000_000
	var sim := CafeSimulation.create_new_game(clock, 3)
	for value in _broken_values():
		var data := SaveCodec.encode(sim)
		data["dirt"] = [value, [value, value], [1]]
		data["avatar"] = {"equipped": value, "owned": value}
		data["delivery"] = {"orders": [value, {"recipe": value, "servings": value, "gold": value, "xp": value}], "next_at": value}
		data["branch"] = {"open": value, "level": value, "since": value}
		data["neighbors"] = {"ana": value, "beto": {"day": value, "friendship": value}}
		var decoded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock, 3)
		var loaded := decoded.simulation
		assert_true(loaded != null, "carregou com %s" % [value])
		assert_true(loaded.branch.level >= 1 and loaded.branch.level <= loaded.branch_config.max_level(), "nível da filial com %s" % [value])
		assert_true(loaded.neighbor_visits.friendship(&"beto") >= 0)
		for order in loaded.delivery.orders:
			assert_true(order.recipe != null and order.servings >= 1)


## Cada campo do save, um de cada vez, com um valor do tipo errado: carrega sem erro de script (o executor reprova o
## teste em qualquer erro) e o café abre.
func test_every_field_with_a_wrong_type_loads_safely() -> void:
	var clock := ManualClock.new()
	clock.time = 2_000_000
	var sim := CafeSimulation.create_new_game(clock, 3)
	var base := SaveCodec.encode(sim)
	for key in base.keys():
		if key == "save_version":
			continue
		for value in _broken_values():
			var data := base.duplicate(true)
			data[key] = value
			var decoded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(JSON.stringify(data))), clock, 3)
			# sem a planta do café o save não tem uso: ele é recusado (sem erro) e o jogo recupera a cópia de segurança
			assert_true(decoded != null and (decoded.simulation != null or key == "layout"), "carregou com %s = %s" % [key, value])
	var old := base.duplicate(true)
	old["save_version"] = 23
	old["xp"] = [1, 2]
	assert_eq(int(SaveCodec.migrate(old)["xp"]), 0, "a conversão de XP também aguenta valor errado")


func test_safe_value_rules() -> void:
	assert_eq(SafeValue.to_int("12"), 12)
	assert_eq(SafeValue.to_int("texto", 7), 7, "texto que não é número vira o padrão")
	assert_eq(SafeValue.to_int(3.9), 3)
	assert_eq(SafeValue.to_int([1], 4), 4)
	assert_eq(SafeValue.to_int(null, -1), -1)
	assert_almost_eq(SafeValue.to_float("2.5"), 2.5, 0.001)
	assert_almost_eq(SafeValue.to_float("x", 1.5), 1.5, 0.001)
	assert_almost_eq(SafeValue.to_float({}, 9.0), 9.0, 0.001)
	assert_true(SafeValue.to_bool(true) and SafeValue.to_bool(1) and not SafeValue.to_bool(0))
	assert_true(SafeValue.to_bool("sim", true), "texto vira o padrão")
	assert_false(SafeValue.to_bool([1, 2]))
	assert_eq(SafeValue.to_array("x"), [])
	assert_eq(SafeValue.to_array([1]), [1])
