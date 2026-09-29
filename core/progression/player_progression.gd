class_name PlayerProgression
extends RefCounted
## XP e nível do jogador.

signal xp_changed(xp: int)
## Emitido uma vez por nível ganho (ganhar 2 níveis de uma vez emite 2 vezes).
signal leveled_up(level: int)

var table: LevelTable
var xp := 0
var level := 1


func _init(level_table: LevelTable) -> void:
	assert(level_table != null and level_table.is_valid(), "Tabela de níveis inválida.")
	table = level_table


## Soma XP. Retorna quantos níveis foram ganhos. No nível máximo o XP continua
## sendo contado, mas o nível não sobe.
func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	xp += amount
	var new_level := table.level_for_xp(xp)
	var gained := new_level - level
	xp_changed.emit(xp)
	while level < new_level:
		level += 1
		leveled_up.emit(level)
	return gained


func is_max_level() -> bool:
	return level >= table.max_level()


## Fração do caminho até o próximo nível (0 a 1). No nível máximo é 1.
func level_progress() -> float:
	if is_max_level():
		return 1.0
	var start := table.xp_to_reach[level - 1]
	var goal := table.xp_for_next(level)
	return clampf(float(xp - start) / float(goal - start), 0.0, 1.0)
