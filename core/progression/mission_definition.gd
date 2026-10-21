class_name MissionDefinition
extends Resource
## Uma missão. As iniciais (res://data/missions) formam uma sequência que ensina
## o jogo jogando (seções 143 e 144): cada uma diz o que fazer e dá uma dica curta.
## As diárias e as semanais (res://data/missions/daily e /weekly) valem todas ao
## mesmo tempo num MissionBoard, com metas e recompensas que crescem com o nível.

enum Kind {
	COLLECT_DISHES,   ## levar pratos prontos do fogão ao balcão
	SERVE_CUSTOMERS,  ## clientes servidos que pagaram
	EARN_GOLD,        ## Café Ouro ganho em vendas
	BUY_FURNITURE,    ## móveis comprados (opcionalmente de uma categoria)
	REACH_LEVEL,      ## chegar a um nível
	EXPAND_CAFE,      ## expansões feitas
	HAPPY_CUSTOMERS,  ## clientes servidos antes de a paciência cair da metade
	EARN_XP,          ## XP ganho cozinhando e servindo (recompensa de missão não conta)
	COOK_DIFFERENT,   ## receitas diferentes levadas ao balcão no período
	CLAIM_DAILY_GIFT, ## presentes diários recebidos
	MENU_ORDERS,      ## pedidos servidos que não estavam no balcão quando o cliente pediu
	SPEND_INGREDIENTS,  ## Café Ouro gasto em ingredientes
	PAINT_FLOOR,      ## pisos reformados
	PAINT_WALL,       ## trechos de parede pintados
	HANG_WALL_ITEMS,  ## trechos com item de parede pendurado
	COMPLETE_DAILY,   ## missões diárias concluídas
	COOK_SLOW,        ## pratos de preparo demorado levados ao balcão (min_cook_time)
	REACH_POPULARITY, ## chegar a uma popularidade (%)
	QUEUE_SEATED,     ## clientes da fila que conseguiram cadeira
}

@export var id: StringName
## Posição na sequência (menor vem antes).
@export var order := 0
## Título; nas diárias e semanais, %d vira a meta (ex.: "Sirva %d clientes").
@export var title := ""
## Dica curta de como cumprir (aparece embaixo do título).
@export var hint := ""
@export var kind := Kind.COLLECT_DISHES
@export var target := 1
## Só para BUY_FURNITURE: categoria exigida (FurnitureDefinition.Category), ou -1 para qualquer.
@export var furniture_category := -1
## Quanto a meta cresce por nível acima do 1 (diárias e semanais).
@export var target_per_level := 0.0
## Nível a partir do qual a missão vale (antes fica com o cadeado).
@export var min_level := 1
## Só para COOK_SLOW: tempo de preparo mínimo da receita, em segundos.
@export var min_cook_time := 0.0
## Só para COOK_DIFFERENT: a meta nunca passa do número de receitas liberadas.
@export var limit_to_unlocked_recipes := false

@export_group("Recompensa")
@export var reward_gold := 0
@export var reward_xp := 0
@export var reward_gold_per_level := 0.0
@export var reward_xp_per_level := 0.0


func is_valid() -> bool:
	return id != &"" and not title.is_empty() and target > 0 and reward_gold >= 0 and reward_xp >= 0 \
		and target_per_level >= 0.0 and reward_gold_per_level >= 0.0 and reward_xp_per_level >= 0.0 and min_level >= 1


## Missão de estado (o progresso é o maior valor visto, não uma soma).
func is_state() -> bool:
	return kind in [Kind.REACH_LEVEL, Kind.REACH_POPULARITY]


## Meta no nível [param level], arredondada para um número redondo. [param unlocked_recipes] limita
## "pratos diferentes".
func target_at(level: int, unlocked_recipes := 0) -> int:
	var value := MissionDefinition.round_nice(target + target_per_level * (level - 1))
	if limit_to_unlocked_recipes and unlocked_recipes > 0:
		value = mini(value, unlocked_recipes)
	return maxi(value, 1)


func reward_gold_at(level: int) -> int:
	return MissionDefinition.round_nice(reward_gold + reward_gold_per_level * (level - 1))


func reward_xp_at(level: int) -> int:
	return MissionDefinition.round_nice(reward_xp + reward_xp_per_level * (level - 1))


## Título com a meta no lugar do %d.
func title_for(goal: int) -> String:
	return title % goal if title.contains("%d") else title


## Arredonda para um número fácil de ler: até 20 de 1 em 1, até 100 de 5 em 5, até 1.000 de 10 em
## 10 e depois de 50 em 50.
static func round_nice(value: float) -> int:
	var step := 1 if value < 20.0 else (5 if value < 100.0 else (10 if value < 1000.0 else 50))
	return roundi(value / step) * step
