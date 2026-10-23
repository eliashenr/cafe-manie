class_name StageConfig
extends Resource
## Palco (DT-066, res://data/config/stage.tres): com um palco na cafeteria, de tempos em tempos (de café aberto) começa
## um show, e enquanto ele dura os clientes chegam mais rápido.

## Segundos de café aberto entre um show e o próximo.
@export var show_interval := 600.0
## Segundos que o show dura.
@export var show_duration := 120.0
## Multiplica o intervalo entre chegadas durante o show (0.5 = chegam duas vezes mais rápido).
@export_range(0.05, 1.0) var spawn_multiplier := 0.5


func is_valid() -> bool:
	return show_interval > 0.0 and show_duration > 0.0 and spawn_multiplier > 0.0 and spawn_multiplier <= 1.0
