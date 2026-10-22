class_name StoveSetDefinition
extends Resource
## Multifogão em partes (DT-060): fogões de 1 piso que, postos lado a lado na ordem, formam o conjunto. Completo, cada
## peça rende mais porções; a primeira vez que o conjunto fica completo dá um enfeite de prêmio. Cada .tres em
## res://data/stove_sets é um conjunto.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Os móveis (fogões) do conjunto, na ordem em que ficam lado a lado.
@export var parts: Array[StringName] = []
## Porções de cada prato numa peça do conjunto completo (2.0 = o dobro).
@export var servings_multiplier := 2.0
## Enfeite que vai para o inventário quando o conjunto fica completo pela primeira vez (vazio = nenhum).
@export var reward: StringName = &""


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and parts.size() >= 2 and servings_multiplier >= 1.0
