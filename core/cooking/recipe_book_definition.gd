class_name RecipeBookDefinition
extends Resource
## Uma aba do livro de receitas (dado de conteúdo, DT-053). Cada .tres em res://data/recipe_books é uma aba;
## cada receita diz em que aba fica (campo book).

## Identificador único e estável. Nunca mude depois que houver receitas usando.
@export var id: StringName
@export var display_name := ""
## Posição da aba no livro (menor vem antes).
@export var order := 0
## Cor da aba.
@export var color := Color.WHITE


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty()
