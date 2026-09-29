class_name CustomerType
extends Resource
## Tipo de cliente (res://data/customers). Variações de comportamento
## sobre o cliente básico.

@export var id: StringName
@export var display_name := ""
## Multiplica a paciência base (0.6 = espera 40% menos).
@export var patience_multiplier := 1.0
## Multiplica o valor pago.
@export var pay_multiplier := 1.0
## Peso no sorteio de chegada (relativo aos outros tipos).
@export var spawn_weight := 1.0
## PLACEHOLDER_CHARACTER: cor da roupa até existir arte.
@export var placeholder_color := Color.WHITE


func is_valid() -> bool:
	return id != &"" and patience_multiplier > 0.0 and pay_multiplier > 0.0 and spawn_weight > 0.0
