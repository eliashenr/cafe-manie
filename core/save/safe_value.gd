class_name SafeValue
extends RefCounted
## Leitura segura de valores do save (QA, 23/10): save estragado ou editado à mão, com texto onde devia haver número
## (ou lista, ou nada), não pode dar erro de script no meio do carregamento. O valor errado vira o padrão.


static func to_int(value: Variant, fallback := 0) -> int:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return int(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return int(String(value)) if String(value).is_valid_float() else fallback
	return fallback


static func to_float(value: Variant, fallback := 0.0) -> float:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return float(value)
		TYPE_STRING, TYPE_STRING_NAME:
			return float(String(value)) if String(value).is_valid_float() else fallback
	return fallback


static func to_bool(value: Variant, fallback := false) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
	return fallback


static func to_array(value: Variant) -> Array:
	return value if value is Array else []
