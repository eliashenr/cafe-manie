class_name DrinkDefinition
extends Resource
## Definição de uma bebida (dado de conteúdo, DT-052). Cada .tres em res://data/drinks é uma bebida.
## Bebida sai na hora da máquina certa, gastando energia, quando o jogador toca no cliente que pediu.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Que máquina prepara a bebida (o campo machine dos móveis de bebida, ex.: &"coffee" ou &"juice").
@export var machine: StringName

@export_group("Balanceamento")
## Energia gasta para servir.
@export var energy_cost := 1
## Café Ouro que o cliente paga.
@export var sell_price := 5
## XP ao servir.
@export var xp_reward := 2
## Nível do jogador a partir do qual os clientes pedem a bebida.
@export var unlock_level := 1
## Frozen yogurt (DT-065): a fruta que gasta (vazio = bebida comum) e quantas. Com fruta, não precisa de energia.
@export var fruit: StringName = &""
@export var fruit_cost := 1


func is_valid() -> bool:
	return id != &"" and machine != &"" and energy_cost >= 0 and (energy_cost >= 1 or fruit != &"") and sell_price >= 0 \
		and xp_reward >= 0 and unlock_level >= 1 and (fruit == &"" or fruit_cost >= 1)
