class_name EventDefinition
extends Resource
## Evento com prazo e historinha (DT-063). Cada .tres em res://data/events é um evento que volta todo ano nas mesmas
## datas: uma historinha em quadros contada por um visitante, missões próprias com prazo e um fogão de prêmio que
## sobe de nível conforme as missões são concluídas (o último nível é o mais rápido), mais um enfeite no fim.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var title := ""
## Primeiro e último dia do evento (inclusive), no calendário do jogador, todo ano.
@export_range(1, 12) var start_month := 10
@export_range(1, 31) var start_day := 20
@export_range(1, 12) var end_month := 11
@export_range(1, 31) var end_day := 3
## Quem conta a historinha, o retrato dele (nome do sprite) e os quadros, na ordem.
@export var speaker := ""
@export var portrait := ""
## (Array[String], e não PackedStringArray: este sumia na conversão para binário do jogo exportado.)
@export var story: Array[String] = []
## Pasta com as missões do evento (MissionDefinition).
@export_dir var missions_dir := ""
## Fogão de prêmio e quantas missões concluídas liberam cada nível dele (o 1º nível entrega o fogão).
@export var prize_stove: StringName = &""
@export var stove_levels_at: PackedInt32Array = [1, 3, 5]
## Enfeite de prêmio por concluir todas as missões.
@export var final_prize: StringName = &""


func is_valid() -> bool:
	if id == &"" or title.is_empty() or story.is_empty() or missions_dir.is_empty() or stove_levels_at.is_empty():
		return false
	for i in range(1, stove_levels_at.size()):
		if stove_levels_at[i] <= stove_levels_at[i - 1]:
			return false
	return stove_levels_at[0] >= 1


## O evento vale na data [param date] ({"month", "day"})? Aceita datas que viram o ano (dezembro a janeiro).
func is_active_on(date: Dictionary) -> bool:
	var today := _key(int(date.get("month", 0)), int(date.get("day", 0)))
	var first := _key(start_month, start_day)
	var last := _key(end_month, end_day)
	if first <= last:
		return today >= first and today <= last
	return today >= first or today <= last


## A edição (o ano em que esta vez do evento começou), para as missões recomeçarem a cada ano.
func edition_for(date: Dictionary) -> int:
	var year := int(date.get("year", 0))
	var crosses_year := _key(start_month, start_day) > _key(end_month, end_day)
	return year - 1 if crosses_year and _key(int(date.get("month", 0)), int(date.get("day", 0))) < _key(start_month, start_day) else year


## Nível do fogão de prêmio com [param completed] missões concluídas (0 = ainda não ganhou).
func stove_level_for(completed: int) -> int:
	var level := 0
	for needed in stove_levels_at:
		if completed >= needed:
			level += 1
	return level


static func _key(month: int, day: int) -> int:
	return month * 100 + day
