extends SceneTree
## Desempenho com o café cheio (FAÇA QA): monta o café no tamanho máximo, com fogões, balcões, mesas, enfeites, todos
## os garçons e o movimento de clientes no máximo, e mede quanto tempo cada quadro leva (sem limite de quadros por
## segundo, com o desenho de verdade).
##
##   godot -s res://tools/perf_check.gd -- [segundos medidos] [multiplicador de clientes, para estresse]

const WARMUP_FRAMES := 120

var _cafe: Node
var _sim
var _frames := 0
var _last := 0
var _times: Array[int] = []
var _measure_seconds := 20.0
var _measured := 0.0
var _max_customers := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_measure_seconds = float(args[0])
	var rush := float(args[1]) if args.size() > 1 else 1.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var clock = load("res://core/time/manual_clock.gd").new()
	clock.time = Time.get_unix_time_from_datetime_string("2026-03-03T12:00:00")
	_sim = load("res://core/service/cafe_simulation.gd").create_new_game(clock, 7)
	_sim.progression.add_xp(99999)
	_sim.wallet.earn(&"soft_currency", 9999999, "desempenho")
	for i in 20:
		if _sim.expand() != 0:
			break
	for i in 10:
		if _sim.hire_waiter() != 0:
			break
	_sim.restore_popularity(100.0)
	_sim.config = _sim.config.duplicate()
	_sim.config.spawn_interval /= rush
	_sim.config.max_customers = roundi(_sim.config.max_customers * rush)
	_fill()
	_cafe = load("res://scenes/cafe/cafe.tscn").instantiate()
	_cafe.simulation = _sim
	_cafe.get_node("SoundBoard").settings_path = ""
	root.add_child(_cafe)


## Fogões e balcões na parede do fundo, mesas com cadeiras pelo salão e enfeites nos cantos que sobrarem.
func _fill() -> void:
	var size: Vector2i = _sim.layout.grid.size
	for x in range(0, size.x - 1):
		_sim.acquire_and_place(_sim.furniture.get_definition(&"stove_basic" if x % 3 != 2 else &"counter_basic"), Vector2i(x, 0), 0)
	for y in range(3, size.y - 1, 2):
		for x in range(2, size.x - 1, 3):
			if _sim.acquire_and_place(_sim.furniture.get_definition(&"table_round"), Vector2i(x, y), 0) == 0:
				_sim.acquire_and_place(_sim.furniture.get_definition(&"chair_wood"), Vector2i(x - 1, y), 3)
				_sim.acquire_and_place(_sim.furniture.get_definition(&"chair_wood"), Vector2i(x + 1, y), 1)
	for y in range(2, size.y - 1):
		_sim.acquire_and_place(_sim.furniture.get_definition(&"plant_pot"), Vector2i(0, y), 0)


func _process(_delta: float) -> bool:
	_frames += 1
	var now := Time.get_ticks_usec()
	if _frames > WARMUP_FRAMES:
		_times.append(now - _last)
		_measured += (now - _last) / 1000000.0
	_last = now
	_max_customers = maxi(_max_customers, _sim.customers.size())
	if _frames % 30 == 0:
		_cook()
	if _measured >= _measure_seconds:
		_report()
		return true
	return false


func _cook() -> void:
	for placement in _sim.layout.placements():
		if _sim.kitchen.is_stove(placement.id) and _sim.kitchen.stove_status(placement.id) == 0:
			_sim.start_cooking(placement.id, &"coffee")


func _report() -> void:
	var sorted := _times.duplicate()
	sorted.sort()
	var total := 0
	for t in _times:
		total += t
	var average := total / float(_times.size()) / 1000.0
	var p95: float = sorted[int(sorted.size() * 0.95)] / 1000.0
	var worst: float = sorted[-1] / 1000.0
	print("=== Desempenho: café %s, %d móveis, %d garçons, até %d clientes ao mesmo tempo ===" % [_sim.layout.grid.size,
		_sim.layout.count(), _sim.waiters.size(), _max_customers])
	print("quadros medidos: %d em %.1f s" % [_times.size(), _measured])
	print("média %.2f ms (%.0f quadros por segundo), 95%% abaixo de %.2f ms, pior quadro %.2f ms" % [average, 1000.0 / average,
		p95, worst])
	print("nós na cena: %d, memória estática: %.1f MB" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
