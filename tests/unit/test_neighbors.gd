extends TestCase
## Vizinhos simulados (DT-074): visitar e ajudar cada vizinho uma vez por dia dá ouro (mais para café mais avançado
## e para amizade maior) e XP; a amizade cresce a cada visita, até o máximo.

const DAY := 86400.0

var clock: ManualClock
var sim: CafeSimulation


func _setup() -> void:
	clock = ManualClock.new()
	clock.time = Time.get_unix_time_from_datetime_string("2026-10-20T12:00:00") - ManualClock.new().utc_offset_seconds()
	sim = CafeSimulation.with_game_data(clock, CafeLayout.new(Vector2i(8, 8), Vector2i(7, 4)), FurnitureCatalog.load_from(), 5)
	sim.customer_types.clear()


func test_the_neighbors_and_config_are_valid() -> void:
	_setup()
	assert_eq(sim.neighbors.size(), 7, "os 7 vizinhos da faixa")
	for neighbor: NeighborDefinition in sim.neighbors.all():
		assert_true(neighbor.is_valid(), String(neighbor.id))
	assert_true(sim.neighbors_config.is_valid())
	var broken: NeighborDefinition = sim.neighbors.get_definition(&"ana").duplicate()
	broken.help_text = ""
	assert_false(broken.is_valid(), "sem o que fazer na visita")
	var config: NeighborsConfig = sim.neighbors_config.duplicate()
	config.max_friendship = 0
	assert_false(config.is_valid(), "sem corações")


func test_a_visit_pays_gold_and_xp_once_a_day() -> void:
	_setup()
	var ana: NeighborDefinition = sim.neighbors.get_definition(&"ana")
	var config := sim.neighbors_config
	var gold := sim.wallet.balance(Wallet.SOFT)
	var xp := sim.progression.xp
	var expected := config.visit_gold + config.visit_gold_per_level * ana.level
	assert_eq(sim.neighbor_reward(&"ana"), expected)
	var visited := []
	sim.neighbor_visited.connect(func(n: NeighborDefinition, g: int) -> void: visited.append([n.id, g]))
	assert_true(sim.can_visit_neighbor(&"ana"))
	assert_eq(sim.visit_neighbor(&"ana"), ServiceResult.OK)
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + expected)
	assert_eq(sim.progression.xp, xp + config.visit_xp)
	assert_eq(visited, [[&"ana", expected]])
	assert_eq(sim.neighbor_visits.friendship(&"ana"), 1, "um coração")
	assert_false(sim.can_visit_neighbor(&"ana"))
	assert_eq(sim.visit_neighbor(&"ana"), ServiceResult.ALREADY_VISITED, "uma vez por dia")
	assert_eq(sim.wallet.balance(Wallet.SOFT), gold + expected, "a segunda visita não paga")
	assert_true(sim.can_visit_neighbor(&"beto"), "os outros vizinhos continuam livres")
	assert_eq(sim.visit_neighbor(&"ninguem"), ServiceResult.UNKNOWN_ITEM)


func test_friendship_grows_each_day_up_to_the_max_and_pays_more() -> void:
	_setup()
	var config := sim.neighbors_config
	var first := sim.neighbor_reward(&"caio")
	sim.visit_neighbor(&"caio")
	clock.advance(DAY)
	assert_true(sim.can_visit_neighbor(&"caio"), "no dia seguinte, pode de novo")
	assert_eq(sim.neighbor_reward(&"caio"), roundi(first * (1.0 + config.gold_per_friendship)), "a amizade aumenta o ouro")
	for i in config.max_friendship + 3:
		sim.visit_neighbor(&"caio")
		clock.advance(DAY)
	assert_eq(sim.neighbor_visits.friendship(&"caio"), config.max_friendship, "para no máximo")


func test_a_richer_neighbor_pays_more() -> void:
	_setup()
	assert_true(sim.neighbor_reward(&"vo_cida") > sim.neighbor_reward(&"rafa"), "café de nível maior, visita mais rica")


func test_the_save_keeps_the_visits() -> void:
	_setup()
	sim.visit_neighbor(&"lia")
	var text := JSON.stringify(SaveCodec.encode(sim))
	var loaded := SaveCodec.decode(SaveCodec.migrate(JSON.parse_string(text)), clock, 5).simulation
	assert_false(loaded.can_visit_neighbor(&"lia"), "a visita de hoje continua")
	assert_eq(loaded.neighbor_visits.friendship(&"lia"), 1)
	var old := SaveCodec.encode(sim)
	old["save_version"] = 22
	old.erase("neighbors")
	var migrated := SaveCodec.migrate(JSON.parse_string(JSON.stringify(old)))
	assert_eq(migrated["neighbors"], {}, "a migração começa sem visitas")
