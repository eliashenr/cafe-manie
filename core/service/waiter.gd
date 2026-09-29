class_name Waiter
extends Agent
## Garçom: pega pedidos da fila, busca o prato no balcão e leva até a mesa.
## Quem move a máquina de estados é a CafeSimulation.

enum State {
	IDLE,         ## parado, sem pedido
	RETURNING,    ## voltando para o posto (pode pegar pedido no caminho)
	TO_COUNTER,   ## indo buscar o prato
	PICKING_UP,
	TO_TABLE,     ## levando o prato
	DELIVERING,
}

var state := State.IDLE
## Piso onde fica esperando pedidos.
var home := Vector2i.ZERO
## Pedido em andamento (CafeSimulation.Order) ou null.
var order: RefCounted
## Receita que está carregando (null se de mãos vazias).
var carrying: RecipeDefinition
var timer := 0.0
