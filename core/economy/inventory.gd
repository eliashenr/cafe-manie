class_name Inventory
extends RefCounted
## Móveis guardados pelo jogador (tirados da cafeteria). Recolocar um móvel
## guardado é grátis: ele já foi pago.

signal changed

var _counts: Dictionary = {}  # id da definição (StringName) -> quantidade


func count(furniture_id: StringName) -> int:
	return _counts.get(furniture_id, 0)


func total() -> int:
	var sum := 0
	for amount: int in _counts.values():
		sum += amount
	return sum


func add(furniture_id: StringName, amount := 1) -> void:
	if furniture_id == &"" or amount <= 0:
		return
	_counts[furniture_id] = count(furniture_id) + amount
	changed.emit()


## Tira uma unidade. Retorna false se não houver nenhuma guardada.
func take(furniture_id: StringName) -> bool:
	var current := count(furniture_id)
	if current <= 0:
		return false
	if current == 1:
		_counts.erase(furniture_id)
	else:
		_counts[furniture_id] = current - 1
	changed.emit()
	return true


func to_data() -> Dictionary:
	var data := {}
	for furniture_id: StringName in _counts:
		data[String(furniture_id)] = _counts[furniture_id]
	return data


func restore(data: Dictionary) -> void:
	_counts.clear()
	for furniture_id in data:
		var amount := int(data[furniture_id])
		if amount > 0:
			_counts[StringName(furniture_id)] = amount
	changed.emit()
