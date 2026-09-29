extends TestCase
## Save em disco: gravação atômica, cópia de segurança, recuperação e quarentena.
## Cada teste usa uma pasta própria em user://, apagada no fim.

var dir := ""
var service: SaveService
var clock: ManualClock


func _setup() -> CafeSimulation:
	dir = "user://test_saves/%d_%d" % [Time.get_ticks_usec(), randi()]
	DirAccess.make_dir_recursive_absolute(dir)
	service = SaveService.new(dir.path_join("save.json"))
	clock = ManualClock.new()
	return CafeSimulation.create_new_game(clock, 3)


func cleanup() -> void:
	super.cleanup()
	if dir.is_empty():
		return
	for file_name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file_name))
	DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(dir.get_base_dir())  # só some se estiver vazia


func _files() -> PackedStringArray:
	return DirAccess.get_files_at(dir)


func _write(file_path: String, text: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_first_launch_has_no_save() -> void:
	_setup()
	assert_false(service.has_save())
	assert_eq(service.load_game(clock).status, SaveService.Status.NO_SAVE)


func test_save_then_load_restores_the_game() -> void:
	var sim := _setup()
	sim.wallet.earn(Wallet.SOFT, 77, "teste")
	assert_eq(service.save(sim), OK)
	var loaded := service.load_game(clock)
	assert_eq(loaded.status, SaveService.Status.OK)
	assert_eq(loaded.simulation.wallet.balance(Wallet.SOFT), sim.wallet.balance(Wallet.SOFT))
	assert_eq(loaded.saved_at, clock.now())


func test_second_save_keeps_the_previous_one_as_backup() -> void:
	var sim := _setup()
	service.save(sim)
	sim.wallet.earn(Wallet.SOFT, 1, "teste")
	service.save(sim)
	assert_true(FileAccess.file_exists(service.backup_path()), "cópia de segurança criada")
	assert_false(FileAccess.file_exists(service.temp_path()), "nenhum temporário sobrando")
	var backup: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(service.backup_path()))
	assert_eq(int(backup["wallet"]["soft_currency"]), sim.wallet.balance(Wallet.SOFT) - 1, "a cópia é o save anterior")


func test_corrupt_save_falls_back_to_backup_and_is_kept_aside() -> void:
	var sim := _setup()
	service.save(sim)
	sim.wallet.earn(Wallet.SOFT, 50, "teste")
	service.save(sim)
	_write(service.path, "{ isso não é json")  # arquivo estragado (queda de energia, etc.)

	var loaded := service.load_game(clock)
	assert_eq(loaded.status, SaveService.Status.RECOVERED_FROM_BACKUP)
	assert_eq(loaded.simulation.wallet.balance(Wallet.SOFT), sim.wallet.balance(Wallet.SOFT) - 50, "voltou ao save anterior")
	var quarantined := Array(_files()).filter(func(f: String) -> bool: return f.contains(".corrupt-"))
	assert_eq(quarantined.size(), 1, "o arquivo estragado foi guardado, não apagado")


func test_everything_corrupt_starts_fresh_without_deleting_files() -> void:
	_setup()
	_write(service.path, "lixo")
	_write(service.backup_path(), "[]")
	var loaded := service.load_game(clock)
	assert_eq(loaded.status, SaveService.Status.CORRUPT)
	assert_eq(loaded.simulation, null)
	assert_false(service.has_save(), "os ruins saíram do caminho do próximo save")
	assert_eq(_files().size(), 2, "mas continuam guardados")


func test_save_from_a_newer_game_version_is_protected() -> void:
	var sim := _setup()
	var data := SaveCodec.encode(sim)
	data["save_version"] = SaveCodec.CURRENT_VERSION + 1
	_write(service.path, JSON.stringify(data))
	var loaded := service.load_game(clock)
	assert_eq(loaded.status, SaveService.Status.NEWER_VERSION)
	assert_false(FileAccess.file_exists(service.path), "saiu do caminho para não ser sobrescrito")
	var kept := Array(_files()).filter(func(f: String) -> bool: return f.contains(".newer-"))
	assert_eq(kept.size(), 1, "o save mais novo foi guardado à parte")


func test_delete_save_removes_save_and_backup() -> void:
	var sim := _setup()
	service.save(sim)
	service.save(sim)
	service.delete_save()
	assert_false(service.has_save())
	assert_eq(service.load_game(clock).status, SaveService.Status.NO_SAVE)
