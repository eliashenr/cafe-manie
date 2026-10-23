class_name Attractions
extends RefCounted
## Atrações (DT-066): o ouro que os clientes deixam em cada uma (até a capacidade dela), esperando o jogador coletar.
## Atração que sai da cafeteria perde o ouro guardado.

signal changed

var layout: CafeLayout
## id da atração -> ouro guardado.
var _gold := {}


func _init(cafe_layout: CafeLayout) -> void:
	layout = cafe_layout
	layout.changed.connect(_forget_removed)


func is_attraction(id: StringName) -> bool:
	var placement := layout.get_placement(id)
	return placement != null and placement.definition.attraction_gold > 0


func gold(id: StringName) -> int:
	return int(_gold.get(id, 0))


## Cabe mais uma brincadeira (o ouro dela não passa da capacidade)?
func has_room(id: StringName) -> bool:
	if not is_attraction(id):
		return false
	var definition := layout.get_placement(id).definition
	return gold(id) + definition.attraction_gold <= definition.attraction_capacity


## Um cliente brincou: guarda o ouro dele (até a capacidade).
func add_play(id: StringName) -> void:
	if not is_attraction(id):
		return
	var definition := layout.get_placement(id).definition
	_gold[id] = mini(gold(id) + definition.attraction_gold, definition.attraction_capacity)
	changed.emit()


## Tira todo o ouro guardado e devolve quanto era.
func collect(id: StringName) -> int:
	var amount := gold(id)
	_gold.erase(id)
	if amount > 0:
		changed.emit()
	return amount


func to_data() -> Dictionary:
	var data := {}
	for id: StringName in _gold:
		data[String(id)] = _gold[id]
	return data


func restore(data: Dictionary) -> void:
	_gold.clear()
	for id in data:
		if is_attraction(StringName(id)):
			_gold[StringName(id)] = maxi(int(data[id]), 0)
	changed.emit()


func _forget_removed() -> void:
	for id: StringName in _gold.keys():
		if not is_attraction(id):
			_gold.erase(id)
