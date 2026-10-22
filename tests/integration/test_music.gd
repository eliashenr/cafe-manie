extends CafeTestCase
## Música ambiente: a bossa do café toca em loop, baixinha, e tem botão próprio,
## separado dos efeitos sonoros, que o aparelho lembra. Ao sair da cena, nenhum som fica preso.


func _find(cafe: Cafe, node_name: String) -> Node:
	return cafe.find_child(node_name, true, false)


func test_music_plays_softly_in_a_loop() -> void:
	var cafe := await spawn_cafe()
	await settle()
	assert_true(cafe.sound_board.music_playing(), "a música começa sozinha")
	var music := _find(cafe, "Music") as AudioStreamPlayer
	var stream := music.stream as AudioStreamWAV
	assert_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "toca em loop, sem parar")
	assert_true(stream.get_length() > 90.0, "faixa longa, para não cansar: %.1f s" % stream.get_length())
	assert_true(cafe.sound_board.music_volume_db <= -6.0, "fica atrás dos sons de feedback")


func test_music_button_toggles_and_the_device_remembers() -> void:
	var cafe := await spawn_cafe()
	var path := "user://test_music_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	cafe.sound_board.settings_path = path
	var button := _find(cafe, "MusicButton") as Button
	assert_eq(button.tooltip_text, "Música: ligada")
	button.pressed.emit()
	assert_true(cafe.sound_board.music_muted)
	assert_false(cafe.sound_board.music_playing(), "desligada")
	assert_eq(button.tooltip_text, "Música: desligada")
	var config := ConfigFile.new()
	assert_eq(config.load(path), OK, "preferência guardada no aparelho")
	assert_eq(config.get_value("audio", "music_muted"), true)
	button.pressed.emit()
	assert_false(cafe.sound_board.music_muted)
	assert_true(cafe.sound_board.music_playing(), "ligada de novo")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_sound_and_music_are_separate() -> void:
	var cafe := await spawn_cafe()
	await settle()
	(_find(cafe, "SoundButton") as Button).pressed.emit()
	assert_true(cafe.sound_board.muted, "efeitos desligados")
	assert_true(cafe.sound_board.music_playing(), "a música continua")
	(_find(cafe, "MusicButton") as Button).pressed.emit()
	(_find(cafe, "SoundButton") as Button).pressed.emit()
	assert_false(cafe.sound_board.muted, "efeitos de volta")
	assert_false(cafe.sound_board.music_playing(), "a música continua desligada")


func test_leaving_the_scene_lets_go_of_every_sound() -> void:
	var cafe := await spawn_cafe()
	await settle()
	cafe.sound_board.play(&"error")
	var players := cafe.sound_board.find_children("*", "AudioStreamPlayer", false, false)
	cafe.get_parent().remove_child(cafe)
	for player: AudioStreamPlayer in players:
		assert_true(player.stream == null and not player.playing, "%s soltou o som ao sair da cena" % player.name)
