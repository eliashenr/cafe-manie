extends Node
## Canal central de sinais entre sistemas.
##
## Sistemas emitem e escutam aqui em vez de se referenciarem diretamente,
## o que mantém os módulos desacoplados. Só declare aqui sinais que mais de
## um sistema precisa conhecer.

## Emitido quando o jogador seleciona uma célula do grid.
## Recebe CafeGrid.NO_CELL quando a seleção é limpa.
@warning_ignore("unused_signal")
signal cell_selected(cell: Vector2i)
