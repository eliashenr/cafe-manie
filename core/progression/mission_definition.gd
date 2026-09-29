class_name MissionDefinition
extends Resource
## Uma missão (res://data/missions). As missões iniciais formam uma sequência
## que ensina o jogo jogando (seções 143 e 144): cada uma diz o que fazer e dá
## uma dica curta.

enum Kind {
	COLLECT_DISHES,   ## levar pratos prontos do fogão ao balcão
	SERVE_CUSTOMERS,  ## clientes servidos que pagaram
	EARN_GOLD,        ## Café Ouro ganho em vendas
	BUY_FURNITURE,    ## móveis comprados (opcionalmente de uma categoria)
	REACH_LEVEL,      ## chegar a um nível
	EXPAND_CAFE,      ## expansões feitas
}

@export var id: StringName
## Posição na sequência (menor vem antes).
@export var order := 0
@export var title := ""
## Dica curta de como cumprir (aparece embaixo do título).
@export var hint := ""
@export var kind := Kind.COLLECT_DISHES
@export var target := 1
## Só para BUY_FURNITURE: categoria exigida (FurnitureDefinition.Category), ou -1 para qualquer.
@export var furniture_category := -1

@export_group("Recompensa")
@export var reward_gold := 0
@export var reward_xp := 0


func is_valid() -> bool:
	return id != &"" and not title.is_empty() and target > 0 and reward_gold >= 0 and reward_xp >= 0
