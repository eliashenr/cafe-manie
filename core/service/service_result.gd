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
}
