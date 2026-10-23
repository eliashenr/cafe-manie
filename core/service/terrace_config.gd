class_name TerraceConfig
extends Resource
## Terraço ao ar livre (DT-069, res://data/config/terrace.tres): uma compra que transforma a fileira da frente do
## salão (ao longo da borda de baixo) num terraço, com deque de madeira e cerca de jardim no lugar da mureta.
## De dia, quem senta no terraço paga mais; à noite, paga o normal.

@export var display_name := "Terraço ao ar livre"
## Coleção da loja em que o cartão do terraço aparece (aba Pisos).
@export var collection: StringName = &"classico"

@export_group("Balanceamento")
@export var price := 3000
@export var min_level := 10
@export_range(0, 100) var beauty := 15
## Quanto a mais paga quem senta no terraço de dia (0.25 = 25%).
@export_range(0.0, 2.0) var day_pay_bonus := 0.25


func is_valid() -> bool:
	return not display_name.is_empty() and price >= 0 and min_level >= 1 and day_pay_bonus >= 0.0
