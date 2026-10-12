class_name PaymentProvider
extends RefCounted
## Quem cobra de verdade (Google Play Billing, no Android publicado). Esta base não cobra nada:
## cada provedor concreto diz se está disponível e o resultado da compra (CoinShop.Result).


func is_available() -> bool:
	return false


## Cobra o produto da loja. Retorna CoinShop.Result.
func purchase(_product_id: String) -> int:
	return CoinShop.Result.UNAVAILABLE
