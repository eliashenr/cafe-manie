class_name FurnitureDefinition
extends Resource
## Definição de um tipo de móvel (dado de conteúdo).
##
## Cada arquivo .tres em res://data/furniture é um móvel do catálogo. Preços,
## níveis e atributos são parâmetros de balanceamento: ajuste-os no inspetor
## da Godot, sem mexer em código.

enum Category { TABLE, SEATING, COOKING, COUNTER, DECOR }

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var category := Category.DECOR
## Células ocupadas na rotação 0 (largura em x, profundidade em y).
@export var footprint := Vector2i.ONE
## Se true, precisa de pelo menos uma célula vizinha alcançável a partir da
## entrada (é onde cliente ou garçom param para usar o móvel).
@export var needs_access := true

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0
@export_range(0, 100) var efficiency := 0
@export_range(0, 100) var comfort := 0

@export_group("Placeholder")
## PLACEHOLDER_FURNITURE: cor da caixa desenhada até existir arte final.
@export var placeholder_color := Color.WHITE
## PLACEHOLDER_FURNITURE: altura da caixa, em pixels de mundo.
@export var placeholder_height := 32.0


func is_valid() -> bool:
	return id != &"" and footprint.x > 0 and footprint.y > 0 and price >= 0 and min_level >= 1
