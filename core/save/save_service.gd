class_name SaveService
extends RefCounted
## Grava e lê o save em disco, sem nunca deixar o jogador sem progresso.
##
## - Gravação atômica: escreve num arquivo temporário e só então troca pelo
##   save. Se o jogo fechar no meio, o save anterior continua inteiro.
## - Cópia de segurança: o save anterior vira ".bak" a cada gravação.
## - Save corrompido: tenta a cópia de segurança. O arquivo ruim é guardado
##   à parte ("quarentena"), nunca apagado.
## - Save de versão mais nova que o jogo: também vai para a quarentena, para
##   o jogo novo não gravar por cima dele.

const DEFAULT_PATH := "user://save.json"

enum Status {
	OK,
	NO_SAVE,                ## primeira vez: não existe save
	RECOVERED_FROM_BACKUP,  ## o save estava ruim; a cópia de segurança foi usada
	CORRUPT,                ## save e cópia inutilizáveis (guardados à parte)
	NEWER_VERSION,          ## save de uma versão mais nova do jogo (guardado à parte)
}


class LoadResult:
	extends RefCounted
	var status := Status.NO_SAVE
	var simulation: CafeSimulation
	var warnings: Array[String] = []
	## Horário (relógio do jogo) em que o save foi gravado.
	var saved_at := 0.0


var path: String


func _init(save_path := DEFAULT_PATH) -> void:
	path = save_path


func backup_path() -> String:
	return path + ".bak"


func temp_path() -> String:
	return path + ".tmp"


func has_save() -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(backup_path())


func save(simulation: CafeSimulation) -> Error:
	# full_precision: horários do relógio são números grandes. A precisão padrão já
	# erra menos de 1 ms, mas gravar o valor exato não custa nada.
	var text := JSON.stringify(SaveCodec.encode(simulation), "\t", true, true)
	var dir_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return dir_error
	var file := FileAccess.open(temp_path(), FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(backup_path())
		var backup_error := DirAccess.rename_absolute(path, backup_path())
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(temp_path(), path)


func load_game(clock: GameClock, random_seed := 0) -> LoadResult:
	var result := LoadResult.new()
	if not has_save():
		return result

	var primary := _read(path, clock, random_seed)
	if primary.status == Status.OK:
		return primary
	if primary.status == Status.NEWER_VERSION:
		_quarantine(path, "newer")
		return primary

	var backup := _read(backup_path(), clock, random_seed)
	if FileAccess.file_exists(path):
		_quarantine(path, "corrupt")
	if backup.status == Status.OK:
		backup.status = Status.RECOVERED_FROM_BACKUP
		return backup
	if FileAccess.file_exists(backup_path()):
		_quarantine(backup_path(), "newer" if backup.status == Status.NEWER_VERSION else "corrupt")
	result.status = Status.NEWER_VERSION if backup.status == Status.NEWER_VERSION else Status.CORRUPT
	return result


## Apaga o save e a cópia de segurança (usado por "Recomeçar do zero").
func delete_save() -> void:
	for file_path in [path, backup_path(), temp_path()]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)


func _read(file_path: String, clock: GameClock, random_seed: int) -> LoadResult:
	var result := LoadResult.new()
	result.status = Status.CORRUPT
	if not FileAccess.file_exists(file_path):
		return result
	# JSON.new().parse() devolve o erro sem registrá-lo: save estragado é um caso
	# esperado e tratado aqui, não um erro do jogo.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return result
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return result
	if int(parsed.get("save_version", 0)) > SaveCodec.CURRENT_VERSION:
		result.status = Status.NEWER_VERSION
		return result
	var migrated := SaveCodec.migrate(parsed)
	if migrated.is_empty():
		return result
	var decoded := SaveCodec.decode(migrated, clock, random_seed)
	result.warnings = decoded.warnings
	if decoded.simulation == null:
		return result
	result.status = Status.OK
	result.simulation = decoded.simulation
	result.saved_at = decoded.saved_at
	return result


## Guarda um arquivo problemático com outro nome, sem apagar nada.
## (O horário do sistema aqui só serve para dar um nome único ao arquivo.)
func _quarantine(file_path: String, reason: String) -> void:
	var target := "%s.%s-%d" % [file_path, reason, int(Time.get_unix_time_from_system())]
	DirAccess.rename_absolute(file_path, target)
