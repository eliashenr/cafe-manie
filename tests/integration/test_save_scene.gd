extends CafeTestCase
## Save na cena: fechar e reabrir o jogo com tudo no lugar, salvamento
## automático, boas-vindas e "Recomeçar". Cada teste usa uma pasta própria.

var dir := ""


func _save_path() -> String:
	if dir.is_empty():
		dir = "user://test_saves/scene_%d_%d" % [Time.get_ticks_usec(), randi()]
		DirAccess.make_dir_recursive_absolute(dir)
	return dir.path_join("save.json")


func cleanup() -> void:
	super.cleanup()
	if dir.is_empty():
		return
	for file_name in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file_name))
	DirAccess.remove_absolute(dir)
	DirAccess.remove_absolute(dir.get_base_dir())


## Abre o jogo "de verdade": sem simulação injetada, lendo do save.
func _open_game(game_clock: GameClock) -> Cafe:
	var cafe: Cafe = CafeScene.instantiate()
	cafe.save_service = SaveService.new(_save_path())
	cafe.game_clock = game_clock
	add_to_tree(cafe)
	await tree.process_frame
	return cafe


## Fecha o jogo como o sistema faria (salva ao sair) e tira da árvore.
func _close_game(cafe: Cafe) -> void:
	cafe.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	cafe.get_parent().remove_child(cafe)
	cafe.queue_free()


func _find(cafe: Cafe, origin: Vector2i) -> StringName:
	var placement := cafe.layout.placement_at(origin)
	return placement.id if placement != null else &""


func test_first_launch_starts_a_new_game() -> void:
	var cafe := await _open_game(ManualClock.new())
	var new_game: NewGameConfig = load("res://data/config/new_game.tres")
	assert_eq(cafe.layout.count(), new_game.starter_items.size())
	assert_eq(cafe.hud.toast_text(), "", "primeira vez: nada de 'bem-vindo de volta'")


func test_close_and_reopen_keeps_everything() -> void:
	var clock_a := ManualClock.new()
	var first := await _open_game(clock_a)
	var plant := first.layout.place(first.catalog.get_definition(&"plant_pot"), Vector2i(6, 7))
	var stove := _find(first, Vector2i(0, 0))
	first.simulation.start_cooking(stove, &"cheese_bread")
	first.simulation.progression.add_xp(40)
	var gold := first.simulation.wallet.balance(Wallet.SOFT)
	var level := first.simulation.progression.level
	_close_game(first)

	var clock_b := ManualClock.new()
	clock_b.time = clock_a.time + 10.0  # reaberto 10 s depois
	var second := await _open_game(clock_b)
	assert_true(second.layout.get_placement(plant) != null, "a planta continua lá")
	assert_eq(second.simulation.wallet.balance(Wallet.SOFT), gold)
	assert_eq(second.simulation.progression.level, level)
	assert_eq(second.simulation.kitchen.stove_status(stove), Kitchen.StoveStatus.COOKING)
	assert_almost_eq(second.simulation.kitchen.time_left(stove), 30.0, 0.01, "o tempo continuou correndo")


func test_dish_gets_ready_while_closed_and_the_player_is_told() -> void:
	var clock_a := ManualClock.new()
	var first := await _open_game(clock_a)
	first.simulation.start_cooking(_find(first, Vector2i(0, 0)), &"coffee")
	first.simulation.start_cooking(_find(first, Vector2i(1, 0)), &"cheese_bread")
	_close_game(first)

	var clock_b := ManualClock.new()
	clock_b.time = clock_a.time + 7200.0  # duas horas depois
	var second := await _open_game(clock_b)
	assert_eq(second.hud.toast_text(), "Bem-vindo de volta! 2 pratos ficaram prontos enquanto você estava fora.")
	assert_eq(second.simulation.kitchen.stove_status(_find(second, Vector2i(0, 0))), Kitchen.StoveStatus.READY)


func test_autosave_happens_after_a_change() -> void:
	var cafe := await _open_game(ManualClock.new())
	cafe.autosave_min_interval = 0.0
	assert_false(FileAccess.file_exists(_save_path()), "nada salvo enquanto nada mudou")
	cafe.simulation.wallet.earn(Wallet.SOFT, 5, "teste")
	await tree.process_frame
	assert_true(FileAccess.file_exists(_save_path()), "salvou sozinho depois da mudança")


func test_minimizing_on_mobile_saves_immediately() -> void:
	var cafe := await _open_game(ManualClock.new())
	cafe.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	assert_true(FileAccess.file_exists(_save_path()))


func test_damaged_save_recovers_the_backup_and_says_so() -> void:
	var first := await _open_game(ManualClock.new())
	first.simulation.wallet.earn(Wallet.SOFT, 1, "teste")
	first.save_now()
	var gold := first.simulation.wallet.balance(Wallet.SOFT)
	first.save_now()  # agora existe save e cópia de segurança iguais
	_close_game(first)
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	file.store_string("{ estragado")
	file.close()

	var second := await _open_game(ManualClock.new())
	assert_eq(second.simulation.wallet.balance(Wallet.SOFT), gold)
	assert_true(second.hud.toast_text().contains("recuperamos a cópia anterior"), second.hud.toast_text())


func test_restart_asks_first_and_then_wipes_the_save() -> void:
	var cafe := await _open_game(ManualClock.new())
	cafe.hud.daily_dialog().hide()  # o jogo novo abre com a recompensa diária
	cafe.save_now()
	cafe.hud.find_child("RestartButton", true, false).pressed.emit()
	assert_true(cafe.hud.restart_dialog().visible, "pede confirmação antes de apagar")
	assert_true(cafe.hud.restart_dialog().get_cancel_button().has_focus(), "o botão já selecionado é Cancelar")
	assert_true(FileAccess.file_exists(_save_path()), "só perguntar não apaga nada")
	cafe.hud.restart_dialog().confirmed.emit()
	assert_false(cafe.save_service.has_save(), "confirmado: save apagado")
	assert_eq(cafe.save_now(), ERR_UNAVAILABLE, "e não é regravado ao sair")


func test_injected_simulation_never_touches_the_disk() -> void:
	var cafe := await spawn_cafe()
	assert_eq(cafe.save_now(), ERR_UNAVAILABLE, "testes com simulação injetada não salvam")
