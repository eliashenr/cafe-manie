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


## Diferença do fuso horário local para o UTC, em segundos (Brasília: -10800).
func utc_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## Número do dia no calendário local (muda à meia-noite do jogador).
func local_day() -> int:
	return floori((now() + utc_offset_seconds()) / 86400.0)


## Segundos até a próxima meia-noite do jogador (quando o dia local muda).
func seconds_to_next_local_day() -> float:
	return 86400.0 - fposmod(now() + utc_offset_seconds(), 86400.0)
