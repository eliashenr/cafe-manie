class_name DailyRewards
extends RefCounted
## Estado da recompensa diária: qual foi o último dia recebido e em que dia da
## sequência o jogador está. Os dias vêm de GameClock.local_day().
##
## Relógio voltando para trás (dia menor que o último recebido) não libera
## nada: adiantar e depois atrasar o relógio não rende recompensa extra.

signal changed

var calendar: DailyRewardCalendar

var last_claim_day := -1
## Dias já recebidos na sequência atual (0 a days.size()).
var streak := 0


func _init(reward_calendar: DailyRewardCalendar = null) -> void:
	calendar = reward_calendar


func enabled() -> bool:
	return calendar != null and not calendar.days.is_empty()


func can_claim(today: int) -> bool:
	return enabled() and today > last_claim_day


## Índice (0 = Dia 1) da recompensa que seria recebida hoje.
func index_for(today: int) -> int:
	if not enabled():
		return 0
	var continues := last_claim_day >= 0 and today == last_claim_day + 1
	if calendar.reset_when_missed and not continues:
		return 0
	return streak % calendar.days.size()


func reward_for(today: int) -> Dictionary:
	return calendar.days[index_for(today)] if enabled() else {}


## Marca a recompensa de hoje como recebida e a retorna ({} se não pode).
func claim(today: int) -> Dictionary:
	if not can_claim(today):
		return {}
	var index := index_for(today)
	streak = index + 1
	last_claim_day = today
	changed.emit()
	return calendar.days[index]


func to_data() -> Dictionary:
	return {"last_claim_day": last_claim_day, "streak": streak}


func restore(data: Dictionary) -> void:
	last_claim_day = int(data.get("last_claim_day", -1))
	streak = maxi(int(data.get("streak", 0)), 0)
	changed.emit()
