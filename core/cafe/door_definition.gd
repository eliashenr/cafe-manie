class_name DoorDefinition
extends Resource
## Modelo de porta da entrada (DT-067). Cada .tres em res://data/doors é uma porta; cada coleção da loja tem a sua.
## Comprada uma vez, trocar para ela é grátis. A porta inicial vem de graça.

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
## Coleção da loja (estilo ou cultura) a que a porta pertence (res://data/collections).
@export var collection: StringName = &"classico"
## A porta com que toda cafeteria nova começa (só uma).
@export var is_default := false
## Nome-base do desenho: o jogo usa "<base>_L" aberta e "<base>_fechada_L" com a plaquinha FECHADO.
@export var sprite_base := "enfeite_porta"

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and not sprite_base.is_empty() and price >= 0 and min_level >= 1
