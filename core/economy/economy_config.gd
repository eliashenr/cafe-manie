class_name EconomyConfig
extends Resource
## Parâmetros de economia da loja (res://data/config/economy.tres).

## Quanto do preço volta ao vender um móvel (0.5 = metade).
@export_range(0.0, 1.0) var sell_fraction := 0.5
## Categorias que não podem ficar zeradas: sem pelo menos um, o jogador
## não tem como ganhar ouro de novo (fogão e balcão).
@export var essential_categories: Array[FurnitureDefinition.Category] = [
	FurnitureDefinition.Category.COOKING, FurnitureDefinition.Category.COUNTER,
]


## Garçons: preço de cada contratação (o primeiro já vem com a cafeteria) e o nível que libera cada uma.
@export var waiter_prices: Array[int] = [0, 500, 1500, 4000]
@export var waiter_levels: Array[int] = [1, 3, 5, 8]
## Robô Garçom (DT-082): a partir desta contratação (0 = o primeiro garçom), quem chega é um robô. Ele trabalha
## igual aos outros; muda só o visual.
@export var robot_waiter_from := 2


func is_valid() -> bool:
	return sell_fraction >= 0.0 and sell_fraction <= 1.0 and not waiter_prices.is_empty() \
		and waiter_prices.size() == waiter_levels.size() and robot_waiter_from >= 0


func max_waiters() -> int:
	return waiter_prices.size()
