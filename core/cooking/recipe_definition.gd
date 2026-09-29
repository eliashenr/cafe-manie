class_name RecipeDefinition
extends Resource
## Definição de uma receita (dado de conteúdo). Cada .tres em
## res://data/recipes é uma receita. Todos os números são parâmetros de
## balanceamento, editáveis no inspetor da Godot.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""

@export_group("Balanceamento")
## Segundos de preparo. É tempo real: continua passando com o jogo fechado.
@export var cook_time := 30.0
## Porções que vão para o balcão quando o prato fica pronto.
@export var servings := 4
## Café Ouro pago para começar a preparar.
@export var ingredient_cost := 10
## Café Ouro que o cliente paga por porção.
@export var sell_price := 5
## XP ao retirar o prato pronto do fogão.
@export var xp_reward := 5
## Nível do jogador a partir do qual a receita pode ser preparada.
@export var unlock_level := 1

@export_group("Placeholder")
## PLACEHOLDER_FOOD: cor usada para o prato até existir arte.
@export var placeholder_color := Color.WHITE


func is_valid() -> bool:
	return id != &"" and cook_time > 0.0 and servings > 0 and ingredient_cost >= 0 \
		and sell_price >= 0 and xp_reward >= 0 and unlock_level >= 1


## Lucro de uma fornada inteira vendida (sem gorjetas).
func batch_profit() -> int:
	return servings * sell_price - ingredient_cost
