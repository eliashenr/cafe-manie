class_name CoinPack
extends Resource
## Pacote de Café Ouro vendido por dinheiro de verdade (res://data/coin_packs).
##
## O preço fica em centavos de real; na Play Store, o preço de verdade vem da loja (o produto
## product_id é cadastrado lá com o mesmo valor). Ver DT-043.

@export var id: StringName
@export var display_name := ""
## Identificador do produto na Play Store (cadastrado pelo dono da conta de desenvolvedor).
@export var product_id := ""
@export var gold := 0
## Preço em centavos de real (ex.: 490 = R$ 4,90).
@export var price_cents := 0
## Ordem na vitrine (do menor ao maior).
@export var order := 0


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and not product_id.is_empty() and gold > 0 and price_cents > 0


## "R$ 4,90".
func price_text() -> String:
	return "R$ %d,%02d" % [price_cents / 100, price_cents % 100]


## Café Ouro por real deste pacote.
func gold_per_real() -> float:
	return gold * 100.0 / price_cents
