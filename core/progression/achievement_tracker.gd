class_name AchievementTracker
extends RefCounted
## Acompanha as conquistas contra os contadores do jogador.
##
## Quando um contador passa da meta de um degrau, o degrau é desbloqueado e
## achievement_unlocked é emitido (quem ouve paga a recompensa). Um contador que
## pula vários degraus de uma vez desbloqueia cada um, em ordem.

signal achievement_unlocked(achievement: AchievementDefinition, tier: int)

var achievements: Array[AchievementDefinition] = []
var stats: PlayerStats

var _unlocked: Dictionary = {}  # StringName -> degraus desbloqueados (int)


func _init(achievement_list: Array[AchievementDefinition], player_stats: PlayerStats) -> void:
	achievements = achievement_list
	stats = player_stats
	stats.changed.connect(_on_stat_changed)


## Para de ouvir os contadores (quando a lista de conquistas é trocada).
func detach() -> void:
	if stats.changed.is_connected(_on_stat_changed):
		stats.changed.disconnect(_on_stat_changed)


## Quantos degraus da conquista já foram desbloqueados (0 = nenhum).
func unlocked_tiers(id: StringName) -> int:
	return _unlocked.get(id, 0)


func unlocked_total() -> int:
	var total := 0
	for achievement in achievements:
		total += unlocked_tiers(achievement.id)
	return total


func tiers_total() -> int:
	var total := 0
	for achievement in achievements:
		total += achievement.tier_count()
	return total


## Confere todas as conquistas contra os contadores atuais.
func refresh() -> void:
	for achievement in achievements:
		_check(achievement)


func _on_stat_changed(stat: StringName, _value: int) -> void:
	for achievement in achievements:
		if achievement.stat == stat:
			_check(achievement)


func _check(achievement: AchievementDefinition) -> void:
	var current := stats.value(achievement.stat)
	var tier := unlocked_tiers(achievement.id)
	while tier < achievement.tier_count() and current >= achievement.tier_targets[tier]:
		tier += 1
		_unlocked[achievement.id] = tier
		achievement_unlocked.emit(achievement, tier - 1)


func to_data() -> Dictionary:
	var data := {}
	for id in _unlocked:
		data[String(id)] = _unlocked[id]
	return data


## Restaura sem emitir avisos nem pagar de novo.
func restore(data: Dictionary) -> void:
	_unlocked.clear()
	for achievement in achievements:
		var tiers := clampi(int(data.get(String(achievement.id), 0)), 0, achievement.tier_count())
		if tiers > 0:
			_unlocked[achievement.id] = tiers
