class_name SurfaceDefinition
extends Resource
## Revestimento de piso ou de parede (dado de conteúdo, em res://data/surfaces).
##
## O jogador pinta piso a piso e trecho a trecho de parede, pagando tile_price por célula (pedido
## do PO: dá para misturar revestimentos). Os comprados inteiros antes disso pintam de graça.

enum Kind { FLOOR, WALL }
## Desenho usado até existir arte final (PLACEHOLDER_SURFACE).
enum Pattern { CHECKER, PLANKS, TILES, PLAIN, BRICK, STRIPES }

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var kind := Kind.FLOOR
## O revestimento com que toda cafeteria nova começa (um por tipo).
@export var is_default := false
## Coleção da loja (estilo ou cultura) a que o revestimento pertence (res://data/collections).
@export var collection: StringName = &"classico"

@export_group("Balanceamento")
## Preço antigo do revestimento inteiro (referência para o tile_price e para saves antigos).
@export var price := 0
## Preço de pintar um piso ou um trecho de parede.
@export var tile_price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0

@export_group("Placeholder")
@export var pattern := Pattern.CHECKER
@export var color_a := Color.WHITE
@export var color_b := Color.GRAY


func is_valid() -> bool:
	return id != &"" and price >= 0 and tile_price >= 0 and min_level >= 1
