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
	WAITING_FOR_DRINK, ## pediu uma bebida: espera o jogador tocar nele (DT-052)
	WALKING_TO_PLAY,   ## depois de pagar, a caminho de uma atração (DT-066)
	PLAYING,           ## brincando na atração; depois deixa o ouro e vai embora
}

var type: CustomerType
var state := State.WALKING_IN
## Cadeira reservada para este cliente.
var seat_id: StringName = &""
var seat_cell := Vector2i.ZERO
## O prato que pediu (null até pedir, ou se pediu uma bebida).
var order: RecipeDefinition
## A bebida que pediu (null se pediu um prato).
var drink: DrinkDefinition
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
## É o crítico gastronômico (DT-061).
var critic := false
## Atração em que vai brincar (DT-066) e quantos segundos ainda brinca.
var attraction_id: StringName = &""
var play_left := 0.0


func patience_fraction() -> float:
	return clampf(patience_left / patience_total, 0.0, 1.0)


func is_seated() -> bool:
	return state in [State.WAITING_TO_ORDER, State.WAITING_FOR_FOOD, State.WAITING_FOR_DRINK, State.EATING]
