class_name SoundBoard
extends Node
## Toca os sons de feedback (seção 123). Os sons são gerados por código a
## partir de res://data/sounds na primeira vez que o nó entra na árvore.
##
## O "som ligado/desligado" é uma preferência do aparelho, não do progresso:
## fica em user://settings.cfg, separado do save.

signal muted_changed(muted: bool)

const SOUNDS_DIR := "res://data/sounds"
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"

## Vozes simultâneas (vários clientes pagando juntos).
@export var voices := 6
## Onde guardar a preferência. Vazio = não guarda (testes).
@export var settings_path := DEFAULT_SETTINGS_PATH

var muted := false
## Últimos sons pedidos (para testes e diagnóstico), mesmo com o som desligado.
var history: Array[StringName] = []

var _streams: Dictionary = {}  # StringName -> AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	var store := DefinitionStore.new(func(a: SoundCue, b: SoundCue) -> bool: return String(a.id) < String(b.id))
	store.load_dir(SOUNDS_DIR, SoundCue)
	for cue in store.all():
		_streams[cue.id] = SoundSynth.render(cue)
	for i in voices:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_load_settings()


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


func _save_settings() -> void:
	if settings_path.is_empty():
		return
	var config := ConfigFile.new()
	config.load(settings_path)  # mantém outras preferências que existirem
	config.set_value("audio", "muted", muted)
	config.save(settings_path)
