class_name NewGameConfig
extends Resource
## Como começa um jogo novo (res://data/config/new_game.tres): tamanho da
## cafeteria, ouro inicial e os móveis que já vêm posicionados.

@export var grid_size := Vector2i(8, 8)
@export var starting_gold := 200
## Cada item: [code]{"id": &"stove_basic", "origin": Vector2i(0, 0), "rotation": 0}[/code].
@export var starter_items: Array[Dictionary] = []


func is_valid() -> bool:
	return grid_size.x > 0 and grid_size.y > 0 and starting_gold >= 0
