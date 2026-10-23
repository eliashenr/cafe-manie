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
## Quantos desse móvel cabem na cafeteria (0 = sem limite).
@export var max_per_cafe := 0
## Atração (DT-066): ouro que cada cliente deixa ao brincar, quanto ouro cabe guardado e quantos segundos ele brinca.
@export var attraction_gold := 0
@export var attraction_capacity := 0
@export var attraction_time := 0.0
## Palco (DT-066): com ele na cafeteria, de tempos em tempos tem show e os clientes chegam mais rápido.
@export var stage := false
## Balcão de Entregas (DT-071): com ele na cafeteria, chegam pedidos de porções para mandar para casa.
@export var delivery := false
## Pé de fruta (DT-065): a fruta que dá, quanto tempo leva para amadurecer e quantas frutas dá por colheita.
@export var fruit: StringName = &""
@export var fruit_grow_time := 0.0
@export var fruit_yield := 0
## Luminária (DT-064): raio da luz que acende à noite, em pixels de mundo (0 = não acende).
@export var light_radius := 0.0
## false = não se compra com ouro: só se ganha (prêmio de conjunto, de evento ou da loja de cupons).
@export var sold_for_gold := true
## Cupons para trocar na aba Cupons da loja (DT-062); 0 = não está na loja de troca.
@export var coupon_price := 0
## Temporada da loja de troca em que o item aparece (-1 = em todas).
@export var coupon_season := -1

@export_group("Perfil do fogão (DT-058)")
## Corte no tempo de preparo (0.25 = 25% menos tempo).
@export_range(0.0, 0.9) var stove_time_cut := 0.0
## Nenhum prato demora mais que isso neste fogão, em segundos (0 = sem limite).
@export var stove_max_time := 0.0
## Porções a mais em cada prato (0.15 = +15%, pelo menos 1 a mais).
@export_range(0.0, 2.0) var stove_servings_bonus := 0.0
## XP a mais ao tirar cada prato (0.25 = +25%).
@export_range(0.0, 2.0) var stove_xp_bonus := 0.0
## Fogão de evento (DT-063): corte no tempo de preparo em cada nível (o 1º valor é o do nível 1).
@export var stove_level_cuts: PackedFloat32Array = []

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
		and (not is_trophy() or (trophy_dishes > 0 and renew_price >= 0)) \
		and max_per_cafe >= 0 and stove_max_time >= 0.0 and coupon_price >= 0 \
		and (fruit == &"" or (fruit_grow_time > 0.0 and fruit_yield > 0)) \
		and (attraction_gold == 0 or (attraction_capacity >= attraction_gold and attraction_time > 0.0)) \
		and (coupon_price == 0 or not sold_for_gold) \
		and (category == Category.COOKING or not has_stove_profile())


## Fogão com perfil (DT-058): mais rápido, com tempo máximo, mais porções ou mais XP?
func has_stove_profile() -> bool:
	return stove_time_cut > 0.0 or stove_max_time > 0.0 or stove_servings_bonus > 0.0 or stove_xp_bonus > 0.0 \
		or not stove_level_cuts.is_empty()


## Troféu que acelera os fogões em volta (DT-057)?
func is_trophy() -> bool:
	return stove_speed_bonus > 0.0
