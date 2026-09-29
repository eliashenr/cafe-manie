class_name LevelTable
extends Resource
## Curva de níveis (dado de conteúdo, em res://data/progression).
##
## xp_to_reach[i] é o XP total necessário para estar no nível i + 1.
## O primeiro valor é sempre 0 (nível 1). O nível máximo é o tamanho da lista.

@export var xp_to_reach := PackedInt32Array([0])


func is_valid() -> bool:
	if xp_to_reach.is_empty() or xp_to_reach[0] != 0:
		return false
	for i in range(1, xp_to_reach.size()):
		if xp_to_reach[i] <= xp_to_reach[i - 1]:
			return false
	return true


func max_level() -> int:
	return xp_to_reach.size()


func level_for_xp(xp: int) -> int:
	var level := 1
	for i in xp_to_reach.size():
		if xp >= xp_to_reach[i]:
			level = i + 1
	return level


## XP total para chegar ao nível seguinte, ou -1 no nível máximo.
func xp_for_next(level: int) -> int:
	return xp_to_reach[level] if level < max_level() else -1
