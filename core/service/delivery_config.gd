class_name DeliveryConfig
extends Resource
## Entregas (DT-071, res://data/config/delivery.tres): com o Balcão de Entregas na cafeteria, chegam pedidos de
## porções prontas para mandar para a casa dos clientes, por mais ouro que no salão.

## Pedidos esperando ao mesmo tempo, no máximo.
@export var max_orders := 3
## Segundos de relógio entre um pedido novo e o próximo (também com o jogo fechado).
@export var order_interval := 1800.0
## Porções de cada pedido (sorteadas entre o mínimo e o máximo).
@export var min_servings := 3
@export var max_servings := 8
## Quanto o pedido paga, em relação ao preço de cada porção no salão.
@export_range(1.0, 5.0) var gold_multiplier := 1.5
@export var xp_per_serving := 2


func is_valid() -> bool:
	return max_orders > 0 and order_interval > 0.0 and min_servings >= 1 and max_servings >= min_servings \
		and gold_multiplier >= 1.0 and xp_per_serving >= 0
