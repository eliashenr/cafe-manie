class_name PlayerStats
extends RefCounted
## Contadores de tudo o que o jogador já fez (base das conquistas).
##
## Alguns somam (clientes servidos), outros guardam o maior valor já visto
## (nível, beleza). Ids neutros e estáveis: nunca mude um depois que houver saves.

signal changed(stat: StringName, value: int)

const CUSTOMERS_SERVED := &"customers_served"
const DISHES_COOKED := &"dishes_cooked"
const GOLD_EARNED := &"gold_earned"
const FURNITURE_BOUGHT := &"furniture_bought"
const EXPANSIONS := &"expansions"
const LEVEL := &"level"
const BEAUTY := &"beauty"

var _values: Dictionary = {}  # StringName -> int


func value(stat: StringName) -> int:
	return _values.get(stat, 0)


func add(stat: StringName, amount := 1) -> void:
	if amount <= 0:
		return
	_values[stat] = value(stat) + amount
	changed.emit(stat, _values[stat])


## Guarda o maior valor já visto (para nível e beleza).
func record_max(stat: StringName, current: int) -> void:
	if current > value(stat):
		_values[stat] = current
		changed.emit(stat, current)


func to_data() -> Dictionary:
	var data := {}
	for stat in _values:
		data[String(stat)] = _values[stat]
	return data


func restore(data: Dictionary) -> void:
	_values.clear()
	for key in data:
		_values[StringName(str(key))] = maxi(int(data[key]), 0)
