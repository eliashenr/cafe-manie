class_name ServiceResult
extends RefCounted
## Resultados das ações de cozinha e atendimento, para a interface explicar
## ao jogador por que algo não aconteceu.

enum {
	OK,
	NOT_A_STOVE,        ## o móvel escolhido não é um fogão
	STOVE_BUSY,         ## o fogão já está cozinhando ou com prato pronto
	NOT_READY,          ## ainda não terminou (ou está vazio)
	NO_COUNTER_SPACE,   ## nenhum balcão com espaço para as porções
	RECIPE_LOCKED,      ## nível insuficiente para a receita
	NOT_ENOUGH_GOLD,    ## ouro insuficiente para os ingredientes
	UNKNOWN_RECIPE,     ## receita inexistente
	FURNITURE_LOCKED,   ## nível insuficiente para comprar o móvel
	INVALID_PLACEMENT,  ## o móvel não pode ficar nessa posição (motivo no CafeLayout.Check)
	NO_MORE_EXPANSIONS, ## a cafeteria já está no tamanho máximo
	EXPANSION_LOCKED,   ## nível insuficiente para a próxima expansão
	SURFACE_LOCKED,     ## nível insuficiente para o revestimento
	UNKNOWN_ITEM,       ## item (móvel, revestimento) inexistente
	IN_USE,             ## o móvel está sendo usado agora
	LAST_ESSENTIAL,     ## é o último fogão ou balcão: sem ele o jogo trava
	NO_MORE_WAITERS,    ## a cafeteria já tem todos os garçons possíveis
	WAITER_LOCKED,      ## nível insuficiente para contratar o próximo garçom
	NOT_WAITING_FOR_DRINK, ## o cliente não está esperando uma bebida
	NO_MACHINE,         ## falta a máquina dessa bebida
	NOT_ENOUGH_ENERGY,  ## energia insuficiente para a bebida
	SPOILED,            ## o prato pronto estragou no fogão: só dá para jogar fora
	NOT_SPOILED,        ## não há prato estragado para jogar fora (nem para salvar com tempero)
	NO_SPICE,           ## não há esse tempero na prateleira
	SPICE_LOCKED,       ## nível insuficiente para comprar o tempero
	NOT_COOKING,        ## o tempero só serve para o prato que está cozinhando
	ALREADY_SEASONED,   ## o prato já levou tempero de porções
	NOT_A_TROPHY,       ## o móvel escolhido não é um troféu acelerador
	TROPHY_FULL,        ## o troféu ainda está com as cargas cheias
	FURNITURE_LIMIT,    ## a cafeteria já tem o máximo desse móvel
	WRONG_STOVE,        ## a receita só sai num fogão temático (DT-059)
	NOT_FOR_SALE,       ## o móvel não se compra com ouro: só se ganha (DT-060)
	NOT_IN_SEASON,      ## o item da loja de troca não está nesta temporada (DT-062)
	NOT_ENOUGH_COUPONS, ## cupons insuficientes para a troca
	NOT_NIGHT,          ## prato do cardápio noturno: só começa à noite (DT-064)
	NOT_A_TREE,         ## o móvel escolhido não é um pé de fruta (DT-065)
	NOT_RIPE,           ## as frutas ainda não amadureceram
	NO_FRUIT,           ## faltam frutas para o frozen yogurt
	NOT_AN_ATTRACTION,  ## o móvel escolhido não é uma atração (DT-066)
	NOTHING_TO_COLLECT, ## a atração ainda não tem ouro
	DOOR_LOCKED,        ## nível insuficiente para a porta (DT-067)
	NOT_DIRTY,          ## não há mancha nesse piso (DT-068)
	TERRACE_LOCKED,     ## nível insuficiente para o terraço (DT-069)
	ALREADY_BUILT,      ## o terraço já foi construído
	AVATAR_LOCKED,      ## nível insuficiente para a peça do avatar (DT-070)
}
