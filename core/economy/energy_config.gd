class_name EnergyConfig
extends Resource
## Parâmetros da energia das máquinas de bebida (res://data/config/energy.tres, DT-052).

## Energia máxima no nível 1.
@export var base_max := 10
## A cada tantos níveis, a energia máxima cresce 1 ponto.
@export var levels_per_extra_point := 2
## Segundos para recarregar 1 ponto. É tempo real: continua com o jogo fechado.
@export var seconds_per_point := 60.0


func is_valid() -> bool:
	return base_max > 0 and levels_per_extra_point > 0 and seconds_per_point > 0.0


## Energia máxima no nível.
func max_at(level: int) -> int:
	return base_max + maxi(0, level - 1) / levels_per_extra_point
