class_name FruitDefinition
extends Resource
## Fruta da plantação (DT-065). Cada .tres em res://data/fruits é uma fruta: dá nos pés de fruta e vira frozen yogurt.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Posição nas listas (estoque de frutas).
@export var order := 0


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty()
