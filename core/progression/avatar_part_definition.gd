class_name AvatarPartDefinition
extends Resource
## Peça do avatar do chef (DT-070), em res://data/avatar: um tom de pele, um cabelo, um chapéu ou uma roupa.
## O retrato empilha três camadas: a roupa, a cabeça (pele e cabelo juntos) e o chapéu.

enum Slot { SKIN, HAIR, HAT, OUTFIT }

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var slot := Slot.HAIR
## Nome na arte: a pele e o cabelo formam a cabeça ("avatar_cabeca_<pele>_<cabelo>"); o chapéu e a roupa são
## "avatar_chapeu_<art>" e "avatar_roupa_<art>".
@export var art := ""
## A peça com que todo chef começa (uma por parte do corpo).
@export var is_default := false

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty() and not art.is_empty() and price >= 0 and min_level >= 1
