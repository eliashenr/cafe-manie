class_name SpiceDefinition
extends Resource
## Tempero (DT-056): item da prateleira que se usa num fogão. Cada .tres em res://data/spices é um tempero.
## Ganha-se no presente diário e nas missões semanais, ou compra-se com Café Ouro na hora de usar.

enum Effect {
	EXTRA_SERVINGS, ## mais porções no prato que cozinha (amount = fração: 0.2 = +20%, pelo menos 1 a mais)
	CUT_TIME,       ## menos tempo de preparo (amount = segundos); se faltar menos que isso, fica pronto na hora
	INSTANT,        ## o prato que cozinha fica pronto na hora
	RECOVER,        ## o prato estragado volta a ficar pronto
}

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Frase curta do efeito, para o cartão do tempero.
@export var description := ""
@export var effect := Effect.EXTRA_SERVINGS
## Tamanho do efeito (ver Effect).
@export var amount := 0.0
## Café Ouro para comprar um na hora de usar (0 = não se vende).
@export var price := 0
## Nível a partir do qual dá para comprar. Os ganhos de presente valem antes disso.
@export var unlock_level := 1
## Posição na prateleira.
@export var order := 0


func is_valid() -> bool:
	if id == &"" or display_name.is_empty() or price < 0 or unlock_level < 1:
		return false
	if effect in [Effect.EXTRA_SERVINGS, Effect.CUT_TIME]:
		return amount > 0.0
	return true


## Serve para um fogão neste estado? Recuperar só vale para o prato estragado; o resto, para o que cozinha.
func works_on(status: Kitchen.StoveStatus) -> bool:
	if effect == Effect.RECOVER:
		return status == Kitchen.StoveStatus.SPOILED
	return status == Kitchen.StoveStatus.COOKING


## Porções a mais que o tempero dá a uma fornada de [param servings] porções.
func extra_servings(servings: int) -> int:
	return maxi(1, roundi(servings * amount)) if effect == Effect.EXTRA_SERVINGS else 0
