class_name Orchard
extends RefCounted
## Pés de fruta na cafeteria (DT-065): cada um amadurece as frutas pelo relógio (inclusive com o jogo fechado) e,
## maduro, espera ser colhido; colhido, começa a crescer de novo. O pé posto na cafeteria começa a crescer na hora.

signal changed

var layout: CafeLayout
var clock: GameClock
## id do pé -> horário em que começou a crescer a fornada atual.
var _planted_at := {}


func _init(cafe_layout: CafeLayout, game_clock: GameClock) -> void:
	layout = cafe_layout
	clock = game_clock
	layout.changed.connect(_sync)
	_sync()


## O móvel é um pé de fruta?
func is_tree(id: StringName) -> bool:
	var placement := layout.get_placement(id)
	return placement != null and placement.definition.fruit != &""


func is_ripe(id: StringName) -> bool:
	return is_tree(id) and seconds_left(id) <= 0.0


## Segundos até as frutas amadurecerem (0 se maduro ou se não é pé de fruta).
func seconds_left(id: StringName) -> float:
	if not is_tree(id):
		return 0.0
	var definition := layout.get_placement(id).definition
	return maxf(float(_planted_at.get(id, clock.now())) + definition.fruit_grow_time - clock.now(), 0.0)


## Colhe o pé maduro: devolve quantas frutas deu (0 se não está maduro) e começa a próxima fornada.
func harvest(id: StringName) -> int:
	if not is_ripe(id):
		return 0
	_planted_at[id] = clock.now()
	changed.emit()
	return layout.get_placement(id).definition.fruit_yield


func to_data() -> Dictionary:
	var data := {}
	for id: StringName in _planted_at:
		data[String(id)] = _planted_at[id]
	return data


func restore(data: Dictionary) -> void:
	for id in data:
		if is_tree(StringName(id)):
			_planted_at[StringName(id)] = float(data[id])
	changed.emit()


## Pé novo começa a crescer agora; pé que saiu da cafeteria é esquecido.
func _sync() -> void:
	for id: StringName in _planted_at.keys():
		if not is_tree(id):
			_planted_at.erase(id)
	for placement in layout.placements():
		if placement.definition.fruit != &"" and not _planted_at.has(placement.id):
			_planted_at[placement.id] = clock.now()
