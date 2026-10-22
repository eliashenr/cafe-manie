class_name DailyRewardCalendar
extends Resource
## Calendário da recompensa diária (res://data/config/daily_rewards.tres, seção 51).
##
## Cada dia: [code]{"gold": 50, "xp": 0, "furniture": &"", "surface": &"", "spice": &"", "spice_amount": 1}[/code].
## Chaves ausentes valem zero ou nada. Depois do último dia, recomeça do primeiro.

@export var days: Array[Dictionary] = []
## Se true, perder um dia volta a sequência para o primeiro dia.
@export var reset_when_missed := true


func is_valid() -> bool:
	if days.is_empty():
		return false
	for day in days:
		if int(day.get("gold", 0)) < 0 or int(day.get("xp", 0)) < 0 or int(day.get("spice_amount", 1)) < 1:
			return false
		if int(day.get("gold", 0)) == 0 and int(day.get("xp", 0)) == 0 \
				and StringName(day.get("furniture", &"")) == &"" and StringName(day.get("surface", &"")) == &"" \
				and StringName(day.get("spice", &"")) == &"":
			return false
	return true
