class_name SoundBoard
extends Node
## Toca os sons de feedback (seção 123) e a música ambiente. Os sons são gerados
## por código a partir de res://data/sounds na primeira vez que o nó entra na
## árvore. A música é a bossa do café, composta por tools/music/compose_bossa.py,
## e toca em loop, baixinha, atrás dos sons.
##
## "Som" e "música" ligados ou desligados são preferências do aparelho, não do
## progresso: ficam em user://settings.cfg, separados do save.

signal muted_changed(muted: bool)
signal music_muted_changed(muted: bool)

const SOUNDS_DIR := "res://data/sounds"
const MUSIC_PATH := "res://art/music/bossa_do_cafe.wav"
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
## Volume de quem está calado (a música sai e entra a partir daqui).
const SILENT_DB := -60.0

## Vozes simultâneas (vários clientes pagando juntos).
@export var voices := 6
## Onde guardar a preferência. Vazio = não guarda (testes).
@export var settings_path := DEFAULT_SETTINGS_PATH
## Volume da música ambiente: fica atrás dos sons de feedback.
@export var music_volume_db := -11.0
## Segundos para a música entrar e sair, sem susto.
@export var music_fade := 2.0
## Sem saída de som de verdade (o driver "Dummy" do modo sem janela), a música não toca:
## lá ela nunca termina de parar e fica presa na memória ao fechar. Os testes ligam isto.
@export var music_without_audio_device := false

var muted := false
var music_muted := false
## Últimos sons pedidos (para testes e diagnóstico), mesmo com o som desligado.
var history: Array[StringName] = []

var _streams: Dictionary = {}  # StringName -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_tween: Tween


func _ready() -> void:
	var store := DefinitionStore.new(func(a: SoundCue, b: SoundCue) -> bool: return String(a.id) < String(b.id))
	store.load_dir(SOUNDS_DIR, SoundCue)
	for cue in store.all():
		_streams[cue.id] = SoundSynth.render(cue)
	for i in voices:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.volume_db = SILENT_DB
	if ResourceLoader.exists(MUSIC_PATH):
		_music.stream = load(MUSIC_PATH)
	add_child(_music)
	_load_settings()
	if not music_muted:
		_fade_music(true)


## Ao sair da cena (inclusive ao fechar o jogo), a música para e solta o arquivo:
## sem isso, a faixa que tocava fica presa na memória no fechamento.
func _exit_tree() -> void:
	if _music_tween != null:
		_music_tween.kill()
	if _music != null:
		_music.stop()
		_music.stream = null


## A música ambiente está tocando (ligada e com arquivo)?
func music_playing() -> bool:
	return _music != null and _music.playing and not music_muted


func set_music_muted(value: bool) -> void:
	if music_muted == value:
		return
	music_muted = value
	_save_settings()
	_fade_music(not value)
	music_muted_changed.emit(music_muted)


## Entra (de baixinho até o volume da música) ou sai (até calar e parar).
func _fade_music(on: bool) -> void:
	if _music == null or _music.stream == null:
		return
	if AudioServer.get_driver_name() == "Dummy" and not music_without_audio_device:
		return
	if _music_tween != null:
		_music_tween.kill()
	if on and not _music.playing:
		_music.volume_db = SILENT_DB
		_music.play()
	if not is_inside_tree():
		_music.volume_db = music_volume_db if on else SILENT_DB
		return
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", music_volume_db if on else SILENT_DB, music_fade)
	if not on:
		_music_tween.tween_callback(_music.stop)


func has_cue(cue: StringName) -> bool:
	return _streams.has(cue)


func play(cue: StringName) -> void:
	history.append(cue)
	if history.size() > 20:
		history.pop_front()
	if muted or not _streams.has(cue) or _players.is_empty():
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[cue]
	player.play()


func set_muted(value: bool) -> void:
	if muted == value:
		return
	muted = value
	_save_settings()
	muted_changed.emit(muted)


func _load_settings() -> void:
	if settings_path.is_empty():
		return
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		muted = bool(config.get_value("audio", "muted", false))
		music_muted = bool(config.get_value("audio", "music_muted", false))


func _save_settings() -> void:
	if settings_path.is_empty():
		return
	var config := ConfigFile.new()
	config.load(settings_path)  # mantém outras preferências que existirem
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "music_muted", music_muted)
	config.save(settings_path)
