class_name Waiter
extends Agent
## Garçom: leva os pedidos do balcão até a mesa e busca nos fogões os pratos prontos
## (só não começa a cozinhar: isso é com o jogador). Sem tarefa, circula entre fogões e balcões.
## Quem move a máquina de estados é a CafeSimulation.

enum State {
	IDLE,         ## parado perto da cozinha, sem tarefa
	RETURNING,    ## indo para outro fogão ou balcão (pega tarefa no caminho)
	TO_COUNTER,   ## indo buscar o prato do pedido
	PICKING_UP,
	TO_TABLE,     ## levando o prato
	DELIVERING,
	TO_STOVE,     ## indo buscar um prato pronto no fogão
	COLLECTING,
	TO_DROP,      ## levando o prato do fogão para o balcão
	DROPPING,
}

var state := State.IDLE
## Robô Garçom (DT-082): só o visual muda; a CafeSimulation marca na contratação.
var robot := false
## Pedido em andamento (CafeSimulation.Order) ou null.
var order: RefCounted
## Fogão de onde vai buscar o prato pronto (&"" se nenhum).
var stove_id: StringName = &""
## Balcão onde vai deixar o prato que buscou no fogão.
var drop_counter: StringName = &""
## Receita que está carregando (null se de mãos vazias).
var carrying: RecipeDefinition
## Tempo da ação atual (pegar, entregar) ou da pausa parado.
var timer := 0.0
