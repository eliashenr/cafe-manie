class_name Customer
extends Agent
## Cliente: espera na fila (se não há cadeira), entra, senta, pede, espera, come, paga e vai embora.
## Quem move a máquina de estados é a CafeSimulation.

enum State {
	WALKING_IN,        ## a caminho do assento
	WAITING_TO_ORDER,  ## sentado, olhando o cardápio
	WAITING_FOR_FOOD,  ## pediu, esperando o garçom
	EATING,
	LEAVING,           ## indo para a saída (satisfeito ou irritado)
	GONE,              ## saiu; será removido
	QUEUED,            ## na fila da calçada, esperando vagar uma cadeira
}

var type: CustomerType
var state := State.WALKING_IN
## Cadeira reservada para este cliente.
var seat_id: StringName = &""
var seat_cell := Vector2i.ZERO
## O que pediu (null até pedir).
var order: RecipeDefinition
var patience_total := 1.0
var patience_left := 1.0
## Fração de paciência que restava quando foi servido (define o ganho de popularidade).
var patience_when_served := 0.0
var eat_left := 0.0
## Segundos olhando o cardápio antes de pedir.
var think_left := 0.0
## Saiu satisfeito (true) ou irritado (false). Só vale em LEAVING/GONE.
var happy := false
## Desistiu na fila da calçada, sem chegar a sentar.
var gave_up_in_line := false
## Ouro pago (0 se saiu sem ser servido).
var paid := 0
## O prato pedido não estava no balcão na hora do pedido (o jogador teve que cozinhar).
var ordered_from_menu := false


func patience_fraction() -> float:
	return clampf(patience_left / patience_total, 0.0, 1.0)


func is_seated() -> bool:
	return state in [State.WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.EATING]
