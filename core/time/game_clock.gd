class_name GameClock
extends RefCounted
## Fonte de tempo do jogo, em segundos (Unix).
##
## Todo timer que precisa sobreviver ao jogo fechado (preparo de receitas,
## recompensas) guarda "início + duração" medidos por este relógio, nunca
## contagem de frames. Hoje é o relógio do aparelho; com backend, passa a
## ser o horário do servidor (seção 66 do master prompt).


func now() -> float:
	return Time.get_unix_time_from_system()
