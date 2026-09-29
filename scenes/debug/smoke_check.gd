class_name SmokeCheck
extends Node
## Checagem rápida do jogo exportado (o .exe/.x86_64), sem abrir janela:
##
##   CafeManie.exe --headless -- --smoke-check
##
## Sobe a cafeteria, deixa rodar alguns segundos de jogo, confere se o
## conteúdo de res://data carregou e se nenhum erro apareceu, imprime
## "SMOKE OK ..." (ou "SMOKE FALHOU ...") e fecha com código 0 ou 1.
## Não salva nada: o save do jogador não é tocado.

const ARGUMENT := "--smoke-check"
## Quadros de jogo antes de conferir.
@export var frames_to_run := 600


class ErrorCounter:
	extends Logger

	var messages: Array[String] = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		messages.append("%s (%s:%d em %s)" % [rationale if not rationale.is_empty() else code, file, line, function])
		_mutex.unlock()


var _errors := ErrorCounter.new()
var _frames := 0


static func requested() -> bool:
	return ARGUMENT in OS.get_cmdline_user_args()


func _enter_tree() -> void:
	OS.add_logger(_errors)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == frames_to_run:
		_finish()


func _finish() -> void:
	var cafe := get_parent() as Cafe
	var sim := cafe.simulation
	var problems: Array[String] = []
	var counts := {
		"moveis": sim.furniture.all().size(),
		"receitas": sim.recipes.all().size(),
		"clientes": sim.customer_types.size(),
		"missoes": sim.missions.missions.size(),
		"expansoes": sim.expansions.steps.size(),
		"moveis_na_cafeteria": sim.layout.count(),
	}
	for key in counts:
		if counts[key] == 0:
			problems.append("nada carregado em " + key)
	if not sim.expansions.is_valid():
		problems.append("expansões inválidas")
	problems.append_array(_errors.messages)
	OS.remove_logger(_errors)
	var summary := " ".join(counts.keys().map(func(k: String) -> String: return "%s=%d" % [k, counts[k]]))
	if problems.is_empty():
		print("SMOKE OK ", summary)
	else:
		print("SMOKE FALHOU ", summary)
		for problem in problems:
			print("  - ", problem)
	get_tree().quit(0 if problems.is_empty() else 1)
