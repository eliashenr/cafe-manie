class_name NightConfig
extends Resource
## Noite no café (DT-064, res://data/config/night.tres): o horário da noite pelo relógio do jogador. À noite o café e
## a cidade escurecem (com o anoitecer e o amanhecer aos poucos), as luminárias acendem e o cardápio noturno abre.

## Hora em que a noite começa e em que ela acaba (0 a 24, no horário local).
@export_range(0.0, 24.0) var night_start_hour := 19.0
@export_range(0.0, 24.0) var night_end_hour := 6.0
## Horas do anoitecer e do amanhecer (a escuridão cresce ou some aos poucos, dentro da noite).
@export var twilight_hours := 1.0


func is_valid() -> bool:
	return twilight_hours > 0.0 and night_start_hour != night_end_hour and twilight_hours * 2.0 < _length()


## É noite na hora [param hour] (cardápio noturno aberto)?
func is_night(hour: float) -> bool:
	return _since_start(hour) < _length()


## Quanto escuro está na hora [param hour]: 0 de dia, 1 no meio da noite, subindo e descendo nos crepúsculos.
func darkness(hour: float) -> float:
	# de dia, length - since fica negativo e a conta dá 0
	var since := _since_start(hour)
	return clampf(minf(since, _length() - since) / twilight_hours, 0.0, 1.0)


func _length() -> float:
	return fposmod(night_end_hour - night_start_hour, 24.0)


func _since_start(hour: float) -> float:
	return fposmod(hour - night_start_hour, 24.0)
