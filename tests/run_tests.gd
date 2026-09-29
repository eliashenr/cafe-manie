extends SceneTree
## Executor de testes do projeto.
##
## Uso (na pasta do projeto):
##   godot --headless --import
##   godot --headless -s res://tests/run_tests.gd
##
## Sai com código 0 se tudo passar e 1 se algo falhar. Um erro de script
## durante um teste também reprova o teste, para nunca haver falso sucesso.

const TEST_DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]


class ErrorCounter:
	extends Logger

	var count := 0
	var messages: Array[String] = []
	var _mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		count += 1
		var detail := rationale if not rationale.is_empty() else code
		messages.append("%s (%s:%d em %s)" % [detail, file, line, function])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _errors := ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(_errors)
	_run.call_deferred()


func _run() -> void:
	var passed := 0
	var failed := 0

	for dir_path in TEST_DIRS:
		for file_name in _test_files(dir_path):
			var script: GDScript = load(dir_path.path_join(file_name))
			print("\n", file_name)
			for method_name in _test_methods(script):
				var result := await _run_one(script, method_name)
				if result.is_empty():
					passed += 1
					print("  PASSOU  ", method_name)
				else:
					failed += 1
					print("  FALHOU  ", method_name)
					for reason in result:
						print("          - ", reason)

	print("\n%d passaram, %d falharam" % [passed, failed])
	OS.remove_logger(_errors)
	quit(1 if failed > 0 or passed == 0 else 0)


func _run_one(script: GDScript, method_name: String) -> Array[String]:
	var errors_before := _errors.count
	var test: TestCase = script.new()
	test.tree = self
	await test.call(method_name)
	test.cleanup()
	await process_frame

	var reasons: Array[String] = test.failures.duplicate()
	if _errors.count > errors_before:
		for message in _errors.messages.slice(errors_before):
			reasons.append("erro durante o teste: " + message)
	return reasons


func _test_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			files.append(file_name)
	files.sort()
	return files


func _test_methods(script: GDScript) -> PackedStringArray:
	var names := PackedStringArray()
	for method in script.get_script_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names
