class_name NeighborsConfig
extends Resource
## Vizinhos simulados (DT-074, res://data/config/neighbors.tres): a recompensa de visitar e ajudar, e a amizade
## que cresce a cada visita e aumenta a recompensa.

## Ouro da visita: o fixo mais um tanto por nível do café do vizinho.
@export var visit_gold := 40
@export var visit_gold_per_level := 4
@export var visit_xp := 10
## Corações de amizade: um a mais por visita, até o máximo; cada um aumenta o ouro da visita.
@export var max_friendship := 5
@export_range(0.0, 1.0) var gold_per_friendship := 0.1


func is_valid() -> bool:
	return visit_gold >= 0 and visit_gold_per_level >= 0 and visit_xp >= 0 and max_friendship >= 1 and gold_per_friendship >= 0.0
