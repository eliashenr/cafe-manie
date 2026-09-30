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


func is_valid() -> bool:
	return sell_fraction >= 0.0 and sell_fraction <= 1.0
