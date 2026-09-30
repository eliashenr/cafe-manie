class_name SurfaceDefinition
extends Resource
## Revestimento de piso ou de parede (dado de conteúdo, em res://data/surfaces).
##
## Um revestimento cobre a cafeteria inteira: comprar uma vez libera para
## sempre, e trocar entre os já comprados é grátis (seção 34).

enum Kind { FLOOR, WALL }
## Desenho usado até existir arte final (PLACEHOLDER_SURFACE).
enum Pattern { CHECKER, PLANKS, TILES, PLAIN, BRICK, STRIPES }

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var kind := Kind.FLOOR
## O revestimento com que toda cafeteria nova começa (um por tipo).
@export var is_default := false

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0

@export_group("Placeholder")
@export var pattern := Pattern.CHECKER
@export var color_a := Color.WHITE
@export var color_b := Color.GRAY


func is_valid() -> bool:
	return id != &"" and price >= 0 and min_level >= 1
