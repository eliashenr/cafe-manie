class_name WallItemDefinition
extends Resource
## Item de pendurar na parede (janela, quadro, relógio, TV, rádio...), em res://data/wall_items.
## Fica num trecho de parede; um por trecho.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Nome do desenho na arte (enfeite_<art>_R / _L).
@export var art := ""
## Coleção da loja (estilo ou cultura) a que o item pertence (res://data/collections).
@export var collection: StringName = &"classico"
## Janela: a luz dela entra no chão.
@export var lets_light_in := false

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and not art.is_empty() and price >= 0 and min_level >= 1
