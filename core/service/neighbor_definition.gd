class_name NeighborDefinition
extends Resource
## Vizinho simulado (DT-074), em res://data/neighbors: um personagem do jogo com o café dele, para visitar e ajudar
## uma vez por dia. Fica no lugar dos amigos de verdade até existir o servidor (seção 3.9 do relatório).

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var cafe_name := ""
## O que o jogador faz quando visita (aparece no aviso): "limpou as mesas", "temperou os pratos"...
@export var help_text := ""
## Retrato na arte ("vizinho_<art>").
@export var art := ""
## Nível do café do vizinho: vizinho mais avançado dá mais ouro na visita.
@export var level := 1


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and not cafe_name.is_empty() and not help_text.is_empty() \
		and not art.is_empty() and level >= 1
