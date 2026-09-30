class_name ManualClock
extends GameClock
## Relógio controlado à mão: o tempo só anda quando alguém chama advance().
## Usado nos testes para simular minutos ou horas em milissegundos.

var time := 1_000_000.0
## Fuso usado nos testes (em segundos).
var offset := 0


func now() -> float:
	return time


func advance(seconds: float) -> void:
	time += seconds


func utc_offset_seconds() -> int:
	return offset
