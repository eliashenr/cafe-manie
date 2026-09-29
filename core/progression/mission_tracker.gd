class_name MissionTracker
extends RefCounted
## Acompanha a sequência de missões: uma ativa por vez, na ordem dos dados.
##
## Recebe eventos do jogo (record) e avisa quando uma missão é concluída.
## Quem entrega a recompensa é a CafeSimulation.

signal mission_completed(mission: MissionDefinition)
signal progress_changed

var missions: Array[MissionDefinition] = []
## Para missões de estado (como "chegue ao nível 2"): retorna o valor atual
## daquele tipo, para a missão já nascer com o progresso certo.
var state_provider: Callable

var _index := 0
var _progress := 0


func _init(mission_list: Array[MissionDefinition]) -> void:
	missions = mission_list.duplicate()
	missions.sort_custom(func(a: MissionDefinition, b: MissionDefinition) -> bool: return a.order < b.order)


## Missão ativa, ou null quando todas foram concluídas.
func current() -> MissionDefinition:
	return missions[_index] if _index < missions.size() else null


func progress() -> int:
	return _progress


func completed_count() -> int:
	return _index


func all_done() -> bool:
	return _index >= missions.size()


## Registra um evento. Para REACH_LEVEL, [param amount] é o nível alcançado.
func record(kind: MissionDefinition.Kind, amount := 1, furniture_category := -1) -> void:
	var mission := current()
	if mission == null or mission.kind != kind:
		return
	if kind == MissionDefinition.Kind.BUY_FURNITURE and mission.furniture_category >= 0 \
			and mission.furniture_category != furniture_category:
		return
	if kind == MissionDefinition.Kind.REACH_LEVEL:
		_progress = maxi(_progress, amount)
	else:
		_progress += amount
	progress_changed.emit()
	_complete_if_done()


## Confere a missão ativa contra o estado atual (usado ao começar e ao carregar).
func refresh() -> void:
	var mission := current()
	if mission != null and mission.kind == MissionDefinition.Kind.REACH_LEVEL and state_provider.is_valid():
		_progress = maxi(_progress, state_provider.call(mission.kind))
		progress_changed.emit()
	_complete_if_done()


func _complete_if_done() -> void:
	var mission := current()
	if mission == null or _progress < mission.target:
		return
	# Avança antes de avisar: a recompensa pode gerar novos eventos (ex.: subir de nível),
	# que já devem contar para a próxima missão.
	_index += 1
	_progress = 0
	mission_completed.emit(mission)
	progress_changed.emit()
	refresh()


func to_data() -> Dictionary:
	return {"index": _index, "progress": _progress}


func restore(data: Dictionary) -> void:
	_index = clampi(int(data.get("index", 0)), 0, missions.size())
	_progress = maxi(int(data.get("progress", 0)), 0)
	progress_changed.emit()
