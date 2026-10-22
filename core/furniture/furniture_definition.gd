class_name FurnitureDefinition
extends Resource
## Definição de um tipo de móvel (dado de conteúdo).
##
## Cada arquivo .tres em res://data/furniture é um móvel do catálogo. Preços,
## níveis e atributos são parâmetros de balanceamento: ajuste-os no inspetor
## da Godot, sem mexer em código.

## MACHINE (DT-052): máquina de bebida (fica no fim, para os .tres antigos manterem o número da categoria).
enum Category { TABLE, SEATING, COOKING, COUNTER, DECOR, MACHINE }

## Identificador único e estável. Nunca mude depois que houver saves usando.
@export var id: StringName
@export var display_name := ""
@export var category := Category.DECOR
## Células ocupadas na rotação 0 (largura em x, profundidade em y).
@export var footprint := Vector2i.ONE
## Se true, precisa de pelo menos uma célula vizinha alcançável a partir da
## entrada (é onde cliente ou garçom param para usar o móvel).
@export var needs_access := true
## Coleção da loja (estilo ou cultura) a que o móvel pertence (res://data/collections).
@export var collection: StringName = &"classico"
## Máquina de bebida: que bebidas ela prepara (o campo machine das DrinkDefinition). Vazio nos outros móveis.
@export var machine: StringName = &""

@export_group("Balanceamento")
@export var price := 0
@export var min_level := 1
@export_range(0, 100) var beauty := 0
@export_range(0, 100) var efficiency := 0
@export_range(0, 100) var comfort := 0

@export_group("Troféu acelerador (DT-057)")
## Quanto mais rápidos ficam os fogões nas 8 casas em volta (0.25 = 25% menos tempo). 0 = não é troféu.
@export_range(0.0, 0.9) var stove_speed_bonus := 0.0
## Pratos que o troféu acelera antes de se gastar.
@export var trophy_dishes := 0
## Café Ouro para renovar o troféu (voltar às cargas cheias).
@export var renew_price := 0

@export_group("Placeholder")
## PLACEHOLDER_FURNITURE: cor da caixa desenhada até existir arte final.
@export var placeholder_color := Color.WHITE
## PLACEHOLDER_FURNITURE: altura da caixa, em pixels de mundo.
@export var placeholder_height := 32.0


func is_valid() -> bool:
	return id != &"" and footprint.x > 0 and footprint.y > 0 and price >= 0 and min_level >= 1 \
		and (category == Category.MACHINE) == (machine != &"") \
		and (not is_trophy() or (trophy_dishes > 0 and renew_price >= 0))


## Troféu que acelera os fogões em volta (DT-057)?
func is_trophy() -> bool:
	return stove_speed_bonus > 0.0
